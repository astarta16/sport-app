// Phone helpers. Never log or store a full phone number outside users/{uid}.

/** "+995599123456" -> "+995*****3456". Keeps the country code and last 4 digits. */
export function maskPhone(phone: string | undefined | null): string {
  if (!phone) return '';
  const trimmed = phone.replace(/\s+/g, '');
  const plus = trimmed.startsWith('+') ? '+' : '';
  const digits = trimmed.replace(/\D/g, '');
  if (digits.length <= 4) return plus + '*'.repeat(digits.length);
  const cc = plus && digits.startsWith('995') ? '995' : '';
  const middle = digits.length - cc.length - 4;
  return plus + cc + '*'.repeat(Math.max(0, middle)) + digits.slice(-4);
}

/** Normalises Georgian mobile numbers to E.164 (+9955XXXXXXXX); returns null if invalid. */
export function normalizeGeorgianPhone(phone: string | undefined | null): string | null {
  if (!phone) return null;
  let d = phone.replace(/\D/g, '');
  if (d.startsWith('00')) d = d.slice(2);
  if (d.length === 9 && d.startsWith('5')) d = '995' + d;
  if (/^9955\d{8}$/.test(d)) return '+' + d;
  return null;
}
