#!/usr/bin/env node
// One-off bootstrap: grant (or revoke) the platform-admin custom claim
// (`admin: true`) for the FIRST platform admin. Later admins are managed with
// the setAdminRole callable.
//
// Default target is the LOCAL EMULATOR (project demo-sport-parent, auth
// 127.0.0.1:9099, firestore 127.0.0.1:8080). It refuses to touch a real
// project unless BOTH `--production` and `--project <id>` are given and
// credentials are provided via GOOGLE_APPLICATION_CREDENTIALS.
//
// Usage (from functions/):
//   node scripts/grant-platform-admin.mjs <uid>                 # emulator
//   node scripts/grant-platform-admin.mjs <uid> --revoke        # emulator
//   node scripts/grant-platform-admin.mjs <uid> --production --project my-prod-id
import { createRequire } from 'node:module';

const require = createRequire(import.meta.url);
const args = process.argv.slice(2);
const flag = (name) => args.includes(name);
const opt = (name) => {
  const i = args.indexOf(name);
  return i >= 0 ? args[i + 1] : undefined;
};
const uid = args.find((a, i) => !a.startsWith('--') && args[i - 1] !== '--project');
const revoke = flag('--revoke');
const production = flag('--production');

if (!uid) {
  console.error('usage: node scripts/grant-platform-admin.mjs <uid> [--revoke] [--production --project <id>]');
  process.exit(2);
}

let projectId;
if (production) {
  projectId = opt('--project');
  if (!projectId || projectId.startsWith('demo-')) {
    console.error('refusing: --production requires --project <real-project-id>');
    process.exit(2);
  }
  for (const v of ['FIREBASE_AUTH_EMULATOR_HOST', 'FIRESTORE_EMULATOR_HOST']) {
    if (process.env[v]) {
      console.error(`refusing: ${v} is set; unset emulator variables for a production run`);
      process.exit(2);
    }
  }
  if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) {
    console.error('refusing: set GOOGLE_APPLICATION_CREDENTIALS to a service-account key for production');
    process.exit(2);
  }
  console.warn(`!! PRODUCTION: ${revoke ? 'revoking' : 'granting'} platform admin for ${uid} in ${projectId}`);
} else {
  projectId = opt('--project') ?? 'demo-sport-parent';
  if (!projectId.startsWith('demo-')) {
    console.error('refusing: without --production only demo-* (emulator) projects are allowed');
    process.exit(2);
  }
  process.env.FIREBASE_AUTH_EMULATOR_HOST ??= '127.0.0.1:9099';
  process.env.FIRESTORE_EMULATOR_HOST ??= '127.0.0.1:8080';
  console.log(`emulator: auth ${process.env.FIREBASE_AUTH_EMULATOR_HOST}, firestore ${process.env.FIRESTORE_EMULATOR_HOST}, project ${projectId}`);
}

const { initializeApp } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
initializeApp({ projectId });
const auth = getAuth();
const db = getFirestore();

const user = await auth.getUser(uid).catch(() => null);
if (!user) {
  console.error(`auth user ${uid} not found`);
  process.exit(1);
}
const claims = { ...(user.customClaims ?? {}) };
if (revoke) delete claims.admin;
else claims.admin = true;
await auth.setCustomUserClaims(uid, claims);

const userRef = db.doc(`users/${uid}`);
if ((await userRef.get()).exists) {
  await userRef.update(revoke ? { adminRole: FieldValue.delete() } : { adminRole: 'platform' });
}
await db.collection('auditLog').add({
  action: 'role.set', actorId: 'ops-script', actorRole: 'ops', actorName: 'grant-platform-admin.mjs',
  targetType: 'user', targetId: uid, clubId: null, details: { role: revoke ? 'none' : 'platform' }, at: FieldValue.serverTimestamp(),
});
console.log(`${revoke ? 'revoked' : 'granted'} platform admin for ${uid}. The user must sign in again (or refresh the ID token).`);
