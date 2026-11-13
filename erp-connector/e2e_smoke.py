"""End-to-end demo: driver completes a trip -> events land in the ERP.

Start these first (three terminals):
    cd api && npm start
    cd erp-connector && python mock_erp.py
Then run:
    python e2e_smoke.py

It plays the driver (log in, pick up, log fuel, report a delay, deliver), then runs
one connector cycle and prints what the ERP received. Fresh seed data has trip
KL-00002 assigned to driver 0700000012; re-seed (delete api/klan-demo.db) to repeat.
"""
import json
import sys
import urllib.request

import connector
import mock_erp

API = "http://127.0.0.1:3000"
ERP = "http://127.0.0.1:9000"


def call(method, path, token=None, body=None):
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    req = urllib.request.Request(API + path, method=method, headers=headers,
                                 data=json.dumps(body).encode() if body is not None else None)
    try:
        with urllib.request.urlopen(req) as resp:
            return json.loads(resp.read())
    except urllib.error.HTTPError as err:
        print(f"  ! {method} {path} -> {err.code} {err.read().decode()}")
        sys.exit(1)


def main():
    driver = call("POST", "/api/auth/login", body={"phone": "0700000012", "pin": "2222"})
    token = driver["token"]
    print(f"Logged in as {driver['user']['name']}")

    trips = call("GET", "/api/trips?status=assigned", token)["trips"]
    if not trips:
        print("No assigned trip for this driver. Delete api/klan-demo.db and restart the API to re-seed.")
        sys.exit(1)
    trip = trips[0]
    print(f"Trip {trip['ref']}: {trip['origin']} -> {trip['destination']}")

    for status in ("picked_up", "in_transit"):
        call("POST", f"/api/trips/{trip['id']}/status", token, {"status": status, "lat": 0.3476, "lng": 32.5825})
        print(f"  status -> {status}")
    call("POST", f"/api/trips/{trip['id']}/fuel", token, {"liters": 80, "costUgx": 372000, "odometerKm": 51200})
    print("  fuel logged")
    call("POST", f"/api/trips/{trip['id']}/incidents", token, {"category": "delay", "note": "Traffic at Mukono"})
    print("  incident reported")
    call("POST", f"/api/trips/{trip['id']}/status", token, {"status": "delivered"})
    print("  status -> delivered")

    print("\nRunning one connector cycle...")
    summary = connector.run_once(
        connector.FleetApiClient(API, "dev-erp-key"),
        connector.ErpClient(ERP, mock_erp.API_KEY),
    )
    print(f"synced={summary.synced} failed={summary.failed} skipped={summary.skipped}")

    req = urllib.request.Request(ERP + "/erp/v1/records", headers={"X-ERP-Key": mock_erp.API_KEY})
    with urllib.request.urlopen(req) as resp:
        records = json.loads(resp.read())["records"]
    print("\nWhat the ERP now holds:")
    for r in records:
        print(f"  {r['erpId']}  {r['path']}  ref={r['externalRef']}")


if __name__ == "__main__":
    main()
