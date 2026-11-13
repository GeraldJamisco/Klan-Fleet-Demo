"""A pretend ERP, for demos and tests only.

Real ERPs differ (SAP, Odoo, Dynamics, in-house systems), but they share the
traits this mock reproduces: API-key auth, its own vocabulary for the same
business facts, and occasional outages. Run it with:

    python mock_erp.py --port 9000            # always up
    python mock_erp.py --port 9000 --flaky 0.3  # fails ~30% of calls with 503
"""
from __future__ import annotations

import argparse
import json
import random
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

API_KEY = "dev-erp-secret"

ROUTES = {
    "/erp/v1/fleet/trip-completions": ("reference", {"reference", "route", "completedAt"}),
    "/erp/v1/finance/fuel-expenses": ("expenseRef", {"expenseRef", "amount", "vehicleRegistration"}),
    "/erp/v1/fleet/incidents": ("incidentRef", {"incidentRef", "category", "vehicleRegistration"}),
}


class ErpState:
    """In-memory ledger plus the idempotency table."""

    def __init__(self, flaky: float = 0.0, api_key: str = API_KEY, rng: random.Random | None = None):
        self.flaky = flaky
        self.api_key = api_key
        self.rng = rng or random.Random()
        self.lock = threading.Lock()
        self.records: list[dict] = []
        self.by_idempotency_key: dict[str, dict] = {}

    def should_fail(self) -> bool:
        return self.flaky > 0 and self.rng.random() < self.flaky


def make_handler(state: ErpState):
    class Handler(BaseHTTPRequestHandler):
        def log_message(self, fmt, *args):  # keep test output quiet
            pass

        def _send(self, status: int, body: dict):
            data = json.dumps(body).encode()
            self.send_response(status)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(data)))
            self.end_headers()
            self.wfile.write(data)

        def _authorised(self) -> bool:
            return self.headers.get("X-ERP-Key") == state.api_key

        def do_GET(self):
            if not self._authorised():
                return self._send(401, {"error": "bad api key"})
            if self.path == "/erp/v1/records":
                with state.lock:
                    return self._send(200, {"records": list(state.records)})
            self._send(404, {"error": "not found"})

        def do_POST(self):
            if not self._authorised():
                return self._send(401, {"error": "bad api key"})
            if self.path not in ROUTES:
                return self._send(404, {"error": "not found"})
            if state.should_fail():
                return self._send(503, {"error": "ERP temporarily unavailable"})

            length = int(self.headers.get("Content-Length") or 0)
            try:
                body = json.loads(self.rfile.read(length) or b"{}")
            except json.JSONDecodeError:
                return self._send(400, {"error": "invalid json"})

            key_field, required = ROUTES[self.path]
            missing = sorted(required - set(body))
            if missing:
                return self._send(422, {"error": "missing fields", "fields": missing})

            idem = self.headers.get("Idempotency-Key")
            if not idem:
                return self._send(400, {"error": "Idempotency-Key header required"})

            with state.lock:
                existing = state.by_idempotency_key.get(idem)
                if existing:
                    # Same event delivered twice (e.g. our ack was lost): do not double-book.
                    return self._send(200, {"status": "duplicate", "erpId": existing["erpId"]})
                record = {
                    "erpId": f"ERP-{len(state.records) + 1:05d}",
                    "path": self.path,
                    "externalRef": body[key_field],
                    "body": body,
                }
                state.records.append(record)
                state.by_idempotency_key[idem] = record
            self._send(201, {"status": "created", "erpId": record["erpId"]})

    return Handler


def serve(port: int = 9000, flaky: float = 0.0, api_key: str = API_KEY):
    state = ErpState(flaky=flaky, api_key=api_key)
    server = ThreadingHTTPServer(("127.0.0.1", port), make_handler(state))
    return server, state


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--port", type=int, default=9000)
    parser.add_argument("--flaky", type=float, default=0.0, help="probability (0-1) of a 503 per request")
    args = parser.parse_args()
    httpd, _ = serve(args.port, args.flaky)
    print(f"Mock ERP listening on http://127.0.0.1:{args.port} (flaky={args.flaky})")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        pass
