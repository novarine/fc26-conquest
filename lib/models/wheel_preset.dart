class WheelPreset {
  const WheelPreset({
    required this.id,
    required this.name,
    required this.entries,
  });

  final String id;
  final String name;
  final List<String> entries;

  factory WheelPreset.fromJson(Map<String, dynamic> json) {
    return WheelPreset(
      id: json['id'] as String,
      name: json['name'] as String,
      entries: (json['entries'] as List<dynamic>)
          .map((entry) => entry as String)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'entries': entries,
    };
  }
}
