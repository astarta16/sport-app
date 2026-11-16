# Design system — v1.9

One system for all five roles. The admin web is operational and restrained.
Parent and coach screens are practical. Student screens are more colourful
but use the same tokens and components. v1.9 **extends** the existing theme
and widgets; nothing was replaced wholesale, and the spec's component names
map to existing components where those already existed.

## Tokens

| Token | Where | Values |
|---|---|---|
| Colour (brand) | `AppColors` (`core/theme/app_theme.dart`) | navy, blue, blueDeep, volt, coral |
| Colour (semantic) | `AppColors`, `AppStatusColors` (`core/theme/design_tokens.dart`) | success, warning, danger, **info** (new), neutral |
| Colour scheme | `AppTheme.light()` / `dark()` | full Material 3 scheme, light **and** dark |
| Status text on tints | `StatusPill.readableOn` | darkens or lightens text until it reaches 4.5:1 (WCAG AA) |
| Spacing | `AppSpacing` | 4, 8, 12, 16, 20, 24, 32; page padding 20 |
| Radii | `AppSpacing.radiusSm / radius / radiusLg` | 12 / 20 / 28; inputs 16; chips pill-shaped |
| Elevation | `AppElevation.level1/level2` (new) | soft shadows for floating surfaces only; cards stay flat with an outline |
| Motion | `AppMotion` (new) | fast 120 ms, medium 220 ms, slow 320 ms; `AppMotion.of(context, d)` returns zero under reduced motion |
| Breakpoints | `Breakpoints` (`core/layout/responsive.dart`) | medium 600, expanded 840, large 1200, readable 720 |
| Touch target | `AppA11y.minTouchTarget` (new) | 48 dp; picker rows 56 dp |
| Focus | input focus border 1.6 px primary; picker keyboard cursor highlight; `AppA11y.focusRingWidth` | |
| Iconography | Material Rounded; sports via `SportVisuals` (v1.9 adds volleyball, badminton, MMA, taekwondo and fitness icons and colours) | |
| Disabled | Material disabled state; disabled picker options stay visible with a **reason** | |

## Components

| Spec name | Implementation | Status |
|---|---|---|
| AppPrimaryButton / AppSecondaryButton | Themed `FilledButton` / `OutlinedButton` (54 / 50 px min height), `LoadingButton` | existing, reused |
| AppTextField | Themed `TextField` / `InputDecoration` (label, `*` for required, helper, inline `errorText`) | existing, convention documented |
| AppSearchField | `TextField` with search prefix (`admin-search`, `app-picker-search`) | existing |
| **AppSelect / AppEntityPicker / AppSearchableBottomSheet** | `AppPickerField<T>` + `showAppPicker` (`core/widgets/app_picker.dart`): bottom sheet on phones, dialog on wide windows; search above 6 options; recents; keyboard ↑ ↓ Enter; disabled options with reason; group headers | **new** |
| **AppMultiSelect** | `AppPickerField.multi` + `showAppMultiPicker`: checkboxes, selected chips, select all, clear all, count | **new** |
| Choice of 2–4 | `AppChoiceGroup<T>`: wrapping choice chips, so labels are never clipped | **new** |
| SportsPicker | `SportsPickerField` (single or multi) on `sportOptions` (`core/widgets/entity_options.dart`): stable ids, merged names, icons, search in every language, organization-allowed filter | **new** |
| Coach / group / room / student / organization options | `coachOptions`, `groupOptions`, `roomOptions` (busy rooms shown with the occupying session), `studentOptions` (birth year and groups for namesakes), `organizationOptions` | **new** |
| AppDatePicker / AppTimePicker | `PickerField` + `showDatePicker` / `showTimePicker`; `DateTimeRow` | existing |
| AppEmptyState / AppLoadingState / AppErrorState | `EmptyState`, `Skeleton` / `SkeletonList`, `ErrorView` (retry), `AsyncView` | existing; more screens use them |
| AppStatusBadge | `StatusPill` (now contrast-safe) | improved |
| AppConfirmationDialog | `confirmDialog(destructive:)` | existing; used for more destructive actions |
| AppFormSection | `AppFormSection` (`core/widgets/app_feedback.dart`) | **new** |
| AppStepWizard | `AppStepHeader`: numbered steps, completed ticks, revisit earlier steps, screen-reader "Step n of N" | **new** |
| AppEntityCard | `AppCard` (+ `borderColor` for "still to do") | improved |
| AppResponsiveTable / AppFilterBar | `AdminTable`: search, filter chips, sort, pagination with labelled buttons, card layout below 760 px; **separate "no data" and "no matches" states with Clear filters** | improved |
| AppCalendar | `CalendarScreen` (mobile), `SchedulePage` (admin: day/week, room columns, now-line, drag with conflict choices) | improved |
| AppActionMenu | `PopupMenuButton`, `ActionChip` rows on hub cards | existing |
| AppFeedbackBanner | `AppFeedbackBanner` (info, success, warning, error; live region for errors and success) | **new** |

## Rules

1. Two to four fixed choices: `AppChoiceGroup`. Five or more, or entities:
   `AppPickerField`. Never a bare dropdown for coaches, groups, rooms,
   students, organizations or venues.
2. Never hide an unavailable option the user expects (a busy room). Show it
   disabled, with the reason.
3. Required fields carry `*` in the label. Errors appear on the field, after
   the first attempt.
4. Destructive actions: `confirmDialog(destructive: true)`, say what is
   kept, then show a **specific** result message.
5. Never show a blank screen or an endless skeleton. Every async state needs
   loading, error with retry, and "not found" or "empty".
6. Motion only where it explains something. `AppMotion.of` respects reduced
   motion. No decorative animation in admin workflows.
