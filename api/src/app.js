'use strict';

const express = require('express');
const { verifyPin, newToken, hashToken, safeEqual } = require('./security');

const NEXT_STATUS = { assigned: 'picked_up', picked_up: 'in_transit', in_transit: 'delivered' };
const INCIDENT_CATEGORIES = ['breakdown', 'accident', 'delay', 'cargo_damage', 'other'];
const LOGIN_WINDOW_MS = 10 * 60 * 1000;
const LOGIN_MAX_ATTEMPTS = 5;

class HttpError extends Error {
  constructor(status, code, message) {
    super(message);
    this.status = status;
    this.code = code;
  }
}

const bad = (message, code = 'validation_error') => new HttpError(400, code, message);

function createApp(db, { erpServiceKey = 'dev-erp-key', now = () => Date.now() } = {}) {
  const app = express();
  app.use(express.json({ limit: '100kb' }));

  // Demo CORS so the Flutter app can also run in a browser (flutter run -d chrome).
  // Auth uses bearer tokens, not cookies, so a wildcard origin is acceptable here.
  // Restrict this to known origins in any real deployment.
  app.use((req, res, next) => {
    res.set({
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Headers': 'Authorization, Content-Type',
      'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    });
    if (req.method === 'OPTIONS') return res.sendStatus(204);
    next();
  });

  // ---------- helpers ----------

  const TRIP_SELECT = `
    SELECT t.id, t.ref, t.origin, t.destination, t.cargo, t.status,
           t.created_at AS createdAt, t.updated_at AS updatedAt, t.delivered_at AS deliveredAt,
           u.id AS driverId, u.name AS driverName,
           v.id AS vehicleId, v.plate AS vehiclePlate, v.model AS vehicleModel
    FROM trips t
    JOIN users u ON u.id = t.driver_id
    JOIN vehicles v ON v.id = t.vehicle_id`;

  const getTrip = (id) => db.prepare(`${TRIP_SELECT} WHERE t.id = ?`).get(id);

  function enqueue(eventType, entityId, payload) {
    db.prepare(
      'INSERT OR IGNORE INTO erp_outbox (event_type, payload, idempotency_key) VALUES (?, ?, ?)'
    ).run(eventType, JSON.stringify(payload), `${eventType}:${entityId}`);
  }

  function loadTripForUser(req) {
    const id = Number(req.params.id);
    if (!Number.isInteger(id)) throw bad('Trip id must be a number');
    const trip = getTrip(id);
    if (!trip) throw new HttpError(404, 'not_found', 'Trip not found');
    if (req.user.role === 'driver' && trip.driverId !== req.user.id) {
      throw new HttpError(403, 'forbidden', 'This trip is not assigned to you');
    }
    return trip;
  }

  const requireText = (value, field, max = 200) => {
    if (typeof value !== 'string' || !value.trim()) throw bad(`${field} is required`);
    if (value.trim().length > max) throw bad(`${field} is too long (max ${max})`);
    return value.trim();
  };

  const optionalNumber = (value, field, { min = -Infinity, max = Infinity } = {}) => {
    if (value === undefined || value === null) return null;
    if (typeof value !== 'number' || !Number.isFinite(value) || value < min || value > max) {
      throw bad(`${field} is invalid`);
    }
    return value;
  };

  // ---------- auth ----------

  const loginAttempts = new Map();

  function checkLoginThrottle(phone) {
    const t = now();
    const recent = (loginAttempts.get(phone) || []).filter((ts) => t - ts < LOGIN_WINDOW_MS);
    loginAttempts.set(phone, recent);
    if (recent.length >= LOGIN_MAX_ATTEMPTS) {
      throw new HttpError(429, 'too_many_attempts', 'Too many attempts. Try again later.');
    }
    return recent;
  }

  app.post('/api/auth/login', (req, res) => {
    const phone = requireText(req.body.phone, 'phone', 30);
    const pin = requireText(String(req.body.pin ?? ''), 'pin', 20);
    const attempts = checkLoginThrottle(phone);

    const user = db.prepare('SELECT * FROM users WHERE phone = ?').get(phone);
    if (!user || !verifyPin(pin, user.pin_hash)) {
      attempts.push(now());
      throw new HttpError(401, 'invalid_credentials', 'Wrong phone number or PIN');
    }
    loginAttempts.delete(phone);

    const token = newToken();
    db.prepare('INSERT INTO sessions (token_hash, user_id) VALUES (?, ?)').run(hashToken(token), user.id);
    res.json({ token, user: { id: user.id, name: user.name, phone: user.phone, role: user.role } });
  });

  function auth(req, _res, next) {
    const header = req.get('authorization') || '';
    const match = /^Bearer (.+)$/.exec(header);
    if (!match) throw new HttpError(401, 'unauthenticated', 'Missing bearer token');
    const user = db
      .prepare(
        `SELECT u.id, u.name, u.phone, u.role FROM sessions s
         JOIN users u ON u.id = s.user_id WHERE s.token_hash = ?`
      )
      .get(hashToken(match[1]));
    if (!user) throw new HttpError(401, 'unauthenticated', 'Invalid or expired token');
    req.user = user;
    next();
  }

  const requireRole = (role) => (req, _res, next) => {
    if (req.user.role !== role) throw new HttpError(403, 'forbidden', `Requires ${role} role`);
    next();
  };

  app.get('/api/health', (_req, res) => res.json({ ok: true }));

  app.get('/api/me', auth, (req, res) => res.json({ user: req.user }));

  app.post('/api/auth/logout', auth, (req, res) => {
    const token = /^Bearer (.+)$/.exec(req.get('authorization'))[1];
    db.prepare('DELETE FROM sessions WHERE token_hash = ?').run(hashToken(token));
    res.json({ ok: true });
  });

  // ---------- trips ----------

  app.get('/api/trips', auth, (req, res) => {
    const where = [];
    const params = [];
    if (req.user.role === 'driver') {
      where.push('t.driver_id = ?');
      params.push(req.user.id);
    }
    if (req.query.status) {
      const statuses = String(req.query.status).split(',');
      where.push(`t.status IN (${statuses.map(() => '?').join(',')})`);
      params.push(...statuses);
    }
    const sql = `${TRIP_SELECT} ${where.length ? 'WHERE ' + where.join(' AND ') : ''}
                 ORDER BY t.updated_at DESC, t.id DESC LIMIT 200`;
    res.json({ trips: db.prepare(sql).all(...params) });
  });

  app.get('/api/trips/:id', auth, (req, res) => {
    const trip = loadTripForUser(req);
    res.json({
      trip,
      events: db.prepare('SELECT status, lat, lng, note, created_at AS createdAt FROM trip_events WHERE trip_id = ? ORDER BY id').all(trip.id),
      fuelLogs: db.prepare('SELECT id, liters, cost_ugx AS costUgx, odometer_km AS odometerKm, created_at AS createdAt FROM fuel_logs WHERE trip_id = ? ORDER BY id').all(trip.id),
      incidents: db.prepare('SELECT id, category, note, created_at AS createdAt FROM incidents WHERE trip_id = ? ORDER BY id').all(trip.id),
    });
  });

  app.post('/api/trips', auth, requireRole('manager'), (req, res) => {
    const origin = requireText(req.body.origin, 'origin');
    const destination = requireText(req.body.destination, 'destination');
    const cargo = requireText(req.body.cargo, 'cargo');
    const driverId = Number(req.body.driverId);
    const vehicleId = Number(req.body.vehicleId);

    const created = db.transaction(() => {
      const driver = db.prepare("SELECT id FROM users WHERE id = ? AND role = 'driver'").get(driverId);
      if (!driver) throw bad('driverId does not match a driver');
      const vehicle = db.prepare('SELECT id, status FROM vehicles WHERE id = ?').get(vehicleId);
      if (!vehicle) throw bad('vehicleId does not match a vehicle');
      if (vehicle.status !== 'available') {
        throw new HttpError(409, 'vehicle_unavailable', 'That vehicle is not available');
      }
      const nextId = db.prepare('SELECT COALESCE(MAX(id), 0) + 1 AS n FROM trips').get().n;
      const ref = `KL-${String(nextId).padStart(5, '0')}`;
      const info = db
        .prepare('INSERT INTO trips (ref, origin, destination, cargo, driver_id, vehicle_id) VALUES (?,?,?,?,?,?)')
        .run(ref, origin, destination, cargo, driverId, vehicleId);
      db.prepare("INSERT INTO trip_events (trip_id, status, note) VALUES (?, 'assigned', 'Trip created')").run(info.lastInsertRowid);
      return info.lastInsertRowid;
    })();

    res.status(201).json({ trip: getTrip(created) });
  });

  app.post('/api/trips/:id/status', auth, (req, res) => {
    const trip = loadTripForUser(req);
    const target = requireText(req.body.status, 'status', 20);
    const note = req.body.note == null ? null : requireText(req.body.note, 'note', 300);
    const lat = optionalNumber(req.body.lat, 'lat', { min: -90, max: 90 });
    const lng = optionalNumber(req.body.lng, 'lng', { min: -180, max: 180 });

    if (target === 'cancelled') {
      if (req.user.role !== 'manager') throw new HttpError(403, 'forbidden', 'Only a manager can cancel a trip');
      if (['delivered', 'cancelled'].includes(trip.status)) {
        throw new HttpError(409, 'invalid_transition', `A ${trip.status} trip cannot be cancelled`);
      }
    } else if (NEXT_STATUS[trip.status] !== target) {
      throw new HttpError(
        409,
        'invalid_transition',
        `Cannot move a ${trip.status} trip to ${target}` +
          (NEXT_STATUS[trip.status] ? ` (next step is ${NEXT_STATUS[trip.status]})` : '')
      );
    }

    db.transaction(() => {
      const deliveredAt = target === 'delivered' ? new Date(now()).toISOString() : null;
      db.prepare(
        `UPDATE trips SET status = ?, updated_at = datetime('now'),
                delivered_at = COALESCE(?, delivered_at) WHERE id = ?`
      ).run(target, deliveredAt, trip.id);
      db.prepare('INSERT INTO trip_events (trip_id, status, lat, lng, note) VALUES (?,?,?,?,?)').run(
        trip.id, target, lat, lng, note
      );
      if (target === 'picked_up') {
        db.prepare("UPDATE vehicles SET status = 'on_trip' WHERE id = ?").run(trip.vehicleId);
      }
      if (target === 'delivered' || target === 'cancelled') {
        db.prepare("UPDATE vehicles SET status = 'available' WHERE id = ?").run(trip.vehicleId);
      }
      if (target === 'delivered') {
        enqueue('trip.delivered', trip.id, {
          tripRef: trip.ref,
          origin: trip.origin,
          destination: trip.destination,
          cargo: trip.cargo,
          driver: { id: trip.driverId, name: trip.driverName },
          vehiclePlate: trip.vehiclePlate,
          deliveredAt,
        });
      }
    })();

    res.json({ trip: getTrip(trip.id) });
  });

  app.post('/api/trips/:id/fuel', auth, requireRole('driver'), (req, res) => {
    const trip = loadTripForUser(req);
    if (!['picked_up', 'in_transit'].includes(trip.status)) {
      throw new HttpError(409, 'invalid_state', 'Fuel can only be logged while a trip is under way');
    }
    const liters = req.body.liters;
    const costUgx = req.body.costUgx;
    if (typeof liters !== 'number' || !Number.isFinite(liters) || liters <= 0 || liters > 1000) {
      throw bad('liters must be a positive number');
    }
    if (!Number.isInteger(costUgx) || costUgx <= 0) throw bad('costUgx must be a positive whole number');
    const odometerKm = optionalNumber(req.body.odometerKm, 'odometerKm', { min: 0, max: 5_000_000 });

    const id = db.transaction(() => {
      const info = db
        .prepare('INSERT INTO fuel_logs (trip_id, driver_id, liters, cost_ugx, odometer_km) VALUES (?,?,?,?,?)')
        .run(trip.id, req.user.id, liters, costUgx, odometerKm);
      enqueue('fuel.recorded', info.lastInsertRowid, {
        fuelLogId: Number(info.lastInsertRowid),
        tripRef: trip.ref,
        driver: { id: trip.driverId, name: trip.driverName },
        vehiclePlate: trip.vehiclePlate,
        liters,
        costUgx,
        odometerKm,
        recordedAt: new Date(now()).toISOString(),
      });
      return info.lastInsertRowid;
    })();

    res.status(201).json({ fuelLog: { id: Number(id), liters, costUgx, odometerKm } });
  });

  app.post('/api/trips/:id/incidents', auth, requireRole('driver'), (req, res) => {
    const trip = loadTripForUser(req);
    if (['delivered', 'cancelled'].includes(trip.status)) {
      throw new HttpError(409, 'invalid_state', 'This trip is closed');
    }
    const category = requireText(req.body.category, 'category', 30);
    if (!INCIDENT_CATEGORIES.includes(category)) {
      throw bad(`category must be one of: ${INCIDENT_CATEGORIES.join(', ')}`);
    }
    const note = requireText(req.body.note, 'note', 500);

    const id = db.transaction(() => {
      const info = db
        .prepare('INSERT INTO incidents (trip_id, driver_id, category, note) VALUES (?,?,?,?)')
        .run(trip.id, req.user.id, category, note);
      enqueue('incident.reported', info.lastInsertRowid, {
        incidentId: Number(info.lastInsertRowid),
        tripRef: trip.ref,
        driver: { id: trip.driverId, name: trip.driverName },
        vehiclePlate: trip.vehiclePlate,
        category,
        note,
        reportedAt: new Date(now()).toISOString(),
      });
      return info.lastInsertRowid;
    })();

    res.status(201).json({ incident: { id: Number(id), category, note } });
  });

  // ---------- manager views ----------

  app.get('/api/drivers', auth, requireRole('manager'), (_req, res) => {
    res.json({ drivers: db.prepare("SELECT id, name, phone FROM users WHERE role = 'driver' ORDER BY name").all() });
  });

  app.get('/api/vehicles', auth, requireRole('manager'), (_req, res) => {
    res.json({ vehicles: db.prepare('SELECT id, plate, model, status FROM vehicles ORDER BY plate').all() });
  });

  function erpCounts() {
    const rows = db.prepare('SELECT status, COUNT(*) AS n FROM erp_outbox GROUP BY status').all();
    const counts = { pending: 0, synced: 0, failed: 0 };
    for (const r of rows) counts[r.status] = r.n;
    return counts;
  }

  app.get('/api/dashboard', auth, requireRole('manager'), (_req, res) => {
    const byStatus = { assigned: 0, picked_up: 0, in_transit: 0, delivered: 0, cancelled: 0 };
    for (const r of db.prepare('SELECT status, COUNT(*) AS n FROM trips GROUP BY status').all()) {
      byStatus[r.status] = r.n;
    }
    const fuel = db.prepare('SELECT COALESCE(SUM(cost_ugx),0) AS cost, COALESCE(SUM(liters),0) AS liters FROM fuel_logs').get();
    const incidents = db.prepare('SELECT COUNT(*) AS n FROM incidents').get().n;
    const fleet = db.prepare("SELECT COUNT(*) AS total, SUM(status = 'available') AS available FROM vehicles").get();
    res.json({
      trips: byStatus,
      fuel: { totalCostUgx: fuel.cost, totalLiters: fuel.liters },
      incidents,
      fleet: { total: fleet.total, available: fleet.available || 0 },
      erp: erpCounts(),
    });
  });

  app.get('/api/erp/status', auth, requireRole('manager'), (_req, res) => {
    const recent = db
      .prepare(
        `SELECT id, event_type AS eventType, status, attempts, last_error AS lastError,
                created_at AS createdAt, synced_at AS syncedAt
         FROM erp_outbox ORDER BY id DESC LIMIT 20`
      )
      .all();
    res.json({ counts: erpCounts(), recent });
  });

  // ---------- ERP connector endpoints (machine-to-machine) ----------

  function requireServiceKey(req, _res, next) {
    const key = req.get('x-service-key') || '';
    if (!safeEqual(key, erpServiceKey)) throw new HttpError(401, 'unauthenticated', 'Invalid service key');
    next();
  }

  app.get('/api/erp/outbox', requireServiceKey, (req, res) => {
    const statuses = String(req.query.status || 'pending').split(',');
    const allowed = ['pending', 'failed', 'synced'];
    if (!statuses.every((s) => allowed.includes(s))) throw bad('status must be pending, failed or synced');
    const limit = Math.min(Number(req.query.limit) || 50, 200);
    const rows = db
      .prepare(
        `SELECT id, event_type AS eventType, payload, idempotency_key AS idempotencyKey,
                status, attempts, created_at AS createdAt
         FROM erp_outbox WHERE status IN (${statuses.map(() => '?').join(',')})
         ORDER BY id LIMIT ?`
      )
      .all(...statuses, limit);
    res.json({ items: rows.map((r) => ({ ...r, payload: JSON.parse(r.payload) })) });
  });

  app.post('/api/erp/outbox/:id/ack', requireServiceKey, (req, res) => {
    const id = Number(req.params.id);
    const { status } = req.body;
    if (!Number.isInteger(id)) throw bad('id must be a number');
    if (!['synced', 'failed'].includes(status)) throw bad('status must be synced or failed');
    const error = status === 'failed' ? String(req.body.error || 'unknown error').slice(0, 500) : null;
    const info = db
      .prepare(
        `UPDATE erp_outbox SET status = ?, attempts = attempts + 1, last_error = ?,
                synced_at = CASE WHEN ? = 'synced' THEN datetime('now') ELSE synced_at END
         WHERE id = ?`
      )
      .run(status, error, status, id);
    if (!info.changes) throw new HttpError(404, 'not_found', 'Outbox item not found');
    res.json({ ok: true });
  });

  // ---------- errors ----------

  app.use((_req, _res, next) => next(new HttpError(404, 'not_found', 'Route not found')));

  // eslint-disable-next-line no-unused-vars
  app.use((err, _req, res, _next) => {
    if (err instanceof HttpError) {
      return res.status(err.status).json({ error: { code: err.code, message: err.message } });
    }
    if (err.type === 'entity.parse.failed') {
      return res.status(400).json({ error: { code: 'invalid_json', message: 'Request body is not valid JSON' } });
    }
    console.error(err);
    res.status(500).json({ error: { code: 'internal_error', message: 'Something went wrong' } });
  });

  return app;
}

module.exports = { createApp };
