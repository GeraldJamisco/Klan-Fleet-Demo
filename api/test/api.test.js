'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');

const { openDb } = require('../src/db');
const { seed } = require('../src/seed');
const { createApp } = require('../src/app');

const SERVICE_KEY = 'test-service-key';

async function startServer(options = {}) {
  const db = openDb(':memory:');
  seed(db);
  const app = createApp(db, { erpServiceKey: SERVICE_KEY, ...options });
  const server = await new Promise((resolve) => {
    const s = app.listen(0, '127.0.0.1', () => resolve(s));
  });
  const base = `http://127.0.0.1:${server.address().port}`;

  async function call(method, path, { token, body, headers = {} } = {}) {
    const res = await fetch(base + path, {
      method,
      headers: {
        'content-type': 'application/json',
        ...(token ? { authorization: `Bearer ${token}` } : {}),
        ...headers,
      },
      body: body === undefined ? undefined : JSON.stringify(body),
    });
    return { status: res.status, body: await res.json() };
  }

  async function login(phone, pin) {
    const r = await call('POST', '/api/auth/login', { body: { phone, pin } });
    assert.equal(r.status, 200, JSON.stringify(r.body));
    return r.body.token;
  }

  return {
    db,
    base,
    call,
    login,
    close: () => new Promise((resolve) => server.close(resolve)),
  };
}

test('login succeeds with the right PIN and fails with the wrong one', async () => {
  const s = await startServer();
  try {
    const ok = await s.call('POST', '/api/auth/login', { body: { phone: '0700000011', pin: '1111' } });
    assert.equal(ok.status, 200);
    assert.equal(ok.body.user.role, 'driver');
    assert.ok(ok.body.token.length >= 32);

    const wrong = await s.call('POST', '/api/auth/login', { body: { phone: '0700000011', pin: '9999' } });
    assert.equal(wrong.status, 401);
    assert.equal(wrong.body.error.code, 'invalid_credentials');
  } finally {
    await s.close();
  }
});

test('login is throttled after repeated failures', async () => {
  const s = await startServer();
  try {
    for (let i = 0; i < 5; i += 1) {
      const r = await s.call('POST', '/api/auth/login', { body: { phone: '0700000012', pin: 'bad' } });
      assert.equal(r.status, 401);
    }
    const blocked = await s.call('POST', '/api/auth/login', { body: { phone: '0700000012', pin: '2222' } });
    assert.equal(blocked.status, 429);
  } finally {
    await s.close();
  }
});

test('protected routes reject missing and invalid tokens', async () => {
  const s = await startServer();
  try {
    assert.equal((await s.call('GET', '/api/trips')).status, 401);
    assert.equal((await s.call('GET', '/api/trips', { token: 'nope' })).status, 401);
  } finally {
    await s.close();
  }
});

test('a driver only sees their own trips; a manager sees all', async () => {
  const s = await startServer();
  try {
    const driver = await s.login('0700000011', '1111');
    const manager = await s.login('0700000001', '1234');

    const mine = await s.call('GET', '/api/trips', { token: driver });
    assert.equal(mine.body.trips.length, 1);
    assert.equal(mine.body.trips[0].ref, 'KL-00001');

    const all = await s.call('GET', '/api/trips', { token: manager });
    assert.equal(all.body.trips.length, 2);

    // Driver 1 cannot open driver 2's trip (KL-00002 has id 2).
    const forbidden = await s.call('GET', '/api/trips/2', { token: driver });
    assert.equal(forbidden.status, 403);
  } finally {
    await s.close();
  }
});

test('manager creates a trip; vehicle must be available', async () => {
  const s = await startServer();
  try {
    const manager = await s.login('0700000001', '1234');
    const driver = await s.login('0700000011', '1111');

    const forbidden = await s.call('POST', '/api/trips', {
      token: driver,
      body: { origin: 'A', destination: 'B', cargo: 'C', driverId: 2, vehicleId: 3 },
    });
    assert.equal(forbidden.status, 403);

    const invalid = await s.call('POST', '/api/trips', { token: manager, body: { origin: 'A' } });
    assert.equal(invalid.status, 400);

    // Vehicle 1 is already on a trip.
    const busy = await s.call('POST', '/api/trips', {
      token: manager,
      body: { origin: 'A', destination: 'B', cargo: 'C', driverId: 4, vehicleId: 1 },
    });
    assert.equal(busy.status, 409);
    assert.equal(busy.body.error.code, 'vehicle_unavailable');

    const created = await s.call('POST', '/api/trips', {
      token: manager,
      body: { origin: 'Jinja Road Depot', destination: 'Entebbe Cargo Village', cargo: '10 crates', driverId: 4, vehicleId: 3 },
    });
    assert.equal(created.status, 201);
    assert.equal(created.body.trip.ref, 'KL-00003');
    assert.equal(created.body.trip.status, 'assigned');
  } finally {
    await s.close();
  }
});

test('trip status moves forward one step at a time and delivery queues an ERP event', async () => {
  const s = await startServer();
  try {
    const driver = await s.login('0700000012', '2222'); // owns trip 2 (assigned)

    const skip = await s.call('POST', '/api/trips/2/status', { token: driver, body: { status: 'delivered' } });
    assert.equal(skip.status, 409);
    assert.equal(skip.body.error.code, 'invalid_transition');

    const picked = await s.call('POST', '/api/trips/2/status', {
      token: driver,
      body: { status: 'picked_up', lat: 0.3476, lng: 32.5825, note: 'Loaded' },
    });
    assert.equal(picked.status, 200);
    assert.equal(s.db.prepare('SELECT status FROM vehicles WHERE id = 2').get().status, 'on_trip');

    await s.call('POST', '/api/trips/2/status', { token: driver, body: { status: 'in_transit' } });
    const done = await s.call('POST', '/api/trips/2/status', { token: driver, body: { status: 'delivered' } });
    assert.equal(done.body.trip.status, 'delivered');
    assert.ok(done.body.trip.deliveredAt);
    assert.equal(s.db.prepare('SELECT status FROM vehicles WHERE id = 2').get().status, 'available');

    const outbox = s.db.prepare('SELECT event_type, idempotency_key FROM erp_outbox').all();
    assert.deepEqual(outbox, [{ event_type: 'trip.delivered', idempotency_key: 'trip.delivered:2' }]);

    const closed = await s.call('POST', '/api/trips/2/status', { token: driver, body: { status: 'in_transit' } });
    assert.equal(closed.status, 409);
  } finally {
    await s.close();
  }
});

test('only a manager can cancel, and not a delivered trip', async () => {
  const s = await startServer();
  try {
    const driver = await s.login('0700000012', '2222');
    const manager = await s.login('0700000001', '1234');

    const denied = await s.call('POST', '/api/trips/2/status', { token: driver, body: { status: 'cancelled' } });
    assert.equal(denied.status, 403);

    const cancelled = await s.call('POST', '/api/trips/2/status', { token: manager, body: { status: 'cancelled' } });
    assert.equal(cancelled.status, 200);
    assert.equal(cancelled.body.trip.status, 'cancelled');

    const again = await s.call('POST', '/api/trips/2/status', { token: manager, body: { status: 'cancelled' } });
    assert.equal(again.status, 409);
  } finally {
    await s.close();
  }
});

test('fuel logs are validated, only allowed mid-trip, and queued for the ERP', async () => {
  const s = await startServer();
  try {
    const driver = await s.login('0700000011', '1111'); // trip 1 is in_transit
    const other = await s.login('0700000012', '2222'); // trip 2 is only assigned

    const badLiters = await s.call('POST', '/api/trips/1/fuel', { token: driver, body: { liters: -5, costUgx: 1000 } });
    assert.equal(badLiters.status, 400);
    const badCost = await s.call('POST', '/api/trips/1/fuel', { token: driver, body: { liters: 10, costUgx: 12.5 } });
    assert.equal(badCost.status, 400);

    const notStarted = await s.call('POST', '/api/trips/2/fuel', { token: other, body: { liters: 10, costUgx: 45000 } });
    assert.equal(notStarted.status, 409);

    const ok = await s.call('POST', '/api/trips/1/fuel', {
      token: driver,
      body: { liters: 55.5, costUgx: 255000, odometerKm: 48210 },
    });
    assert.equal(ok.status, 201);

    const row = s.db.prepare("SELECT payload FROM erp_outbox WHERE event_type = 'fuel.recorded'").get();
    const payload = JSON.parse(row.payload);
    assert.equal(payload.tripRef, 'KL-00001');
    assert.equal(payload.vehiclePlate, 'UBA 123X');
    assert.equal(payload.costUgx, 255000);
  } finally {
    await s.close();
  }
});

test('incident categories are validated', async () => {
  const s = await startServer();
  try {
    const driver = await s.login('0700000011', '1111');
    const bad = await s.call('POST', '/api/trips/1/incidents', { token: driver, body: { category: 'aliens', note: 'x' } });
    assert.equal(bad.status, 400);
    const ok = await s.call('POST', '/api/trips/1/incidents', {
      token: driver,
      body: { category: 'breakdown', note: 'Flat tyre near Karuma' },
    });
    assert.equal(ok.status, 201);
    assert.equal(s.db.prepare("SELECT COUNT(*) AS n FROM erp_outbox WHERE event_type = 'incident.reported'").get().n, 1);
  } finally {
    await s.close();
  }
});

test('ERP outbox endpoints need the service key and support ack', async () => {
  const s = await startServer();
  try {
    const driver = await s.login('0700000011', '1111');
    await s.call('POST', '/api/trips/1/fuel', { token: driver, body: { liters: 20, costUgx: 90000 } });

    assert.equal((await s.call('GET', '/api/erp/outbox')).status, 401);
    assert.equal((await s.call('GET', '/api/erp/outbox', { headers: { 'x-service-key': 'wrong' } })).status, 401);

    const headers = { 'x-service-key': SERVICE_KEY };
    const list = await s.call('GET', '/api/erp/outbox?status=pending', { headers });
    assert.equal(list.status, 200);
    assert.equal(list.body.items.length, 1);
    const item = list.body.items[0];
    assert.equal(item.eventType, 'fuel.recorded');
    assert.equal(item.payload.costUgx, 90000);

    const failed = await s.call('POST', `/api/erp/outbox/${item.id}/ack`, { headers, body: { status: 'failed', error: 'ERP down' } });
    assert.equal(failed.status, 200);
    // A failed item is still returned when the connector asks for retries.
    const retry = await s.call('GET', '/api/erp/outbox?status=pending,failed', { headers });
    assert.equal(retry.body.items[0].attempts, 1);

    await s.call('POST', `/api/erp/outbox/${item.id}/ack`, { headers, body: { status: 'synced' } });
    const after = await s.call('GET', '/api/erp/outbox?status=pending,failed', { headers });
    assert.equal(after.body.items.length, 0);

    const manager = await s.login('0700000001', '1234');
    const dash = await s.call('GET', '/api/dashboard', { token: manager });
    assert.equal(dash.body.erp.synced, 1);
    assert.equal(dash.body.fuel.totalCostUgx, 90000);
  } finally {
    await s.close();
  }
});

test('CORS preflight is answered so the app can run in a browser', async () => {
  const s = await startServer();
  try {
    const res = await fetch(`${s.base}/api/trips`, { method: 'OPTIONS' });
    assert.equal(res.status, 204);
    assert.equal(res.headers.get('access-control-allow-origin'), '*');
    assert.match(res.headers.get('access-control-allow-headers'), /Authorization/);
  } finally {
    await s.close();
  }
});

test('malformed JSON returns a clean 400', async () => {
  const s = await startServer();
  try {
    const res = await fetch(`${s.base}/api/auth/login`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: '{not json',
    });
    assert.equal(res.status, 400);
    assert.equal((await res.json()).error.code, 'invalid_json');
  } finally {
    await s.close();
  }
});
