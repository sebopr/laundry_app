import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';
import 'app_localizations_rm.dart';

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
    Locale('de'),
    Locale('en'),
    Locale('fr'),
    Locale('it'),
    Locale('rm')
  ];

  /// No description provided for @navBookings.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get navBookings;

  /// No description provided for @navNeighbours.
  ///
  /// In en, this message translates to:
  /// **'Neighbours'**
  String get navNeighbours;

  /// No description provided for @navAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get navAdmin;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Lavaplan'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Book your laundry slot'**
  String get appTagline;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get loginSubtitle;

  /// No description provided for @fieldEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get fieldEmail;

  /// No description provided for @fieldPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get fieldPassword;

  /// No description provided for @fieldConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get fieldConfirmPassword;

  /// No description provided for @btnSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get btnSignIn;

  /// No description provided for @btnSignUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get btnSignUp;

  /// No description provided for @btnCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get btnCreateAccount;

  /// No description provided for @btnContinueGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get btnContinueGoogle;

  /// No description provided for @btnContinueApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get btnContinueApple;

  /// No description provided for @loginNoAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get loginNoAccount;

  /// No description provided for @registerHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get registerHaveAccount;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get registerTitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join your building\'s laundry system'**
  String get registerSubtitle;

  /// No description provided for @errorPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get errorPasswordMismatch;

  /// No description provided for @errorWrongCredentials.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password.'**
  String get errorWrongCredentials;

  /// No description provided for @errorInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email.'**
  String get errorInvalidEmail;

  /// No description provided for @errorEmailInUse.
  ///
  /// In en, this message translates to:
  /// **'An account already exists for this email.'**
  String get errorEmailInUse;

  /// No description provided for @errorWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters.'**
  String get errorWeakPassword;

  /// No description provided for @errorNoInternet.
  ///
  /// In en, this message translates to:
  /// **'No internet connection.'**
  String get errorNoInternet;

  /// No description provided for @errorTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Try again later.'**
  String get errorTooManyRequests;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @btnSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get btnSave;

  /// No description provided for @btnCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get btnCancel;

  /// No description provided for @btnContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get btnContinue;

  /// No description provided for @btnPrint.
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get btnPrint;

  /// No description provided for @btnRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get btnRemove;

  /// No description provided for @btnBook.
  ///
  /// In en, this message translates to:
  /// **'Book'**
  String get btnBook;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @sectionAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get sectionAppearance;

  /// No description provided for @sectionHousehold.
  ///
  /// In en, this message translates to:
  /// **'Household'**
  String get sectionHousehold;

  /// No description provided for @sectionAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get sectionAccount;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get darkMode;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @leaveBuilding.
  ///
  /// In en, this message translates to:
  /// **'Leave building'**
  String get leaveBuilding;

  /// No description provided for @leaveBuildingContent.
  ///
  /// In en, this message translates to:
  /// **'You\'ll lose access to this building\'s booking system and chat. If you\'re the head of your household, headship passes to another member (or the household is removed if you\'re its only member). Any future bookings you have will be cancelled.'**
  String get leaveBuildingContent;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountContent.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes your account and all its data. This cannot be undone. Buildings you manage are deleted too if nobody else lives in them. If other residents still live in one, contact us first.'**
  String get deleteAccountContent;

  /// No description provided for @setupHousehold.
  ///
  /// In en, this message translates to:
  /// **'Set up household'**
  String get setupHousehold;

  /// No description provided for @youManageHousehold.
  ///
  /// In en, this message translates to:
  /// **'You manage this household'**
  String get youManageHousehold;

  /// No description provided for @memberLabel.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get memberLabel;

  /// No description provided for @myHousehold.
  ///
  /// In en, this message translates to:
  /// **'My household'**
  String get myHousehold;

  /// No description provided for @householdMembers.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get householdMembers;

  /// No description provided for @inviteHouseholdMember.
  ///
  /// In en, this message translates to:
  /// **'Invite a household member'**
  String get inviteHouseholdMember;

  /// No description provided for @inviteScanText.
  ///
  /// In en, this message translates to:
  /// **'Let them scan this to join your household.'**
  String get inviteScanText;

  /// No description provided for @youLabel.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get youLabel;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile;

  /// No description provided for @displayNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get displayNameLabel;

  /// No description provided for @yourFirstName.
  ///
  /// In en, this message translates to:
  /// **'Your first name'**
  String get yourFirstName;

  /// No description provided for @shownToNeighbours.
  ///
  /// In en, this message translates to:
  /// **'This is shown to your neighbours in the app.'**
  String get shownToNeighbours;

  /// No description provided for @neighboursTitle.
  ///
  /// In en, this message translates to:
  /// **'Neighbours'**
  String get neighboursTitle;

  /// No description provided for @noNeighboursYet.
  ///
  /// In en, this message translates to:
  /// **'No neighbours yet'**
  String get noNeighboursYet;

  /// No description provided for @onbWhatsYourName.
  ///
  /// In en, this message translates to:
  /// **'What\'s your name?'**
  String get onbWhatsYourName;

  /// No description provided for @onbNameSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This is how your neighbours will see you.'**
  String get onbNameSubtitle;

  /// No description provided for @onbNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Anna'**
  String get onbNameHint;

  /// No description provided for @onbHowWillYouUse.
  ///
  /// In en, this message translates to:
  /// **'How will you use this app?'**
  String get onbHowWillYouUse;

  /// No description provided for @onbChangeInSettings.
  ///
  /// In en, this message translates to:
  /// **'You can change this later in Settings.'**
  String get onbChangeInSettings;

  /// No description provided for @onbImAResident.
  ///
  /// In en, this message translates to:
  /// **'I\'m a resident'**
  String get onbImAResident;

  /// No description provided for @onbResidentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'I live in the building and want to book machines'**
  String get onbResidentSubtitle;

  /// No description provided for @onbIManageBuildings.
  ///
  /// In en, this message translates to:
  /// **'I manage building(s)'**
  String get onbIManageBuildings;

  /// No description provided for @onbManagerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'I\'m responsible for the laundry room'**
  String get onbManagerSubtitle;

  /// No description provided for @onbAlsoLive.
  ///
  /// In en, this message translates to:
  /// **'I also live in one of these buildings'**
  String get onbAlsoLive;

  /// No description provided for @onbAlsoLiveSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You\'ll be able to book machines as a resident too'**
  String get onbAlsoLiveSubtitle;

  /// No description provided for @onbJoinYourBuilding.
  ///
  /// In en, this message translates to:
  /// **'Join your building'**
  String get onbJoinYourBuilding;

  /// No description provided for @onbCreateOrScan.
  ///
  /// In en, this message translates to:
  /// **'Create a new building or scan an existing QR.'**
  String get onbCreateOrScan;

  /// No description provided for @onbScanQrRoom.
  ///
  /// In en, this message translates to:
  /// **'Scan the QR code posted in your laundry room.'**
  String get onbScanQrRoom;

  /// No description provided for @onbCreateNewBuilding.
  ///
  /// In en, this message translates to:
  /// **'Create a new building'**
  String get onbCreateNewBuilding;

  /// No description provided for @onbCreateBuildingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set up a building and get its QR code'**
  String get onbCreateBuildingSubtitle;

  /// No description provided for @onbScanExisting.
  ///
  /// In en, this message translates to:
  /// **'Scan existing building QR'**
  String get onbScanExisting;

  /// No description provided for @onbScanExistingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join a building that\'s already set up'**
  String get onbScanExistingSubtitle;

  /// No description provided for @onbScanQrCode.
  ///
  /// In en, this message translates to:
  /// **'Scan QR code'**
  String get onbScanQrCode;

  /// No description provided for @onbYourHousehold.
  ///
  /// In en, this message translates to:
  /// **'Your household'**
  String get onbYourHousehold;

  /// No description provided for @onbSetUpHousehold.
  ///
  /// In en, this message translates to:
  /// **'Set up who shares the laundry with you.'**
  String get onbSetUpHousehold;

  /// No description provided for @onbFirstFromHousehold.
  ///
  /// In en, this message translates to:
  /// **'First from my household'**
  String get onbFirstFromHousehold;

  /// No description provided for @onbFirstSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a new household and invite others later'**
  String get onbFirstSubtitle;

  /// No description provided for @onbJoinExisting.
  ///
  /// In en, this message translates to:
  /// **'Join an existing household'**
  String get onbJoinExisting;

  /// No description provided for @onbJoinSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Scan the invite QR from your household member'**
  String get onbJoinSubtitle;

  /// No description provided for @onbNameOnMailbox.
  ///
  /// In en, this message translates to:
  /// **'Name on your mailbox'**
  String get onbNameOnMailbox;

  /// No description provided for @onbMailboxHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Müller'**
  String get onbMailboxHint;

  /// No description provided for @onbCreateHousehold.
  ///
  /// In en, this message translates to:
  /// **'Create household'**
  String get onbCreateHousehold;

  /// No description provided for @onbNotHouseholdQr.
  ///
  /// In en, this message translates to:
  /// **'This is not a household invite QR.'**
  String get onbNotHouseholdQr;

  /// No description provided for @onbNotBuildingQr.
  ///
  /// In en, this message translates to:
  /// **'This doesn\'t look like a building QR. Try again.'**
  String get onbNotBuildingQr;

  /// No description provided for @onbRequestPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Waiting for approval'**
  String get onbRequestPendingTitle;

  /// No description provided for @onbBuildingRequestPendingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The building admin has been notified and needs to accept your request before you can continue.'**
  String get onbBuildingRequestPendingSubtitle;

  /// No description provided for @onbBuildingRequestRejected.
  ///
  /// In en, this message translates to:
  /// **'Your request to join was declined. You can scan the code again or try a different building.'**
  String get onbBuildingRequestRejected;

  /// No description provided for @scanQrCode.
  ///
  /// In en, this message translates to:
  /// **'Scan QR Code'**
  String get scanQrCode;

  /// No description provided for @adminTitle.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get adminTitle;

  /// No description provided for @addBuilding.
  ///
  /// In en, this message translates to:
  /// **'Add building'**
  String get addBuilding;

  /// No description provided for @noBuildingsYet.
  ///
  /// In en, this message translates to:
  /// **'No buildings yet'**
  String get noBuildingsYet;

  /// No description provided for @tapToAddBuilding.
  ///
  /// In en, this message translates to:
  /// **'Tap + Add building to get started.'**
  String get tapToAddBuilding;

  /// No description provided for @residentsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 resident} other{{count} residents}}'**
  String residentsCount(num count);

  /// No description provided for @maintenanceCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 machine in maintenance} other{{count} machines in maintenance}}'**
  String maintenanceCount(num count);

  /// No description provided for @residentsTab.
  ///
  /// In en, this message translates to:
  /// **'Residents'**
  String get residentsTab;

  /// No description provided for @machinesTab.
  ///
  /// In en, this message translates to:
  /// **'Machines'**
  String get machinesTab;

  /// No description provided for @noResidentsYet.
  ///
  /// In en, this message translates to:
  /// **'No residents yet'**
  String get noResidentsYet;

  /// No description provided for @noHousehold.
  ///
  /// In en, this message translates to:
  /// **'No household'**
  String get noHousehold;

  /// No description provided for @removeResident.
  ///
  /// In en, this message translates to:
  /// **'Remove resident'**
  String get removeResident;

  /// No description provided for @removeResidentContent.
  ///
  /// In en, this message translates to:
  /// **'This will remove the resident from the building. They will need to re-scan the QR to rejoin.'**
  String get removeResidentContent;

  /// No description provided for @pendingRequestsTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 pending request} other{{count} pending requests}}'**
  String pendingRequestsTitle(num count);

  /// No description provided for @joinRequestBuildingLabel.
  ///
  /// In en, this message translates to:
  /// **'Wants to join this building'**
  String get joinRequestBuildingLabel;

  /// No description provided for @btnApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get btnApprove;

  /// No description provided for @btnReject.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get btnReject;

  /// No description provided for @machinesDescription.
  ///
  /// In en, this message translates to:
  /// **'Toggle machines in or out of service, or add/remove machines.'**
  String get machinesDescription;

  /// No description provided for @removeMachineTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove machine?'**
  String get removeMachineTitle;

  /// No description provided for @removeMachineContent.
  ///
  /// In en, this message translates to:
  /// **'Machine {number} will be removed. Existing bookings for this machine are not automatically cancelled.'**
  String removeMachineContent(int number);

  /// No description provided for @addMachine.
  ///
  /// In en, this message translates to:
  /// **'Add machine'**
  String get addMachine;

  /// No description provided for @headLabel.
  ///
  /// In en, this message translates to:
  /// **'Head'**
  String get headLabel;

  /// No description provided for @activeStatus.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeStatus;

  /// No description provided for @maintenanceStatus.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get maintenanceStatus;

  /// No description provided for @removeMachineTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove machine'**
  String get removeMachineTooltip;

  /// No description provided for @removeFromBuilding.
  ///
  /// In en, this message translates to:
  /// **'Remove from building'**
  String get removeFromBuilding;

  /// No description provided for @buildingQrTooltip.
  ///
  /// In en, this message translates to:
  /// **'Building QR'**
  String get buildingQrTooltip;

  /// No description provided for @machineN.
  ///
  /// In en, this message translates to:
  /// **'Machine {number}'**
  String machineN(int number);

  /// No description provided for @newBuilding.
  ///
  /// In en, this message translates to:
  /// **'New building'**
  String get newBuilding;

  /// No description provided for @buildingNameOrAddress.
  ///
  /// In en, this message translates to:
  /// **'Building name or address'**
  String get buildingNameOrAddress;

  /// No description provided for @buildingNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Bahnhofstrasse 12'**
  String get buildingNameHint;

  /// No description provided for @createBuilding.
  ///
  /// In en, this message translates to:
  /// **'Create building'**
  String get createBuilding;

  /// No description provided for @buildingCreatedMsg.
  ///
  /// In en, this message translates to:
  /// **'Building created. Post this QR in the laundry room.'**
  String get buildingCreatedMsg;

  /// No description provided for @scanToJoin.
  ///
  /// In en, this message translates to:
  /// **'Scan to join the laundry booking system'**
  String get scanToJoin;

  /// No description provided for @buildingQrCode.
  ///
  /// In en, this message translates to:
  /// **'Building QR Code'**
  String get buildingQrCode;

  /// No description provided for @postInLaundryRoom.
  ///
  /// In en, this message translates to:
  /// **'Post this in your laundry room'**
  String get postInLaundryRoom;

  /// No description provided for @residentsCanScan.
  ///
  /// In en, this message translates to:
  /// **'Residents scan it to join the booking system.'**
  String get residentsCanScan;

  /// No description provided for @printQr.
  ///
  /// In en, this message translates to:
  /// **'Print QR'**
  String get printQr;

  /// No description provided for @laundryRoomScanToJoin.
  ///
  /// In en, this message translates to:
  /// **'Laundry Room — Scan to join'**
  String get laundryRoomScanToJoin;

  /// No description provided for @scanWithApp.
  ///
  /// In en, this message translates to:
  /// **'Scan with the Lavaplan app to book machines.'**
  String get scanWithApp;

  /// No description provided for @buildingJoined.
  ///
  /// In en, this message translates to:
  /// **'Building joined successfully.'**
  String get buildingJoined;

  /// No description provided for @householdJoined.
  ///
  /// In en, this message translates to:
  /// **'Household joined successfully.'**
  String get householdJoined;

  /// No description provided for @unrecognisedQr.
  ///
  /// In en, this message translates to:
  /// **'Unrecognised QR code.'**
  String get unrecognisedQr;

  /// No description provided for @calendarTitle.
  ///
  /// In en, this message translates to:
  /// **'Laundry'**
  String get calendarTitle;

  /// No description provided for @todayBtn.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayBtn;

  /// No description provided for @tomorrowBtn.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrowBtn;

  /// No description provided for @slotMorning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get slotMorning;

  /// No description provided for @slotAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Afternoon'**
  String get slotAfternoon;

  /// No description provided for @yourBookingToday.
  ///
  /// In en, this message translates to:
  /// **'Your booking today'**
  String get yourBookingToday;

  /// No description provided for @machineOutOfService.
  ///
  /// In en, this message translates to:
  /// **'This machine is temporarily out of service.'**
  String get machineOutOfService;

  /// No description provided for @statusYourBooking.
  ///
  /// In en, this message translates to:
  /// **'Your booking'**
  String get statusYourBooking;

  /// No description provided for @statusTaken.
  ///
  /// In en, this message translates to:
  /// **'Taken'**
  String get statusTaken;

  /// No description provided for @bookedBy.
  ///
  /// In en, this message translates to:
  /// **'Booked by {name}'**
  String bookedBy(String name);

  /// No description provided for @aNeighbour.
  ///
  /// In en, this message translates to:
  /// **'a neighbour'**
  String get aNeighbour;

  /// No description provided for @statusPassed.
  ///
  /// In en, this message translates to:
  /// **'Passed'**
  String get statusPassed;

  /// No description provided for @statusAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get statusAvailable;

  /// No description provided for @legendAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get legendAvailable;

  /// No description provided for @legendPartlyBooked.
  ///
  /// In en, this message translates to:
  /// **'Partly booked'**
  String get legendPartlyBooked;

  /// No description provided for @legendFull.
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get legendFull;

  /// No description provided for @calMonthNames.
  ///
  /// In en, this message translates to:
  /// **'January,February,March,April,May,June,July,August,September,October,November,December'**
  String get calMonthNames;

  /// No description provided for @calShortMonths.
  ///
  /// In en, this message translates to:
  /// **'Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec'**
  String get calShortMonths;

  /// No description provided for @calShortDays.
  ///
  /// In en, this message translates to:
  /// **'Mon,Tue,Wed,Thu,Fri,Sat,Sun'**
  String get calShortDays;

  /// No description provided for @calDayLabels.
  ///
  /// In en, this message translates to:
  /// **'M,T,W,T,F,S,S'**
  String get calDayLabels;

  /// No description provided for @profilePhotosComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Profile photos are coming soon.'**
  String get profilePhotosComingSoon;

  /// No description provided for @orDivider.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get orDivider;

  /// No description provided for @verifyEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm your email'**
  String get verifyEmailTitle;

  /// No description provided for @verifyEmailBodyPrefix.
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit code to '**
  String get verifyEmailBodyPrefix;

  /// No description provided for @verifyEmailBodySuffix.
  ///
  /// In en, this message translates to:
  /// **'. Enter it below.'**
  String get verifyEmailBodySuffix;

  /// No description provided for @btnVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get btnVerify;

  /// No description provided for @btnResendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get btnResendCode;

  /// No description provided for @btnResendCodeCooldown.
  ///
  /// In en, this message translates to:
  /// **'Resend code ({seconds}s)'**
  String btnResendCodeCooldown(int seconds);

  /// No description provided for @useDifferentAccount.
  ///
  /// In en, this message translates to:
  /// **'Use a different account'**
  String get useDifferentAccount;

  /// No description provided for @checkSpamFolder.
  ///
  /// In en, this message translates to:
  /// **'Check your spam folder if it has not arrived.'**
  String get checkSpamFolder;

  /// No description provided for @codeSentSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Verification code sent.'**
  String get codeSentSnackbar;

  /// No description provided for @sessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Your session expired. Please sign in again.'**
  String get sessionExpired;

  /// No description provided for @signedOutElsewhere.
  ///
  /// In en, this message translates to:
  /// **'You were signed out because this account was opened on another device.'**
  String get signedOutElsewhere;

  /// No description provided for @addressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get addressLabel;

  /// No description provided for @onbContactDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your contact details'**
  String get onbContactDetailsTitle;

  /// No description provided for @onbContactDetailsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Shared with your neighbours so they can reach you.'**
  String get onbContactDetailsSubtitle;

  /// No description provided for @fieldStreet.
  ///
  /// In en, this message translates to:
  /// **'Street'**
  String get fieldStreet;

  /// No description provided for @fieldHouseNumber.
  ///
  /// In en, this message translates to:
  /// **'No.'**
  String get fieldHouseNumber;

  /// No description provided for @fieldPostalCode.
  ///
  /// In en, this message translates to:
  /// **'PLZ'**
  String get fieldPostalCode;

  /// No description provided for @fieldCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get fieldCity;

  /// No description provided for @fieldCanton.
  ///
  /// In en, this message translates to:
  /// **'Canton'**
  String get fieldCanton;

  /// No description provided for @fieldPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get fieldPhoneNumber;

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get greetingEvening;

  /// No description provided for @machineOpenStatus.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get machineOpenStatus;

  /// No description provided for @isTypingText.
  ///
  /// In en, this message translates to:
  /// **'{name} is typing...'**
  String isTypingText(String name);

  /// No description provided for @typeYourMessage.
  ///
  /// In en, this message translates to:
  /// **'Type your message'**
  String get typeYourMessage;

  /// No description provided for @yesterdayLabel.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterdayLabel;

  /// No description provided for @sayHelloTo.
  ///
  /// In en, this message translates to:
  /// **'Say hello to {name}'**
  String sayHelloTo(String name);

  /// No description provided for @messageHint.
  ///
  /// In en, this message translates to:
  /// **'Message {name}'**
  String messageHint(String name);

  /// No description provided for @nudgeButtonTooltip.
  ///
  /// In en, this message translates to:
  /// **'Quick nudge'**
  String get nudgeButtonTooltip;

  /// No description provided for @nudgeForgotLaundryLabel.
  ///
  /// In en, this message translates to:
  /// **'Forgot laundry'**
  String get nudgeForgotLaundryLabel;

  /// No description provided for @nudgeForgotLaundryMessage.
  ///
  /// In en, this message translates to:
  /// **'🧺 Hey, looks like you left your laundry in the machine!'**
  String get nudgeForgotLaundryMessage;

  /// No description provided for @nudgeCleanDetergentLabel.
  ///
  /// In en, this message translates to:
  /// **'Clean detergent bay'**
  String get nudgeCleanDetergentLabel;

  /// No description provided for @nudgeCleanDetergentMessage.
  ///
  /// In en, this message translates to:
  /// **'🧴 Hey, could you clean the detergent bay after use?'**
  String get nudgeCleanDetergentMessage;

  /// No description provided for @buildingAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Building address'**
  String get buildingAddressLabel;

  /// No description provided for @buildingAddressHint.
  ///
  /// In en, this message translates to:
  /// **'Street, number, postcode'**
  String get buildingAddressHint;

  /// No description provided for @buildingAddressNoResults.
  ///
  /// In en, this message translates to:
  /// **'No address found. Try street, number and postcode.'**
  String get buildingAddressNoResults;

  /// No description provided for @buildingAddressSearchFailed.
  ///
  /// In en, this message translates to:
  /// **'Address search isn\'t available. Check your connection and try again.'**
  String get buildingAddressSearchFailed;

  /// No description provided for @adminDeclarationText.
  ///
  /// In en, this message translates to:
  /// **'I confirm that I own this building or am authorized by its owner or property management to manage its laundry room.'**
  String get adminDeclarationText;

  /// No description provided for @adminDeclarationLegal.
  ///
  /// In en, this message translates to:
  /// **'I have read the'**
  String get adminDeclarationLegal;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfUse.
  ///
  /// In en, this message translates to:
  /// **'Terms of use'**
  String get termsOfUse;

  /// No description provided for @errorBuildingExists.
  ///
  /// In en, this message translates to:
  /// **'This building is already on Lavaplan. Ask its admin for the QR code to join it.'**
  String get errorBuildingExists;

  /// No description provided for @errorBuildingLimit.
  ///
  /// In en, this message translates to:
  /// **'Unverified admins can manage one building. Contact us to verify your account.'**
  String get errorBuildingLimit;

  /// No description provided for @adminUnverifiedBanner.
  ///
  /// In en, this message translates to:
  /// **'Your admin account isn\'t verified. You can manage one building and see residents\' names only.'**
  String get adminUnverifiedBanner;

  /// No description provided for @sectionBuilding.
  ///
  /// In en, this message translates to:
  /// **'Building'**
  String get sectionBuilding;

  /// No description provided for @adminVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified admin'**
  String get adminVerified;

  /// No description provided for @adminNotVerified.
  ///
  /// In en, this message translates to:
  /// **'Admin not verified'**
  String get adminNotVerified;

  /// No description provided for @reportAdmin.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get reportAdmin;

  /// No description provided for @reportAdminTitle.
  ///
  /// In en, this message translates to:
  /// **'Report this admin?'**
  String get reportAdminTitle;

  /// No description provided for @reportAdminContent.
  ///
  /// In en, this message translates to:
  /// **'Report this person if they don\'t manage your building for its owner or property management. We review every report.'**
  String get reportAdminContent;

  /// No description provided for @reportAdminReasonHint.
  ///
  /// In en, this message translates to:
  /// **'What\'s wrong? (optional)'**
  String get reportAdminReasonHint;

  /// No description provided for @reportAdminSent.
  ///
  /// In en, this message translates to:
  /// **'Report sent. We\'ll review it.'**
  String get reportAdminSent;

  /// No description provided for @handOverBuilding.
  ///
  /// In en, this message translates to:
  /// **'Hand over building'**
  String get handOverBuilding;

  /// No description provided for @handOverExplain.
  ///
  /// In en, this message translates to:
  /// **'Give this code to the person taking over. They enter it in Settings under Take over a building. You stop being this building\'s admin once they accept.'**
  String get handOverExplain;

  /// No description provided for @handOverValidUntil.
  ///
  /// In en, this message translates to:
  /// **'Valid until {date}'**
  String handOverValidUntil(String date);

  /// No description provided for @handOverCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel handover'**
  String get handOverCancel;

  /// No description provided for @handOverCancelled.
  ///
  /// In en, this message translates to:
  /// **'Handover cancelled. The code no longer works.'**
  String get handOverCancelled;

  /// No description provided for @takeOverBuilding.
  ///
  /// In en, this message translates to:
  /// **'Take over a building'**
  String get takeOverBuilding;

  /// No description provided for @takeOverExplain.
  ///
  /// In en, this message translates to:
  /// **'Enter or scan the handover code from the building\'s current admin. You become its admin.'**
  String get takeOverExplain;

  /// No description provided for @takeOverCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Handover code'**
  String get takeOverCodeHint;

  /// No description provided for @btnTakeOver.
  ///
  /// In en, this message translates to:
  /// **'Take over'**
  String get btnTakeOver;

  /// No description provided for @takeOverDone.
  ///
  /// In en, this message translates to:
  /// **'You\'re now the admin of {name}.'**
  String takeOverDone(String name);

  /// No description provided for @errorTransferInvalid.
  ///
  /// In en, this message translates to:
  /// **'This code is invalid or has expired. Ask the current admin for a new one.'**
  String get errorTransferInvalid;

  /// No description provided for @errorTransferOwn.
  ///
  /// In en, this message translates to:
  /// **'You already manage this building.'**
  String get errorTransferOwn;
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
      <String>['de', 'en', 'fr', 'it', 'rm'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
    case 'rm':
      return AppLocalizationsRm();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
