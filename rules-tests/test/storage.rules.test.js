import { afterAll, beforeAll, beforeEach, describe, it } from 'vitest';
import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { deleteObject, getBytes, getMetadata, ref, uploadBytes } from 'firebase/storage';
import { createEnv, seed, UID } from './setup.js';

let env;

beforeAll(async () => {
  env = await createEnv();
});

beforeEach(async () => {
  await env.clearFirestore();
  await env.clearStorage();
  await seed(env);
});

afterAll(async () => {
  await env?.cleanup();
});

const as = (uid) => env.authenticatedContext(uid).storage();
const bytes = (n = 16) => new Uint8Array(n);

describe('storage: medical certificates', () => {
  it('medical files are not client-readable, even by the child\'s own parent', async () => {
    await assertFails(getBytes(ref(as(UID.parentA), 'medical/childA1/cert1')));
    await assertFails(getMetadata(ref(as(UID.parentA), 'medical/childA1/cert1')));
    await assertFails(getBytes(ref(as(UID.coach), 'medical/childA1/cert1')));
    await assertFails(getBytes(ref(env.unauthenticatedContext().storage(), 'medical/childA1/cert1')));
  });

  it('parent of the child may upload jpeg/png/pdf under 10MB', async () => {
    await assertSucceeds(uploadBytes(ref(as(UID.parentA), 'medical/childA1/c2'), bytes(), { contentType: 'application/pdf' }));
    await assertSucceeds(uploadBytes(ref(as(UID.parentA), 'medical/childA1/c3'), bytes(), { contentType: 'image/png' }));
    await assertSucceeds(uploadBytes(ref(as(UID.parentA), 'medical/childA1/c4'), bytes(), { contentType: 'image/jpeg' }));
  });

  it('rejects wrong content type, oversize files and non-parents', async () => {
    await assertFails(uploadBytes(ref(as(UID.parentA), 'medical/childA1/x1'), bytes(), { contentType: 'text/plain' }));
    await assertFails(uploadBytes(ref(as(UID.parentA), 'medical/childA1/x2'), bytes(10 * 1024 * 1024 + 1), { contentType: 'application/pdf' }));
    await assertFails(uploadBytes(ref(as(UID.parentB), 'medical/childA1/x3'), bytes(), { contentType: 'application/pdf' }));
    await assertFails(uploadBytes(ref(as(UID.coach), 'medical/childA1/x4'), bytes(), { contentType: 'application/pdf' }));
  });

  it('only a parent of the child may delete', async () => {
    await assertFails(deleteObject(ref(as(UID.parentB), 'medical/childA1/cert1')));
    await assertSucceeds(deleteObject(ref(as(UID.parentA), 'medical/childA1/cert1')));
  });
});

describe('storage: training photos', () => {
  it('group parents and coach can read; outsiders cannot', async () => {
    await assertSucceeds(getBytes(ref(as(UID.parentA), 'trainingPhotos/g1/photo1.jpg')));
    await assertSucceeds(getBytes(ref(as(UID.coach), 'trainingPhotos/g1/photo1.jpg')));
    await assertFails(getBytes(ref(as(UID.coachOther), 'trainingPhotos/g1/photo1.jpg')));
    await assertFails(getBytes(ref(as(UID.childUser), 'trainingPhotos/g1/photo1.jpg')));
  });

  it('only the approved group coach uploads images under 10MB', async () => {
    await assertSucceeds(uploadBytes(ref(as(UID.coach), 'trainingPhotos/g1/p2.jpg'), bytes(), { contentType: 'image/jpeg' }));
    await assertFails(uploadBytes(ref(as(UID.coach), 'trainingPhotos/g1/p3.pdf'), bytes(), { contentType: 'application/pdf' }));
    await assertFails(uploadBytes(ref(as(UID.coachOther), 'trainingPhotos/g1/p4.jpg'), bytes(), { contentType: 'image/jpeg' }));
    await assertFails(uploadBytes(ref(as(UID.coachPending), 'trainingPhotos/g1/p5.jpg'), bytes(), { contentType: 'image/jpeg' }));
    await assertFails(uploadBytes(ref(as(UID.parentA), 'trainingPhotos/g1/p6.jpg'), bytes(), { contentType: 'image/jpeg' }));
  });
});

describe('storage: chat attachments', () => {
  it('group parents and coaches upload/read images; outsiders and child accounts cannot', async () => {
    await assertSucceeds(uploadBytes(ref(as(UID.parentA), 'chatAttachments/g1/m1/a.jpg'), bytes(), { contentType: 'image/jpeg' }));
    await assertSucceeds(getBytes(ref(as(UID.coach), 'chatAttachments/g1/m1/a.jpg')));
    await assertFails(getBytes(ref(as(UID.coachOther), 'chatAttachments/g1/m1/a.jpg')));
    await assertFails(getBytes(ref(as(UID.childUser), 'chatAttachments/g1/m1/a.jpg')));
    await assertFails(uploadBytes(ref(as(UID.childUser), 'chatAttachments/g1/m2/b.jpg'), bytes(), { contentType: 'image/jpeg' }));
    await assertFails(uploadBytes(ref(as(UID.parentA), 'chatAttachments/g1/m3/c.pdf'), bytes(), { contentType: 'application/pdf' }));
  });
});
