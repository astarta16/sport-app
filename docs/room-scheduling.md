# Room and facility scheduling (v1.7)

Several coaches and programs share an organization's halls (in the demo:
Tianeti Sports School's Hall A and Hall B). The system **never** lets two
active bookings occupy the same room at overlapping times.

## Model

- **Room** (`clubs/{clubId}/rooms/{id}`) has:
  - a name, capacity and supported sports;
  - opening hours per weekday, in minutes from local midnight; the close
    time may go past 1440 for sessions that run over midnight;
  - a status: active, temporarily unavailable, or archived;
  - the venue (address and map pin) it belongs to.
- **Booking** (`clubs/{clubId}/bookings/{id}`) has:
  - the organization, room, kind, start and end;
  - optional coach, group, program and sport;
  - status, `seriesId` and rule (for recurring bookings), expected attendees;
  - `eventId`, the training it creates.
  - Kinds: training, match, special event, maintenance.
- **Time:**
  - boundaries are stored as UTC instants;
  - recurring rules are in the organization's local wall-clock time
    (`Asia/Tbilisi` by default, configurable per organization);
  - the beta offers only fixed-offset zones (Tbilisi, Yerevan, Baku,
    Istanbul, Minsk, UTC), so conversion is exact without the tz database;
  - zones with daylight saving need a tz library first (open item).

## Conflict rules

An overlap exists when `newStart < existingEnd && newEnd > existingStart`.

| Check | Result |
|---|---|
| Same room overlaps (09:00–10:30 vs 10:00–11:00) | **rejected** (`roomOverlap`) |
| Touching (09:00–10:00 then 10:00–11:00) | allowed |
| Within the organization's buffer (e.g. 15 min) | rejected |
| Maintenance block | rejected (`maintenance`) |
| Room unavailable or archived | rejected (`roomNotBookable`) |
| Outside opening hours (incl. cross-midnight without late hours) | rejected (`outsideHours`) |
| More people than the room holds | rejected (`overCapacity`) |
| Same coach anywhere at that time | rejected (`coachOverlap`) |
| Same group at that time | **warning** (`groupOverlap`); the admin may override with a checkbox |
| Room of another organization | rejected (`wrongTenant`); other tenants' bookings never conflict |
| Longer than 12 h or end ≤ start | rejected |

- A rejection returns the reasons, up to three free start times on the same
  day (nearest first), and the other rooms that are free at the requested time.
- The editor shows these and lets the admin apply one with a tap.

## Atomic, server-side

The checker is pure code with two identical implementations:

- Dart: `lib/features/organizations/domain/scheduling.dart`
- TypeScript: `functions/src/lib/scheduling.ts`

The UI uses it only for instant warnings. **The callable is the authority.**
`createBooking`, `createRecurringBookings`, `updateBooking` and
`updateBookingSeries` run one Firestore transaction that:

1. reads the room;
2. reads one **lock document per (room, local day)** that the new intervals
   touch (`roomLocks/{roomId}_{YYYY-MM-DD}`);
3. reads the bookings that could overlap;
4. runs the checker over all new intervals, including against each other;
5. writes the bookings **and** bumps every lock.

Two overlapping bookings always share at least one room-day, so two
administrators booking at once contend on the same lock document. Firestore
retries the later transaction, which then sees the first booking and is
rejected.

- Verified on the emulator: three simultaneous requests, exactly one succeeds
  (`functions/test-integration/v17.integration.mjs`).
- The demo backend gives the same guarantee: check and write happen with no
  `await` in between (`concurrent reservations` test).
- Rules deny every direct client write to bookings, rooms and locks.

## Recurring bookings

- A weekly rule (weekdays, local start, duration, from–until) is expanded
  inside a **bounded window of 26 weeks**.
- **Every** occurrence is checked before anything is written, so one
  conflict rejects the whole series (all or nothing).
- Editing:

| Action | Effect |
|---|---|
| Edit one occurrence (move, resize, change room) | that booking is detached from the series |
| This and later | `updateBookingSeries` re-checks all later occurrences in one transaction |
| Cancel one, or this and later | sets status `cancelled` (history kept) |

## One schedule for rooms and trainings

- A training booking with a group creates the training (`eventId` ↔ `roomId`),
  so the room plan and the parents' calendar can't diverge.
- Moving the booking moves the training. It bumps the training's schedule
  version, so parents are asked to reconfirm and acknowledge the change.
- Cancelling the booking cancels the training (reason "room booking cancelled").
- A coach can't move a room-linked training into a taken slot:
  - demo: `roomConflict`;
  - production: the rules allow time changes only through the booking callables.

## Admin calendar

**Admin Web → Room schedule**

| Feature | Behaviour |
|---|---|
| Day view | one column per room, with booked time per room |
| Week view | one column per day, optional room filter |
| Filters | coach, sport |
| Free slot | tap it to create a booking pre-filled with that room and time |
| Booking chip | tap to edit; drag onto another slot (or room in the day view) to move — the move still goes through the server check, and a rejection shows the reasons |
| Narrow windows | the grid scrolls horizontally, with a minimum column width of 130 px |

- Booking chips show the kind (colour plus legend), title, and ↻ when recurring.
- Times are always shown in the organization's time zone, whatever the
  browser's zone.

How-to steps are in [organization-admin-guide.md](organization-admin-guide.md).
