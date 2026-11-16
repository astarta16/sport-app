# Brain Academy leaderboard policy (v1.7)

Leaderboards involve minors. They are therefore **off unless several
independent conditions all hold**, and they never show anything that could
identify or profile a child.

## When a child appears

All of these must be true:

1. The **platform** allowed the `leaderboards` module for the organization
   (a restricted module, off for new organizations).
2. The **organization admin** enabled it and chose the periods and games
   (Academy settings → Leaderboard).
3. A **guardian** of the child gave consent for that organization (child
   profile → Brain Academy leaderboard). The child, coaches and the
   organization can't give consent. Guardians can withdraw it at any time,
   and the child disappears from every board immediately.
4. The child is an active member of a group of **that** organization.
   There is no global or cross-organization board.
5. At least `minParticipants` opted-in children (default 3, minimum 2) are
   on the board the viewer would see. Otherwise no board is shown, which
   prevents singling out one child.
6. With "rank within age group" on (the default), only children in the same
   age band are compared: 6–8, 9–11, 12–14, 15–17.

If any condition fails, the student sees their **private progress** with a
short explanation.

## What is shown

- Position, display name, points and the number of badges earned. Nothing else.
- Display names are chosen by the guardian:
  - a generated **pseudonym** (default, e.g. "Swift Falcon 12"), or
  - **first name and last-name initial** ("ანა ხ.").
- Never shown: full legal name, phone, birth date, age, health or certificate
  data, contacts, group membership, or location.
- Points are labelled as game points for fun and practice. The app states
  they do not measure intelligence; nothing infers IQ or ranks sensitive
  attributes.

## Scoring (shared, deterministic)

Defined once and implemented identically in Dart (`brain_academy/domain/scoring.dart`)
and TypeScript (`functions/src/lib/scoring.ts`); both sides pin the same test cases.

| Rule | Value |
|---|---|
| Base points | easy 10 · medium 20 · hard 30 |
| Level bonus | +2 per level above 1 |
| Accuracy bonus | up to +10 |
| First clear of a (game, difficulty, level) | +15 once |
| Repeats of the same (game, difficulty, level) on one day | ×1, ×0.5, ×0.25, then 0 |
| Daily cap | 300 points per child per day |
| Incomplete, out-of-bounds, or shorter than 3 s | 0 |
| Duplicate submissions | one result id counts once (idempotency) |
| Ties | points ↓, then whoever reached the total first, then a stable id |

Repeat factors and the daily cap stop point farming on easy levels.

## Integrity

- Results are append-only:
  - created by the linked student;
  - the client-generated id is the idempotency key;
  - rules allow create, never update or delete.
- Clients never submit totals or rankings:
  - the `getLeaderboard` callable recomputes every total from stored results;
  - the demo backend does the same.
- `onBrainResultCreated` marks results invalid when Brain Academy is disabled
  for all of the child's organizations; scoring ignores them.
- Honest limit: the games run on the child's device, so a determined user
  could fabricate a plausible result. The bounds, rate of points (repeat
  factors, daily cap) and plausibility checks limit the effect; this is a
  casual educational game, not a competition with prizes. Stronger
  validation (server replay of seeded games) is listed as future work.

## Moderation

- Organization admins see per-student Brain Academy summaries:
  - first name and initial only;
  - in Reports → Brain Academy.
- They can switch the board off, change games or periods, or raise the
  minimum number of participants.
- Consent changes are written to the audit log: `leaderboard.consent` and
  `leaderboard.revoke`.
