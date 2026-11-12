import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/di.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../clubs/domain/club.dart';
import '../../groups/domain/group.dart';
import '../../matches/domain/match.dart';
import '../../trainings/domain/training.dart';
import '../domain/ics.dart';

/// Last calendar file handed to the share sheet (name, event count). Tests read it.
final lastIcsProvider = StateProvider<({String name, int events})?>((_) => null);

IcsEvent trainingIcsEvent(BuildContext context, Training t, Group? group, Venue? venue) {
  final l = context.l10n;
  return IcsEvent(
    uid: 'training-${t.id}',
    start: t.startAt,
    end: t.startAt.add(Duration(minutes: t.durationMin)),
    summary: [l.trainingTitle, if (group != null) group.name].join(' · '),
    location: venue == null ? null : [venue.name, venue.address].where((s) => s.trim().isNotEmpty).join(', '),
    description: t.description,
    cancelled: t.status == TrainingStatus.cancelled,
  );
}

IcsEvent matchIcsEvent(BuildContext context, SportMatch m, Group? group, Venue? venue) {
  final l = context.l10n;
  return IcsEvent(
    uid: 'match-${m.id}',
    start: m.startAt,
    end: m.startAt.add(Duration(minutes: m.durationMin)),
    summary: [l.matchVs(m.opponentName), if (group != null) group.name].join(' · '),
    location: venue == null ? null : [venue.name, venue.address].where((s) => s.trim().isNotEmpty).join(', '),
    cancelled: m.status == MatchStatus.cancelled,
  );
}

/// Writes the events to an `.ics` file and opens the system share sheet,
/// from which the user picks their calendar app.
Future<void> shareIcs(
  BuildContext context,
  WidgetRef ref,
  List<IcsEvent> events, {
  required String kind,
  required String slug,
}) async {
  final l = context.l10n;
  if (events.isEmpty) {
    showAppSnack(context, l.calendarNothingToExport);
    return;
  }
  final now = ref.read(clockProvider)();
  final name = Ics.fileName(kind, slug, now);
  final bytes = Uint8List.fromList(Ics.bytes(events, stamp: now));
  ref.read(lastIcsProvider.notifier).state = (name: name, events: events.length);
  try {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(bytes, name: name, mimeType: 'text/calendar')],
        fileNameOverrides: [name],
      ),
    );
    if (context.mounted) showAppSnack(context, l.exportReady(name));
  } catch (e) {
    if (context.mounted) showAppSnack(context, errorText(context, e), error: true);
  }
}

/// "Add to calendar" button used on the training and match detail screens.
class AddToCalendarButton extends ConsumerWidget {
  const AddToCalendarButton({super.key, required this.event, required this.kind, required this.slug});

  final IcsEvent event;
  final String kind;
  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: OutlinedButton.icon(
      onPressed: () => shareIcs(context, ref, [event], kind: kind, slug: slug),
      icon: const Icon(Icons.event_available_rounded),
      label: Text(context.l10n.addToCalendar),
    ),
  );
}
