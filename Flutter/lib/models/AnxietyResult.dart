class AnxietyResult {
  final String userId;
  final String type;
  final int count;
  final List<AnxietyRecord> results;

  AnxietyResult({
    required this.userId,
    required this.type,
    required this.count,
    required this.results,
  });

  factory AnxietyResult.fromJson(Map<String, dynamic> json) {
    return AnxietyResult(
      userId: json['user_id'] ?? '',
      type: json['type'] ?? 'Anxiety',
      count: json['count'] ?? 0,
      results: (json['results'] as List<dynamic>?)
              ?.map((item) =>
                  AnxietyRecord.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class AnxietyRecord {
  final String id;
  final String userId;
  final String target;
  final Map<String, dynamic> input;
  final int prediction; // 0 = Normal, 1 = High Anxiety
  final double probability;
  final DateTime createdAt;

  AnxietyRecord({
    required this.id,
    required this.userId,
    required this.target,
    required this.input,
    required this.prediction,
    required this.probability,
    required this.createdAt,
  });

  String get status => prediction == 1 ? 'High Anxiety' : 'Normal';

  factory AnxietyRecord.fromJson(Map<String, dynamic> json) {
    return AnxietyRecord(
      id: json['_id'] ?? '',
      userId: json['user_id'] ?? '',
      target: json['target'] ?? 'Anxiety',
      input: json['input'] as Map<String, dynamic>? ?? {},
      prediction: json['prediction'] ?? 0,
      probability: (json['probability'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }
}
