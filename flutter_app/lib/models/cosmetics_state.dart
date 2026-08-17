/// What the user owns and has equipped from [CosmeticsCatalog]. Kept as
/// one small state object (rather than modeling ownership as a list of
/// rows in memory) since the UI only ever needs "do I own X" and
/// "what's currently equipped" — both cheap lookups against a Set.
class CosmeticsState {
  const CosmeticsState({
    this.ownedIds = const <String>{},
    this.equippedAvatarFrameId,
    this.equippedIconThemeId,
  });

  final Set<String> ownedIds;
  final String? equippedAvatarFrameId;
  final String? equippedIconThemeId;

  bool owns(String id) => ownedIds.contains(id);

  CosmeticsState copyWith({
    Set<String>? ownedIds,
    String? equippedAvatarFrameId,
    String? equippedIconThemeId,
    bool clearAvatarFrame = false,
    bool clearIconTheme = false,
  }) {
    return CosmeticsState(
      ownedIds: ownedIds ?? this.ownedIds,
      equippedAvatarFrameId:
          clearAvatarFrame ? null : (equippedAvatarFrameId ?? this.equippedAvatarFrameId),
      equippedIconThemeId:
          clearIconTheme ? null : (equippedIconThemeId ?? this.equippedIconThemeId),
    );
  }
}
