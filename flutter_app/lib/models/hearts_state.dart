import '../core/constants/game_economy_constants.dart';

/// Snapshot of the user's hearts (lives). Persisted as a tiny single-row
/// table; regeneration is computed lazily from [lastLostAt] rather than
/// via a background job, so the value is always correct the instant the
/// app reads it — no timers required to keep storage accurate.
class HeartsState {
  const HeartsState({
    this.current = HeartsConfig.maxHearts,
    this.lastLostAt,
  });

  /// Hearts remaining as of [lastLostAt]. Use [currentHearts] to get the
  /// regeneration-adjusted value "right now".
  final int current;

  /// Timestamp of the most recent heart loss. Null means the user has
  /// never lost a heart (or is already at full) — nothing to regenerate.
  final DateTime? lastLostAt;

  /// Hearts the user actually has *right now*, accounting for passive
  /// regeneration since [lastLostAt]. One heart regenerates every
  /// [HeartsConfig.regenDuration]; regeneration stops once full.
  int currentHearts({DateTime? now}) {
    if (current >= HeartsConfig.maxHearts || lastLostAt == null) {
      return current.clamp(0, HeartsConfig.maxHearts);
    }
    final DateTime clockNow = now ?? DateTime.now();
    final Duration elapsed = clockNow.difference(lastLostAt!);
    if (elapsed.isNegative) return current.clamp(0, HeartsConfig.maxHearts);

    final int regenerated = elapsed.inMilliseconds ~/
        HeartsConfig.regenDuration.inMilliseconds;
    if (regenerated <= 0) return current.clamp(0, HeartsConfig.maxHearts);

    return (current + regenerated).clamp(0, HeartsConfig.maxHearts);
  }

  /// Time remaining until the *next* heart regenerates, or null if the
  /// user is already full (or has none lost yet). Used to drive a
  /// "next heart in 12:34" countdown in the UI.
  Duration? timeUntilNextHeart({DateTime? now}) {
    final int liveHearts = currentHearts(now: now);
    if (liveHearts >= HeartsConfig.maxHearts || lastLostAt == null) return null;

    final DateTime clockNow = now ?? DateTime.now();
    final int alreadyRegenerated = liveHearts - current;
    final DateTime nextTickAt = lastLostAt!.add(
      HeartsConfig.regenDuration * (alreadyRegenerated + 1),
    );
    final Duration remaining = nextTickAt.difference(clockNow);
    return remaining.isNegative ? Duration.zero : remaining;
  }

  bool get isFull => current >= HeartsConfig.maxHearts;
  bool get isEmpty => currentHearts() <= 0;

  /// Returns the state as it would be "right now" with regeneration
  /// applied and folded into [current] — call this before persisting so
  /// stored values never drift from what regeneration would compute.
  HeartsState normalized({DateTime? now}) {
    final int live = currentHearts(now: now);
    if (live == current) return this;
    return HeartsState(
      current: live,
      lastLostAt: live >= HeartsConfig.maxHearts ? null : lastLostAt,
    );
  }

  HeartsState loseOne({DateTime? now}) {
    final HeartsState fresh = normalized(now: now);
    if (fresh.current <= 0) return fresh;
    return HeartsState(current: fresh.current - 1, lastLostAt: now ?? DateTime.now());
  }

  HeartsState refillAll() => const HeartsState();

  HeartsState addOne() {
    final HeartsState fresh = normalized();
    final int newCount = (fresh.current + 1).clamp(0, HeartsConfig.maxHearts);
    return HeartsState(
      current: newCount,
      lastLostAt: newCount >= HeartsConfig.maxHearts ? null : fresh.lastLostAt,
    );
  }

  HeartsState copyWith({int? current, DateTime? lastLostAt, bool clearLastLostAt = false}) {
    return HeartsState(
      current: current ?? this.current,
      lastLostAt: clearLastLostAt ? null : (lastLostAt ?? this.lastLostAt),
    );
  }

  factory HeartsState.fromJson(Map<String, dynamic> json) {
    return HeartsState(
      current: json['current'] as int? ?? HeartsConfig.maxHearts,
      lastLostAt: json['lastLostAt'] != null
          ? DateTime.tryParse(json['lastLostAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'current': current,
        'lastLostAt': lastLostAt?.toIso8601String(),
      };
}
