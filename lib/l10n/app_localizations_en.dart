// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get navBookings => 'Bookings';

  @override
  String get navNeighbours => 'Neighbours';

  @override
  String get navAdmin => 'Admin';

  @override
  String get navSettings => 'Settings';

  @override
  String get appName => 'Laundry';

  @override
  String get appTagline => 'Book your laundry slot';

  @override
  String get loginTitle => 'Welcome back';

  @override
  String get loginSubtitle => 'Sign in to continue';

  @override
  String get fieldEmail => 'Email';

  @override
  String get fieldPassword => 'Password';

  @override
  String get fieldConfirmPassword => 'Confirm password';

  @override
  String get btnSignIn => 'Sign in';

  @override
  String get btnSignUp => 'Sign up';

  @override
  String get btnCreateAccount => 'Create account';

  @override
  String get btnContinueGoogle => 'Continue with Google';

  @override
  String get btnContinueApple => 'Continue with Apple';

  @override
  String get loginNoAccount => 'Don\'t have an account?';

  @override
  String get registerHaveAccount => 'Already have an account?';

  @override
  String get registerTitle => 'Create account';

  @override
  String get registerSubtitle => 'Join your building\'s laundry system';

  @override
  String get errorPasswordMismatch => 'Passwords do not match.';

  @override
  String get errorWrongCredentials => 'Incorrect email or password.';

  @override
  String get errorInvalidEmail => 'Please enter a valid email.';

  @override
  String get errorEmailInUse => 'An account already exists for this email.';

  @override
  String get errorWeakPassword => 'Password must be at least 6 characters.';

  @override
  String get errorNoInternet => 'No internet connection.';

  @override
  String get errorTooManyRequests => 'Too many attempts. Try again later.';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String get btnSave => 'Save';

  @override
  String get btnCancel => 'Cancel';

  @override
  String get btnContinue => 'Continue';

  @override
  String get btnPrint => 'Print';

  @override
  String get btnRemove => 'Remove';

  @override
  String get btnBook => 'Book';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get sectionAppearance => 'Appearance';

  @override
  String get sectionHousehold => 'Household';

  @override
  String get sectionAccount => 'Account';

  @override
  String get darkMode => 'Dark mode';

  @override
  String get language => 'Language';

  @override
  String get signOut => 'Sign out';

  @override
  String get setupHousehold => 'Set up household';

  @override
  String get youManageHousehold => 'You manage this household';

  @override
  String get memberLabel => 'Member';

  @override
  String get myHousehold => 'My household';

  @override
  String get householdMembers => 'Members';

  @override
  String get inviteHouseholdMember => 'Invite a household member';

  @override
  String get inviteScanText => 'Let them scan this to join your household.';

  @override
  String get youLabel => 'You';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get displayNameLabel => 'Display name';

  @override
  String get yourFirstName => 'Your first name';

  @override
  String get shownToNeighbours =>
      'This is shown to your neighbours in the app.';

  @override
  String get neighboursTitle => 'Neighbours';

  @override
  String get noNeighboursYet => 'No neighbours yet';

  @override
  String get onbWhatsYourName => 'What\'s your name?';

  @override
  String get onbNameSubtitle => 'This is how your neighbours will see you.';

  @override
  String get onbNameHint => 'e.g. Anna';

  @override
  String get onbHowWillYouUse => 'How will you use this app?';

  @override
  String get onbChangeInSettings => 'You can change this later in Settings.';

  @override
  String get onbImAResident => 'I\'m a resident';

  @override
  String get onbResidentSubtitle =>
      'I live in the building and want to book machines';

  @override
  String get onbIManageBuildings => 'I manage building(s)';

  @override
  String get onbManagerSubtitle => 'I\'m responsible for the laundry room';

  @override
  String get onbAlsoLive => 'I also live in one of these buildings';

  @override
  String get onbAlsoLiveSubtitle =>
      'You\'ll be able to book machines as a resident too';

  @override
  String get onbJoinYourBuilding => 'Join your building';

  @override
  String get onbCreateOrScan => 'Create a new building or scan an existing QR.';

  @override
  String get onbScanQrRoom => 'Scan the QR code posted in your laundry room.';

  @override
  String get onbCreateNewBuilding => 'Create a new building';

  @override
  String get onbCreateBuildingSubtitle =>
      'Set up a building and get its QR code';

  @override
  String get onbScanExisting => 'Scan existing building QR';

  @override
  String get onbScanExistingSubtitle =>
      'Join a building that\'s already set up';

  @override
  String get onbScanQrCode => 'Scan QR code';

  @override
  String get onbYourHousehold => 'Your household';

  @override
  String get onbSetUpHousehold => 'Set up who shares the laundry with you.';

  @override
  String get onbFirstFromHousehold => 'First from my household';

  @override
  String get onbFirstSubtitle =>
      'Create a new household and invite others later';

  @override
  String get onbJoinExisting => 'Join an existing household';

  @override
  String get onbJoinSubtitle => 'Scan the invite QR from your household member';

  @override
  String get onbNameOnMailbox => 'Name on your mailbox';

  @override
  String get onbMailboxHint => 'e.g. Müller';

  @override
  String get onbCreateHousehold => 'Create household';

  @override
  String get onbNotHouseholdQr => 'This is not a household invite QR.';

  @override
  String get onbNotBuildingQr =>
      'This doesn\'t look like a building QR. Try again.';

  @override
  String get scanQrCode => 'Scan QR Code';

  @override
  String get adminTitle => 'Admin';

  @override
  String get addBuilding => 'Add building';

  @override
  String get noBuildingsYet => 'No buildings yet';

  @override
  String get tapToAddBuilding => 'Tap + Add building to get started.';

  @override
  String residentsCount(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString residents',
      one: '1 resident',
    );
    return '$_temp0';
  }

  @override
  String maintenanceCount(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString machines in maintenance',
      one: '1 machine in maintenance',
    );
    return '$_temp0';
  }

  @override
  String get residentsTab => 'Residents';

  @override
  String get machinesTab => 'Machines';

  @override
  String get noResidentsYet => 'No residents yet';

  @override
  String get noHousehold => 'No household';

  @override
  String get removeResident => 'Remove resident';

  @override
  String get removeResidentContent =>
      'This will remove the resident from the building. They will need to re-scan the QR to rejoin.';

  @override
  String get machinesDescription =>
      'Toggle machines in or out of service, or add/remove machines.';

  @override
  String get removeMachineTitle => 'Remove machine?';

  @override
  String removeMachineContent(int number) {
    return 'Machine $number will be removed. Existing bookings for this machine are not automatically cancelled.';
  }

  @override
  String get addMachine => 'Add machine';

  @override
  String get headLabel => 'Head';

  @override
  String get activeStatus => 'Active';

  @override
  String get maintenanceStatus => 'Maintenance';

  @override
  String get removeMachineTooltip => 'Remove machine';

  @override
  String get removeFromBuilding => 'Remove from building';

  @override
  String get buildingQrTooltip => 'Building QR';

  @override
  String machineN(int number) {
    return 'Machine $number';
  }

  @override
  String get newBuilding => 'New building';

  @override
  String get buildingNameOrAddress => 'Building name or address';

  @override
  String get buildingNameHint => 'e.g. Bahnhofstrasse 12';

  @override
  String get createBuilding => 'Create building';

  @override
  String get buildingCreatedMsg =>
      'Building created. Post this QR in the laundry room.';

  @override
  String get scanToJoin => 'Scan to join the laundry booking system';

  @override
  String get buildingQrCode => 'Building QR Code';

  @override
  String get postInLaundryRoom => 'Post this in your laundry room';

  @override
  String get residentsCanScan =>
      'Residents scan it to join the booking system.';

  @override
  String get printQr => 'Print QR';

  @override
  String get laundryRoomScanToJoin => 'Laundry Room — Scan to join';

  @override
  String get scanWithApp => 'Scan with the Laundry app to book machines.';

  @override
  String get buildingJoined => 'Building joined successfully.';

  @override
  String get householdJoined => 'Household joined successfully.';

  @override
  String get unrecognisedQr => 'Unrecognised QR code.';

  @override
  String get calendarTitle => 'Laundry';

  @override
  String get todayBtn => 'Today';

  @override
  String get tomorrowBtn => 'Tomorrow';

  @override
  String get slotMorning => 'Morning';

  @override
  String get slotAfternoon => 'Afternoon';

  @override
  String get yourBookingToday => 'Your booking today';

  @override
  String get machineOutOfService =>
      'This machine is temporarily out of service.';

  @override
  String get statusYourBooking => 'Your booking';

  @override
  String get statusTaken => 'Taken';

  @override
  String get statusPassed => 'Passed';

  @override
  String get statusAvailable => 'Available';

  @override
  String get legendAvailable => 'Available';

  @override
  String get legendPartlyBooked => 'Partly booked';

  @override
  String get legendFull => 'Full';

  @override
  String get calMonthNames =>
      'January,February,March,April,May,June,July,August,September,October,November,December';

  @override
  String get calShortMonths =>
      'Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec';

  @override
  String get calShortDays => 'Mon,Tue,Wed,Thu,Fri,Sat,Sun';

  @override
  String get calDayLabels => 'M,T,W,T,F,S,S';

  @override
  String isTypingText(String name) {
    return '$name is typing...';
  }

  @override
  String get typeYourMessage => 'Type your message';
}
