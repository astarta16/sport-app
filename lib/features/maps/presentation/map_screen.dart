import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../app/di.dart';
import '../../../app/routes.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/services/launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/geo.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/visuals.dart';
import '../../sports/presentation/sports_providers.dart';
import '../domain/location_repository.dart';

final placesProvider = FutureProvider.autoDispose.family<List<MapPlace>, (String?, String)>((ref, q) {
  return ref.watch(locationRepositoryProvider).search(LocationQuery(sportId: q.$1, text: q.$2));
});

/// Tbilisi city centre — default camera for the initial (Georgia) launch.
const tbilisiCenter = GeoCoord(41.7151, 44.7871);

/// Clubs and venues map (spec §6.3). Works in guest mode without sign-in.
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key, this.guest = false});

  final bool guest;

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final _map = MapController();
  final _search = TextEditingController();
  Timer? _debounce;
  String? _sportId;
  String _query = '';
  MapPlace? _selected;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearch(String v) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 300),
      () => setState(() {
        _query = v;
        _selected = null;
      }),
    );
  }

  void _select(MapPlace p) {
    setState(() => _selected = p);
    _map.move(LatLng(p.location.latitude, p.location.longitude), 15);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final places = ref.watch(placesProvider((_sportId, _query)));
    final sports = ref.watch(sportsProvider).value ?? const [];
    final list = places.value ?? const <MapPlace>[];
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: widget.guest ? AppBar(title: Text(l.navMap)) : null,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter: LatLng(tbilisiCenter.latitude, tbilisiCenter.longitude),
              initialZoom: 12.3,
              onTap: (_, _) => setState(() => _selected = null),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'ge.sportparent.sport_parent_app',
              ),
              MarkerLayer(
                markers: [
                  for (final p in list)
                    Marker(
                      key: Key('marker-${p.id}'),
                      point: LatLng(p.location.latitude, p.location.longitude),
                      width: _selected?.id == p.id ? 54 : 44,
                      height: _selected?.id == p.id ? 54 : 44,
                      child: GestureDetector(
                        onTap: () => _select(p),
                        child: _Pin(place: p, selected: _selected?.id == p.id),
                      ),
                    ),
                ],
              ),
              const SimpleAttributionWidget(source: Text('OpenStreetMap contributors')),
            ],
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
                  child: Material(
                    elevation: 6,
                    shadowColor: Colors.black26,
                    borderRadius: BorderRadius.circular(18),
                    child: TextField(
                      key: const Key('map-search'),
                      controller: _search,
                      onChanged: _onSearch,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: l.searchPlaces,
                        prefixIcon: const Icon(Icons.search_rounded),
                        fillColor: scheme.surface,
                        suffixIcon: _query.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.close_rounded),
                                onPressed: () {
                                  _search.clear();
                                  _onSearch('');
                                },
                              ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 52,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, 0),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(l.allSports),
                          selected: _sportId == null,
                          onSelected: (_) => setState(() => _sportId = null),
                        ),
                      ),
                      for (final s in sports)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            key: Key('map-filter-${s.id}'),
                            avatar: Icon(SportVisuals.icon(s.icon), size: 16, color: SportVisuals.color(s.icon)),
                            label: Text(s.name),
                            selected: _sportId == s.id,
                            onSelected: (_) => setState(() {
                              _sportId = s.id;
                              _selected = null;
                            }),
                          ),
                        ),
                    ],
                  ),
                ),
                if (places.isLoading) const LinearProgressIndicator(minHeight: 2),
                const Spacer(),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (c, a) => SlideTransition(
                    position: Tween(begin: const Offset(0, 0.3), end: Offset.zero).animate(a),
                    child: FadeTransition(opacity: a, child: c),
                  ),
                  child: _selected != null
                      ? Padding(
                          key: ValueKey(_selected!.id),
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: PlaceCard(place: _selected!, guest: widget.guest),
                        )
                      : _ResultsStrip(
                          key: const ValueKey('strip'),
                          places: list,
                          onTap: _select,
                          emptyText: places.hasValue && list.isEmpty ? l.mapNoResults : null,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Pin extends StatelessWidget {
  const _Pin({required this.place, required this.selected});

  final MapPlace place;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final sport = place.sportIds.isEmpty ? '' : place.sportIds.first;
    final isClub = place.kind == MapPlaceKind.club;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isClub ? AppColors.navy : SportVisuals.color(sport),
        shape: BoxShape.circle,
        border: Border.all(color: selected ? AppColors.volt : Colors.white, width: selected ? 3.5 : 2.5),
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 3))],
      ),
      child: Icon(
        isClub ? Icons.shield_rounded : venueTypeIcon(place.venue!.type),
        color: isClub ? AppColors.volt : Colors.white,
        size: selected ? 26 : 20,
      ),
    );
  }
}

class _ResultsStrip extends StatelessWidget {
  const _ResultsStrip({super.key, required this.places, required this.onTap, this.emptyText});

  final List<MapPlace> places;
  final ValueChanged<MapPlace> onTap;
  final String? emptyText;

  @override
  Widget build(BuildContext context) {
    if (emptyText != null) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: AppCard(
          child: Row(
            children: [
              const Icon(Icons.search_off_rounded),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(emptyText!)),
            ],
          ),
        ),
      );
    }
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
        itemCount: places.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (context, i) {
          final p = places[i];
          return SizedBox(
            width: 250,
            child: AppCard(
              padding: const EdgeInsets.all(AppSpacing.sm),
              onTap: () => onTap(p),
              child: Row(
                children: [
                  SportBadge(sportKey: p.sportIds.isEmpty ? '' : p.sportIds.first, size: 44),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(
                          p.address,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Location card: name, address, sports, club, directions (spec §6.3).
class PlaceCard extends ConsumerWidget {
  const PlaceCard({super.key, required this.place, this.guest = false});

  final MapPlace place;
  final bool guest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final sports = ref.watch(sportsByIdProvider);
    final isClub = place.kind == MapPlaceKind.club;
    final typeLabel = isClub ? l.clubLabel : venueTypeLabel(context, place.venue!.type);
    return AppCard(
      key: const Key('place-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              SportBadge(sportKey: place.sportIds.isEmpty ? '' : place.sportIds.first, size: 48),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(place.name, style: t.titleMedium),
                    Text(typeLabel, style: t.labelMedium?.copyWith(color: Theme.of(context).colorScheme.primary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(Icons.place_outlined, size: 18),
              const SizedBox(width: 6),
              Expanded(child: Text(place.address, style: t.bodyMedium)),
            ],
          ),
          if (!isClub && place.venue!.clubId != null && place.club != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.shield_outlined, size: 18),
                const SizedBox(width: 6),
                Expanded(child: Text(place.club!.name, style: t.bodyMedium)),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final s in place.sportIds)
                StatusPill(
                  label: sports[s]?.name ?? s,
                  color: SportVisuals.color(s),
                  icon: SportVisuals.icon(s),
                  dense: true,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 46)),
                  onPressed: () => openDirections(context, place.location, place.name),
                  icon: const Icon(Icons.directions_rounded, size: 20),
                  label: Text(l.directions),
                ),
              ),
              if (place.clubId != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton(
                    key: const Key('open-club'),
                    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 46)),
                    onPressed: () => context.push(Routes.club(place.clubId!)),
                    child: Text(l.clubDetails),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
