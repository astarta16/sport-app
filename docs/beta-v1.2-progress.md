# Beta v1.2 — progress

Legend: ✅ Verified (tests run locally) · 🟢 Implemented · 🟡 In progress · ⛔ Blocked · 🔧 Requires production configuration

Contract for all new data: [data-model-v1.2.md](data-model-v1.2.md).

## Audit (start of v1.2)

Baseline commit `5b62e9f`: v1.0 spec implemented (130 Flutter tests, 68 functions tests,
52 rules tests). The **v1.1 changes document was not implemented** — none of: group
invite codes / invitations, coach-created pending children, profile photos, chat icon in
the top bar (chat was still a bottom tab), coach media posts, sport category/age/medical
fields + MMA/Taekwondo/Wrestling, mandatory cancel reason, matches, venue pins.
Also missing from v1.0 Phase 3: attendance, progress, admin panel, persisted inbox.

| Area | Status |
|---|---|
| v1.1 groups + invitations + join by code | 🟡 |
| v1.1 profile photos | 🟡 |
| v1.1 chat icon in top bar, nav Home·Calendar·Map·Profile | 🟡 |
| v1.1 coach media posts | 🟡 |
| v1.1 sports catalog fields + new sports | 🟡 |
| v1.1 mandatory cancel reason | 🟡 |
| v1.1 matches | 🟡 |
| v1.1 venue pin + 200 m duplicate check | 🟡 |
| Attendance + parent RSVP | 🟡 |
| Recurring schedules | 🟡 |
| Progress + achievements + feedback | 🟡 |
| Notification center | 🟡 |
| Chat improvements | 🟡 |
| Payments completion + audit | 🟡 |
| Admin web (platform / club admin) | 🟡 |
| Account lifecycle | 🟡 |
| Security review + emulator tests | 🟡 |
| Offline / errors | 🟡 |
| Monitoring + environments | 🟡 |
| Builds (APK, iOS sim, admin web) | 🟡 |
