// Group invite codes: 6 characters from an alphabet without 0/O/1/I.
import { randomInt } from 'node:crypto';

export const INVITE_CODE_ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
export const INVITE_CODE_LENGTH = 6;
const CODE_RE = /^[A-HJ-NP-Z2-9]{6}$/;

export function generateInviteCode(rand: (max: number) => number = randomInt): string {
  let out = '';
  for (let i = 0; i < INVITE_CODE_LENGTH; i++) out += INVITE_CODE_ALPHABET[rand(INVITE_CODE_ALPHABET.length)];
  return out;
}

/** Upper-cases, strips spaces/dashes; returns null when not a valid code. */
export function normalizeInviteCode(input: unknown): string | null {
  if (typeof input !== 'string') return null;
  const c = input.replace(/[\s-]/g, '').toUpperCase();
  return CODE_RE.test(c) ? c : null;
}
