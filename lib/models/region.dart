class Region {
  const Region({
    required this.id,
    required this.label,
    required this.ownerId,
    required this.neighbors,
  });

  final int id;
  final String label;
  final int ownerId;
  final List<int> neighbors;

  Region copyWith({
    int? id,
    String? label,
    int? ownerId,
    List<int>? neighbors,
  }) {
    return Region(
      id: id ?? this.id,
      label: label ?? this.label,
      ownerId: ownerId ?? this.ownerId,
      neighbors: neighbors ?? this.neighbors,
    );
  }

  factory Region.fromJson(Map<String, dynamic> json) {
    return Region(
      id: json['id'] as int,
      label: json['label'] as String,
      ownerId: json['ownerId'] as int,
      neighbors: (json['neighbors'] as List<dynamic>).cast<int>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'ownerId': ownerId,
      'neighbors': neighbors,
    };
  }
}
