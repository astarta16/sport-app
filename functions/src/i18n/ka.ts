// Georgian (ka) message templates for SMS and push notifications.
// Placeholders use {name} syntax and are filled by renderTemplate().
//
// SMS note: Georgian text is sent as UCS-2, where one segment holds 70
// characters (67 per segment when concatenated). Keep templates short; the
// sender logs the computed segment count for every SMS.

export const SMS_TEMPLATES_KA = {
  /** 5 days before the due date, one child. */
  d5: 'შეხსენება: {child}-ს {sport}-ის გადასახადი {amount} ₾ გადასახდელია {date}-მდე.',
  /** 1 day before the due date, one child. */
  d1: 'შეხსენება: ხვალ {date} ბოლო დღეა {child}-ს {sport}-ის გადასახადის ({amount} ₾) გადასახდელად.',
  /** 5 days before, several children of the same parent due the same day. */
  d5Multi: 'შეხსენება: {children}-ს გადასახადები ({amount} ₾) გადასახდელია {date}-მდე.',
  /** 1 day before, several children of the same parent due the same day. */
  d1Multi: 'შეხსენება: ხვალ {date} ბოლო დღეა {children}-ს გადასახადების ({amount} ₾) გადასახდელად.',
  /** Group invitation to a phone without a registered parent account. */
  invite: '{group}: მოწვევა ({child}). დარეგისტრირდით აპლიკაციაში ამ ნომრით.',
} as const;

export const PUSH_TEMPLATES_KA = {
  newTraining: { title: 'ახალი ვარჯიში', body: '{group}: {date}, {time}' },
  trainingCancelled: { title: 'ვარჯიში გაუქმდა', body: '{group}: {date}, {time}' },
  trainingMoved: { title: 'ვარჯიში გადაიდო', body: '{group}: ახალი დრო {date}, {time}' },
  trainingReminder: { title: 'ვარჯიში 2 საათში', body: '{group}: დღეს {time}' },
  newPhotos: { title: 'ახალი ფოტოები', body: '{group}: {count} ახალი ფოტო' },
  chatMessage: { title: '{sender} · {group}', body: '{text}' },
  certificateExpiring: { title: 'ცნობის ვადა იწურება', body: '{child}: სამედიცინო ცნობის ვადა იწურება {days} დღეში ({date}).' },
  certificateExpired: { title: 'ცნობის ვადა ამოიწურა', body: '{child}: სამედიცინო ცნობის ვადა ამოიწურა. ატვირთეთ ახალი ცნობა.' },
  paymentReminder: { title: 'გადასახადის შეხსენება', body: '{text}' },
  trainingCancelledReason: { title: 'ვარჯიში გაუქმდა', body: '{group}: {date}, {time}. მიზეზი: {reason}' },
  newMatch: { title: 'ახალი მატჩი', body: '{group}: {opponent}, {date}, {time}' },
  matchCancelled: { title: 'მატჩი გაუქმდა', body: '{group}: {opponent}, {date}. მიზეზი: {reason}' },
  matchMoved: { title: 'მატჩი გადაიდო', body: '{group}: {opponent}, ახალი დრო {date}, {time}' },
  matchReminder1d: { title: 'ხვალ მატჩია', body: '{group}: {opponent}, {date}, {time}' },
  matchReminder2h: { title: 'მატჩი 2 საათში', body: '{group}: {opponent}, დღეს {time}' },
  groupInvite: { title: 'მოწვევა ჯგუფში', body: '{group}: {child}' },
  inviteAnswered: { title: 'მოწვევაზე პასუხი', body: '{child}: {answer}' },
  scheduleChanged: { title: 'განრიგი განახლდა', body: '{group}: {summary}' },
  announcement: { title: 'განცხადება · {group}', body: '{text}' },
  newMedia: { title: 'ახალი მედია', body: '{group}: {count} ახალი ფაილი' },
} as const;

/** Server-written chat messages (type 'system'). */
export const SYSTEM_MESSAGES_KA = {
  trainingCancelled: 'ვარჯიში ({date}, {time}) გაუქმდა. მიზეზი: {reason}',
  matchCancelled: 'მატჩი {opponent}-თან ({date}, {time}) გაუქმდა. მიზეზი: {reason}',
  newMatch: 'ახალი მატჩი: {opponent} — {date}, {time}',
  matchMoved: 'მატჩი {opponent}-თან გადაიდო: {date}, {time}',
} as const;

export const WEEKDAYS_SHORT_KA = ['ორშ', 'სამ', 'ოთხ', 'ხუთ', 'პარ', 'შაბ', 'კვი'] as const;

/** "ორშ, ოთხ 18:00" — schedule summary for the series notification. */
export function weekdaySummary(weekdays: number[], startTime: string): string {
  const days = [...new Set(weekdays)].sort((a, b) => a - b).map((d) => WEEKDAYS_SHORT_KA[d - 1] ?? String(d));
  return `${days.join(', ')} ${startTime}`;
}

export type SmsTemplateKey = keyof typeof SMS_TEMPLATES_KA;
export type PushTemplateKey = keyof typeof PUSH_TEMPLATES_KA;

/** Replaces {key} placeholders. Unknown placeholders are left as-is. */
export function renderTemplate(template: string, vars: Record<string, string | number>): string {
  return template.replace(/\{(\w+)\}/g, (m, key: string) =>
    Object.prototype.hasOwnProperty.call(vars, key) ? String(vars[key]) : m,
  );
}

export function renderPush(key: PushTemplateKey, vars: Record<string, string | number>): { title: string; body: string } {
  const t = PUSH_TEMPLATES_KA[key];
  return { title: renderTemplate(t.title, vars), body: renderTemplate(t.body, vars) };
}

/** "80" for whole numbers, "80.50" otherwise. */
export function formatAmount(amount: number): string {
  return Number.isInteger(amount) ? String(amount) : amount.toFixed(2);
}

/** Truncate for push bodies without splitting surrogate pairs. */
export function truncate(text: string, max = 120): string {
  const chars = Array.from(text);
  return chars.length <= max ? text : chars.slice(0, max - 1).join('') + '…';
}
