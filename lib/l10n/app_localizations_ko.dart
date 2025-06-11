// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => '벽바둑';

  @override
  String get enterNickname => '닉네임을 입력하세요';

  @override
  String get nicknameHint => '예: imTak';

  @override
  String get confirm => '확인';

  @override
  String get difficultySelectionTitle => '난이도 선택';

  @override
  String get difficultySelectionContent => 'AI 난이도를 선택하세요.';

  @override
  String get difficultyEasy => '초급';

  @override
  String get difficultyMedium => '중급';

  @override
  String get sideSelectionTitle => '말 선택';

  @override
  String get sideSelectionContent => '어느 말을 사용하시겠습니까?';

  @override
  String get sideSelectionOptionA => '선배치';

  @override
  String get sideSelectionOptionB => '선공';

  @override
  String get placementInstruction => '말을 배치하세요';

  @override
  String get moveInstruction => '말을 이동하세요';

  @override
  String get wallInstruction => '벽을 세우세요';

  @override
  String get confirmExitTitle => '알림';

  @override
  String get separatedArea => '벽 설치 공간이 남아있지 않으므로 턴을 종료합니다.';

  @override
  String get confirmExitContentOnline => '탈주로 간주되어 패배처리됩니다.\n나가시겠습니까?';

  @override
  String get confirmExitContentLocal => '나가시겠습니까?';

  @override
  String get no => '아니요';

  @override
  String get yes => '예';

  @override
  String get opponentLeft => '상대가 퇴장하여 승리하였습니다!';

  @override
  String get gameOverButton => '게임 종료';

  @override
  String scoreLabel(Object score) {
    return '점수: $score';
  }

  @override
  String get victory => '승리!';

  @override
  String get draw => '무승부!';

  @override
  String get leaderboardTitle => '🏆 리더보드';

  @override
  String get topRankersTab => '상위 랭커';

  @override
  String get viewMyRankingTab => '내 랭킹 보기';

  @override
  String get myRecordsTab => '내 기록';

  @override
  String get noData => '데이터 없음';

  @override
  String get noRecentMatches => '최근 경기가 없습니다.';

  @override
  String nicknameLabel(Object nickname) {
    return '닉네임: $nickname';
  }

  @override
  String winRateLabel(Object winRate) {
    return '승률: $winRate%';
  }

  @override
  String get matchesHeading => '최근 10경기';

  @override
  String get loadError => '정보를 불러오지 못했습니다.';

  @override
  String get legalInfoTitle => '법적 고지';

  @override
  String get developerInfoTab => '개발자 정보';

  @override
  String get termsOfServiceTab => '이용약관';

  @override
  String get privacyPolicyTab => '개인정보처리방침';

  @override
  String get settingsTooltip => '설정';

  @override
  String get leaderboardTooltip => '리더보드';

  @override
  String get gameRulesTooltip => '게임 규칙';

  @override
  String get findingOpponent => '상대를 찾는 중...';

  @override
  String get cancelButton => '취소';

  @override
  String get createRoomTitle => '방 생성';

  @override
  String get joinRoomTitle => '방 입장';

  @override
  String get enterRoomCodeLabel => '방 코드 입력';

  @override
  String get roomNotExist => '해당 방이 존재하지 않습니다.';

  @override
  String get waitingForFriend => '친구 기다리는 중...';

  @override
  String get roomCodeLabel => '방 코드';

  @override
  String get copyTooltip => '복사하기';

  @override
  String get roomCodeCopied => '방 코드가 복사되었습니다';

  @override
  String get shareRoomCode => '방 코드 공유';

  @override
  String get settingsTitle => '설정';

  @override
  String get toggleSound => '효과음 켜기/끄기';

  @override
  String get soundVolume => '효과음 볼륨 조절';

  @override
  String get themeSelection => '게임 테마 선택';

  @override
  String get changeNickname => '닉네임 변경';

  @override
  String get nicknameChanged => '닉네임이 변경되었습니다.';

  @override
  String get versionInfo => '버전 정보';

  @override
  String get developerInfo => '개발자 정보';

  @override
  String get termsOfService => '이용약관';

  @override
  String get privacyPolicy => '개인정보처리방침';

  @override
  String get gameRulesTitle => '게임 규칙';

  @override
  String get rule1Title => '1. 말 배치하기';

  @override
  String get rule1Desc =>
      '각 플레이어는 총 4개의 말을 사용합니다.\n• 이 중 2개는 미리 정해진 위치에 자동 배치되고,\n• 나머지 2개는 원하는 칸에 자유롭게 배치합니다.';

  @override
  String get rule2Title => '2. 말 이동';

  @override
  String get rule2Desc =>
      '마지막에 말을 배치한 플레이어부터 턴을 시작합니다.\n말은 상하좌우 방향으로 최대 2칸까지 이동할 수 있습니다.\n제자리 이동도 허용됩니다.';

  @override
  String get rule3Title => '3. 벽 설치';

  @override
  String get rule3Desc =>
      '말을 이동한 후, 각 말의 주변에 벽 1개씩 설치할 수 있습니다.\n벽으로 막힌 방향으로는 이동할 수 없습니다.\n⏱ 제한 시간 60초 안에 이동과 벽 설치를 완료하지 않으면, 무작위로 벽이 자동 설치됩니다.';

  @override
  String get rule4Title => '4. 영역 분리';

  @override
  String get rule4Desc => '벽 설치로 인해 내 말들과 상대방 말들의 영역이 분리되면, 게임은 즉시 종료됩니다.';

  @override
  String get rule5Title => '5. 점수 계산';

  @override
  String get rule5Desc =>
      '분리된 각 영역의 칸 개수를 세어 점수를 계산합니다.\n더 많은 영역을 확보한 쪽이 승리합니다.';

  @override
  String get secondsSuffix => '초';

  @override
  String get opponentTurn => '상대방 플레이 중';

  @override
  String get accountSectionTitle => '계정 관리';

  @override
  String get linkGoogle => 'Google 계정 연결';

  @override
  String loggedInAs(Object userInfo) {
    return '로그인 중 : $userInfo';
  }

  @override
  String get logout => '로그아웃';

  @override
  String get anonymousUser => '익명';

  @override
  String get linkApple => 'Apple 계정 연결';

  @override
  String get save => '저장';

  @override
  String get loginMethodTitle => '로그인 방식 선택';

  @override
  String get continueAsGuest => '게스트로 계속하기';

  @override
  String get signInWithGoogle => 'Sign in with Google';

  @override
  String get googleLoginFailed => 'Google 로그인에 실패했습니다';

  @override
  String get loginComplete => '로그인 완료';

  @override
  String get logoutConfirm => '로그아웃 하시겠습니까?';

  @override
  String get cancel => '취소';

  @override
  String get guestLoginWarnTitle => '게스트 로그인 주의';

  @override
  String get guestLoginWarnText =>
      '게스트 로그인으로 진행하시는 경우, 앱 삭제 또는 재설치 시 저장된 데이터가 모두 삭제됩니다.\n\n이후 소셜 로그인으로 전환하더라도 익명 로그인 중 진행된 기록은 복구되지 않습니다.';

  @override
  String get pleaseEnterNickname => '닉네임을 입력해주세요';

  @override
  String nicknameTooLong(Object maxHan, Object maxEng) {
    return '닉네임이 너무 깁니다. 한글 $maxHan자, 영문 $maxEng자 이내로 입력해주세요.';
  }

  @override
  String get googleLoggingIn => 'Google 로그인 중입니다...';

  @override
  String welcomeWithEmail(Object email) {
    return '환영합니다, $email님!';
  }
}
