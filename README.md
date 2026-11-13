# Klan Fleet Demo

A working prototype of a **fleet and trips mobile app** for a logistics company, built as a portfolio piece
in response to the IT Officer (Mobile Applications Development) role: Flutter app, Node.js and Python back end,
integrated with an ERP.

All data is fake. Names, plates and phone numbers are invented. "Klan" is used only as the demo's working name.

## What it does

- **Drivers** log in, see their assigned trips, move a trip through *picked up, in transit, delivered*,
  log fuel, and report problems (breakdown, delay, accident, cargo damage).
- **Managers** see a live overview (trips by status, fleet availability, fuel spend, problems),
  create and assign trips to a driver and an available vehicle, cancel trips, and watch ERP sync health.
- **The ERP** receives delivered trips, fuel expenses and incidents automatically, in *its own* format.

## Architecture

```
 Flutter app  ──REST/JSON──►  Node.js API  ──► SQLite
 (drivers,       bearer          │  writes business change + outbox event
  managers)      token           │  in ONE transaction
                                 ▼
                          erp_outbox table
                                 ▲
                                 │ poll + ack (service key)
                       Python connector ──► ERP (mock)
                        map • retry • idempotency
```

| Part | Folder | Tech |
|---|---|---|
| Mobile app | `mobile/` | Flutter, provider, http |
| REST API | `api/` | Node.js, Express, SQLite (built-in `node:sqlite`, or `better-sqlite3` on older Node) |
| ERP connector + mock ERP | `erp-connector/` | Python (standard library only) |

## Design decisions worth discussing

1. **Transactional outbox.** The API saves a trip change and its ERP event in one database transaction.
   If the ERP is down, nothing is lost and drivers are never blocked. The connector delivers later.
2. **Idempotent delivery.** Events can be delivered twice (a lost acknowledgement), so each carries an
   idempotency key and the ERP de-duplicates. Tested.
3. **Mapping layer.** The API and the ERP name things differently (`vehiclePlate` vs `vehicleRegistration`).
   Translation lives in one function, so switching ERP vendors means changing one place.
4. **Retries with backoff, dead-letter.** Network errors and 5xx are retried with exponential backoff. 4xx are
   recorded as permanent failures. Items that keep failing stop being retried so a person can look at them.
5. **Server-enforced rules.** The status flow is enforced by the API, not the app: a driver cannot skip steps,
   open another driver's trip, or cancel; a vehicle cannot be double-booked.
6. **Basic security hygiene.** PINs hashed with scrypt, session tokens stored hashed, login throttling,
   input validation, machine-to-machine endpoints behind a separate service key.

## Run it (Windows)

You need Node.js 22.13+ (zero native installs; Node 20.6+ also works but pulls in `better-sqlite3`), Python 3.9+, and (for the app) Flutter. Open three terminals in this folder.

```
:: Terminal 1: API
cd api
npm install
npm start

:: Terminal 2: mock ERP
cd erp-connector
python mock_erp.py

:: Terminal 3: connector (leave running, syncs every 10 seconds)
cd erp-connector
python connector.py
```

Then set up and run the app: see `mobile/README.md`.

No Flutter yet? You can still see the whole back end work:

```
cd erp-connector
python e2e_smoke.py
```

It plays a driver completing a trip and prints what the ERP received.

## Tests

```
cd api && npm test                       :: 12 tests
cd erp-connector && python -m unittest   :: 10 tests
cd mobile && flutter test                :: helper tests (after Flutter setup)
```

## API summary

| Method and path | Who | Purpose |
|---|---|---|
| `POST /api/auth/login` | anyone | Phone + PIN, returns a token |
| `GET /api/trips`, `GET /api/trips/:id` | driver (own) / manager (all) | List and detail |
| `POST /api/trips` | manager | Create and assign a trip |
| `POST /api/trips/:id/status` | driver (next step) / manager (cancel) | Move a trip forward |
| `POST /api/trips/:id/fuel` | driver | Log fuel, queued for ERP |
| `POST /api/trips/:id/incidents` | driver | Report a problem, queued for ERP |
| `GET /api/dashboard`, `/api/erp/status` | manager | Overview and sync health |
| `GET /api/erp/outbox`, `POST /api/erp/outbox/:id/ack` | connector (service key) | Drain the outbox |

## Known limits (deliberately out of scope for a 4-day demo)

SQLite instead of a production database, HTTP instead of HTTPS, no offline queue or GPS in the app,
a mock ERP instead of a real one, no push notifications, wildcard CORS for convenience.
Each is listed in `mobile/README.md` or noted in the code where it applies.
