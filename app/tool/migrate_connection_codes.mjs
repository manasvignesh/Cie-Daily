#!/usr/bin/env node
/**
 * One-time connection-code migration. DRY RUN is the default.
 * Requires firebase-admin and either Application Default Credentials or
 * FIREBASE_SERVICE_ACCOUNT_JSON. Use --write only after reviewing dry-run output.
 */
import process from 'node:process';
import { createRequire } from 'node:module';
const require = createRequire(new URL('../functions/package.json', import.meta.url));
const { initializeApp, applicationDefault, cert } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');

const write = process.argv.includes('--write');
const rawCredential = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
initializeApp({
  credential: rawCredential ? cert(JSON.parse(rawCredential)) : applicationDefault(),
});
const db = getFirestore();

function codeFor(name, uid, attempt = 0) {
  const raw = String(name || 'STUDENT').trim().split(/\s+/)[0]
    .replace(/[^a-z]/gi, '').toUpperCase() || 'STUDENT';
  const prefix = raw.slice(0, 10);
  const input = attempt ? `${uid}:${attempt}` : uid;
  let hash = 0x811c9dc5;
  for (const ch of input) {
    hash ^= ch.charCodeAt(0);
    hash = Math.imul(hash, 0x01000193) & 0x7fffffff;
  }
  return `${prefix}-${hash.toString(36).toUpperCase().padStart(6, '0').slice(-6)}`;
}

const users = await db.collection('users').get();
const claims = new Map();
const plans = [];
const stats = { scanned: users.size, alreadyValid: 0, missing: 0, duplicates: 0, planned: 0 };

for (const doc of users.docs) {
  const data = doc.data();
  const existing = String(data.connectionCode || '').trim().toUpperCase();
  if (existing) {
    if (!claims.has(existing)) claims.set(existing, doc.id);
    else if (claims.get(existing) !== doc.id) stats.duplicates++;
    else stats.alreadyValid++;
  } else stats.missing++;
}

for (const doc of users.docs) {
  const data = doc.data();
  const existing = String(data.connectionCode || '').trim().toUpperCase();
  if (existing && claims.get(existing) === doc.id) {
    plans.push({ uid: doc.id, code: existing, updateProfile: false });
    continue;
  }
  let attempt = 0;
  let code;
  do code = codeFor(data.name || data.username || 'Student', doc.id, attempt++);
  while (claims.has(code) && claims.get(code) !== doc.id && attempt < 100);
  if (claims.has(code) && claims.get(code) !== doc.id) throw new Error(`No unique code for uid ${doc.id}`);
  claims.set(code, doc.id);
  plans.push({ uid: doc.id, code, updateProfile: true });
}
stats.planned = plans.filter((item) => item.updateProfile).length;
stats.alreadyValid = plans.length - stats.planned;
console.log(JSON.stringify({ mode: write ? 'WRITE' : 'DRY_RUN', ...stats }, null, 2));

if (write) {
  for (let offset = 0; offset < plans.length; offset += 200) {
    const batch = db.batch();
    for (const plan of plans.slice(offset, offset + 200)) {
      if (plan.updateProfile) batch.set(db.collection('users').doc(plan.uid), { connectionCode: plan.code }, { merge: true });
      batch.set(db.collection('connectionCodes').doc(plan.code), {
        uid: plan.uid,
        createdAt: FieldValue.serverTimestamp(),
      }, { merge: true });
    }
    await batch.commit();
  }
  console.log(JSON.stringify({ writtenProfiles: stats.planned, writtenMappings: plans.length }));
}
