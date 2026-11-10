import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/l10n.dart';
import '../layout/responsive.dart';
import '../utils/geo.dart';

/// Builds direction URLs for installed map apps (universal links open the
/// native app when installed, the browser otherwise).
class DirectionLinks {
  DirectionLinks._();

  static Uri apple(GeoCoord to, String label) =>
      Uri.https('maps.apple.com', '/', {'daddr': '${to.latitude},${to.longitude}', 'q': label});

  static Uri google(GeoCoord to) =>
      Uri.https('www.google.com', '/maps/dir/', {'api': '1', 'destination': '${to.latitude},${to.longitude}'});
}

Future<void> openDirections(BuildContext context, GeoCoord to, String label) async {
  final l = context.l10n;
  final options = <(String, IconData, Uri)>[
    if (Platform.isIOS) ('Apple Maps', Icons.map_rounded, DirectionLinks.apple(to, label)),
    ('Google Maps', Icons.navigation_rounded, DirectionLinks.google(to)),
  ];
  final uri = await showAdaptiveSheet<Uri>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(l.openInMaps, style: Theme.of(context).textTheme.titleMedium),
          ),
          for (final (name, icon, uri) in options)
            ListTile(leading: Icon(icon), title: Text(name), onTap: () => Navigator.pop(context, uri)),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
  if (uri == null) return;
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.errorGeneric)));
  }
}

Future<void> callPhone(String phone) => launchUrl(Uri(scheme: 'tel', path: phone.replaceAll(' ', '')));
