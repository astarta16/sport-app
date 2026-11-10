// Builds the SmsProvider for the current environment. Default: Mock.
import { logger } from 'firebase-functions';
import { SMS_HTTP_API_KEY, TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN } from './config';
import { MockSmsProvider, SmsProvider, selectSmsProviderName } from './lib/sms/provider';
import { GenericHttpSmsProvider, TwilioSmsProvider } from './lib/sms/realProviders';

export function createSmsProvider(env: Record<string, string | undefined> = process.env): SmsProvider {
  const name = selectSmsProviderName(env);
  try {
    if (name === 'twilio') {
      return new TwilioSmsProvider(TWILIO_ACCOUNT_SID.value(), TWILIO_AUTH_TOKEN.value(), env.SMS_SENDER_ID ?? '');
    }
    if (name === 'http') {
      return new GenericHttpSmsProvider(env.SMS_HTTP_URL ?? '', SMS_HTTP_API_KEY.value(), env.SMS_SENDER_ID ?? '');
    }
  } catch (e) {
    logger.error('SMS provider misconfigured; falling back to mock (nothing will be sent)', { provider: name, error: String(e) });
  }
  return new MockSmsProvider();
}
