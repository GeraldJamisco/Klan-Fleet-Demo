'use strict';

const { hashPin } = require('./security');

// Fake demo data only. Names, plates and phone numbers are invented.
function seed(db) {
  const existing = db.prepare('SELECT COUNT(*) AS n FROM users').get().n;
  if (existing > 0) return false;

  db.transaction(() => {
    const addUser = db.prepare('INSERT INTO users (name, phone, role, pin_hash) VALUES (?,?,?,?)');
    addUser.run('Grace Namukasa (Fleet Manager)', '0700000001', 'manager', hashPin('1234'));
    const d1 = addUser.run('Joseph Okello', '0700000011', 'driver', hashPin('1111')).lastInsertRowid;
    const d2 = addUser.run('Aisha Nakato', '0700000012', 'driver', hashPin('2222')).lastInsertRowid;
    addUser.run('Peter Mugisha', '0700000013', 'driver', hashPin('3333'));

    const addVehicle = db.prepare('INSERT INTO vehicles (plate, model, status) VALUES (?,?,?)');
    const v1 = addVehicle.run('UBA 123X', 'Isuzu FRR 7-ton', 'on_trip').lastInsertRowid;
    const v2 = addVehicle.run('UBB 456Y', 'Mitsubishi Canter 3-ton', 'available').lastInsertRowid;
    addVehicle.run('UBC 789Z', 'Scania R450 Trailer', 'available');
    addVehicle.run('UBD 321W', 'Toyota Hilux Pickup', 'maintenance');

    const addTrip = db.prepare(
      'INSERT INTO trips (ref, origin, destination, cargo, driver_id, vehicle_id, status) VALUES (?,?,?,?,?,?,?)'
    );
    const addEvent = db.prepare('INSERT INTO trip_events (trip_id, status, note) VALUES (?,?,?)');

    const t1 = addTrip.run('KL-00001', 'Bugolobi Depot, Kampala', 'Gulu Distribution Centre', '120 cartons of beverages', d1, v1, 'in_transit').lastInsertRowid;
    addEvent.run(t1, 'assigned', 'Trip created');
    addEvent.run(t1, 'picked_up', 'Loaded at depot');
    addEvent.run(t1, 'in_transit', 'Departed Kampala');

    const t2 = addTrip.run('KL-00002', 'Namanve Warehouse', 'Mbarara Retail Hub', '40 pallets of roofing sheets', d2, v2, 'assigned').lastInsertRowid;
    addEvent.run(t2, 'assigned', 'Trip created');
  })();

  return true;
}

module.exports = { seed };

if (require.main === module) {
  const { openDb } = require('./db');
  const db = openDb(process.env.DB_FILE || './klan-demo.db');
  console.log(seed(db) ? 'Seeded demo data.' : 'Database already has data; nothing to do.');
}
