import 'dart:math';

import '../core/constants/rewards_constants.dart';
import '../models/duel.dart';
import '../models/gems_wallet.dart';
import '../models/user_progress.dart';
import '../repositories/duel_repository.dart';
import '../repositories/gems_repository.dart';
import '../repositories/progress_repository.dart';

/// Encapsulates duel business rules: generating today's bot opponent,
/// recording player score as duel-countable actions happen, and
/// resolving/claiming the result. Fully offline — the bot's target
/// score is derived deterministically from the player's own level and
/// today's date (so it's stable across app restarts within the same
/// day, without needing a persisted "opponent seed").
class DuelService {
  DuelService({
    required DuelRepository repository,
    required GemsRepository gemsRepository,
    required ProgressRepository progressRepository,
  })  : _repository = repository,
        _gemsRepository = gemsRepository,
        _progressRepository = progressRepository;

  final DuelRepository _repository;
  final GemsRepository _gemsRepository;
  final ProgressRepository _progressRepository;

  String get todayKey => _dateKey(DateTime.now());

  /// Returns today's duel, creating one if it doesn't exist yet. The
  /// bot's target score scales with the player's current level so it
  /// stays a fair, roughly-even race regardless of how experienced the
  /// player is.
  Future<Duel> loadOrCreateToday() async {
    final Duel? existing = await _repository.loadForDate(todayKey);
    if (existing != null) return existing;

    final UserProgress progress = await _progressRepository.load();
    final Random dailyRandom = Random(_dailySeed(progress.level));

    final int baseTarget = 40 + progress.level * 12;
    final int jitter = dailyRandom.nextInt(41) - 20; // +/- 20
    final int targetScore =
        (baseTarget + jitter).clamp(DuelConfig.minBotTarget, DuelConfig.maxBotTarget);

    final String opponentName =
        DuelConfig.opponentNamePool[dailyRandom.nextInt(DuelConfig.opponentNamePool.length)];

    final Duel duel = Duel(
      id: 'duel_$todayKey',
      dateKey: todayKey,
      opponentName: opponentName,
      opponentScore: targetScore,
      playerScore: 0,
      targetScore: targetScore,
      createdAt: DateTime.now(),
    );
    await _repository.save(duel);
    return duel;
  }

  /// Adds [points] to today's duel score (called alongside exercise/
  /// lesson completion events). No-ops if today's duel is already
  /// resolved and claimed, or if there's nothing to add.
  Future<Duel> addScore(int points) async {
    if (points <= 0) return loadOrCreateToday();
    final Duel duel = await loadOrCreateToday();
    if (duel.isResolved) return duel;

    final int newScore = duel.playerScore + points;
    final bool wonNow = newScore >= duel.targetScore;
    final Duel updated = duel.copyWith(
      playerScore: newScore,
      won: wonNow ? true : null,
      clearWon: !wonNow,
    );
    await _repository.save(updated);
    return updated;
  }

  /// Settles yesterday's (or any unresolved past) duel as a loss if the
  /// target was never reached — call this on app open so a duel doesn't
  /// stay "in progress" forever once its day has passed.
  Future<void> settleIfExpired(Duel duel) async {
    if (duel.isResolved) return;
    if (duel.dateKey == todayKey) return; // still today, not expired
    await _repository.save(duel.copyWith(won: false));
  }

  Future<List<Duel>> loadHistory() => _repository.loadRecent();

  /// Claims the gem reward for a won-and-unclaimed duel. Idempotent.
  Future<Duel> claimReward(Duel duel) async {
    if (duel.won != true || duel.isClaimed) return duel;

    final GemsWallet wallet = await _gemsRepository.load();
    await _gemsRepository.save(
      wallet.copyWith(balance: wallet.balance + DuelConfig.gemsRewardOnWin),
    );

    final Duel withReward = Duel(
      id: duel.id,
      dateKey: duel.dateKey,
      opponentName: duel.opponentName,
      opponentScore: duel.opponentScore,
      playerScore: duel.playerScore,
      targetScore: duel.targetScore,
      won: true,
      gemsReward: DuelConfig.gemsRewardOnWin,
      claimedAt: DateTime.now(),
      createdAt: duel.createdAt,
    );
    await _repository.save(withReward);
    return withReward;
  }

  int _dailySeed(int level) {
    final DateTime now = DateTime.now();
    return now.year * 10000 + now.month * 100 + now.day + level;
  }

  String _dateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}
