class LeaderboardEntry {
  final String userId;
  final String name;
  final int completedCount;
  final int totalTopics;
  final double completionRate;

  LeaderboardEntry({
    required this.userId,
    required this.name,
    required this.completedCount,
    required this.totalTopics,
    required this.completionRate,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      completedCount: json['completedCount'] ?? 0,
      totalTopics: json['totalTopics'] ?? 0,
      completionRate: (json['completionRate'] ?? 0).toDouble(),
    );
  }
}
