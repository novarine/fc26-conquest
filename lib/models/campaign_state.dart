import 'match_record.dart';
import 'player.dart';
import 'region.dart';

class CampaignState {
  const CampaignState({
    required this.id,
    required this.mode,
    required this.turn,
    required this.matchesPlayed,
    required this.regions,
    required this.players,
    required this.history,
  });

  final String id;
  final String mode;
  final int turn;
  final int matchesPlayed;
  final List<Region> regions;
  final List<Player> players;
  final List<MatchRecord> history;

  CampaignState copyWith({
    String? id,
    String? mode,
    int? turn,
    int? matchesPlayed,
    List<Region>? regions,
    List<Player>? players,
    List<MatchRecord>? history,
  }) {
    return CampaignState(
      id: id ?? this.id,
      mode: mode ?? this.mode,
      turn: turn ?? this.turn,
      matchesPlayed: matchesPlayed ?? this.matchesPlayed,
      regions: regions ?? this.regions,
      players: players ?? this.players,
      history: history ?? this.history,
    );
  }

  factory CampaignState.fromJson(Map<String, dynamic> json) {
    return CampaignState(
      id: json['id'] as String,
      mode: json['mode'] as String,
      turn: json['turn'] as int,
      matchesPlayed: json['matchesPlayed'] as int,
      regions: (json['regions'] as List<dynamic>)
          .map((entry) => Region.fromJson(entry as Map<String, dynamic>))
          .toList(),
        players: ((json['players'] as List<dynamic>?) ?? const [])
          .map((entry) => Player.fromJson(entry as Map<String, dynamic>))
          .toList(),
      history: (json['history'] as List<dynamic>)
          .map((entry) => MatchRecord.fromJson(entry as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mode': mode,
      'turn': turn,
      'matchesPlayed': matchesPlayed,
      'regions': regions.map((region) => region.toJson()).toList(),
      'players': players.map((player) => player.toJson()).toList(),
      'history': history.map((match) => match.toJson()).toList(),
    };
  }
}
