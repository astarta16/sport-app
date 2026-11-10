// Server-side localization (ka / en / ru) for push, inbox, SMS and system
// chat messages. Georgian is the reference and the fallback for anything
// missing. Pure module (no Firebase imports) — unit-tested in test/i18n.test.ts.
import { MESSAGES_EN } from './en';
import { Catalog, MESSAGES_KA, PushTemplateKey, renderTemplate } from './ka';
import { MESSAGES_RU } from './ru';

export const LOCALES = ['ka', 'en', 'ru'] as const;
export type Locale = (typeof LOCALES)[number];
export const DEFAULT_LOCALE: Locale = 'ka';

export const CATALOGS: Record<Locale, Catalog> = { ka: MESSAGES_KA, en: MESSAGES_EN, ru: MESSAGES_RU };

export function isLocale(v: unknown): v is Locale {
  return typeof v === 'string' && (LOCALES as readonly string[]).includes(v);
}

/** users/{uid}.locale → Locale; anything else (missing, invalid) → 'ka'. */
export function normalizeLocale(v: unknown): Locale {
  return isLocale(v) ? v : DEFAULT_LOCALE;
}

function lookup(catalog: unknown, key: string): string | undefined {
  let cur: unknown = catalog;
  for (const part of key.split('.')) {
    if (cur === null || typeof cur !== 'object') return undefined;
    cur = (cur as Record<string, unknown>)[part];
  }
  return typeof cur === 'string' ? cur : undefined;
}

/**
 * Translate a dotted key ('push.newTraining.title', 'sms.d5', 'system.newMatch',
 * 'words.inviteAccepted', 'cancelReasons.weather', 'weekdays.0') in `locale`,
 * falling back to Georgian, then to the key itself. {placeholders} are filled from args.
 */
export function t(locale: unknown, key: string, args: Record<string, string | number> = {}): string {
  const tpl = lookup(CATALOGS[normalizeLocale(locale)], key) ?? lookup(MESSAGES_KA, key) ?? key;
  return renderTemplate(tpl, args);
}

export type Vars = Record<string, string | number>;
export type VarsFor = Vars | ((locale: Locale) => Vars);

/** Push/inbox title + body for a push template key in `locale`. */
export function renderPushL(locale: unknown, key: PushTemplateKey, vars: Vars): { title: string; body: string } {
  return { title: t(locale, `push.${key}.title`, vars), body: t(locale, `push.${key}.body`, vars) };
}

export interface LocalizedText {
  /** Georgian rendering (fallback, also kept for logs). */
  title: string;
  body: string;
  /** Per-recipient rendering used by notify(). */
  localized: (locale: Locale) => { title: string; body: string };
}

/**
 * notify() payload text: `...pushText('newMatch', vars)`. `vars` may be a
 * function of the locale when a value itself must be translated (reason
 * labels, weekday names, answer words).
 */
export function pushText(key: PushTemplateKey, vars: VarsFor): LocalizedText {
  const varsFor = (l: Locale) => (typeof vars === 'function' ? vars(l) : vars);
  return { ...renderPushL('ka', key, varsFor('ka')), localized: (l: Locale) => renderPushL(l, key, varsFor(l)) };
}

/** "Mon, Wed 18:00" / "ორშ, ოთხ 18:00" — schedule summary in `locale`. */
export function weekdaySummaryL(locale: unknown, weekdays: number[], startTime: string): string {
  const days = [...new Set(weekdays)].sort((a, b) => a - b).map((d) => (d >= 1 && d <= 7 ? t(locale, `weekdays.${d - 1}`) : String(d)));
  return `${days.join(', ')} ${startTime}`;
}

/** "Weather — heavy rain" in `locale` (the free text stays as typed). */
export function cancelReasonTextL(locale: unknown, code: unknown, reason: unknown): string {
  const known = typeof code === 'string' && Object.prototype.hasOwnProperty.call(MESSAGES_KA.cancelReasons, code);
  const label = known ? t(locale, `cancelReasons.${code}`) : '';
  const r = typeof reason === 'string' ? reason.trim() : '';
  if (label && r) return `${label} — ${r}`;
  return r || label;
}

/** Flattens a catalog to dotted keys (arrays by index). Used by tests. */
export function flattenCatalog(c: unknown, prefix = ''): Record<string, string> {
  const out: Record<string, string> = {};
  if (typeof c === 'string') {
    out[prefix] = c;
    return out;
  }
  if (c && typeof c === 'object') {
    for (const [k, v] of Object.entries(c)) Object.assign(out, flattenCatalog(v, prefix ? `${prefix}.${k}` : k));
  }
  return out;
}

/** Sorted, de-duplicated {placeholder} names of a template. */
export function placeholdersOf(template: string): string[] {
  return [...new Set([...template.matchAll(/\{(\w+)\}/g)].map((m) => m[1]))].sort();
}
