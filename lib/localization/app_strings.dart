enum AppLanguage { de, en }

/// Central bilingual (German/English) UI text lookup, switchable at runtime by the user.
/// Club/nation names and all code/comments stay English regardless of [language].
class AppStrings {
  const AppStrings(this.language);

  final AppLanguage language;

  bool get _isDe => language == AppLanguage.de;

  String _v(String de, String en) => _isDe ? de : en;

  // Home screen
  String get homeBadge => _v('Kinderfreundlicher Eroberungsmodus', 'Family-friendly conquest mode');
  String get homeHeadline => _v('Erobere die Welt. Ein Match nach dem anderen.', 'Conquer the world. One match at a time.');
  String get homeDescription => _v(
        'Bunte Weltkarte, sichtbares Gluecksrad und Team-Badges statt trockener Tabellen. Genau richtig fuer einen verspielten Conquest-Prototyp.',
        'Colorful world map, a visible spinning wheel, and team badges instead of dry tables. Just right for a playful Conquest prototype.',
      );
  String get featureWheel => _v('Gluecksrad', 'Wheel');
  String get featureBadges => _v('Team-Badges', 'Team badges');
  String get featureMap => _v('Fantasy-Karte', 'Fantasy map');
  String get setupHeading => _v('Neue Kampagne konfigurieren', 'Configure new campaign');
  String clubsChip(int count) => _v('Clubs ($count)', 'Clubs ($count)');
  String nationsChip(int count) => _v('Nationen ($count)', 'Nations ($count)');
  String get allLeagues => _v('Alle Ligen', 'All leagues');
  String get allCountries => _v('Alle Laender', 'All countries');
  String ratingRangeLabel(int min, int max) => _v('Rating: $min - $max', 'Rating: $min - $max');
  String get licensedOnlyTitle => _v('Nur FC 26 Lizenzteams', 'FC 26 licensed teams only');
  String get licensedOnlySubtitle => _v(
        'Manuell gepflegte Bestenliste, nicht live mit aktuellen FC-26-Patches synchronisiert.',
        'Manually maintained list, not live-synced with current FC 26 patches.',
      );
  String teamCountLabel(int count, int available) =>
      _v('Teamanzahl: $count von $available verfuegbar', 'Team count: $count of $available available');
  String get newCampaignButton => _v('Neue Kampagne', 'New campaign');
  String get continueCampaignButton => _v('Kampagne fortsetzen', 'Continue campaign');
  String get customWheelToolButton => _v('Zufallsrad-Werkzeug', 'Custom wheel tool');

  // Map screen
  String get arenaTitle => 'FC Conquest Arena';
  String get statsTooltip => _v('Statistiken', 'Stats');
  String get resetCampaignTooltip => _v('Kampagne zuruecksetzen', 'Reset campaign');
  String get wheelStep1Title => _v('Schritt 1: Angreifer auslosen', 'Step 1: draw the attacker');
  String get wheelStep1Subtitle => _v('Wie bei Wheel of Names: erst Team A bestimmen.', 'Like Wheel of Names: determine Team A first.');
  String get wheelStep2Title => _v('Schritt 2: Nachbar-Gegner auslosen', 'Step 2: draw the neighboring opponent');
  String get wheelStep2Subtitle => _v('Nur angrenzende Teams sind auf diesem Rad.', 'Only bordering teams are on this wheel.');
  String get finalsLabel => 'FINALS';
  String get vsLabel => 'VS';
  String get statTeams => 'Teams';
  String get statMatches => 'Matches';
  String get statChampion => _v('Champion', 'Champion');
  String get championPending => _v('Noch offen', 'Still open');
  String get statLastWinner => _v('Letzter Sieger', 'Last winner');
  String get noneYet => _v('Noch keiner', 'None yet');
  String get statPlayerTransfer => _v('Spielertransfer', 'Player transfer');
  String get noneLabel => _v('Keiner', 'None');
  String get matchDrawTitle => _v('Match-Auslosung', 'Match draw');
  String get matchDrawDescription => _v(
        'Das Gluecksrad dreht zuerst den Angreifer und danach den gueltigen Nachbar-Gegner.',
        'The wheel first spins for the attacker, then for a valid neighboring opponent.',
      );
  String get wheelSpinning => _v('Rad dreht...', 'Wheel spinning...');
  String get startWheelButton => _v('Gluecksrad starten', 'Start wheel');
  String get activeTeams => _v('Aktive Teams', 'Active teams');
  String get tournamentEnded => _v('Turnier Beendet', 'Tournament ended');
  String championSubtitle(String name) => _v('$name hat den Pokal glorreich geholt.', '$name has gloriously claimed the trophy.');
  String get championCrowned => _v('Kroenung des Conquest-Champions', 'Crowning of the Conquest champion');
  String get finalHeroes => _v('Helden des Finales', 'Heroes of the final');
  String get startNewCampaignButton => _v('Neue Kampagne starten', 'Start new campaign');
  String regionsLabel(int count) => _v('Regionen: $count', 'Regions: $count');
  String get worldChampion => 'WORLD CHAMPION';
  String get celebrateMore => _v('Weiterfeiern', 'Keep celebrating');

  // Battle screen
  String get matchResultTitle => _v('Match-Ergebnis', 'Match result');
  String get whoWonHeading => _v('Wer hat gewonnen?', 'Who won?');
  String get optionalScoreLabel => _v('Optionaler Score', 'Optional score');
  String get scoreHint => _v('z. B. 3:1', 'e.g. 3:1');
  String get cancelButton => _v('Abbrechen', 'Cancel');
  String get captureRegionButton => _v('Gebiet erobern', 'Capture region');
  String get transferSectionTitle => _v('Transfer aus dem besiegten Team', 'Transfer from the defeated team');
  String get noPlayerTransferOption => _v('Keinen Spieler uebernehmen', 'Do not take over a player');
  String get transferHelperText => _v(
        'Optional: ein Spieler wechselt direkt zum Siegerteam.',
        'Optional: a player moves directly to the winning team.',
      );
  String get noPlayersAvailable => _v(
        'Fuer dieses Team sind aktuell keine Spieler verfuegbar.',
        'No players are currently available for this team.',
      );
  String get yearsSuffix => _v('Jahre', 'years');
  String valueWageLabel(String value, String wage) => _v('Wert $value • Lohn $wage', 'Value $value • Wage $wage');

  // Stats screen
  String get statsTitle => _v('Statistiken', 'Stats');
  String teamFallback(int id) => 'Team $id';
  String statsSubtitle({
    required int wins,
    required int losses,
    required int regions,
    required int squad,
    required int transfers,
    required String winRate,
  }) =>
      _v(
        'Siege $wins | Niederlagen $losses | Regionen $regions | Kader $squad | Transfers $transfers | Winrate $winRate%',
        'Wins $wins | Losses $losses | Regions $regions | Squad $squad | Transfers $transfers | Win rate $winRate%',
      );
  String peakLabel(int count) => _v('Peak $count', 'Peak $count');

  // Custom wheel screen
  String get customWheelTitle => _v('Zufallsrad', 'Custom wheel');
  String get newWheelFab => _v('Neues Rad', 'New wheel');
  String get noWheelsYet => _v('Noch keine Zufallsraeder angelegt.', 'No custom wheels created yet.');
  String entriesCount(int count) => _v('$count Eintraege', '$count entries');
  String get spinTooltip => _v('Drehen', 'Spin');
  String get deleteTooltip => _v('Loeschen', 'Delete');
  String get newWheelDialogTitle => _v('Neues Zufallsrad', 'New custom wheel');
  String get nameLabel => _v('Name', 'Name');
  String get entriesLabel => _v('Eintraege (eine Zeile pro Eintrag)', 'Entries (one per line)');
  String get createButton => _v('Erstellen', 'Create');
  String get examplePresetChallengesName => _v('Zufalls-Herausforderungen', 'Random challenges');
  String get examplePresetFormationsName => _v('Formations-Zufall', 'Formation randomizer');
  String get exampleChallengeU21Only => _v('Nur U21-Spieler', 'U21 players only');
  String get exampleChallengeNoPurchases => _v('Kein Kauf erlaubt', 'No purchases allowed');
  String get exampleChallengeCupFinalRules => _v('Pokalfinale-Regeln', 'Cup final rules');
  String get exampleChallengeAwayKit => _v('Auswaertstrikot Pflicht', 'Away kit mandatory');
  String get exampleChallengeFormationOnly => _v('Nur Systemwechsel', 'Formation change only');

  // Shared wheel dialogs (team wheel + generic wheel)
  String get spinButton => _v('Drehen', 'Spin');
  String get spinAgainButton => _v('Nochmal drehen', 'Spin again');
  String get confirmTeamButton => _v('Team bestaetigen', 'Confirm team');
  String get confirmButton => _v('Bestaetigen', 'Confirm');

  // Update banner
  String newVersionAvailable(String version) => _v('Neue Version verfuegbar: $version', 'New version available: $version');
  String get updateButton => _v('Update', 'Update');
  String get dismissTooltip => _v('Schliessen', 'Dismiss');

  // Language switcher
  String get languageSwitcherTooltip => _v('Sprache wechseln', 'Switch language');
}
