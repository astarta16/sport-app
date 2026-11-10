// SMS provider abstraction. The default is MockSmsProvider: no real SMS is
// ever sent unless SMS_PROVIDER is set AND SMS_SENDING_ENABLED === "true".

export interface SmsSendResult {
  ok: boolean;
  /** Provider message id, if any. */
  messageId?: string;
  /** Short, non-secret provider response (status line / error), for smsLog. */
  response: string;
}

export interface SmsProvider {
  readonly name: string;
  send(toE164: string, text: string): Promise<SmsSendResult>;
}

export type SmsProviderName = 'mock' | 'twilio' | 'http';

/**
 * Pure provider selection from environment variables.
 * Real sending requires BOTH a known SMS_PROVIDER and SMS_SENDING_ENABLED=="true".
 */
export function selectSmsProviderName(env: Record<string, string | undefined>): SmsProviderName {
  const enabled = env.SMS_SENDING_ENABLED === 'true';
  const p = (env.SMS_PROVIDER ?? '').trim().toLowerCase();
  if (!enabled) return 'mock';
  if (p === 'twilio') return 'twilio';
  if (p === 'http' || p === 'generic' || p === 'generic_http') return 'http';
  return 'mock';
}

/** In-memory provider: records messages, sends nothing. */
export class MockSmsProvider implements SmsProvider {
  readonly name = 'mock';
  readonly sent: Array<{ to: string; text: string }> = [];

  async send(toE164: string, text: string): Promise<SmsSendResult> {
    this.sent.push({ to: toE164, text });
    return { ok: true, messageId: `mock-${this.sent.length}`, response: 'mock: not sent' };
  }
}

/**
 * Number of SMS segments. Any non-GSM-7 character (all Georgian letters)
 * forces UCS-2: 70 chars in one segment, 67 per part when concatenated.
 */
export function smsSegments(text: string): { encoding: 'GSM-7' | 'UCS-2'; units: number; segments: number } {
  // eslint-disable-next-line no-control-regex
  const gsm7 = /^[\x0A\x0D\x20-\x5F\x61-\x7E£¥èéùìòÇØøÅåΔ_ΦΓΛΩΠΨΣΘΞÆæßÉ¤¡ÄÖÑÜ§¿äöñüà€]*$/.test(text);
  if (gsm7) {
    const units = text.length;
    return { encoding: 'GSM-7', units, segments: units <= 160 ? 1 : Math.ceil(units / 153) };
  }
  const units = text.length; // UTF-16 code units == UCS-2 units for the BMP
  return { encoding: 'UCS-2', units, segments: units <= 70 ? 1 : Math.ceil(units / 67) };
}
