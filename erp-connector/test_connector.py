import random
import threading
import unittest

import connector
import mock_erp


def delivered_item(item_id=1, key="trip.delivered:1", attempts=0):
    return {
        "id": item_id,
        "eventType": "trip.delivered",
        "idempotencyKey": key,
        "attempts": attempts,
        "payload": {
            "tripRef": "KL-00001",
            "origin": "Bugolobi Depot",
            "destination": "Gulu DC",
            "cargo": "120 cartons",
            "driver": {"id": 2, "name": "Joseph Okello"},
            "vehiclePlate": "UBA 123X",
            "deliveredAt": "2026-11-16T10:00:00.000Z",
        },
    }


def fuel_item(item_id=2, fuel_id=7):
    return {
        "id": item_id,
        "eventType": "fuel.recorded",
        "idempotencyKey": f"fuel.recorded:{fuel_id}",
        "attempts": 0,
        "payload": {
            "fuelLogId": fuel_id,
            "tripRef": "KL-00001",
            "driver": {"id": 2, "name": "Joseph Okello"},
            "vehiclePlate": "UBA 123X",
            "liters": 55.5,
            "costUgx": 255000,
            "odometerKm": 48210,
            "recordedAt": "2026-11-16T08:00:00.000Z",
        },
    }


class FakeApi:
    def __init__(self, items):
        self.items = items
        self.acks = {}

    def pending(self, limit=50):
        return [i for i in self.items if self.acks.get(i["id"], ("pending",))[0] != "synced"]

    def ack(self, item_id, status, error=None):
        self.acks[item_id] = (status, error)


class ErpServer:
    """Runs the mock ERP on an ephemeral port for the duration of a test."""

    def __init__(self, flaky=0.0, seed=1):
        self.httpd, self.state = mock_erp.serve(port=0, flaky=flaky)
        self.state.rng = random.Random(seed)
        self.thread = threading.Thread(target=self.httpd.serve_forever, daemon=True)

    def __enter__(self):
        self.thread.start()
        port = self.httpd.server_address[1]
        self.client = connector.ErpClient(f"http://127.0.0.1:{port}", mock_erp.API_KEY)
        return self

    def __exit__(self, *exc):
        self.httpd.shutdown()
        self.httpd.server_close()


class MappingTests(unittest.TestCase):
    def test_trip_delivered_is_translated_to_erp_vocabulary(self):
        path, body = connector.map_event(delivered_item())
        self.assertEqual(path, "/erp/v1/fleet/trip-completions")
        self.assertEqual(body["reference"], "KL-00001")
        self.assertEqual(body["route"], {"from": "Bugolobi Depot", "to": "Gulu DC"})
        self.assertEqual(body["vehicleRegistration"], "UBA 123X")

    def test_fuel_is_translated_with_currency(self):
        path, body = connector.map_event(fuel_item())
        self.assertEqual(path, "/erp/v1/finance/fuel-expenses")
        self.assertEqual(body["expenseRef"], "FUEL-7")
        self.assertEqual(body["amount"], {"value": 255000, "currency": "UGX"})

    def test_unknown_event_is_a_permanent_error(self):
        with self.assertRaises(connector.PermanentError):
            connector.map_event({"eventType": "mystery", "payload": {}})


class SyncTests(unittest.TestCase):
    def test_happy_path_syncs_everything(self):
        api = FakeApi([delivered_item(), fuel_item()])
        with ErpServer() as erp:
            summary = connector.run_once(api, erp.client, sleep=lambda _: None)
            self.assertEqual((summary.synced, summary.failed), (2, 0))
            self.assertEqual(len(erp.state.records), 2)
        self.assertEqual(api.acks[1][0], "synced")

    def test_same_event_sent_twice_is_booked_once(self):
        # Simulates a lost ack: the connector delivers, the API never learns, it retries.
        item = delivered_item()
        with ErpServer() as erp:
            for _ in range(2):
                connector.run_once(FakeApi([item]), erp.client, sleep=lambda _: None)
            self.assertEqual(len(erp.state.records), 1)

    def test_transient_outage_is_retried_then_succeeds(self):
        api = FakeApi([delivered_item()])
        sleeps = []
        with ErpServer() as erp:
            erp.state.flaky = 1.0
            calls = {"n": 0}
            real_post = erp.client.post

            def post_then_recover(path, body, key):
                calls["n"] += 1
                if calls["n"] == 3:
                    erp.state.flaky = 0.0  # ERP comes back on the third try
                return real_post(path, body, key)

            erp.client.post = post_then_recover
            summary = connector.run_once(api, erp.client, backoff=0.5, sleep=sleeps.append)
            self.assertEqual((summary.synced, summary.failed), (1, 0))
            self.assertEqual(sleeps, [0.5, 1.0])  # exponential backoff

    def test_long_outage_marks_item_failed_without_losing_it(self):
        api = FakeApi([delivered_item()])
        with ErpServer(flaky=1.0) as erp:
            summary = connector.run_once(api, erp.client, retries=2, sleep=lambda _: None)
            self.assertEqual((summary.synced, summary.failed), (0, 1))
            self.assertEqual(api.acks[1][0], "failed")
            self.assertEqual(erp.state.records, [])

    def test_permanent_rejection_is_not_retried(self):
        item = delivered_item()
        sleeps = []
        api = FakeApi([item])
        with ErpServer() as erp:
            # Strip a required field via a custom mapping to force a 422.
            original = connector.map_event
            connector.map_event = lambda i: (original(i)[0], {"reference": "KL-00001"})
            try:
                summary = connector.run_once(api, erp.client, sleep=sleeps.append)
            finally:
                connector.map_event = original
        self.assertEqual(summary.failed, 1)
        self.assertEqual(sleeps, [])
        self.assertIn("422", api.acks[1][1])

    def test_wrong_erp_key_is_permanent(self):
        api = FakeApi([delivered_item()])
        with ErpServer() as erp:
            bad = connector.ErpClient(erp.client.base_url, "wrong-key")
            summary = connector.run_once(api, bad, sleep=lambda _: None)
        self.assertEqual(summary.failed, 1)
        self.assertIn("401", api.acks[1][1])

    def test_items_past_max_attempts_are_skipped(self):
        api = FakeApi([delivered_item(attempts=5)])
        with ErpServer() as erp:
            summary = connector.run_once(api, erp.client, max_attempts=5, sleep=lambda _: None)
            self.assertEqual((summary.synced, summary.failed, summary.skipped), (0, 0, 1))
            self.assertEqual(erp.state.records, [])


if __name__ == "__main__":
    unittest.main()
