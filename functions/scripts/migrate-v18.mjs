#!/usr/bin/env node
// v1.8 feature-management migration — REPORT FIRST, write only on request.
//
// For every orgConfigs/{clubId} still on the v1.7 schema (featureSchema < 2
// or missing), it plans ONE versioned, history-recorded update that:
//   1. expands the coarse v1.7 modules into the v1.8 features they implied
//      (payments → receipts / verification / reminders, communication →
//      acknowledgments, brainAcademy → coach challenges, attendance → RSVP,
//      roomScheduling → facilities, trainings → reports / exports), so no
//      organization loses anything it could do before;
//   2. sets packageId from the legacy plan (free → starter, standard →
//      professional, premium → enterprise) and an open-ended active
//      subscription when none exists (no billing, no charges);
//   3. writes the server-derived fields the security rules read
//      (effectiveModules, accessMode, featureSchema: 2, provisioning: ready);
//   4. bumps `version` and appends orgConfigs/{id}/history/{version}.
// Clubs with no configuration document at all are reported (run
// migrate-v17.mjs first); they keep the legacy feature set meanwhile.
// It also seeds subscriptionPackages/{id} with the built-in packages when
// missing (create-only; existing package documents are never touched).
//
// Nothing is deleted. Rollback: each run prints the previous values; the
// history entry keeps the old version number, and `--rollback <file>`
// restores the saved JSON snapshot written by --apply (same directory).
//
// Default target: the LOCAL EMULATOR (demo-sport-parent). Default mode:
// dry run. A real project needs `--production --project <id>` AND
// `--apply` and credentials via GOOGLE_APPLICATION_CREDENTIALS. Export a
// backup (gcloud firestore export) and run on staging first.
//
// Usage (from functions/, after `npm run build`):
//   node scripts/migrate-v18.mjs                                   # emulator, dry run
//   node scripts/migrate-v18.mjs --apply                           # emulator, write
//   node scripts/migrate-v18.mjs --production --project <id>       # dry run
//   node scripts/migrate-v18.mjs --production --project <id> --apply
//   node scripts/migrate-v18.mjs --rollback migrate-v18-<ts>.json [--production --project <id>]
import { createRequire } from 'node:module';
import { readFileSync, writeFileSync } from 'node:fs';

const require = createRequire(import.meta.url);
const args = process.argv.slice(2);
const flag = (n) => args.includes(n);
const opt = (n) => (args.indexOf(n) >= 0 ? args[args.indexOf(n) + 1] : undefined);
const production = flag('--production');
const apply = flag('--apply');
const rollbackFile = opt('--rollback');
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

let orgs;
try {
  orgs = require('../lib/lib/orgs.js');
} catch {
  console.error('Build the functions first: npm run build');
  process.exit(2);
}
const { effectiveConfig, derivedFields, BUILTIN_PACKAGES } = orgs;

const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue, Timestamp } = require('firebase-admin/firestore');
initializeApp({ projectId: project });
const db = getFirestore();
const target = production ? `PRODUCTION ${project}` : 'emulator demo-sport-parent';

// ── rollback ───────────────────────────────────────────────────────────
if (rollbackFile) {
  const snap = JSON.parse(readFileSync(rollbackFile, 'utf8'));
  console.log(`target: ${target}  mode: ${apply ? 'APPLY rollback' : 'dry run rollback'}  entries: ${snap.length}`);
  if (!apply) {
    for (const e of snap) console.log(`  restore orgConfigs/${e.id} to version ${e.before.version ?? 1}`);
    console.log('Dry run only. Re-run with --apply to restore.');
    process.exit(0);
  }
  for (const e of snap) {
    const before = { ...e.before };
    if (before.updatedAt?._seconds != null) before.updatedAt = new Timestamp(before.updatedAt._seconds, before.updatedAt._nanoseconds);
    await db.doc(`orgConfigs/${e.id}`).set(before);
    await db.doc(`orgConfigs/${e.id}/history/${e.newVersion}`).delete();
  }
  console.log(`restored ${snap.length} configuration documents`);
  process.exit(0);
}

// ── plan ───────────────────────────────────────────────────────────────
const PACKAGE_OF_PLAN = { free: 'starter', standard: 'professional', premium: 'enterprise' };
const ms = (v) => (v && typeof v.toMillis === 'function' ? v.toMillis() : v ?? null);
const now = Date.now();
const planned = [];
const withoutConfig = [];

const [clubs, cfgs] = await Promise.all([db.collection('clubs').select().get(), db.collection('orgConfigs').get()]);
const cfgIds = new Set(cfgs.docs.map((d) => d.id));
for (const c of clubs.docs) if (!cfgIds.has(c.id)) withoutConfig.push(c.id);

for (const d of cfgs.docs) {
  const cur = d.data();
  if ((cur.featureSchema ?? 1) >= 2) continue;
  const e = effectiveConfig(cur);
  const next = {
    allowedModules: e.allowedModules,
    enabledModules: e.enabledModules,
    packageId: cur.packageId ?? PACKAGE_OF_PLAN[cur.plan ?? 'standard'] ?? 'professional',
    subscription: cur.subscription ?? { status: 'active', endAt: null, graceDays: 14, note: 'migrate-v18 default' },
    provisioning: cur.provisioning ?? 'ready',
  };
  const forDerived = {
    ...cur, ...next, featureSchema: 2,
    subscription: { status: next.subscription.status, endAtMs: ms(next.subscription.endAt), graceDays: next.subscription.graceDays },
  };
  const derived = derivedFields(forDerived, now);
  const version = (cur.version ?? 1) + 1;
  const added = e.enabledModules.filter((m) => !(cur.enabledModules ?? []).includes(m));
  planned.push({ id: d.id, before: cur, patch: { ...next, ...derived, version }, added, newVersion: version });
}

const missingPackages = [];
for (const id of Object.keys(BUILTIN_PACKAGES)) {
  if (!(await db.doc(`subscriptionPackages/${id}`).get()).exists) missingPackages.push(id);
}

console.log(`target: ${target}  mode: ${apply ? 'APPLY' : 'dry run'}`);
console.log(`v1.7 configurations to upgrade: ${planned.length}`);
for (const p of planned) {
  console.log(`  - ${p.id}: v${p.before.version ?? 1} → v${p.newVersion}, package ${p.patch.packageId}, ` +
    `implied features added: [${p.added.join(', ')}], effective: ${p.patch.effectiveModules.length}`);
}
console.log(`clubs without a configuration (run migrate-v17 first; unchanged): ${withoutConfig.length}`);
for (const c of withoutConfig.slice(0, 50)) console.log(`  - ${c}`);
console.log(`built-in packages to create: [${missingPackages.join(', ')}]`);

if (!apply) {
  console.log('Dry run only. Nothing was written. Re-run with --apply after reviewing the plan.');
  process.exit(0);
}

// ── apply ──────────────────────────────────────────────────────────────
const snapshotFile = `migrate-v18-${new Date().toISOString().replace(/[:.]/g, '-')}.json`;
writeFileSync(snapshotFile, JSON.stringify(planned.map(({ id, before, newVersion }) => ({ id, before, newVersion })), null, 2));
console.log(`rollback snapshot: ${snapshotFile}`);

let writes = 0;
for (const p of planned) {
  // Per-organization transaction: skip if someone changed it meanwhile.
  await db.runTransaction(async (tx) => {
    const ref = db.doc(`orgConfigs/${p.id}`);
    const s = await tx.get(ref);
    if ((s.get('version') ?? 1) !== (p.before.version ?? 1) || (s.get('featureSchema') ?? 1) >= 2) {
      console.log(`  skipped ${p.id}: changed since the plan was made`);
      return;
    }
    tx.set(ref, { ...p.patch, updatedAt: FieldValue.serverTimestamp(), updatedBy: 'migrate-v18', changeReason: 'v1.8 feature schema migration' }, { merge: true });
    tx.set(ref.collection('history').doc(String(p.newVersion)), {
      version: p.newVersion, at: FieldValue.serverTimestamp(), by: 'migrate-v18', reason: 'v1.8 feature schema migration',
      changes: p.added.map((m) => `+${m}`),
    });
    writes += 2;
  });
}
for (const id of missingPackages) {
  await db.doc(`subscriptionPackages/${id}`).create({ ...BUILTIN_PACKAGES[id], names: { en: id[0].toUpperCase() + id.slice(1) }, builtIn: true });
  writes++;
}
console.log(`done: ${writes} writes`);
