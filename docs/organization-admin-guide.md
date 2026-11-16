# Organization admin guide (v1.7)

Admin Web has two kinds of administrators:

- **Platform Super Admin** (claim `admin: true`): the *Platform* section of the
  navigation (Organizations, Sports, Coaches, Clubs, Admins, Moderation, Audit).
- **Organization admin** (claim `clubAdmin: [orgId]`): sees only the
  *Academy* section and only their own organization(s).

Every page of the Academy section has an **Organization** selector. An
organization admin only ever sees their own organizations in it. The server
re-checks every action, whatever is selected.

## Running Admin Web

```bash
flutter run -d chrome -t lib/main_admin.dart
flutter build web -t lib/main_admin.dart --release --dart-define=APP_MODE=demo \
  --dart-define=ALLOW_DEMO_IN_RELEASE=true -o build/admin_web
cd build/admin_web && python3 -m http.server 8765    # http://127.0.0.1:8765
```

Demo sign-in buttons on the Admin Web login page:

| Account | Role |
|---|---|
| Platform admin | Super Admin |
| Club admin | admin of the original demo club |
| **თამარ ლომიძე** | admin of **Tianeti Sports School** |
| **დავით კობახიძე** | admin of **Mtskheta Youth Academy** (the second tenant used to show isolation) |

## Creating a new organization (Super Admin)

1. **Organizations → New organization**.
2. Enter the names (ka, en, ru), address, map coordinates, plan, brand colour
   and sports.
3. Save. The organization starts **active** with the plan's modules, but the
   restricted ones stay **off**: leaderboards, room scheduling, student accounts.
4. **Plan, status and modules** (tune icon) does four things:
   - allow or withdraw modules (withdrawing also switches them off);
   - change the plan or limits;
   - suspend or deactivate the organization;
   - (deactivated organizations are hidden from search, and nothing new can
     be created).
5. **Tenant health** (heart icon) shows students, coaches, groups, rooms,
   upcoming events, bookings this week and Brain Academy plays, plus any
   exceeded limit.

## Assigning organization administrators (Super Admin)

**Organizations → Assign administrator** (shield icon):

1. Pick a user, or paste a user ID.
2. Press **Assign administrator**. This sets the `clubAdmin` claim for that
   organization only.
3. **Remove administrator** takes it away again.

The person then signs in to Admin Web and sees only that organization.

## Enabling and disabling features (organization admin)

1. **Academy settings → Enabled modules**.
2. Tap a chip to switch it on or off.
3. Locked chips (padlock) need the platform first. An organization can't
   self-enable premium or restricted modules.

A switched-off module disappears from the apps, and the server rejects its
operations. For example, attendance off means no RSVPs or attendance marking.

The same page holds:

- **branding**: names, logo URL, colour, description, contacts, address;
- default language, time zone, and the gap between room bookings;
- leaderboard settings;
- the organization's coaches: add an approved coach, or remove one.

## Creating sports programs

1. **Programs → New program**.
2. Fill in:
   - sport (from the organization's sports);
   - name and description;
   - age range and capacity;
   - room, coaches and groups;
   - schedule note and status (active, paused, archived).

Groups and coaches of another organization can't be attached.

## Adding rooms

1. **Rooms and halls → New room**.
2. Fill in:
   - name and capacity;
   - opening hours;
   - supported sports (empty = any);
   - status (available, temporarily unavailable, archived);
   - note.
3. The **wrench** icon adds a maintenance block.
4. The number of rooms is limited by the plan.

## Scheduling recurring sessions

1. **Room schedule → New booking**, or tap a free slot.
2. Choose:
   - kind (training, match, special event, maintenance) and room;
   - title, group, coach and program;
   - date, start time and duration.
3. Switch on **Repeat weekly**, pick the weekdays and the end date
   (at most 26 weeks ahead).
4. Save. Every occurrence is checked first. If one collides, nothing is
   saved and the reasons are shown.

A training booking with a group also creates the training, and parents are
notified.

## Reviewing booking conflicts

The editor warns while you type, for example "Check before saving: the room
is already booked at this time (17:00–18:30)". The **Save** button stays
disabled until the warning is resolved.

If the server rejects a booking (for example, another admin booked the slot
a moment earlier), you see:

- the reasons;
- up to three free times the same day — tap one to use it;
- free rooms at that time — tap one to switch.

**Group double-booking** is only a warning. Tick "The group really has two
sessions at once" to save anyway.

**Moving bookings:** drag a booking chip onto another slot (or another room
in the day view). The move is validated like a new booking; a rejected move
shows the reasons and changes nothing.

**Edit a series:** open an occurrence, then:

- **Save only this one** detaches it from the series;
- **Save this and later** re-times the rest of the series;
- **Cancel only this one** / **Cancel this and all later**.

## Configuring leaderboards

1. The platform must allow the module.
2. Academy settings → **Leaderboard**:
   - enable it;
   - choose the periods (week, month, all time) and the games that count;
   - keep "rank only within the same age group" on (recommended);
   - set the minimum number of opted-in students (default 3).
3. Students appear only after a guardian consents in the parent app.

Policy: [leaderboard-policy.md](leaderboard-policy.md).

## Reports

**Reports** has three views:

| View | What it shows |
|---|---|
| Parent responses | upcoming events, with confirmed / declined / not sure / no answer / needs reconfirmation |
| Attendance | past events by date range and group: present / absent / excused / not marked |
| Brain Academy | points, completed games and last play per student (first name + initial only) |

## Running Demo Mode (mobile)

```bash
flutter run                      # debug builds default to demo mode
```

New quick sign-in accounts:

| Account | Role |
|---|---|
| **ეკა ხუციშვილი** | Tianeti parent: Ana has two guardians; Saba's answer needs reconfirmation |
| **ნინო გელაშვილი** | Tianeti volleyball coach |

Existing accounts: parent Nino (two organizations), coach Giorgi, student Luka
(member of both the demo club and Tianeti, appears on the Tianeti leaderboard).
