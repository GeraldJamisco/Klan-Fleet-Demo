'use strict';

const crypto = require('node:crypto');

// scrypt keeps the demo dependency-free while still storing PINs properly hashed.
function hashPin(pin) {
  const salt = crypto.randomBytes(16);
  const hash = crypto.scryptSync(String(pin), salt, 32);
  return `${salt.toString('hex')}:${hash.toString('hex')}`;
}

function verifyPin(pin, stored) {
  const [saltHex, hashHex] = String(stored).split(':');
  if (!saltHex || !hashHex) return false;
  const expected = Buffer.from(hashHex, 'hex');
  const actual = crypto.scryptSync(String(pin), Buffer.from(saltHex, 'hex'), expected.length);
  return crypto.timingSafeEqual(actual, expected);
}

function newToken() {
  return crypto.randomBytes(32).toString('hex');
}

// Only a hash of the token is stored, so a leaked database does not leak sessions.
function hashToken(token) {
  return crypto.createHash('sha256').update(String(token)).digest('hex');
}

function safeEqual(a, b) {
  const ba = Buffer.from(String(a));
  const bb = Buffer.from(String(b));
  return ba.length === bb.length && crypto.timingSafeEqual(ba, bb);
}

module.exports = { hashPin, verifyPin, newToken, hashToken, safeEqual };
