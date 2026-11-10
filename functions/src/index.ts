// Sport Parent App — Cloud Functions entry point.
// Region europe-west1, schedules in Asia/Tbilisi (see config.ts).
import './config';

export { onTrainingWritten, sendTrainingReminders } from './triggers/trainings';
export { onChatMessageCreated } from './triggers/chat';
export {
  certificateExpiryCheck,
  deleteCertificate,
  getCertificateUrl,
  onCertificateCreated,
  onCertificateDeleted,
} from './triggers/certificates';
export { onChildDeleted, onGroupWritten, onMembershipRequestUpdated } from './triggers/groups';
export { deleteAccount, getParentPhone, onUserDeleted, setCoachStatus, syncPublicProfile } from './triggers/users';
export { generateRecurringPayments, sendPaymentReminders } from './triggers/payments';
