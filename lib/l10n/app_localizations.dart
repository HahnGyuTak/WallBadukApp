import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko'),
  ];

  /// 앱 이름
  ///
  /// In ko, this message translates to:
  /// **'벽바둑'**
  String get appTitle;

  /// 닉네임 입력을 요청하는 다이얼로그 제목
  ///
  /// In ko, this message translates to:
  /// **'닉네임을 입력하세요'**
  String get enterNickname;

  /// 닉네임 입력란의 힌트 텍스트
  ///
  /// In ko, this message translates to:
  /// **'예: imTak'**
  String get nicknameHint;

  /// 다이얼로그 확인 버튼 텍스트
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get confirm;

  /// Bot 모드에서 난이도 선택 다이얼로그 제목
  ///
  /// In ko, this message translates to:
  /// **'난이도 선택'**
  String get difficultySelectionTitle;

  /// Bot 모드에서 난이도 선택 다이얼로그 내용
  ///
  /// In ko, this message translates to:
  /// **'AI 난이도를 선택하세요.'**
  String get difficultySelectionContent;

  /// Bot 모드에서 초급 난이도 버튼 텍스트
  ///
  /// In ko, this message translates to:
  /// **'초급'**
  String get difficultyEasy;

  /// Bot 모드에서 중급 난이도 버튼 텍스트
  ///
  /// In ko, this message translates to:
  /// **'중급'**
  String get difficultyMedium;

  /// Bot 모드에서 말 선택 다이얼로그 제목
  ///
  /// In ko, this message translates to:
  /// **'말 선택'**
  String get sideSelectionTitle;

  /// Bot 모드에서 말 선택 다이얼로그 내용
  ///
  /// In ko, this message translates to:
  /// **'어느 말을 사용하시겠습니까?'**
  String get sideSelectionContent;

  /// 말 선택 다이얼로그에서 A 옵션 텍스트
  ///
  /// In ko, this message translates to:
  /// **'선배치'**
  String get sideSelectionOptionA;

  /// 말 선택 다이얼로그에서 B 옵션 텍스트
  ///
  /// In ko, this message translates to:
  /// **'선공'**
  String get sideSelectionOptionB;

  /// 배치 단계에서 상단에 표시할 안내 텍스트
  ///
  /// In ko, this message translates to:
  /// **'말을 배치하세요'**
  String get placementInstruction;

  /// 이동 단계에서 상단에 표시할 안내 텍스트
  ///
  /// In ko, this message translates to:
  /// **'말을 이동하세요'**
  String get moveInstruction;

  /// 벽 설치 단계에서 상단에 표시할 안내 텍스트
  ///
  /// In ko, this message translates to:
  /// **'벽을 세우세요'**
  String get wallInstruction;

  /// 벽 설치 공간이 없을 때
  ///
  /// In ko, this message translates to:
  /// **'알림'**
  String get confirmExitTitle;

  /// 벽 설치 공간이 없을 때
  ///
  /// In ko, this message translates to:
  /// **'벽 설치 공간이 남아있지 않으므로 턴을 종료합니다.'**
  String get separatedArea;

  /// 게임 중 뒤로가기 버튼 눌렀을 때 안내텍스트
  ///
  /// In ko, this message translates to:
  /// **'탈주로 간주되어 패배처리됩니다.\n나가시겠습니까?'**
  String get confirmExitContentOnline;

  /// 게임 중 뒤로가기 버튼 눌렀을 때 안내텍스트
  ///
  /// In ko, this message translates to:
  /// **'나가시겠습니까?'**
  String get confirmExitContentLocal;

  /// Yes or No
  ///
  /// In ko, this message translates to:
  /// **'아니요'**
  String get no;

  /// Yes or No
  ///
  /// In ko, this message translates to:
  /// **'예'**
  String get yes;

  /// 상대 퇴장 승리 안내 문구
  ///
  /// In ko, this message translates to:
  /// **'상대가 퇴장하여 승리하였습니다!'**
  String get opponentLeft;

  /// 결과 화면 종료 버튼
  ///
  /// In ko, this message translates to:
  /// **'게임 종료'**
  String get gameOverButton;

  /// 게임 결과에서 점수를 보여주는 라벨
  ///
  /// In ko, this message translates to:
  /// **'점수: {score}'**
  String scoreLabel(Object score);

  /// 승리 표시 텍스트
  ///
  /// In ko, this message translates to:
  /// **'승리!'**
  String get victory;

  /// 무승부 표시 텍스트
  ///
  /// In ko, this message translates to:
  /// **'무승부!'**
  String get draw;

  /// 리더보드 화면 제목
  ///
  /// In ko, this message translates to:
  /// **'🏆 리더보드'**
  String get leaderboardTitle;

  /// 리더보드 탭바 상단 탭 텍스트
  ///
  /// In ko, this message translates to:
  /// **'상위 랭커'**
  String get topRankersTab;

  /// 리더보드 탭바 내 랭킹 보기 탭 텍스트
  ///
  /// In ko, this message translates to:
  /// **'내 랭킹 보기'**
  String get viewMyRankingTab;

  /// 리더보드 탭바 내 기록 탭 텍스트
  ///
  /// In ko, this message translates to:
  /// **'내 기록'**
  String get myRecordsTab;

  /// 데이터 없을 때 표시할 텍스트
  ///
  /// In ko, this message translates to:
  /// **'데이터 없음'**
  String get noData;

  /// 최근 경기 없을 때 표시할 텍스트
  ///
  /// In ko, this message translates to:
  /// **'최근 경기가 없습니다.'**
  String get noRecentMatches;

  /// 사용자 이름 앞에 붙는 '닉네임:' 레이블
  ///
  /// In ko, this message translates to:
  /// **'닉네임: {nickname}'**
  String nicknameLabel(Object nickname);

  /// 승률 레이블
  ///
  /// In ko, this message translates to:
  /// **'승률: {winRate}%'**
  String winRateLabel(Object winRate);

  /// 최근 경기 목록 상단 제목
  ///
  /// In ko, this message translates to:
  /// **'최근 10경기'**
  String get matchesHeading;

  /// 오류 창 안내 문구
  ///
  /// In ko, this message translates to:
  /// **'정보를 불러오지 못했습니다.'**
  String get loadError;

  /// 법적 고지 탭 제목
  ///
  /// In ko, this message translates to:
  /// **'법적 고지'**
  String get legalInfoTitle;

  /// 오류 창 안내 문구
  ///
  /// In ko, this message translates to:
  /// **'개발자 정보'**
  String get developerInfoTab;

  /// 오류 창 안내 문구
  ///
  /// In ko, this message translates to:
  /// **'이용약관'**
  String get termsOfServiceTab;

  /// 오류 창 안내 문구
  ///
  /// In ko, this message translates to:
  /// **'개인정보처리방침'**
  String get privacyPolicyTab;

  /// 메인 메뉴의 설정 아이콘 툴팁
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get settingsTooltip;

  /// 메인 메뉴의 리더보드 아이콘 툴팁
  ///
  /// In ko, this message translates to:
  /// **'리더보드'**
  String get leaderboardTooltip;

  /// 메인 메뉴의 게임 규칙 아이콘 툴팁
  ///
  /// In ko, this message translates to:
  /// **'게임 규칙'**
  String get gameRulesTooltip;

  /// 매칭 페이지에서 상대를 찾고 있는 중임을 표시하는 텍스트
  ///
  /// In ko, this message translates to:
  /// **'상대를 찾는 중...'**
  String get findingOpponent;

  /// 매칭 페이지에서 매칭 취소 버튼 텍스트
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get cancelButton;

  /// RoomModePage의 방 생성 카드 제목
  ///
  /// In ko, this message translates to:
  /// **'방 생성'**
  String get createRoomTitle;

  /// RoomModePage의 방 입장 카드 제목
  ///
  /// In ko, this message translates to:
  /// **'방 입장'**
  String get joinRoomTitle;

  /// RoomModePage의 텍스트필드 레이블
  ///
  /// In ko, this message translates to:
  /// **'방 코드 입력'**
  String get enterRoomCodeLabel;

  /// 존재하지 않는 방에 입장 시 표시할 스낵바 메시지
  ///
  /// In ko, this message translates to:
  /// **'해당 방이 존재하지 않습니다.'**
  String get roomNotExist;

  /// 방 대기 페이지에서 친구를 기다리고 있음을 표시하는 텍스트
  ///
  /// In ko, this message translates to:
  /// **'친구 기다리는 중...'**
  String get waitingForFriend;

  /// 방 코드 레이블 텍스트
  ///
  /// In ko, this message translates to:
  /// **'방 코드'**
  String get roomCodeLabel;

  /// 방 코드 옆 복사 버튼 툴팁 텍스트
  ///
  /// In ko, this message translates to:
  /// **'복사하기'**
  String get copyTooltip;

  /// 방 코드 복사 후 표시되는 스낵바 메시지
  ///
  /// In ko, this message translates to:
  /// **'방 코드가 복사되었습니다'**
  String get roomCodeCopied;

  /// 방 코드 공유 버튼 텍스트
  ///
  /// In ko, this message translates to:
  /// **'방 코드 공유'**
  String get shareRoomCode;

  /// 설정 페이지 AppBar 제목
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get settingsTitle;

  /// 설정 페이지의 효과음 토글 레이블
  ///
  /// In ko, this message translates to:
  /// **'효과음 켜기/끄기'**
  String get toggleSound;

  /// 설정 페이지의 효과음 볼륨 슬라이더 레이블
  ///
  /// In ko, this message translates to:
  /// **'효과음 볼륨 조절'**
  String get soundVolume;

  /// 설정 페이지의 테마 선택 레이블
  ///
  /// In ko, this message translates to:
  /// **'게임 테마 선택'**
  String get themeSelection;

  /// 설정 페이지의 닉네임 변경 레이블
  ///
  /// In ko, this message translates to:
  /// **'닉네임 변경'**
  String get changeNickname;

  /// 닉네임 변경 후 스낵바 메시지
  ///
  /// In ko, this message translates to:
  /// **'닉네임이 변경되었습니다.'**
  String get nicknameChanged;

  /// 설정 페이지의 버전 정보 레이블
  ///
  /// In ko, this message translates to:
  /// **'버전 정보'**
  String get versionInfo;

  /// 설정 페이지의 개발자 정보 레이블
  ///
  /// In ko, this message translates to:
  /// **'개발자 정보'**
  String get developerInfo;

  /// 설정 페이지의 이용약관 레이블
  ///
  /// In ko, this message translates to:
  /// **'이용약관'**
  String get termsOfService;

  /// 설정 페이지의 개인정보처리방침 레이블
  ///
  /// In ko, this message translates to:
  /// **'개인정보처리방침'**
  String get privacyPolicy;

  /// 튜토리얼 페이지 앱바 제목
  ///
  /// In ko, this message translates to:
  /// **'게임 규칙'**
  String get gameRulesTitle;

  /// 튜토리얼 첫 번째 규칙 제목
  ///
  /// In ko, this message translates to:
  /// **'1. 말 배치하기'**
  String get rule1Title;

  /// 튜토리얼 첫 번째 규칙 설명
  ///
  /// In ko, this message translates to:
  /// **'각 플레이어는 총 4개의 말을 사용합니다.\n• 이 중 2개는 미리 정해진 위치에 자동 배치되고,\n• 나머지 2개는 원하는 칸에 자유롭게 배치합니다.'**
  String get rule1Desc;

  /// 튜토리얼 두 번째 규칙 제목
  ///
  /// In ko, this message translates to:
  /// **'2. 말 이동'**
  String get rule2Title;

  /// 튜토리얼 두 번째 규칙 설명
  ///
  /// In ko, this message translates to:
  /// **'마지막에 말을 배치한 플레이어부터 턴을 시작합니다.\n말은 상하좌우 방향으로 최대 2칸까지 이동할 수 있습니다.\n제자리 이동도 허용됩니다.'**
  String get rule2Desc;

  /// 튜토리얼 세 번째 규칙 제목
  ///
  /// In ko, this message translates to:
  /// **'3. 벽 설치'**
  String get rule3Title;

  /// 튜토리얼 세 번째 규칙 설명
  ///
  /// In ko, this message translates to:
  /// **'말을 이동한 후, 각 말의 주변에 벽 1개씩 설치할 수 있습니다.\n벽으로 막힌 방향으로는 이동할 수 없습니다.\n⏱ 제한 시간 60초 안에 이동과 벽 설치를 완료하지 않으면, 무작위로 벽이 자동 설치됩니다.'**
  String get rule3Desc;

  /// 튜토리얼 네 번째 규칙 제목
  ///
  /// In ko, this message translates to:
  /// **'4. 영역 분리'**
  String get rule4Title;

  /// 튜토리얼 네 번째 규칙 설명
  ///
  /// In ko, this message translates to:
  /// **'벽 설치로 인해 내 말들과 상대방 말들의 영역이 분리되면, 게임은 즉시 종료됩니다.'**
  String get rule4Desc;

  /// 튜토리얼 다섯 번째 규칙 제목
  ///
  /// In ko, this message translates to:
  /// **'5. 점수 계산'**
  String get rule5Title;

  /// 튜토리얼 다섯 번째 규칙 설명
  ///
  /// In ko, this message translates to:
  /// **'분리된 각 영역의 칸 개수를 세어 점수를 계산합니다.\n더 많은 영역을 확보한 쪽이 승리합니다.'**
  String get rule5Desc;

  /// 타이머 뒤에 붙는 '초' 텍스트
  ///
  /// In ko, this message translates to:
  /// **'초'**
  String get secondsSuffix;

  /// AI 혹은 온라인 모드에서 상대 턴일 때 표시하는 텍스트
  ///
  /// In ko, this message translates to:
  /// **'상대방 플레이 중'**
  String get opponentTurn;

  /// 세팅 페이지
  ///
  /// In ko, this message translates to:
  /// **'계정 관리'**
  String get accountSectionTitle;

  /// 세팅 페이지
  ///
  /// In ko, this message translates to:
  /// **'Google 계정 연결'**
  String get linkGoogle;

  /// Text showing which account the user is logged in with
  ///
  /// In ko, this message translates to:
  /// **'로그인 중 : {userInfo}'**
  String loggedInAs(Object userInfo);

  /// 로그아웃 버튼 텍스트
  ///
  /// In ko, this message translates to:
  /// **'로그아웃'**
  String get logout;

  /// 로그아웃 버튼 텍스트
  ///
  /// In ko, this message translates to:
  /// **'익명'**
  String get anonymousUser;

  /// apple
  ///
  /// In ko, this message translates to:
  /// **'Apple 계정 연결'**
  String get linkApple;

  /// save
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get save;

  /// Dialog title for selecting login method
  ///
  /// In ko, this message translates to:
  /// **'로그인 방식 선택'**
  String get loginMethodTitle;

  /// Button for continuing as guest
  ///
  /// In ko, this message translates to:
  /// **'게스트로 계속하기'**
  String get continueAsGuest;

  /// Button for Google sign in
  ///
  /// In ko, this message translates to:
  /// **'Sign in with Google'**
  String get signInWithGoogle;

  /// Snackbar message when Google login fails
  ///
  /// In ko, this message translates to:
  /// **'Google 로그인에 실패했습니다'**
  String get googleLoginFailed;

  /// Snackbar message when login is complete
  ///
  /// In ko, this message translates to:
  /// **'로그인 완료'**
  String get loginComplete;

  ///
  ///
  /// In ko, this message translates to:
  /// **'로그아웃 하시겠습니까?'**
  String get logoutConfirm;

  ///
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get cancel;

  /// 게스트 로그인 시 주의 안내 다이얼로그 제목
  ///
  /// In ko, this message translates to:
  /// **'게스트 로그인 주의'**
  String get guestLoginWarnTitle;

  /// 게스트 로그인 데이터 손실 안내 문구
  ///
  /// In ko, this message translates to:
  /// **'게스트 로그인으로 진행하시는 경우, 앱 삭제 또는 재설치 시 저장된 데이터가 모두 삭제됩니다.\n\n이후 소셜 로그인으로 전환하더라도 익명 로그인 중 진행된 기록은 복구되지 않습니다.'**
  String get guestLoginWarnText;

  /// 게스트 로그인 데이터 손실 안내 문구
  ///
  /// In ko, this message translates to:
  /// **'닉네임을 입력해주세요'**
  String get pleaseEnterNickname;

  /// 에러 메시지: 닉네임이 최대 길이를 초과할 때
  ///
  /// In ko, this message translates to:
  /// **'닉네임이 너무 깁니다. 한글 {maxHan}자, 영문 {maxEng}자 이내로 입력해주세요.'**
  String nicknameTooLong(Object maxHan, Object maxEng);

  /// No description provided for @googleLoggingIn.
  ///
  /// In ko, this message translates to:
  /// **'Google 로그인 중입니다...'**
  String get googleLoggingIn;

  ///
  ///
  /// In ko, this message translates to:
  /// **'환영합니다, {email}님!'**
  String welcomeWithEmail(Object email);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
