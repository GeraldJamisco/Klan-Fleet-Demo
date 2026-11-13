'use strict';

const { openDb } = require('./db');
const { seed } = require('./seed');
const { createApp } = require('./app');

const PORT = Number(process.env.PORT) || 3000;
const DB_FILE = process.env.DB_FILE || './klan-demo.db';
const ERP_SERVICE_KEY = process.env.ERP_SERVICE_KEY || 'dev-erp-key';

const db = openDb(DB_FILE);
if (seed(db)) console.log('Seeded demo data (fake drivers, vehicles and trips).');

const app = createApp(db, { erpServiceKey: ERP_SERVICE_KEY });

// 0.0.0.0 so a phone on the same Wi-Fi can reach the API, not just this computer.
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Klan fleet API listening on http://0.0.0.0:${PORT}`);
  console.log('Demo logins: manager 0700000001 / 1234, driver 0700000011 / 1111');
});
