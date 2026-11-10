import { getApps, initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { getStorage } from 'firebase-admin/storage';
import { getMessaging } from 'firebase-admin/messaging';
import { getAuth } from 'firebase-admin/auth';

if (getApps().length === 0) initializeApp();

export const db = getFirestore();
export const bucket = () => getStorage().bucket();
export const messaging = () => getMessaging();
export const auth = () => getAuth();

export const isEmulator = process.env.FUNCTIONS_EMULATOR === 'true';
