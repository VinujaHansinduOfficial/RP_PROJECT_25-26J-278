class StressResult {
  final String userId;
  final String type;
  final int count;
  final List<StressRecord> results;

  StressResult({
    required this.userId,
    required this.type,
    required this.count,
    required this.results,
  });

  factory StressResult.fromJson(Map<String, dynamic> json) {
    return StressResult(
      userId: json['user_id'] ?? '',
      type: json['type'] ?? 'Stress',
      count: json['count'] ?? 0,
      results: (json['results'] as List<dynamic>?)
              ?.map(
                  (item) => StressRecord.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class StressRecord {
  final String id;
  final String userId;
  final String target;
  final Map<String, dynamic> input;
  final int prediction; // 1 = Stressed, 0 = Not Stressed
  final double probability;
  final DateTime createdAt;

  StressRecord({
    required this.id,
    required this.userId,
    required this.target,
    required this.input,
    required this.prediction,
    required this.probability,
    required this.createdAt,
  });

  String get status => prediction == 1 ? 'Stressed' : 'Not Stressed';

  factory StressRecord.fromJson(Map<String, dynamic> json) {
    return StressRecord(
      id: json['_id'] ?? '',
      userId: json['user_id'] ?? '',
      target: json['target'] ?? 'Stress',
      input: json['input'] as Map<String, dynamic>? ?? {},
      prediction: json['prediction'] ?? 0,
      probability: (json['probability'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }
}
