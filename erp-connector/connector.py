"""Drains the fleet API's ERP outbox into an ERP.

Design notes (the part worth talking about in an interview):

* Transactional outbox: the API writes ERP events in the same database
  transaction as the business change. This worker delivers them afterwards, so
  an ERP outage never loses data or blocks a driver.
* At-least-once delivery + idempotency: an event may be sent twice (the ack can
  be lost), so every request carries an Idempotency-Key and the ERP de-duplicates.
* Mapping layer: the fleet API and the ERP name the same facts differently.
  Translation lives in one place (``map_event``) so changing ERP vendor means
  changing one function.
* Retries with backoff for transient errors (5xx, timeouts); permanent errors
  (4xx) are recorded and not hammered; items that keep failing stop being retried
  (``max_attempts``) so they can be reviewed by a person.

Run once:   python connector.py --once
Run loop:   python connector.py --interval 10
"""
from __future__ import annotations

import argparse
import json
import time
import urllib.error
import urllib.request
from dataclasses import dataclass, field


class PermanentError(Exception):
    """The ERP rejected the data; retrying the same request will not help."""


class TransientError(Exception):
    """Network problem or ERP outage; worth retrying."""


# ---------- mapping layer (fleet API vocabulary -> ERP vocabulary) ----------

def map_event(item: dict) -> tuple[str, dict]:
    """Return (ERP path, ERP request body) for one outbox item."""
    event_type = item["eventType"]
    p = item["payload"]

    if event_type == "trip.delivered":
        return "/erp/v1/fleet/trip-completions", {
            "reference": p["tripRef"],
            "route": {"from": p["origin"], "to": p["destination"]},
            "cargoDescription": p["cargo"],
            "driverName": p["driver"]["name"],
            "vehicleRegistration": p["vehiclePlate"],
            "completedAt": p["deliveredAt"],
        }
    if event_type == "fuel.recorded":
        return "/erp/v1/finance/fuel-expenses", {
            "expenseRef": f"FUEL-{p['fuelLogId']}",
            "tripReference": p["tripRef"],
            "vehicleRegistration": p["vehiclePlate"],
            "quantityLitres": p["liters"],
            "amount": {"value": p["costUgx"], "currency": "UGX"},
            "odometerKm": p.get("odometerKm"),
            "postedAt": p["recordedAt"],
        }
    if event_type == "incident.reported":
        return "/erp/v1/fleet/incidents", {
            "incidentRef": f"INC-{p['incidentId']}",
            "tripReference": p["tripRef"],
            "vehicleRegistration": p["vehiclePlate"],
            "category": p["category"],
            "description": p["note"],
            "reportedAt": p["reportedAt"],
        }
    raise PermanentError(f"unsupported event type: {event_type}")


# ---------- HTTP clients ----------

def _request(method: str, url: str, headers: dict, body: dict | None = None, timeout: float = 10.0):
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(url, data=data, method=method, headers={"Content-Type": "application/json", **headers})
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            return resp.status, json.loads(resp.read() or b"{}")
    except urllib.error.HTTPError as err:
        try:
            payload = json.loads(err.read() or b"{}")
        except json.JSONDecodeError:
            payload = {}
        return err.code, payload
    except (urllib.error.URLError, TimeoutError, ConnectionError) as err:
        raise TransientError(f"network error: {err}") from err


class FleetApiClient:
    def __init__(self, base_url: str, service_key: str):
        self.base_url = base_url.rstrip("/")
        self.headers = {"X-Service-Key": service_key}

    def pending(self, limit: int = 50) -> list[dict]:
        status, body = _request("GET", f"{self.base_url}/api/erp/outbox?status=pending,failed&limit={limit}", self.headers)
        if status != 200:
            raise TransientError(f"fleet API returned {status}")
        return body["items"]

    def ack(self, item_id: int, status: str, error: str | None = None) -> None:
        payload = {"status": status}
        if error:
            payload["error"] = error
        code, _ = _request("POST", f"{self.base_url}/api/erp/outbox/{item_id}/ack", self.headers, payload)
        if code != 200:
            raise TransientError(f"ack failed with {code}")


class ErpClient:
    def __init__(self, base_url: str, api_key: str):
        self.base_url = base_url.rstrip("/")
        self.headers = {"X-ERP-Key": api_key}

    def post(self, path: str, body: dict, idempotency_key: str) -> dict:
        status, resp = _request(
            "POST", self.base_url + path, {**self.headers, "Idempotency-Key": idempotency_key}, body
        )
        if status in (200, 201):
            return resp
        if status in (408, 429) or status >= 500:
            raise TransientError(f"ERP returned {status}")
        raise PermanentError(f"ERP rejected the request ({status}): {json.dumps(resp)[:200]}")


# ---------- the sync cycle ----------

@dataclass
class Summary:
    synced: int = 0
    failed: int = 0
    skipped: int = 0
    errors: list[str] = field(default_factory=list)


def deliver(erp, item: dict, retries: int, backoff: float, sleep=time.sleep) -> None:
    path, body = map_event(item)
    for attempt in range(retries + 1):
        try:
            erp.post(path, body, item["idempotencyKey"])
            return
        except TransientError:
            if attempt == retries:
                raise
            sleep(backoff * (2 ** attempt))


def run_once(api, erp, *, max_attempts: int = 5, retries: int = 3, backoff: float = 0.5, sleep=time.sleep) -> Summary:
    summary = Summary()
    for item in api.pending():
        if item["attempts"] >= max_attempts:
            summary.skipped += 1  # dead-letter: needs a human, stop retrying
            continue
        try:
            deliver(erp, item, retries, backoff, sleep)
        except (PermanentError, TransientError) as err:
            api.ack(item["id"], "failed", str(err))
            summary.failed += 1
            summary.errors.append(f"#{item['id']} {item['eventType']}: {err}")
        else:
            api.ack(item["id"], "synced")
            summary.synced += 1
    return summary


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--api", default="http://127.0.0.1:3000")
    parser.add_argument("--api-key", default="dev-erp-key", help="service key of the fleet API")
    parser.add_argument("--erp", default="http://127.0.0.1:9000")
    parser.add_argument("--erp-key", default="dev-erp-secret")
    parser.add_argument("--interval", type=float, default=10.0, help="seconds between cycles")
    parser.add_argument("--once", action="store_true", help="run a single cycle and exit")
    args = parser.parse_args()

    api = FleetApiClient(args.api, args.api_key)
    erp = ErpClient(args.erp, args.erp_key)

    while True:
        try:
            s = run_once(api, erp)
            print(f"synced={s.synced} failed={s.failed} skipped={s.skipped}")
            for line in s.errors:
                print("  !", line)
        except TransientError as err:
            print("cycle skipped:", err)
        if args.once:
            break
        time.sleep(args.interval)


if __name__ == "__main__":
    main()
