// Sport Parent App — Cloud Functions entry point.
// Region europe-west1, schedules in Asia/Tbilisi (see config.ts).
import './config';

export { onTrainingWritten, sendTrainingReminders } from './triggers/trainings';
export { onChatMemberWritten, onChatMessageCreated } from './triggers/chat';
export {
  certificateExpiryCheck,
  deleteCertificate,
  getCertificateUrl,
  onCertificateCreated,
  onCertificateDeleted,
} from './triggers/certificates';
export { onChildDeleted, onGroupWritten, onMembershipRequestUpdated } from './triggers/groups';
export { deleteAccount, getParentPhone, onUserDeleted, syncPublicProfile } from './triggers/users';
export { generateRecurringPayments, onPaymentWritten, sendPaymentReminders } from './triggers/payments';
// v1.1 / v1.2
export {
  createGroup, createInvite, joinGroupByCode, leaveGroup, respondInvite, revokeInvite, searchChildren,
} from './triggers/invites';
export { matchReminders, onMatchWritten } from './triggers/matches';
export { extendTrainingSeries, onSeriesWritten, splitTrainingSeries } from './triggers/series';
export { getMediaUrl, onMediaPostWritten, onMediaUpload } from './triggers/media';
export { createReport, moderate } from './triggers/moderation';
export {
  adminCompliance, adminStats, archiveClub, assignCoach, setAdminRole, setCoachStatus, updateGroup, upsertClub, upsertSport,
} from './triggers/adminCallables';
export {
  getExportUrl, onAccountRequestCreated, requestAccountDeletion, requestDataExport,
} from './triggers/account';
// v1.3
export { getReceiptUrl, reviewPaymentProof, startPaymentReview, submitPaymentProof } from './triggers/paymentProofs';
export { getPlanMediaUrl, onTrainingPlanWritten } from './triggers/trainingPlans';
export { onAttendanceWritten, onFeedbackWritten } from './triggers/progress';
