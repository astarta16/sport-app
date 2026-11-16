# Accessibility — v1.9

Target: WCAG 2.2 AA where it applies to native and Flutter-web UI. These are
the checks and changes made in v1.9. No assistive-technology session with
real users was run.

## Changes

| Area | Change | WCAG |
|---|---|---|
| Status badges | Text colour adjusted per badge to reach at least 4.5:1 against its tint (amber was about 2:1). Covered by a test. | 1.4.3 |
| Reschedule card | Fixed light background replaced by a theme-aware tint; it was unreadable in dark mode. | 1.4.3 |
| Pickers | Rows 56 dp; search field; ↑ ↓ Enter keyboard selection with a visible cursor on desktop; selected state announced (`Semantics(selected:)`); disabled options give their reason as text, not only a colour. | 2.1.1, 2.5.8, 1.4.1, 4.1.2 |
| Picker field | Exposed as a button with label (with "required" marker) and current value for screen readers. | 4.1.2 |
| Choice groups | Mutually exclusive choice semantics; labels wrap instead of clipping. | 1.3.1, 1.4.10 |
| Wizard | Step header announces "Step n of N: name". Errors appear on the field. | 3.3.1, 3.3.3 |
| Feedback banner | Live region for error and success messages. | 4.1.3 |
| Tables | "No matches" state with a Clear-filters action; labelled previous/next page buttons. | 3.3.3, 4.1.2 |
| Admin | Section headers in the sidebar; organization context named; Enter submits the change-reason dialog. | 2.4.6, 2.1.1 |
| RSVP | Reason field labelled; send button has an accessible name; reason saved on leaving the field. | 3.3.2, 4.1.2 |
| Confirmation | Destructive admin actions and sign-out confirmed. | 3.3.4 |
| Motion | `AppMotion.of` returns zero under reduced motion; used for the Home entrance animation. Existing Brain Academy feedback unchanged. | 2.3.3 |
| Touch targets | `AppChoiceGroup` uses padded tap targets; picker rows ≥ 48 dp. | 2.5.8 |

## Verified by tests

- `test/v19/v19_ux_test.dart`: picker search, keyboard Enter, disabled option, multi-select count; badge contrast ≥ 4.5:1; no layout overflow of the new hubs at 320 px and 390 px in Georgian, English and Russian.
- Existing responsive suites (`test/responsive/*`) at phone, iPad and desktop sizes, text scale, and Georgian/Russian layouts still pass.

## Known gaps

- Admin tables: no row focus or keyboard row actions; sortable headers have no sort semantics (A34, A35).
- Colour swatches in branding and clickable stat cards lack semantics (A34).
- Some IconButtons still lack tooltips (M39, A33 partly done).
- Calendar moves are drag-only. Changing a booking's time via its dialog is the keyboard path.
- The 54 hard-coded animation durations were not all moved to `AppMotion`.
