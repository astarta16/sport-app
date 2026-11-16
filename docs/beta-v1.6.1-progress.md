# Beta v1.6.1 — Brain Academy polish

All six games are kept and work as before; this release makes them clearer and more fun.
Everything runs locally in demo mode. Nothing was pushed or deployed, and no Firebase project was touched.

## Shared game shell (`brain_game_screen.dart`, `game_feedback.dart`, `game_fx.dart`)

### Start screen
- gradient header with the game icon, name and a one-line objective;
- an instructions card;
- a card per difficulty, each with a short hint (selection shown with a check icon, not colour alone);
- level stepper with "levels unlocked" and best score;
- a large Start button.

### In-game status bar (HUD)
- shows difficulty, level, score, time, progress (bar plus done/total), lives (hearts) and streak;
- wraps onto several lines, so it never overflows at 320 px in Russian.

### Feedback banners
- correct, wrong, warning and info states, each with an icon and bold text, and screen-reader live regions;
- neutral hints use a smaller, calmer style;
- a `Shake` animation on mistakes and a `GlowPop` on correct answers;
- confetti on success;
- with the system "reduce motion" setting, animations are skipped.

### Success screen
- trophy and "level complete" title;
- 1–3 stars, based on accuracy;
- score, plus "new high score" or the best score;
- accuracy, time and attempts;
- "challenge complete" banner;
- badge reveal animation;
- "Level N unlocked" line;
- buttons: Next level, Play again, Back to Brain Academy.

### Failure screen
- friendly icon, an encouraging message, and what went wrong:
  - out of lives;
  - fewer than half of the answers right;
  - too slow;
- score and stats;
- buttons: Try again, Try an easier level (only above Easy), Back to Brain Academy;
- no empty stars and no red "fail".

### Sound and haptics
- 7 short bundled sounds (`assets/sounds/*.wav`, about 100 KB, generated locally):
  - tap, correct, wrong, level complete, fail, reward, timer tick;
- played with `audioplayers`;
- haptics: selection click on taps, light on correct, heavy on mistakes, medium plus heavy on level complete;
- **Game settings** sheet (speaker icon in the game bar) with switches for Sound and Vibration;
- the settings persist in SharedPreferences (`brain.sound`, `brain.haptics`);
- audio errors are swallowed, so a game never breaks because sound is unavailable;
- no background music was added.

## Per game

### Memory Match
- 3D card flip;
- matched pairs glow, turn green and get a check mark;
- a mismatched pair shakes, turns red and gets a cross;
- "Match!" / "Not a pair" banners;
- combo counter (×2, ×3…) shown in the banner and the status bar.

### Logic Quest
- an answer no longer auto-advances;
- the picked option is marked (cross or check);
- the correct option is always marked green with a check, other options fade, and the "?" slot reveals the answer;
- an explanation follows each answer, e.g. "the row repeats every 3 shapes" or "each step adds one more";
- a **Next** button moves on.

### Smart Play
- options are lettered A/B/C, and the same letters appear on arrows drawn on the pitch, so each move is visible;
- after answering:
  - a big Correct / Not this one banner appears;
  - the best option is always marked ("Best choice", green, check);
  - a wrong pick is marked ("Your choice", red, cross);
  - only those two arrows remain (wrong one dashed);
  - a "Coach's tip" card shows the explanation;
- opponents are drawn as red squares and teammates as blue circles, so shape tells them apart, not colour alone.

### Quick Mind
- the timer bar runs green to red, with an hourglass icon and a "Hurry!" label;
- one tick sound when time runs low;
- the target pulses;
- after each tap, the right target is shown;
- reaction-time feedback ("Reaction: 0.84 s");
- "Too slow!" state on timeout;
- a short pause between rounds;
- streak shown in the status bar;
- the failure reason says whether time ran out or answers were wrong.

### Sequence Master
- clearly separated phases:
  - "Watch carefully…" (eye icon, blue, pads dimmed);
  - "Your turn!" (hand icon, green, with an x/n counter);
- pads glow while playing back;
- a wrong pad flashes red with a cross and the pad grid shakes;
- "Sequence complete!" between rounds;
- lives shown as hearts.

### Path Finder
- objective banner;
- Start flag;
- pulsing goal;
- the old warning icons are replaced by traffic cones (cone shape, not colour alone);
- legend (Start / Goal / Blocked);
- a blocked move shakes the board, flashes the border and shows "Blocked!";
- the finish shows a glow and confetti;
- the board now sizes itself to the space left, so the arrow pad always stays on screen (it was pushed below the screen on a 390×844 phone).

## Other fixes found while checking on the iOS simulator

- On the Smart Play pitch, option letters could hide under player markers, and two options to the same player overlapped. Labels are now drawn on top, and duplicates are spread along the arrow.
- The game app bar is tinted light, so the status-bar icons are now dark (they were white on a light background).
- The pitch is a little shorter on phones, so the coach's tip appears sooner.
- **Outside Brain Academy:** the profile screen showed `version 1.2.0-beta`, because `AppConfig.version` had not been updated since v1.2. It now reads `1.6.1-beta`.

## Localization

- 49 new keys in ka, en and ru; there are no hardcoded UI strings in the games;
- a test checks that every new key exists and is translated.

## Tests

- **Flutter tests:** 318 passed (298 before, plus 20 new in `test/v161/v161_polish_test.dart`). The new tests cover:
  - feedback banner icons and text;
  - star rules;
  - settings persistence across restarts;
  - no sound when sound is off;
  - settings sheet;
  - status bar contents;
  - Logic: wrong answer, correct answer marked, Next;
  - Smart Play: after a wrong pick, the best option is still marked; correct banner;
  - success result screen: stars, unlock, buttons, level-complete sound;
  - failure screen: reason, retry, try easier → restarts on Easy, fail sound;
  - Quick Mind: wrong-tap feedback and next round;
  - Path Finder: "Blocked!", start and goal markers;
  - Sequence Master: mistake feedback and lives;
  - in-game layout sweep with feedback showing, at 320 px ru, phone landscape, iPad portrait and iPad landscape;
  - localization;
  - bundled sound files.
- **v1.6 game tests** were updated for the new flow:
  - Logic: tap Next;
  - Quick Mind: wait for the pause between rounds;
  - Path Finder: finish animation.
- `flutter analyze`: no issues. `dart format` applied.
- Firebase Functions and rules tests were not re-run: there were no backend changes.
- **Flaky tests (not related to the games):** in 2 of 5 full runs, one unrelated widget test failed:
  - in one run, the calendar export test;
  - in the other, the v1.4 and v1.5 download tests.
  These tests pass when run on their own (twice) and in the other full runs. They look timing-sensitive under full-suite load and were not investigated further.

## Simulator check (iPhone 16 Pro, iOS 18.3, debug build, demo mode)

- Student dashboard → coach challenge → Smart Play:
  - the new start screen;
  - status bar with difficulty, level, score, timer and progress;
  - the pitch with lettered arrows;
  - a wrong pick (red banner, "Best choice" and "Your choice" marks, coach's tip);
  - a right pick (green banner, score 150);
  - the success screen (1 star at 67%, score 300, "coach's challenge completed", "level 2 unlocked", confetti, Next level / Play again / Back).
- Sound and haptics cannot be judged on the simulator; checking them on a real phone is still open.

## Build

- `~/Desktop/SportParentApp-Beta-v1.6.1.apk`: versionName 1.6.1, versionCode 19, 80,258,530 bytes (80.3 MB), 7 sound files bundled.
- Built with:
  `flutter build apk --release --dart-define=APP_MODE=demo --dart-define=ALLOW_DEMO_IN_RELEASE=true --build-name=1.6.1 --build-number=19`.
- Signed with the debug key; only for side-loading.
