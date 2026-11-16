import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di.dart';
import '../domain/organization.dart';
import 'org_providers.dart';

/// v1.8 client-side feature availability for the signed-in user: the union
/// of effective features of their organizations (or of the selected
/// organization only). This only hides UI — every operation is re-checked
/// by the backend (demo backend / rules / callables).
///
/// `null` while the configuration loads (nothing is hidden or blocked yet;
/// the backend still rejects disabled operations). Configuration streams
/// are live, so a platform change shows up without an app rebuild.
final availableModulesProvider = Provider<Set<OrgModule>?>((ref) {
  final configs = ref.watch(orgConfigsProvider);
  final active = ref.watch(activeOrgProvider);
  final now = ref.watch(clockProvider)();
  final list = configs.value;
  if (list == null) return null;
  final scoped = active == null ? list : list.where((c) => c.orgId == active).toList();
  if (scoped.isEmpty) return null;
  return {
    for (final c in scoped)
      for (final m in OrgModule.values)
        if (c.isEnabled(m, now: now)) m,
  };
});

final featureOnProvider = Provider.family<bool, OrgModule>((ref, m) {
  final s = ref.watch(availableModulesProvider);
  return s == null || s.contains(m);
});

/// Shows [child] only when [module] is available to the user.
class FeatureGate extends ConsumerWidget {
  const FeatureGate({super.key, required this.module, required this.child});

  final OrgModule module;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      ref.watch(featureOnProvider(module)) ? child : const SizedBox.shrink();
}

/// The feature a route belongs to (direct links and old deep links to a
/// disabled feature are redirected home).
OrgModule? routeModule(String location) {
  final path = location.split('?').first;
  if (path == '/payments' || path.startsWith('/payments/') || RegExp(r'^/group/[^/]+/payments').hasMatch(path)) {
    if (path.startsWith('/payments/proofs') || path.endsWith('/proof')) return OrgModule.paymentReceipts;
    if (path == '/payments/review') return OrgModule.paymentVerification;
    return OrgModule.payments;
  }
  if (path == '/chats' || path.startsWith('/chat/') || path.endsWith('/chat')) return OrgModule.communication;
  if (path == '/plans' || path.startsWith('/plans/')) return OrgModule.trainingPlans;
  if (path.startsWith('/certificates/')) return OrgModule.medicalCertificates;
  if (path.startsWith('/media/')) return OrgModule.media;
  if (RegExp(r'^/group/[^/]+/challenges').hasMatch(path)) return OrgModule.coachChallenges;
  if (path.startsWith('/kid/brain/')) return OrgModule.brainAcademy;
  if (path.endsWith('/attendance')) return OrgModule.attendance;
  if (path == '/students') return OrgModule.dataExports;
  return null;
}
