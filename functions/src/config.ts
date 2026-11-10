// Global function options and parameters (secrets / env).
import { setGlobalOptions } from 'firebase-functions/v2';
import { defineSecret } from 'firebase-functions/params';

export const REGION = 'europe-west1';
export const TIMEZONE = 'Asia/Tbilisi';

setGlobalOptions({ region: REGION, maxInstances: 10 });

// Secret Manager secrets for real SMS providers. Only read when
// SMS_SENDING_ENABLED=="true" and SMS_PROVIDER selects that provider.
export const TWILIO_ACCOUNT_SID = defineSecret('TWILIO_ACCOUNT_SID');
export const TWILIO_AUTH_TOKEN = defineSecret('TWILIO_AUTH_TOKEN');
export const SMS_HTTP_API_KEY = defineSecret('SMS_HTTP_API_KEY');

export const SMS_SECRETS = [TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN, SMS_HTTP_API_KEY];
