import '../models/team.dart';

List<Team> filterTeams(
  List<Team> teams, {
  String? league,
  String? country,
  int? minRating,
  int? maxRating,
}) {
  return teams.where((team) {
    if (league != null && team.league != league) {
      return false;
    }
    if (country != null && team.country != country) {
      return false;
    }
    if (minRating != null && team.rating < minRating) {
      return false;
    }
    if (maxRating != null && team.rating > maxRating) {
      return false;
    }
    return true;
  }).toList();
}
