#!/usr/bin/env node
// v1.7 multi-tenant migration — REPORT FIRST, write only on request.
//
// What it does (all additive; existing documents are never rewritten):
//   1. orgConfigs/{clubId} for every club that has none, with the LEGACY
//      feature set (exactly what the club could use before v1.7; the new
//      restricted modules — leaderboards, roomScheduling — stay off).
//   2. clubs/{clubId}/orgMembers/{uid} for coaches, parents and linked
//      students of each club's groups (what onGroupOrgMembers maintains
//      from now on), plus club admins from clubs.adminIds.
//   3. Reports records whose tenant cannot be derived (a training/match
//      whose group is missing or has no clubId) so a human can decide.
//
// Records that already carry the tenant are untouched: trainings, RSVPs and
// attendance resolve their organization through groups.clubId; matches,
// payments and plans already store clubId. scheduleVersion / eventType are
// optional fields that default to 1 / 'training' when absent.
//
// Default target: the LOCAL EMULATOR (demo-sport-parent). Default mode:
// dry run (prints the plan, writes nothing). A real project needs
// `--production --project <id>` AND `--apply`, and credentials via
// GOOGLE_APPLICATION_CREDENTIALS. Run against a staging copy first and
// export a backup (gcloud firestore export) before any production run.
//
// Usage (from functions/):
//   node scripts/migrate-v17.mjs                      # emulator, dry run
//   node scripts/migrate-v17.mjs --apply              # emulator, write
//   node scripts/migrate-v17.mjs --production --project <id>            # dry run
//   node scripts/migrate-v17.mjs --production --project <id> --apply    # write
import { createRequire } from 'node:module';

const require = createRequire(import.meta.url);
const args = process.argv.slice(2);
const flag = (n) => args.includes(n);
const opt = (n) => (args.indexOf(n) >= 0 ? args[args.indexOf(n) + 1] : undefined);
const production = flag('--production');
const apply = flag('--apply');
const project = production ? opt('--project') : 'demo-sport-parent';

if (production && !project) {
  console.error('--production requires --project <id>');
  process.exit(2);
}
if (!production) {
  process.env.FIRESTORE_EMULATOR_HOST ??= '127.0.0.1:8080';
} else if (process.env.FIRESTORE_EMULATOR_HOST) {
  console.error('Refusing: FIRESTORE_EMULATOR_HOST is set together with --production.');
  process.exit(2);
}

const LEGACY = ['trainings', 'matches', 'attendance', 'communication', 'notifications', 'studentAccounts',
  'brainAcademy', 'trainingPlans', 'payments', 'medicalCertificates', 'media'];

const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
initializeApp({ projectId: project });
const db = getFirestore();

const plan = { orgConfigs: [], members: new Map(), orphans: [] };

const clubs = await db.collection('clubs').get();
for (const c of clubs.docs) {
  const cfg = await db.doc(`orgConfigs/${c.id}`).get();
  if (!cfg.exists) plan.orgConfigs.push(c.id);
  const add = (uid, role) => {
    const key = `${c.id}|${uid}`;
    const roles = plan.members.get(key) ?? new Set();
    roles.add(role);
    plan.members.set(key, roles);
  };
  for (const a of c.get('adminIds') ?? []) add(a, 'admin');
  const groups = await db.collection('groups').where('clubId', '==', c.id).get();
  for (const g of groups.docs) {
    for (const u of g.get('coachIds') ?? []) add(u, 'coach');
    for (const u of g.get('parentIds') ?? []) add(u, 'parent');
    for (const cid of g.get('memberChildIds') ?? []) {
      const kid = await db.doc(`children/${cid}`).get();
      if (kid.get('userId')) add(kid.get('userId'), 'student');
    }
  }
}
for (const col of ['trainings', 'matches']) {
  const evs = await db.collection(col).select('groupId').get();
  for (const e of evs.docs) {
    const g = await db.doc(`groups/${e.get('groupId')}`).get();
    if (!g.exists || !g.get('clubId')) plan.orphans.push(`${col}/${e.id}`);
  }
}

console.log(`target: ${production ? `PRODUCTION ${project}` : 'emulator demo-sport-parent'}  mode: ${apply ? 'APPLY' : 'dry run'}`);
console.log(`orgConfigs to create (legacy feature set): ${plan.orgConfigs.length}`);
console.log(`orgMembers to upsert: ${plan.members.size}`);
console.log(`events without a resolvable tenant (manual review, not changed): ${plan.orphans.length}`);
for (const o of plan.orphans.slice(0, 50)) console.log(`  - ${o}`);

if (!apply) {
  console.log('Dry run only. Nothing was written. Re-run with --apply after reviewing the plan.');
  process.exit(0);
}

let writes = 0;
let batch = db.batch();
const flush = async () => {
  if (writes % 400 === 0 && writes > 0) {
    await batch.commit();
    batch = db.batch();
  }
};
for (const id of plan.orgConfigs) {
  batch.create(db.doc(`orgConfigs/${id}`), {
    status: 'active', plan: 'standard', allowedModules: LEGACY, enabledModules: LEGACY, timezone: 'Asia/Tbilisi',
    defaultLanguage: 'ka', bookingBufferMin: 0, leaderboard: { enabled: false, minParticipants: 3, byAgeBand: true, periods: ['week', 'month'], games: [] },
    migratedAt: FieldValue.serverTimestamp(), migratedBy: 'migrate-v17',
  });
  writes++;
  await flush();
}
for (const [key, roles] of plan.members) {
  const [clubId, uid] = key.split('|');
  batch.set(db.doc(`clubs/${clubId}/orgMembers/${uid}`), {
    orgId: clubId, userId: uid, roles: FieldValue.arrayUnion(...roles), active: true,
  }, { merge: true });
  writes++;
  await flush();
}
await batch.commit();
console.log(`done: ${writes} additive writes`);
