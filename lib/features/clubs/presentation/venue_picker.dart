import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../app/di.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_picker.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/visuals.dart';
import '../../groups/domain/group.dart';
import '../domain/club.dart';
import 'clubs_providers.dart';

/// Venue dropdown for trainings/matches with "new location on map"
/// (v1.1 §9): pin → nearby venues within 200 m are offered first to avoid
/// duplicates → unverified venue saved with the coach as creator.
class VenuePicker extends ConsumerWidget {
  const VenuePicker({super.key, required this.group, required this.value, required this.onChanged, this.fieldKey});

  final Group? group;
  final String? value;
  final ValueChanged<String?> onChanged;
  final Key? fieldKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final g = group;
    final venues = ref.watch(venuesProvider).value ?? const <Venue>[];
    final list = g == null
        ? const <Venue>[]
        : (venues.where((v) => v.clubId == g.clubId || v.sportIds.contains(g.sportId)).toList()
            ..sort((a, b) => (a.clubId == g.clubId ? 0 : 1).compareTo(b.clubId == g.clubId ? 0 : 1)));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // v1.9: searchable; the club's own venues first, then other venues
        // of the same sport (that list grows with the city).
        AppPickerField<String>(
          key: fieldKey,
          label: l.selectVenue,
          icon: Icons.place_rounded,
          value: list.any((v) => v.id == value) ? value : null,
          recentsId: 'venue',
          options: [
            for (final v in list)
              AppPickerOption(
                value: v.id,
                label: v.name,
                subtitle: v.address,
                leading: Icon(venueTypeIcon(v.type), color: scheme.onSurfaceVariant),
                trailing: v.verified
                    ? null
                    : StatusPill(label: l.venueUnverified, color: AppColors.warning, dense: true),
                group: v.clubId == g?.clubId ? l.venueGroupClub : l.venueGroupOther,
              ),
          ],
          onChanged: onChanged,
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            key: const Key('venue-new'),
            onPressed: g == null
                ? null
                : () async {
                    final id = await Navigator.of(context)
                        .push<String>(MaterialPageRoute(builder: (_) => VenuePinScreen(group: g)));
                    if (id != null) onChanged(id);
                  },
            icon: const Icon(Icons.add_location_alt_rounded),
            label: Text(l.newVenue),
          ),
        ),
      ],
    );
  }
}

class VenuePinScreen extends ConsumerStatefulWidget {
  const VenuePinScreen({super.key, required this.group});

  final Group group;

  @override
  ConsumerState<VenuePinScreen> createState() => _VenuePinScreenState();
}

class _VenuePinScreenState extends ConsumerState<VenuePinScreen> {
  LatLng? _pin;
  List<Venue> _nearby = const [];
  final _name = TextEditingController();
  final _address = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _drop(LatLng p) async {
    setState(() => _pin = p);
    final near = await ref.read(clubsRepositoryProvider).venuesNear(p.latitude, p.longitude);
    if (mounted) setState(() => _nearby = near);
  }

  Future<void> _save() async {
    final p = _pin;
    if (p == null) return;
    setState(() => _saving = true);
    try {
      final v = await ref
          .read(clubsRepositoryProvider)
          .createVenue(
            name: _name.text,
            address: _address.text,
            lat: p.latitude,
            lng: p.longitude,
            sportIds: [widget.group.sportId],
            clubId: widget.group.clubId,
          );
      ref.invalidate(venuesProvider);
      if (!mounted) return;
      showAppSnack(context, context.l10n.venueSaved);
      Navigator.pop(context, v.id);
    } catch (e) {
      if (mounted) showAppSnack(context, errorText(context, e), error: true);
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final club = ref.watch(clubsProvider).value?.where((c) => c.id == widget.group.clubId).firstOrNull;
    final center = club == null
        ? const LatLng(41.7151, 44.8271)
        : LatLng(club.location.latitude, club.location.longitude);
    return Scaffold(
      appBar: AppBar(title: Text(l.newVenue)),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              options: MapOptions(initialCenter: center, initialZoom: 15, onTap: (_, p) => _drop(p)),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'ge.sportparent.sport_parent_app',
                ),
                MarkerLayer(
                  markers: [
                    for (final v in _nearby)
                      Marker(
                        point: LatLng(v.location.latitude, v.location.longitude),
                        child: const Icon(Icons.place_rounded, color: AppColors.blue, size: 32),
                      ),
                    if (_pin != null)
                      Marker(
                        point: _pin!,
                        child: const Icon(Icons.location_on_rounded, color: AppColors.coral, size: 40),
                      ),
                  ],
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: _pin == null
                  ? Text(l.venuePickHint, textAlign: TextAlign.center)
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_nearby.isNotEmpty) ...[
                          Text(l.venueNearby, style: Theme.of(context).textTheme.titleSmall),
                          for (final v in _nearby.take(3))
                            ListTile(
                              dense: true,
                              leading: Icon(venueTypeIcon(v.type)),
                              title: Text(v.name),
                              subtitle: Text(v.address, maxLines: 1, overflow: TextOverflow.ellipsis),
                              trailing: TextButton(
                                onPressed: () => Navigator.pop(context, v.id),
                                child: Text(l.venueUseExisting),
                              ),
                            ),
                        ],
                        TextField(
                          key: const Key('venue-name'),
                          controller: _name,
                          decoration: InputDecoration(labelText: l.venueName),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        TextField(
                          controller: _address,
                          decoration: InputDecoration(labelText: l.venueAddress),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        LoadingButton(label: l.save, loading: _saving, onPressed: _save),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
