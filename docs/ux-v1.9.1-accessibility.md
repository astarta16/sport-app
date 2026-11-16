# Accessibility — v1.9.1

Builds on [ux-v1.9-accessibility.md](ux-v1.9-accessibility.md). The target is WCAG 2.2 AA where it applies.
No session with assistive-technology users was run.

## Changes in v1.9.1

| Area | Change | WCAG |
|---|---|---|
| Unsaved changes | Stay / Discard dialog; Stay is the default focused action | 3.3.4 |
| Forms | Errors shown next to the field, in the certificate, receipt, wizard and dialogs. Unknown validation codes fall back to a plain sentence. | 3.3.1, 3.3.3 |
| Certificate upload | File type and 10 MB limit stated before picking; file card names the file and its size; Remove and Replace are labelled buttons | 3.3.2 |
| Calendar | Matches differ from trainings by **shape** (trophy marker vs dot) and colour, with a text legend | 1.4.1 |
| Setup checklist | Done and to-do icons have semantic labels; strikethrough is not the only cue | 1.4.1, 1.1.1 |
| Admin tables | Sortable headers are buttons announcing "Sort by X · ascending/descending", focusable and activated with Enter or Space; an unfold icon marks sortable columns | 2.1.1, 4.1.2 |
| Room schedule | Labelled previous/next day or week; date picker; overlapping bookings never hide each other | 2.4.6, 1.3.1 |
| Pickers | Floating label no longer overlaps the placeholder (readability) | 1.4.8 (AAA, readability) |
| Home | "Add child" exposed as a button; child details reachable without long-press | 4.1.2, 2.5.1 |
| Roster | Destructive Remove moved into a menu, with confirmation | 3.3.4 |
| Text clipping | Georgian "Next training" label never truncated; tested at 320, 360 and 390 px in ka/en/ru with real fonts | 1.4.10 |
| Touch targets | Feedback stars no longer compact (≥ 48 dp) | 2.5.8 |
| Tooltips | Chat send and discard, thread send, map clear, directions, series clear date, plan remove media, game level −/+ | 4.1.2 |

## Verification

- `test/v191/mobile_screens_test.dart`: label truncation in 3 languages × 3 widths, plus the calendar legend.
- `test/v191/mobile_forms_test.dart`: guard dialog behaviour and inline errors.
- Existing responsive and text-scale suites pass.

## Known limitations

- No keyboard row focus or row actions in admin tables. Actions are reachable as focusable buttons in each row.
- Calendar booking moves: drag, or open the booking and change its time. No keyboard drag.
- Branding colour swatches and clickable stat cards lack semantics (A34).
- Dialog focus does not explicitly return to the triggering control after closing. Flutter restores focus to the previous scope, but this was not verified with a screen reader.
- Browser close or refresh is **not** protected by the unsaved-changes guard. Only in-app navigation is.
- Dark-mode screenshots were not captured for every new screen.
