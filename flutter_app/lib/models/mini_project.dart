enum MiniProjectStatus {
  locked,
  available,
  inProgress,
  completed;

  static MiniProjectStatus fromJson(String value) {
    return MiniProjectStatus.values.firstWhere(
      (MiniProjectStatus e) => e.name == value,
      orElse: () => MiniProjectStatus.locked,
    );
  }

  String toJson() => name;
}

/// A small hands-on project unlocked after a cluster of lessons.
/// Designed to be completable in ~5-20 minutes.
class MiniProject {
  const MiniProject({
    required this.id,
    required this.title,
    required this.description,
    required this.instructions,
    this.starterCode = '',
    this.solutionCode = '',
    this.requiredTopics = const <String>[],
    this.xpReward = 100,
    this.status = MiniProjectStatus.locked,
    this.hints = const <String>[],
  });

  final String id;
  final String title;
  final String description;

  /// Full task instructions shown to the user, e.g.
  /// "Создай программу, которая спрашивает имя пользователя..."
  final String instructions;

  final String starterCode;
  final String solutionCode;

  /// Topic ids that must be completed before this project unlocks
  /// (e.g. ['variables', 'conditions', 'strings']).
  final List<String> requiredTopics;

  final int xpReward;
  final MiniProjectStatus status;

  /// Progressive hints; AI hint-assist escalates through these before
  /// ever revealing [solutionCode].
  final List<String> hints;

  factory MiniProject.fromJson(Map<String, dynamic> json) {
    return MiniProject(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      instructions: json['instructions'] as String? ?? '',
      starterCode: json['starterCode'] as String? ?? '',
      solutionCode: json['solutionCode'] as String? ?? '',
      requiredTopics: (json['requiredTopics'] as List<dynamic>?)
              ?.map((dynamic e) => e.toString())
              .toList() ??
          const <String>[],
      xpReward: json['xpReward'] as int? ?? 100,
      status: MiniProjectStatus.fromJson(json['status'] as String? ?? 'locked'),
      hints: (json['hints'] as List<dynamic>?)
              ?.map((dynamic e) => e.toString())
              .toList() ??
          const <String>[],
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'description': description,
        'instructions': instructions,
        'starterCode': starterCode,
        'solutionCode': solutionCode,
        'requiredTopics': requiredTopics,
        'xpReward': xpReward,
        'status': status.toJson(),
        'hints': hints,
      };

  MiniProject copyWith({MiniProjectStatus? status}) {
    return MiniProject(
      id: id,
      title: title,
      description: description,
      instructions: instructions,
      starterCode: starterCode,
      solutionCode: solutionCode,
      requiredTopics: requiredTopics,
      xpReward: xpReward,
      status: status ?? this.status,
      hints: hints,
    );
  }

  String? validate() {
    if (id.isEmpty) return 'MiniProject missing id';
    if (title.isEmpty) return 'MiniProject missing title';
    if (instructions.isEmpty) return 'MiniProject missing instructions';
    return null;
  }
}
