import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../authentication/presentation/session_providers.dart';
import '../domain/brain_models.dart';
import '../domain/student_view.dart';

final studentViewProvider = StreamProvider.autoDispose<StudentView>((ref) {
  ref.watch(currentUidProvider);
  return ref.watch(studentRepositoryProvider).watchMyView();
});

final brainResultsProvider = StreamProvider.autoDispose.family<List<GameResult>, String>((ref, childId) {
  ref.watch(currentUidProvider);
  return ref.watch(brainAcademyRepositoryProvider).watchResults(childId);
});

final childChallengesProvider = StreamProvider.autoDispose.family<List<ChallengeAssignment>, String>((ref, childId) {
  ref.watch(currentUidProvider);
  return ref.watch(brainAcademyRepositoryProvider).watchAssignmentsForChild(childId);
});

final groupChallengesProvider = StreamProvider.autoDispose.family<List<ChallengeAssignment>, String>((ref, groupId) {
  ref.watch(currentUidProvider);
  return ref.watch(brainAcademyRepositoryProvider).watchAssignmentsForGroup(groupId);
});

String gameName(BuildContext context, BrainGame g) {
  final l = context.l10n;
  return switch (g) {
    BrainGame.memoryMatch => l.gameMemoryMatch,
    BrainGame.logicQuest => l.gameLogicQuest,
    BrainGame.smartPlay => l.gameSmartPlay,
    BrainGame.quickMind => l.gameQuickMind,
    BrainGame.sequenceMaster => l.gameSequenceMaster,
    BrainGame.pathFinder => l.gamePathFinder,
  };
}

String gameDescription(BuildContext context, BrainGame g) {
  final l = context.l10n;
  return switch (g) {
    BrainGame.memoryMatch => l.gameDescMemory,
    BrainGame.logicQuest => l.gameDescLogic,
    BrainGame.smartPlay => l.gameDescSmart,
    BrainGame.quickMind => l.gameDescQuick,
    BrainGame.sequenceMaster => l.gameDescSequence,
    BrainGame.pathFinder => l.gameDescPath,
  };
}

String gameHowTo(BuildContext context, BrainGame g) {
  final l = context.l10n;
  return switch (g) {
    BrainGame.memoryMatch => l.gameHowToMemory,
    BrainGame.logicQuest => l.gameHowToLogic,
    BrainGame.smartPlay => l.gameHowToSmart,
    BrainGame.quickMind => l.gameHowToQuick,
    BrainGame.sequenceMaster => l.gameHowToSequence,
    BrainGame.pathFinder => l.gameHowToPath,
  };
}

IconData gameIcon(BrainGame g) => switch (g) {
  BrainGame.memoryMatch => Icons.style_rounded,
  BrainGame.logicQuest => Icons.extension_rounded,
  BrainGame.smartPlay => Icons.sports_soccer_rounded,
  BrainGame.quickMind => Icons.bolt_rounded,
  BrainGame.sequenceMaster => Icons.queue_music_rounded,
  BrainGame.pathFinder => Icons.route_rounded,
};

Color gameColor(BrainGame g) => switch (g) {
  BrainGame.memoryMatch => const Color(0xFF7C4DFF),
  BrainGame.logicQuest => const Color(0xFF00897B),
  BrainGame.smartPlay => AppColors.success,
  BrainGame.quickMind => const Color(0xFFF57C00),
  BrainGame.sequenceMaster => const Color(0xFFD81B60),
  BrainGame.pathFinder => AppColors.blue,
};

String difficultyLabel(BuildContext context, GameDifficulty d) {
  final l = context.l10n;
  return switch (d) {
    GameDifficulty.easy => l.diffEasy,
    GameDifficulty.medium => l.diffMedium,
    GameDifficulty.hard => l.diffHard,
  };
}

String badgeLabel(BuildContext context, BrainBadge b) {
  final l = context.l10n;
  return switch (b) {
    BrainBadge.firstGame => l.badgeFirstGame,
    BrainBadge.explorer => l.badgeExplorer,
    BrainBadge.tenCompleted => l.badgeTenCompleted,
    BrainBadge.memoryHard => l.badgeMemoryHard,
    BrainBadge.perfectLogic => l.badgePerfectLogic,
    BrainBadge.tactician => l.badgeTactician,
    BrainBadge.quickReflexes => l.badgeQuickReflexes,
    BrainBadge.sequenceSeven => l.badgeSequenceSeven,
    BrainBadge.mazeHard => l.badgeMazeHard,
  };
}

IconData badgeIcon(BrainBadge b) => switch (b) {
  BrainBadge.firstGame => Icons.flag_rounded,
  BrainBadge.explorer => Icons.explore_rounded,
  BrainBadge.tenCompleted => Icons.workspace_premium_rounded,
  BrainBadge.memoryHard => Icons.psychology_rounded,
  BrainBadge.perfectLogic => Icons.lightbulb_rounded,
  BrainBadge.tactician => Icons.sports_rounded,
  BrainBadge.quickReflexes => Icons.flash_on_rounded,
  BrainBadge.sequenceSeven => Icons.format_list_numbered_rounded,
  BrainBadge.mazeHard => Icons.map_rounded,
};

String formatGameTime(int ms) {
  final s = ms ~/ 1000;
  return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
}
