// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Wall Baduk';

  @override
  String get enterNickname => 'Enter your nickname';

  @override
  String get nicknameHint => 'e.g. John Doe';

  @override
  String get confirm => 'Confirm';

  @override
  String get difficultySelectionTitle => 'AI Difficulty Level';

  @override
  String get difficultySelectionContent => 'Please choose an AI difficulty.';

  @override
  String get difficultyEasy => 'Easy';

  @override
  String get difficultyMedium => 'Medium';

  @override
  String get sideSelectionTitle => 'Choose Your Side';

  @override
  String get sideSelectionContent => 'Which side would you like to use?';

  @override
  String get sideSelectionOptionA => 'First Placement';

  @override
  String get sideSelectionOptionB => 'First Move';

  @override
  String get placementInstruction => 'Place your pieces';

  @override
  String get moveInstruction => 'Move a piece';

  @override
  String get wallInstruction => 'Place a wall';

  @override
  String get confirmExitTitle => 'Notice';

  @override
  String get separatedArea => 'No wall placement space. Ending turn.';

  @override
  String get confirmExitContentOnline =>
      'Leaving counts as a forfeit. Do you want to exit?';

  @override
  String get confirmExitContentLocal => 'Do you want to exit?';

  @override
  String get no => 'No';

  @override
  String get yes => 'Yes';

  @override
  String get opponentLeft => 'Opponent left the game. You win!';

  @override
  String get gameOverButton => 'End Game';

  @override
  String scoreLabel(Object score) {
    return 'Score: $score';
  }

  @override
  String get victory => 'Victory!';

  @override
  String get draw => 'Draw!';

  @override
  String get leaderboardTitle => '🏆 Leaderboard';

  @override
  String get topRankersTab => 'Top Rankers';

  @override
  String get viewMyRankingTab => 'My Ranking';

  @override
  String get myRecordsTab => 'My Records';

  @override
  String get noData => 'No data available';

  @override
  String get noRecentMatches => 'No recent matches.';

  @override
  String nicknameLabel(Object nickname) {
    return 'Nickname: $nickname';
  }

  @override
  String winRateLabel(Object winRate) {
    return 'Win Rate: $winRate%';
  }

  @override
  String get matchesHeading => 'Recent 10 Matches';

  @override
  String get loadError => 'Failed to load information.';

  @override
  String get legalInfoTitle => 'Legal Notice';

  @override
  String get developerInfoTab => 'Developer Info';

  @override
  String get termsOfServiceTab => 'Terms of Service';

  @override
  String get privacyPolicyTab => 'Privacy Policy';

  @override
  String get settingsTooltip => 'Settings';

  @override
  String get leaderboardTooltip => 'Leaderboard';

  @override
  String get gameRulesTooltip => 'Game Rules';

  @override
  String get findingOpponent => 'Finding opponent...';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get createRoomTitle => 'Create Room';

  @override
  String get joinRoomTitle => 'Join Room';

  @override
  String get enterRoomCodeLabel => 'Room Code';

  @override
  String get roomNotExist => 'That room does not exist.';

  @override
  String get waitingForFriend => 'Waiting for friend...';

  @override
  String get roomCodeLabel => 'Room Code';

  @override
  String get copyTooltip => 'Copy';

  @override
  String get roomCodeCopied => 'Room code copied!';

  @override
  String get shareRoomCode => 'Share Room Code';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get toggleSound => 'Toggle Sound Effects';

  @override
  String get soundVolume => 'Adjust Sound Volume';

  @override
  String get themeSelection => 'Select Game Theme';

  @override
  String get changeNickname => 'Change Nickname';

  @override
  String get nicknameChanged => 'Nickname has been changed.';

  @override
  String get versionInfo => 'Version Info';

  @override
  String get developerInfo => 'Developer Info';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get gameRulesTitle => 'Game Rules';

  @override
  String get rule1Title => '1. Placing Pieces';

  @override
  String get rule1Desc =>
      'Each player has 4 pieces.\n• Two pieces are automatically placed in predetermined positions,\n• The remaining two can be freely placed on any empty spot.';

  @override
  String get rule2Title => '2. Moving Pieces';

  @override
  String get rule2Desc =>
      'The player who placed the last piece goes first.\nYou can move a piece up to two spaces vertically or horizontally.\nMoving to the same spot is also allowed.';

  @override
  String get rule3Title => '3. Placing Walls';

  @override
  String get rule3Desc =>
      'After moving a piece, you may place one wall around each piece.\nYou cannot move in a direction blocked by a wall.\n⏱ If you do not complete moving and placing a wall within 60 seconds, a random wall will be placed automatically.';

  @override
  String get rule4Title => '4. Separating Territories';

  @override
  String get rule4Desc =>
      'If walls separate your pieces from the opponent’s pieces into distinct territories, the game ends immediately.';

  @override
  String get rule5Title => '5. Scoring';

  @override
  String get rule5Desc =>
      'Count the number of grid cells in each separated territory to calculate scores.\nThe player with the larger territory wins.';

  @override
  String get secondsSuffix => 's';

  @override
  String get opponentTurn => 'Opponent\'s turn';

  @override
  String get accountSectionTitle => 'Account Management';

  @override
  String get linkGoogle => 'Link Google Account';

  @override
  String loggedInAs(Object userInfo) {
    return 'Logged in as: $userInfo';
  }

  @override
  String get logout => 'Logout';

  @override
  String get anonymousUser => 'Anonymous';

  @override
  String get linkApple => 'Link Apple';

  @override
  String get save => 'Save';

  @override
  String get loginMethodTitle => 'Login Method';

  @override
  String get continueAsGuest => 'Guest';

  @override
  String get signInWithGoogle => 'Sign in with Google';

  @override
  String get googleLoginFailed => 'Failed to sign in with Google';

  @override
  String get loginComplete => 'Login complete';

  @override
  String get logoutConfirm => 'Do you want to log out?';

  @override
  String get cancel => 'No';

  @override
  String get guestLoginWarnTitle => 'Guest Login Warning';

  @override
  String get guestLoginWarnText =>
      'If you proceed as a guest, your data will not be preserved if the app is uninstalled.\n\nEven if you later sign in with a social account, your guest session records cannot be recovered.';

  @override
  String get pleaseEnterNickname => 'Please enter a nickname';

  @override
  String nicknameTooLong(Object maxHan, Object maxEng) {
    return 'Nickname is too long. Please enter up to $maxEng characters.';
  }

  @override
  String get googleLoggingIn => 'Signing in with Google...';

  @override
  String welcomeWithEmail(Object email) {
    return 'Welcome, $email!';
  }
}
