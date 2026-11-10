# Assumptions and defaults

The specification (§12) leaves several questions open. These are the
development defaults chosen; each is configurable and should be confirmed.

| # | Open question / gap | Default chosen | Where to change |
|---|---|---|---|
| 1 | Child accounts and age (§4.3, §12.1) | No independent child sign-in. 14–17 account support is modelled (`children.userId`, rules for child reads, no chat ever) but **disabled**; the role is shown as "soon". | `PolicyFlags.childAccountsEnabled` / `childAccountMinAge` in `access_policy.dart`; rules already deny child self-registration |
| 2 | Who approves coaches (§12.2) | Club administrator / app admin via the admin-only `setCoachStatus` callable (custom claim `admin`). Demo has a button acting as that admin. | `functions/src/triggers/users.ts` |
| 3 | Multiple parents per child (§12.3) | Yes — `parentIds[]`. Adding a second guardian by invitation is not built yet. | — |
| 4 | Who enters clubs/venues (§12.4) | Admin-managed catalogue (`clubs`, `venues` writable by admin only); demo uses fictional seed data for Tbilisi and Batumi. | `demo_seed.dart`, rules |
| 5 | Business model (§12.5) | Not modelled; payments are informational with manual status (spec §14.5). No online payment. | — |
| 6 | Launch cities (§12.6) | Map centres on Tbilisi; seed includes one Batumi club. | `tbilisiCenter` in `map_screen.dart` |
| 7 | Timezone | Asia/Tbilisi is UTC+4 all year (no DST since 2005), implemented as a fixed offset. | `TbilisiTime` |
| 8 | "Expiring" certificate window | ≤ 14 days before `validUntil` (matches the first reminder). | `CertificatePolicy.expiringWindowDays` |
| 9 | Signed URL lifetime | 5 minutes (spec example). | `CertificatePolicy.signedUrlTtl`, functions |
| 10 | Training duration bounds | 15–300 minutes; slider in the form covers 15–180. | `TrainingValidator` + rules |
| 11 | Photo consent | Per-child `photoConsent` flag set by the parent; the coach form lists children without consent and requires an explicit confirmation before uploading. Faces are not detected automatically. | `training_form_screen.dart` |
| 12 | Group join flow | Parents request; a coach of the club approves; a Cloud Function adds the child. Public group listing comes from a server-maintained `clubs/{clubId}/publicGroups` projection (no member/parent/coach ids). | `functions/src/triggers/groups.ts` |
| 13 | Requests show the child name | `membershipRequests.childName` (first name only) is denormalized so the coach can review without reading a non-member child's profile. | rules + `club.dart` |
| 14 | Payments creation | Parents/coaches can't create payment documents in production (rules: admin/server). Coaches can create **plans**; the monthly function generates payments; one-off charges are admin-only. Demo lets the coach do both to show the flow. | `firebase_payments_repository.dart` |
| 15 | Combined SMS | Several payments for the same parent, same kind (d5/d1) and same due day → one SMS (spec §14.5 recommendation). | `PaymentReminderService` |
| 16 | SMS delivery failure | Client-side service releases the claim so a later run may retry; the server function logs `failed` and does **not** retry (at-most-once, to avoid duplicates). Pick one policy before launch. | `payment_reminders.dart`, `functions/src/triggers/payments.ts` |
| 17 | Notification inbox | Server sends FCM pushes only. In Firebase mode the in-app inbox lists pushes received during the session; a persisted `users/{uid}/notifications` collection is a follow-up. Demo persists notifications in memory. | `firebase_notifications_repository.dart` |
| 18 | FCM tokens | Uses `getToken()` (deprecated in firebase_messaging 17 in favour of FID `register()`), because the functions send via registration tokens. Migrate both sides together. | same |
| 19 | Certificate access log for parents | Demo shows it to the parent; in production `certificateAccessLog` is admin-only. Exposing it to parents needs a callable. | rules |
| 20 | Certificate file metadata | Production Firestore doc stores only rule-allowed fields; file name/type live in Storage metadata. | `firebase_certificates_repository.dart` |
| 21 | iOS dependency manager | CocoaPods (Swift Package Manager disabled in `pubspec.yaml`) because the Firebase iOS SDK manifest failed to resolve via SwiftPM with Xcode 26.1. | `pubspec.yaml` `flutter.config` |
| 22 | Map tiles | Public OpenStreetMap tiles for development only; production needs a tile provider respecting the OSM tile usage policy (or Google Maps). | `TileLayer` usages |
| 23 | English | `app_en.arb` is fully translated so the switch in Settings works, but Georgian remains the reviewed source. | `tool/strings.py` |

Legal (spec §8): Georgian personal-data law treats health data as a special
category; privacy policy, data-processing terms and store requirements for
children's apps must be reviewed by a lawyer before launch. The consent texts
in the app are drafts.
