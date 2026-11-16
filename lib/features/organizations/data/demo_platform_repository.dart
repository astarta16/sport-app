import '../../../core/errors/app_exception.dart';
import '../../../core/utils/geo.dart';
import '../../authentication/domain/app_user.dart';
import '../../clubs/domain/club.dart';
import '../../demo/data/demo_backend.dart';
import '../domain/organization.dart';
import '../domain/platform.dart';
import '../domain/repositories.dart';

/// Demo Platform Super Admin backend. Every operation re-checks the
/// platform role (or, for invitations, the invited user) exactly like the
/// production callables in functions/src/triggers/v18.ts.
class DemoPlatformRepository implements PlatformRepository {
  DemoPlatformRepository(this.db);

  final DemoBackend db;

  AppUser _platform() {
    final me = db.me;
    if (!me.isPlatformAdmin) throw const PermissionDeniedException('platform');
    return me;
  }

  OrgConfig _cfg(String orgId) {
    if (!db.clubs.containsKey(orgId)) throw const NotFoundException('organization');
    return db.orgConfig(orgId);
  }

  SubscriptionPackage _package(String id) => db.packages[id] ?? (throw const ValidationException('package'));

  String _reason(String reason) {
    final r = reason.trim();
    if (r.length < 3 || r.length > 300) throw const ValidationException('changeReason');
    return r;
  }

  // ── overview ─────────────────────────────────────────────────────────

  @override
  Stream<PlatformStats> watchStats() => db.watch(() {
    _platform();
    final now = db.clock();
    final ids = db.clubs.keys.toList();
    final cfgs = [for (final id in ids) db.orgConfig(id)];
    final alerts = <PlatformAlert>[];
    for (final c in cfgs) {
      final pkg = db.packages[c.packageId];
      if (pkg != null && db.usageOf(c.orgId).exceeded(pkg.limits).isNotEmpty) {
        alerts.add(
          PlatformAlert(AlertKind.overLimit, c.orgId, detail: db.usageOf(c.orgId).exceeded(pkg.limits).join(',')),
        );
      }
      final end = c.subscription.endAt;
      if (c.subscription.status == SubscriptionStatus.trial && end != null && end.difference(now).inDays <= 7) {
        alerts.add(PlatformAlert(AlertKind.trialEnding, c.orgId));
      }
      if (c.subscription.status == SubscriptionStatus.pastDue) alerts.add(PlatformAlert(AlertKind.pastDue, c.orgId));
      if (c.accessAt(now) == AccessMode.readOnly) alerts.add(PlatformAlert(AlertKind.readOnly, c.orgId));
      if (c.provisioning != ProvisioningState.ready) alerts.add(PlatformAlert(AlertKind.provisioningStuck, c.orgId));
    }
    for (final i in db.invitations.values) {
      if (i.statusAt(now) == InvitationStatus.pending && i.expiresAt.difference(now).inDays < 2) {
        alerts.add(PlatformAlert(AlertKind.invitationExpiring, i.orgId));
      }
    }
    final users = db.users.values.where((u) => !u.isPlatformAdmin);
    return PlatformStats(
      organizations: ids.length,
      active: cfgs.where((c) => c.isActive).length,
      suspended: cfgs.where((c) => !c.isActive).length,
      trial: cfgs.where((c) => c.subscription.status == SubscriptionStatus.trial).length,
      users: users.length,
      coaches: users.where((u) => u.isCoach).length,
      students: db.children.length,
      parents: users.where((u) => u.isParent).length,
      adoption: {for (final m in OrgModule.values) m: cfgs.where((c) => c.isEnabled(m, now: now)).length},
      bySubscription: {
        for (final st in SubscriptionStatus.values) st: cfgs.where((c) => c.subscription.status == st).length,
      },
      alerts: alerts,
      synthetic: true,
    );
  });

  // ── packages ─────────────────────────────────────────────────────────

  @override
  Stream<List<SubscriptionPackage>> watchPackages() => db.watch(() {
    final me = db.me;
    if (!me.isAdmin) throw const PermissionDeniedException('packages');
    return db.packages.values.toList();
  });

  @override
  Future<SubscriptionPackage> upsertPackage(SubscriptionPackage p) async {
    db.requireOnline();
    _platform();
    final errors = PackageLimits.validate(p.limits);
    if (errors.isNotEmpty) throw ValidationException(errors.first);
    if (p.names.values.every((n) => n.trim().length < 2)) throw const ValidationException('packageName');
    if (!p.custom && !FeatureCatalog.isValid(p.modules)) throw const ValidationException('featureDependencies');
    final saved = p.id.isEmpty ? p.copyWith(id: db.newId('pkg')) : p;
    db.packages[saved.id] = saved;
    db.auditLog('package.upsert', 'package', saved.id, details: {'modules': '${saved.modules.length}'});
    db.commit();
    return saved;
  }

  // ── templates ────────────────────────────────────────────────────────

  @override
  Stream<List<OrgTemplate>> watchTemplates() => db.watch(() {
    _platform();
    return db.templates.values.toList();
  });

  @override
  Future<OrgTemplate> upsertTemplate(OrgTemplate t) async {
    db.requireOnline();
    _platform();
    final errors = OrgTemplate.validate(t);
    if (errors.isNotEmpty) throw ValidationException(errors.first);
    _package(t.packageId);
    final saved = t.id.isEmpty ? t.copyWith(id: db.newId('tpl'), builtIn: false) : t;
    db.templates[saved.id] = saved;
    db.auditLog('template.upsert', 'template', saved.id);
    db.commit();
    return saved;
  }

  @override
  Future<OrgTemplate> duplicateTemplate(String templateId) async {
    final t = db.templates[templateId] ?? (throw const NotFoundException('template'));
    return upsertTemplate(
      t.copyWith(
        id: '',
        builtIn: false,
        archived: false,
        names: {for (final e in t.names.entries) e.key: '${e.value} (2)'},
      ),
    );
  }

  @override
  Future<void> archiveTemplate(String templateId, {required bool archived}) async {
    db.requireOnline();
    _platform();
    final t = db.templates[templateId] ?? (throw const NotFoundException('template'));
    db.templates[templateId] = t.copyWith(archived: archived);
    db.auditLog(archived ? 'template.archive' : 'template.restore', 'template', templateId);
    db.commit();
  }

  // ── provisioning ─────────────────────────────────────────────────────

  @override
  Future<ProvisionResult> provisionOrganization(ProvisionRequest r) async {
    db.requireOnline();
    final me = _platform();
    final errors = ProvisionRequest.validate(r);
    if (errors.isNotEmpty) throw ValidationException(errors.first);
    final pkg = _package(r.packageId);
    final tpl = r.templateId == null
        ? null
        : (db.templates[r.templateId] ?? (throw const NotFoundException('template')));
    if (tpl != null && tpl.archived) throw const ValidationException('templateArchived');
    for (final s in r.sportIds) {
      if (!db.sports.containsKey(s)) throw const ValidationException('sport');
    }
    final modules = r.modules ?? tpl?.modules ?? pkg.modules.difference(restrictedModules);
    final notIn = modules.where((m) => !pkg.includes(m)).toList();
    if (notIn.isNotEmpty) throw ValidationException('notInPackage:${notIn.first.name}');
    // Stable unique id: slug of the English/Georgian name + sequence.
    final base = (r.names['en'] ?? r.names['ka'] ?? 'org')
        .toLowerCase()
        .replaceAll(RegExp('[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    final orgId = 'org-${base.isEmpty ? 'school' : base}-${db.newId('p').split('-').last}';
    final now = db.clock();
    // Phase 1: everything is written with provisioning = provisioning.
    final club = Club(
      id: orgId,
      name: (r.names['ka'] ?? r.names['en'])!.trim(),
      address: r.address.trim(),
      sportIds: r.sportIds,
      location: GeoCoord(r.lat, r.lng),
      geohash: Geohash.encode(r.lat, r.lng),
      phone: r.contactPhone.trim(),
      description: r.description,
    );
    final cfg = OrgConfig(
      orgId: orgId,
      packageId: pkg.id,
      allowedModules: pkg.custom ? modules : pkg.modules,
      enabledModules: modules,
      limits: pkg.limits.orgLimits,
      subscription: r.subscription.copyWith(
        startAt: r.subscription.startAt ?? now,
        endAt: r.subscription.endAt ?? now.add(Duration(days: pkg.durationDays)),
      ),
      branding: OrgBranding(
        names: r.names,
        primaryColor: r.primaryColor,
        secondaryColor: r.secondaryColor,
        logoUrl: r.logoUrl,
        description: r.description,
        contactEmail: r.contactEmail.trim(),
        contactPhone: r.contactPhone.trim(),
        address: r.address.trim(),
      ),
      profile: OrgProfile(
        legalName: r.legalName.trim(),
        type: tpl?.type ?? r.type,
        funding: r.funding,
        registrationId: r.registrationId,
        city: r.city.trim(),
      ),
      settings: tpl?.settings ?? const OrgSettings(),
      bookingBufferMin: tpl?.bookingBufferMin ?? 0,
      timezone: OrgTimeZones.normalize(r.timezone),
      defaultLanguage: r.defaultLanguage,
      templateId: tpl?.id,
      provisioning: ProvisioningState.provisioning,
      version: 0,
      updatedAt: now,
    );
    final snapshot = (Map.of(db.clubs), Map.of(db.orgConfigs), Map.of(db.invitations), db.configHistory.length);
    try {
      db.clubs[orgId] = club;
      db.orgConfigs[orgId] = cfg;
      final issued = _issue(orgId, phone: r.adminPhone?.trim(), email: r.adminEmail?.trim(), by: me.id);
      // Phase 2: only now does the organization become usable.
      db.saveConfig(
        cfg.copyWith(provisioning: ProvisioningState.ready),
        reason: tpl == null ? 'provisioned' : 'provisioned from template ${tpl.id}',
        action: 'org.provision',
      );
      db.commit();
      return ProvisionResult(orgId: orgId, invitation: issued.invitation, token: issued.token);
    } catch (_) {
      // Recover: nothing half-created stays behind.
      db.clubs
        ..clear()
        ..addAll(snapshot.$1);
      db.orgConfigs
        ..clear()
        ..addAll(snapshot.$2);
      db.invitations
        ..clear()
        ..addAll(snapshot.$3);
      db.configHistory.removeRange(snapshot.$4, db.configHistory.length);
      rethrow;
    }
  }

  @override
  Future<List<TemplateChange>> previewTemplate(String orgId, String templateId) async {
    _platform();
    final t = db.templates[templateId] ?? (throw const NotFoundException('template'));
    return TemplateDiff.compute(_cfg(orgId), t);
  }

  @override
  Future<OrgConfig> applyTemplate(
    String orgId,
    String templateId, {
    required int expectedVersion,
    required String reason,
  }) async {
    db.requireOnline();
    _platform();
    final t = db.templates[templateId] ?? (throw const NotFoundException('template'));
    final c = _cfg(orgId);
    final pkg = _package(t.packageId);
    final saved = db.saveConfig(
      c.copyWith(
        packageId: pkg.id,
        allowedModules: pkg.custom ? t.modules : pkg.modules,
        enabledModules: t.modules,
        limits: pkg.limits.orgLimits,
        settings: t.settings,
        bookingBufferMin: t.bookingBufferMin,
        profile: OrgProfile(
          legalName: c.profile.legalName,
          type: t.type,
          funding: t.funding,
          registrationId: c.profile.registrationId,
          city: c.profile.city,
        ),
        templateId: t.id,
      ),
      expectedVersion: expectedVersion,
      reason: _reason(reason),
      action: 'org.template.apply',
    );
    db.commit();
    return saved;
  }

  // ── entitlements & subscriptions ─────────────────────────────────────

  @override
  Future<OrgConfig> updateEntitlements(
    String orgId, {
    required int expectedVersion,
    required Set<OrgModule> allowed,
    Map<OrgModule, FeatureRollout> rollout = const {},
    required String reason,
  }) async {
    db.requireOnline();
    _platform();
    final c = _cfg(orgId);
    final pkg = _package(c.packageId);
    final notIn = allowed.where((m) => !pkg.includes(m)).toList();
    if (notIn.isNotEmpty) throw ValidationException('notInPackage:${notIn.first.name}');
    if (!FeatureCatalog.isValid(allowed)) throw const ValidationException('featureDependencies');
    for (final r in rollout.values) {
      if (r.state == RolloutState.trial && r.until == null) throw const ValidationException('rolloutDate');
      if (r.state == RolloutState.scheduled && r.at == null) throw const ValidationException('rolloutDate');
    }
    final saved = db.saveConfig(
      c.copyWith(
        allowedModules: allowed,
        // Withdrawn features (and what depends on them) switch off.
        enabledModules: FeatureCatalog.prune(c.enabledModules.intersection(allowed)),
        rollout: rollout,
      ),
      expectedVersion: expectedVersion,
      reason: _reason(reason),
      action: 'org.entitlements',
    );
    db.commit();
    return saved;
  }

  @override
  Future<OrgConfig> updateSubscription(
    String orgId, {
    required int expectedVersion,
    String? packageId,
    SubscriptionInfo? subscription,
    OrgLimits? limits,
    required String reason,
  }) async {
    db.requireOnline();
    _platform();
    final c = _cfg(orgId);
    final pkg = _package(packageId ?? c.packageId);
    if (pkg.archived && pkg.id != c.packageId) throw const ValidationException('packageArchived');
    final allowed = pkg.custom ? c.allowedModules : c.allowedModules.intersection(pkg.modules);
    final changedPackage = pkg.id != c.packageId;
    final saved = db.saveConfig(
      c.copyWith(
        packageId: pkg.id,
        allowedModules: changedPackage && !pkg.custom ? pkg.modules : allowed,
        enabledModules: FeatureCatalog.prune(
          c.enabledModules.intersection(changedPackage && !pkg.custom ? pkg.modules : allowed),
        ),
        // Custom limits only for custom (negotiated) packages.
        limits: pkg.custom ? (limits ?? c.limits) : pkg.limits.orgLimits,
        subscription: subscription,
      ),
      expectedVersion: expectedVersion,
      reason: _reason(reason),
      action: 'org.subscription',
    );
    db.commit();
    return saved;
  }

  @override
  Stream<List<ConfigHistoryEntry>> watchHistory(String orgId) => db.watch(() {
    if (!db.me.administersClub(orgId)) throw const PermissionDeniedException('history');
    return db.configHistory.where((h) => h.orgId == orgId).toList().reversed.toList();
  });

  @override
  Future<OrgUsage> usage(String orgId) async {
    if (!db.me.administersClub(orgId)) throw const PermissionDeniedException('usage');
    return db.usageOf(orgId);
  }

  // ── invitations ──────────────────────────────────────────────────────

  InvitationIssued _issue(String orgId, {String? phone, String? email, String? transferFrom, required String by}) {
    if ((phone ?? '').isEmpty && (email ?? '').isEmpty) throw const ValidationException('orgAdminMissing');
    final token = InvitationTokens.generate();
    final inv = OrgInvitation(
      id: db.newId('inv'),
      orgId: orgId,
      tokenHash: InvitationTokens.hash(token),
      expiresAt: db.clock().add(OrgInvitation.validity),
      invitedBy: by,
      createdAt: db.clock(),
      phone: (phone ?? '').isEmpty ? null : phone,
      email: (email ?? '').isEmpty ? null : email,
      transferFrom: transferFrom,
    );
    db.invitations[inv.id] = inv;
    db.auditLog('invitation.create', 'invitation', inv.id, clubId: orgId);
    return InvitationIssued(inv, token);
  }

  @override
  Stream<List<OrgInvitation>> watchInvitations({String? orgId}) => db.watch(() {
    final me = db.me;
    if (orgId == null ? !me.isPlatformAdmin : !me.administersClub(orgId)) {
      throw const PermissionDeniedException('invitations');
    }
    final now = db.clock();
    return [
      for (final i in db.invitations.values)
        if (orgId == null || i.orgId == orgId) i.copyWith(status: i.statusAt(now)),
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  });

  @override
  Future<InvitationIssued> inviteAdmin(String orgId, {String? phone, String? email, String? transferFrom}) async {
    db.requireOnline();
    final me = db.me;
    _cfg(orgId);
    // Platform admin invites; an organization admin may only hand over
    // their OWN role (transfer), never add admins at will.
    final selfTransfer = transferFrom == me.id && me.administersClub(orgId);
    if (!me.isPlatformAdmin && !selfTransfer) throw const PermissionDeniedException('invite');
    if (transferFrom != null && !(db.users[transferFrom]?.adminClubIds.contains(orgId) ?? false)) {
      throw const ValidationException('transferFrom');
    }
    final issued = _issue(orgId, phone: phone, email: email, transferFrom: transferFrom, by: me.id);
    db.commit();
    return issued;
  }

  @override
  Future<InvitationIssued> resendInvitation(String invitationId) async {
    db.requireOnline();
    _platform();
    final i = db.invitations[invitationId] ?? (throw const NotFoundException('invitation'));
    final st = i.statusAt(db.clock());
    if (st != InvitationStatus.pending && st != InvitationStatus.expired) {
      throw const ValidationException('invitationClosed');
    }
    // A new token invalidates the old link.
    final token = InvitationTokens.generate();
    final next = i.copyWith(
      tokenHash: InvitationTokens.hash(token),
      expiresAt: db.clock().add(OrgInvitation.validity),
      status: InvitationStatus.pending,
      resendCount: i.resendCount + 1,
    );
    db.invitations[i.id] = next;
    db.auditLog('invitation.resend', 'invitation', i.id, clubId: i.orgId);
    db.commit();
    return InvitationIssued(next, token);
  }

  @override
  Future<void> revokeInvitation(String invitationId) async {
    db.requireOnline();
    final me = db.me;
    final i = db.invitations[invitationId] ?? (throw const NotFoundException('invitation'));
    if (!me.isPlatformAdmin && i.invitedBy != me.id) throw const PermissionDeniedException('revoke');
    db.invitations[i.id] = i.copyWith(status: InvitationStatus.revoked);
    db.auditLog('invitation.revoke', 'invitation', i.id, clubId: i.orgId);
    db.commit();
  }

  OrgInvitation _byToken(String token) {
    final h = InvitationTokens.hash(token.trim());
    final i = db.invitations.values.where((x) => x.tokenHash == h).firstOrNull;
    if (i == null) throw const NotFoundException('invitation');
    final st = i.statusAt(db.clock());
    if (st == InvitationStatus.expired) throw const ValidationException('invitationExpired');
    if (st != InvitationStatus.pending) throw const ValidationException('invitationClosed');
    return i;
  }

  @override
  Future<String> acceptInvitation(String token) async {
    db.requireOnline();
    final me = db.me;
    final i = _byToken(token);
    // Bound to the invited phone when one was given.
    if (i.phone != null && i.phone!.replaceAll(' ', '') != me.phone.replaceAll(' ', '')) {
      throw const PermissionDeniedException('invitationRecipient');
    }
    if (me.isPlatformAdmin) throw const ValidationException('alreadyPlatformAdmin');
    AppUser grant(AppUser u, Set<String> clubs) => AppUser.fromMap(u.id, {
      ...u.toMap(),
      'role': u.role.name,
      'adminRole': clubs.isEmpty ? null : AdminRole.club.name,
      'adminClubIds': clubs.toList(),
      'coachStatusReason': u.coachStatusReason,
    });
    db.users[me.id] = grant(me, {...me.adminClubIds, i.orgId});
    final key = '${i.orgId}|${me.id}';
    db.memberships[key] = OrgMembership(
      orgId: i.orgId,
      userId: me.id,
      roles: {...?db.memberships[key]?.roles, OrgRole.admin},
    );
    db.clubs[i.orgId] = db.clubs[i.orgId]!.copyWith(adminIds: {...db.clubs[i.orgId]!.adminIds, me.id}.toList());
    final from = i.transferFrom;
    if (from != null && from != me.id && db.users[from] != null) {
      final old = db.users[from]!;
      db.users[from] = grant(old, {...old.adminClubIds}..remove(i.orgId));
      final k = '${i.orgId}|$from';
      final roles = {...?db.memberships[k]?.roles}..remove(OrgRole.admin);
      db.memberships[k] = OrgMembership(orgId: i.orgId, userId: from, roles: roles, active: roles.isNotEmpty);
      db.clubs[i.orgId] = db.clubs[i.orgId]!.copyWith(
        adminIds: db.clubs[i.orgId]!.adminIds.where((a) => a != from).toList(),
      );
    }
    db.invitations[i.id] = i.copyWith(status: InvitationStatus.accepted, acceptedBy: me.id);
    db.auditLog('invitation.accept', 'invitation', i.id, clubId: i.orgId, details: {'transferFrom': from ?? ''});
    db.commit();
    return i.orgId;
  }

  @override
  Future<void> rejectInvitation(String token) async {
    db.requireOnline();
    final i = _byToken(token);
    db.invitations[i.id] = i.copyWith(status: InvitationStatus.rejected);
    db.auditLog('invitation.reject', 'invitation', i.id, clubId: i.orgId);
    db.commit();
  }

  // ── scheduler ────────────────────────────────────────────────────────

  @override
  Future<List<String>> refreshEntitlements() async {
    _platform();
    return refreshAll();
  }

  /// The scheduler itself (no signed-in user): the demo equivalent of the
  /// hourly `refreshEntitlements` Cloud Function.
  List<String> refreshAll() {
    final now = db.clock();
    final changed = <String>[];
    for (final id in db.orgConfigs.keys.toList()) {
      final c = db.orgConfigs[id]!;
      var sub = c.subscription;
      // Ended trials / subscriptions past their grace period become expired.
      if ((sub.status == SubscriptionStatus.trial || sub.status == SubscriptionStatus.active) &&
          sub.accessAt(now) == AccessMode.readOnly) {
        sub = sub.copyWith(status: SubscriptionStatus.expired);
      }
      final trialsOver = {
        for (final e in c.rollout.entries)
          if (e.value.state == RolloutState.trial && !e.value.allows(now)) e.key,
      };
      if (sub.status != c.subscription.status || trialsOver.isNotEmpty) {
        db.saveConfig(
          c.copyWith(
            subscription: sub,
            rollout: {
              for (final e in c.rollout.entries)
                e.key: trialsOver.contains(e.key) ? const FeatureRollout(RolloutState.disabled) : e.value,
            },
          ),
          reason: 'scheduled entitlement refresh',
          action: 'org.entitlements.refresh',
        );
        changed.add(id);
      }
    }
    if (changed.isNotEmpty) db.commit();
    return changed;
  }
}
