class Player {
  const Player({
    required this.id,
    required this.name,
    required this.position,
    required this.rating,
    required this.originTeamId,
    required this.currentTeamId,
    this.age,
    this.nation,
    this.value,
    this.wage,
    this.pace,
    this.shooting,
    this.passing,
    this.dribbling,
    this.defending,
    this.physical,
    this.face,
  });

  final int id;
  final String name;
  final String position;
  final int rating;
  final int originTeamId;
  final int currentTeamId;
  final int? age;
  final String? nation;
  final String? value;
  final String? wage;
  final int? pace;
  final int? shooting;
  final int? passing;
  final int? dribbling;
  final int? defending;
  final int? physical;
  final String? face;

  Player copyWith({
    int? id,
    String? name,
    String? position,
    int? rating,
    int? originTeamId,
    int? currentTeamId,
    int? age,
    String? nation,
    String? value,
    String? wage,
    int? pace,
    int? shooting,
    int? passing,
    int? dribbling,
    int? defending,
    int? physical,
    String? face,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      position: position ?? this.position,
      rating: rating ?? this.rating,
      originTeamId: originTeamId ?? this.originTeamId,
      currentTeamId: currentTeamId ?? this.currentTeamId,
      age: age ?? this.age,
      nation: nation ?? this.nation,
      value: value ?? this.value,
      wage: wage ?? this.wage,
      pace: pace ?? this.pace,
      shooting: shooting ?? this.shooting,
      passing: passing ?? this.passing,
      dribbling: dribbling ?? this.dribbling,
      defending: defending ?? this.defending,
      physical: physical ?? this.physical,
      face: face ?? this.face,
    );
  }

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'] as int,
      name: json['name'] as String,
      position: json['position'] as String,
      rating: json['rating'] as int,
      originTeamId: json['originTeamId'] as int,
      currentTeamId: json['currentTeamId'] as int,
      age: json['age'] as int?,
      nation: json['nation'] as String?,
      value: json['value'] as String?,
      wage: json['wage'] as String?,
      pace: json['pace'] as int?,
      shooting: json['shooting'] as int?,
      passing: json['passing'] as int?,
      dribbling: json['dribbling'] as int?,
      defending: json['defending'] as int?,
      physical: json['physical'] as int?,
      face: json['face'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'position': position,
      'rating': rating,
      'originTeamId': originTeamId,
      'currentTeamId': currentTeamId,
      'age': age,
      'nation': nation,
      'value': value,
      'wage': wage,
      'pace': pace,
      'shooting': shooting,
      'passing': passing,
      'dribbling': dribbling,
      'defending': defending,
      'physical': physical,
      'face': face,
    };
  }
}
