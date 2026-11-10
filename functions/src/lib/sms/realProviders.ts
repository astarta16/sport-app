// Stub real SMS providers. They are only constructed when
// SMS_SENDING_ENABLED=="true" and SMS_PROVIDER is set (see selectSmsProviderName).
// Credentials come from Secret Manager via defineSecret (see src/config.ts).
// NOTE: untested against a live provider — verify with the provider's
// sandbox before enabling in production.

import { SmsProvider, SmsSendResult } from './provider';

type FetchLike = typeof fetch;

export class TwilioSmsProvider implements SmsProvider {
  readonly name = 'twilio';

  constructor(
    private readonly accountSid: string,
    private readonly authToken: string,
    private readonly from: string,
    private readonly fetchImpl: FetchLike = fetch,
  ) {
    if (!accountSid || !authToken || !from) throw new Error('TwilioSmsProvider: missing credentials or sender');
  }

  async send(toE164: string, text: string): Promise<SmsSendResult> {
    const url = `https://api.twilio.com/2010-04-01/Accounts/${encodeURIComponent(this.accountSid)}/Messages.json`;
    const body = new URLSearchParams({ To: toE164, From: this.from, Body: text });
    const auth = Buffer.from(`${this.accountSid}:${this.authToken}`).toString('base64');
    const res = await this.fetchImpl(url, {
      method: 'POST',
      headers: { Authorization: `Basic ${auth}`, 'Content-Type': 'application/x-www-form-urlencoded' },
      body,
    });
    const json = (await res.json().catch(() => ({}))) as { sid?: string; status?: string; message?: string };
    return {
      ok: res.ok,
      messageId: json.sid,
      response: `${res.status} ${json.status ?? json.message ?? ''}`.trim().slice(0, 300),
    };
  }
}

/**
 * Generic JSON-over-HTTP gateway (most Georgian SMS gateways follow this shape).
 * POST {url} with {"to","text","sender"} and "Authorization: Bearer <key>".
 * Adapt the payload to the chosen gateway's API.
 */
export class GenericHttpSmsProvider implements SmsProvider {
  readonly name = 'http';

  constructor(
    private readonly url: string,
    private readonly apiKey: string,
    private readonly sender: string,
    private readonly fetchImpl: FetchLike = fetch,
  ) {
    if (!url || !apiKey) throw new Error('GenericHttpSmsProvider: missing SMS_HTTP_URL or API key');
  }

  async send(toE164: string, text: string): Promise<SmsSendResult> {
    const res = await this.fetchImpl(this.url, {
      method: 'POST',
      headers: { Authorization: `Bearer ${this.apiKey}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({ to: toE164, text, sender: this.sender }),
    });
    const raw = await res.text().catch(() => '');
    let messageId: string | undefined;
    try {
      const j = JSON.parse(raw) as { id?: string; messageId?: string };
      messageId = j.messageId ?? j.id;
    } catch {
      /* non-JSON response */
    }
    return { ok: res.ok, messageId, response: `${res.status} ${raw}`.trim().slice(0, 300) };
  }
}
