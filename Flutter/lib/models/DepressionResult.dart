class DepressionResult {
  final String userId;
  final String type;
  final int count;
  final List<DepressionRecord> results;

  DepressionResult({
    required this.userId,
    required this.type,
    required this.count,
    required this.results,
  });

  factory DepressionResult.fromJson(Map<String, dynamic> json) {
    return DepressionResult(
      userId: json['user_id'] ?? '',
      type: json['type'] ?? 'Depression',
      count: json['count'] ?? 0,
      results: (json['results'] as List<dynamic>?)
              ?.map((item) =>
                  DepressionRecord.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class DepressionRecord {
  final String id;
  final String userId;
  final String target;
  final Map<String, dynamic> input;
  final int prediction; // 0 = Stable, 1 = Depressed
  final double probability;
  final DateTime createdAt;

  DepressionRecord({
    required this.id,
    required this.userId,
    required this.target,
    required this.input,
    required this.prediction,
    required this.probability,
    required this.createdAt,
  });

  String get status => prediction == 1 ? 'Depressed' : 'Stable';

  factory DepressionRecord.fromJson(Map<String, dynamic> json) {
    return DepressionRecord(
      id: json['_id'] ?? '',
      userId: json['user_id'] ?? '',
      target: json['target'] ?? 'Depression',
      input: json['input'] as Map<String, dynamic>? ?? {},
      prediction: json['prediction'] ?? 0,
      probability: (json['probability'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }
}
