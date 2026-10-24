// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get navBookings => 'Réservations';

  @override
  String get navNeighbours => 'Voisins';

  @override
  String get navAdmin => 'Admin';

  @override
  String get navSettings => 'Paramètres';

  @override
  String get appName => 'Lavaplan';

  @override
  String get appTagline => 'Réservez votre créneau';

  @override
  String get loginTitle => 'Bon retour';

  @override
  String get loginSubtitle => 'Connectez-vous pour continuer';

  @override
  String get fieldEmail => 'E-mail';

  @override
  String get fieldPassword => 'Mot de passe';

  @override
  String get fieldConfirmPassword => 'Confirmer le mot de passe';

  @override
  String get btnSignIn => 'Se connecter';

  @override
  String get btnSignUp => 'S\'inscrire';

  @override
  String get btnCreateAccount => 'Créer un compte';

  @override
  String get btnContinueGoogle => 'Continuer avec Google';

  @override
  String get btnContinueApple => 'Continuer avec Apple';

  @override
  String get loginNoAccount => 'Pas encore de compte ?';

  @override
  String get registerHaveAccount => 'Déjà un compte ?';

  @override
  String get registerTitle => 'Créer un compte';

  @override
  String get registerSubtitle =>
      'Rejoignez le système de laverie de votre immeuble';

  @override
  String get errorPasswordMismatch => 'Les mots de passe ne correspondent pas.';

  @override
  String get errorWrongCredentials => 'E-mail ou mot de passe incorrect.';

  @override
  String get errorInvalidEmail => 'Veuillez saisir un e-mail valide.';

  @override
  String get errorEmailInUse => 'Un compte existe déjà pour cet e-mail.';

  @override
  String get errorWeakPassword =>
      'Le mot de passe doit contenir au moins 6 caractères.';

  @override
  String get errorNoInternet => 'Pas de connexion internet.';

  @override
  String get errorTooManyRequests => 'Trop de tentatives. Réessayez plus tard.';

  @override
  String get errorGeneric => 'Une erreur s\'est produite. Veuillez réessayer.';

  @override
  String get somethingWentWrong => 'Une erreur s\'est produite';

  @override
  String get btnSave => 'Enregistrer';

  @override
  String get btnCancel => 'Annuler';

  @override
  String get btnContinue => 'Continuer';

  @override
  String get btnPrint => 'Imprimer';

  @override
  String get btnRemove => 'Supprimer';

  @override
  String get btnBook => 'Réserver';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get sectionAppearance => 'Apparence';

  @override
  String get sectionHousehold => 'Ménage';

  @override
  String get sectionAccount => 'Compte';

  @override
  String get darkMode => 'Mode sombre';

  @override
  String get language => 'Langue';

  @override
  String get signOut => 'Se déconnecter';

  @override
  String get leaveBuilding => 'Quitter l\'immeuble';

  @override
  String get leaveBuildingContent =>
      'Vous perdrez l\'accès au système de réservation et au chat de cet immeuble. Si vous êtes le chef de votre foyer, la direction passe à un autre membre (ou le foyer est supprimé si vous en êtes le seul membre). Vos réservations futures seront annulées.';

  @override
  String get deleteAccount => 'Supprimer le compte';

  @override
  String get deleteAccountContent =>
      'Votre compte et toutes ses données seront définitivement supprimés. Cette action est irréversible. Les immeubles que vous gérez sont aussi supprimés si personne d\'autre n\'y habite. Si d\'autres résidents y habitent encore, contactez-nous d\'abord.';

  @override
  String get setupHousehold => 'Configurer le ménage';

  @override
  String get youManageHousehold => 'Vous gérez ce ménage';

  @override
  String get memberLabel => 'Membre';

  @override
  String get myHousehold => 'Mon ménage';

  @override
  String get householdMembers => 'Membres';

  @override
  String get inviteHouseholdMember => 'Inviter un membre du ménage';

  @override
  String get inviteScanText =>
      'Laissez-les scanner pour rejoindre votre ménage.';

  @override
  String get youLabel => 'Vous';

  @override
  String get editProfile => 'Modifier le profil';

  @override
  String get displayNameLabel => 'Nom affiché';

  @override
  String get yourFirstName => 'Votre prénom';

  @override
  String get shownToNeighbours =>
      'C\'est ce que vos voisins verront dans l\'application.';

  @override
  String get neighboursTitle => 'Voisins';

  @override
  String get noNeighboursYet => 'Pas encore de voisins';

  @override
  String get onbWhatsYourName => 'Quel est votre nom ?';

  @override
  String get onbNameSubtitle => 'C\'est ainsi que vos voisins vous verront.';

  @override
  String get onbNameHint => 'ex. Anna';

  @override
  String get onbHowWillYouUse => 'Comment utiliserez-vous cette application ?';

  @override
  String get onbChangeInSettings =>
      'Vous pouvez modifier cela dans les Paramètres.';

  @override
  String get onbImAResident => 'Je suis un résident';

  @override
  String get onbResidentSubtitle =>
      'Je vis dans l\'immeuble et souhaite réserver des machines';

  @override
  String get onbIManageBuildings => 'Je gère des immeubles';

  @override
  String get onbManagerSubtitle => 'Je suis responsable de la laverie';

  @override
  String get onbAlsoLive => 'Je vis aussi dans un de ces immeubles';

  @override
  String get onbAlsoLiveSubtitle =>
      'Vous pourrez aussi réserver des machines en tant que résident';

  @override
  String get onbJoinYourBuilding => 'Rejoindre votre immeuble';

  @override
  String get onbCreateOrScan =>
      'Créer un nouvel immeuble ou scanner un QR existant.';

  @override
  String get onbScanQrRoom => 'Scannez le QR affiché dans votre laverie.';

  @override
  String get onbCreateNewBuilding => 'Créer un nouvel immeuble';

  @override
  String get onbCreateBuildingSubtitle =>
      'Configurer un immeuble et obtenir son QR';

  @override
  String get onbScanExisting => 'Scanner un QR d\'immeuble existant';

  @override
  String get onbScanExistingSubtitle => 'Rejoindre un immeuble déjà configuré';

  @override
  String get onbScanQrCode => 'Scanner le QR';

  @override
  String get onbYourHousehold => 'Votre ménage';

  @override
  String get onbSetUpHousehold =>
      'Configurez qui partage la laverie avec vous.';

  @override
  String get onbFirstFromHousehold => 'Premier de mon ménage';

  @override
  String get onbFirstSubtitle =>
      'Créer un nouveau ménage et inviter les autres plus tard';

  @override
  String get onbJoinExisting => 'Rejoindre un ménage existant';

  @override
  String get onbJoinSubtitle =>
      'Scannez le QR d\'invitation de votre membre de ménage';

  @override
  String get onbNameOnMailbox => 'Nom sur la boîte aux lettres';

  @override
  String get onbMailboxHint => 'ex. Müller';

  @override
  String get onbCreateHousehold => 'Créer un ménage';

  @override
  String get onbNotHouseholdQr =>
      'Ce n\'est pas un QR d\'invitation de ménage.';

  @override
  String get onbNotBuildingQr =>
      'Cela ne ressemble pas à un QR d\'immeuble. Réessayez.';

  @override
  String get onbRequestPendingTitle => 'En attente d\'approbation';

  @override
  String get onbBuildingRequestPendingSubtitle =>
      'L\'administrateur de l\'immeuble a été averti et doit accepter votre demande avant que vous puissiez continuer.';

  @override
  String get onbBuildingRequestRejected =>
      'Votre demande d\'adhésion a été refusée. Vous pouvez rescanner le code ou essayer un autre immeuble.';

  @override
  String get scanQrCode => 'Scanner le QR';

  @override
  String get adminTitle => 'Admin';

  @override
  String get addBuilding => 'Ajouter un immeuble';

  @override
  String get noBuildingsYet => 'Pas encore d\'immeubles';

  @override
  String get tapToAddBuilding =>
      'Appuyez sur + Ajouter un immeuble pour commencer.';

  @override
  String residentsCount(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString résidents',
      one: '1 résident',
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
      other: '$countString machines en maintenance',
      one: '1 machine en maintenance',
    );
    return '$_temp0';
  }

  @override
  String get residentsTab => 'Résidents';

  @override
  String get machinesTab => 'Machines';

  @override
  String get noResidentsYet => 'Pas encore de résidents';

  @override
  String get noHousehold => 'Pas de ménage';

  @override
  String get removeResident => 'Supprimer le résident';

  @override
  String get removeResidentContent =>
      'Cela supprimera le résident de l\'immeuble. Il devra re-scanner le QR pour rejoindre.';

  @override
  String pendingRequestsTitle(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString demandes en attente',
      one: '1 demande en attente',
    );
    return '$_temp0';
  }

  @override
  String get joinRequestBuildingLabel => 'Souhaite rejoindre cet immeuble';

  @override
  String get btnApprove => 'Accepter';

  @override
  String get btnReject => 'Refuser';

  @override
  String get machinesDescription =>
      'Activez ou désactivez les machines, ajoutez ou supprimez-en.';

  @override
  String get removeMachineTitle => 'Supprimer la machine ?';

  @override
  String removeMachineContent(int number) {
    return 'La machine $number sera supprimée. Les réservations existantes ne seront pas annulées automatiquement.';
  }

  @override
  String get addMachine => 'Ajouter une machine';

  @override
  String get headLabel => 'Chef';

  @override
  String get activeStatus => 'Actif';

  @override
  String get maintenanceStatus => 'Maintenance';

  @override
  String get removeMachineTooltip => 'Supprimer la machine';

  @override
  String get removeFromBuilding => 'Supprimer de l\'immeuble';

  @override
  String get buildingQrTooltip => 'QR de l\'immeuble';

  @override
  String machineN(int number) {
    return 'Machine $number';
  }

  @override
  String get newBuilding => 'Nouvel immeuble';

  @override
  String get buildingNameOrAddress => 'Nom ou adresse de l\'immeuble';

  @override
  String get buildingNameHint => 'ex. Bahnhofstrasse 12';

  @override
  String get createBuilding => 'Créer l\'immeuble';

  @override
  String get buildingCreatedMsg =>
      'Immeuble créé. Affichez ce QR dans la laverie.';

  @override
  String get scanToJoin => 'Scanner pour rejoindre le système de réservation';

  @override
  String get buildingQrCode => 'QR de l\'immeuble';

  @override
  String get postInLaundryRoom => 'Afficher dans la laverie';

  @override
  String get residentsCanScan =>
      'Les résidents le scannent pour rejoindre le système.';

  @override
  String get printQr => 'Imprimer le QR';

  @override
  String get laundryRoomScanToJoin => 'Laverie — Scanner pour rejoindre';

  @override
  String get scanWithApp =>
      'Scanner avec l\'application pour réserver des machines.';

  @override
  String get buildingJoined => 'Immeuble rejoint avec succès.';

  @override
  String get householdJoined => 'Ménage rejoint avec succès.';

  @override
  String get unrecognisedQr => 'QR non reconnu.';

  @override
  String get calendarTitle => 'Laverie';

  @override
  String get todayBtn => 'Aujourd\'hui';

  @override
  String get tomorrowBtn => 'Demain';

  @override
  String get slotMorning => 'Matin';

  @override
  String get slotAfternoon => 'Après-midi';

  @override
  String get yourBookingToday => 'Votre réservation aujourd\'hui';

  @override
  String get machineOutOfService =>
      'Cette machine est temporairement hors service.';

  @override
  String get statusYourBooking => 'Votre réservation';

  @override
  String get statusTaken => 'Pris';

  @override
  String bookedBy(String name) {
    return 'Réservé par $name';
  }

  @override
  String get aNeighbour => 'un voisin';

  @override
  String get statusPassed => 'Passé';

  @override
  String get statusAvailable => 'Disponible';

  @override
  String get legendAvailable => 'Disponible';

  @override
  String get legendPartlyBooked => 'Partiellement réservé';

  @override
  String get legendFull => 'Complet';

  @override
  String get calMonthNames =>
      'Janvier,Février,Mars,Avril,Mai,Juin,Juillet,Août,Septembre,Octobre,Novembre,Décembre';

  @override
  String get calShortMonths =>
      'Jan,Fév,Mar,Avr,Mai,Jun,Jul,Aoû,Sep,Oct,Nov,Déc';

  @override
  String get calShortDays => 'Lun,Mar,Mer,Jeu,Ven,Sam,Dim';

  @override
  String get calDayLabels => 'L,M,M,J,V,S,D';

  @override
  String get profilePhotosComingSoon =>
      'Les photos de profil arrivent bientôt.';

  @override
  String get orDivider => 'ou';

  @override
  String get verifyEmailTitle => 'Confirmez votre e-mail';

  @override
  String get verifyEmailBodyPrefix =>
      'Nous avons envoyé un code à 6 chiffres à ';

  @override
  String get verifyEmailBodySuffix => '. Saisissez-le ci-dessous.';

  @override
  String get btnVerify => 'Vérifier';

  @override
  String get btnResendCode => 'Renvoyer le code';

  @override
  String btnResendCodeCooldown(int seconds) {
    return 'Renvoyer le code (${seconds}s)';
  }

  @override
  String get useDifferentAccount => 'Utiliser un autre compte';

  @override
  String get checkSpamFolder =>
      'Vérifiez votre dossier spam s\'il n\'est pas arrivé.';

  @override
  String get codeSentSnackbar => 'Code de vérification envoyé.';

  @override
  String get sessionExpired =>
      'Votre session a expiré. Veuillez vous reconnecter.';

  @override
  String get signedOutElsewhere =>
      'Vous avez été déconnecté car ce compte a été ouvert sur un autre appareil.';

  @override
  String get addressLabel => 'Adresse';

  @override
  String get onbContactDetailsTitle => 'Vos coordonnées';

  @override
  String get onbContactDetailsSubtitle =>
      'Partagées avec vos voisins pour qu\'ils puissent vous joindre.';

  @override
  String get fieldStreet => 'Rue';

  @override
  String get fieldHouseNumber => 'N°';

  @override
  String get fieldPostalCode => 'NPA';

  @override
  String get fieldCity => 'Ville';

  @override
  String get fieldCanton => 'Canton';

  @override
  String get fieldPhoneNumber => 'Numéro de téléphone';

  @override
  String get greetingMorning => 'Bonjour';

  @override
  String get greetingAfternoon => 'Bon après-midi';

  @override
  String get greetingEvening => 'Bonsoir';

  @override
  String get machineOpenStatus => 'Libre';

  @override
  String isTypingText(String name) {
    return '$name est en train d\'écrire...';
  }

  @override
  String get typeYourMessage => 'Votre message';

  @override
  String get yesterdayLabel => 'Hier';

  @override
  String sayHelloTo(String name) {
    return 'Dites bonjour à $name';
  }

  @override
  String messageHint(String name) {
    return 'Message à $name';
  }

  @override
  String get nudgeButtonTooltip => 'Rappel rapide';

  @override
  String get nudgeForgotLaundryLabel => 'Linge oublié';

  @override
  String get nudgeForgotLaundryMessage =>
      '🧺 Salut, on dirait que tu as oublié ton linge dans la machine !';

  @override
  String get nudgeCleanDetergentLabel => 'Nettoyer le bac à lessive';

  @override
  String get nudgeCleanDetergentMessage =>
      '🧴 Salut, tu pourrais nettoyer le bac à lessive après utilisation ?';

  @override
  String get buildingAddressLabel => 'Adresse de l\'immeuble';

  @override
  String get buildingAddressHint => 'Rue, numéro, NPA';

  @override
  String get buildingAddressNoResults =>
      'Aucune adresse trouvée. Essayez rue, numéro et NPA.';

  @override
  String get buildingAddressSearchFailed =>
      'La recherche d\'adresse n\'est pas disponible. Vérifiez votre connexion et réessayez.';

  @override
  String get adminDeclarationText =>
      'Je confirme être propriétaire de cet immeuble ou mandaté par son propriétaire ou sa gérance pour gérer la buanderie.';

  @override
  String get adminDeclarationLegal => 'J\'ai lu :';

  @override
  String get privacyPolicy => 'Politique de confidentialité';

  @override
  String get termsOfUse => 'Conditions d\'utilisation';

  @override
  String get errorBuildingExists =>
      'Cet immeuble est déjà sur Lavaplan. Demandez le code QR à son administrateur pour le rejoindre.';

  @override
  String get errorBuildingLimit =>
      'Les administrateurs non vérifiés peuvent gérer un seul immeuble. Contactez-nous pour vérifier votre compte.';

  @override
  String get adminUnverifiedBanner =>
      'Votre compte administrateur n\'est pas vérifié. Vous pouvez gérer un immeuble et ne voyez que les noms des résidents.';

  @override
  String get sectionBuilding => 'Immeuble';

  @override
  String get adminVerified => 'Administrateur vérifié';

  @override
  String get adminNotVerified => 'Administrateur non vérifié';

  @override
  String get reportAdmin => 'Signaler';

  @override
  String get reportAdminTitle => 'Signaler cet administrateur ?';

  @override
  String get reportAdminContent =>
      'Signalez cette personne si elle ne gère pas votre immeuble pour son propriétaire ou sa gérance. Nous examinons chaque signalement.';

  @override
  String get reportAdminReasonHint => 'Quel est le problème ? (facultatif)';

  @override
  String get reportAdminSent => 'Signalement envoyé. Nous allons l\'examiner.';

  @override
  String get handOverBuilding => 'Transmettre l\'immeuble';

  @override
  String get handOverExplain =>
      'Donnez ce code à la personne qui reprend. Elle le saisit dans Réglages sous Reprendre un immeuble. Dès qu\'elle accepte, vous n\'êtes plus administrateur de cet immeuble.';

  @override
  String handOverValidUntil(String date) {
    return 'Valable jusqu\'au $date';
  }

  @override
  String get handOverCancel => 'Annuler la transmission';

  @override
  String get handOverCancelled =>
      'Transmission annulée. Le code ne fonctionne plus.';

  @override
  String get takeOverBuilding => 'Reprendre un immeuble';

  @override
  String get takeOverExplain =>
      'Saisissez ou scannez le code de transmission de l\'administrateur actuel. Vous devenez administrateur de l\'immeuble.';

  @override
  String get takeOverCodeHint => 'Code de transmission';

  @override
  String get btnTakeOver => 'Reprendre';

  @override
  String takeOverDone(String name) {
    return 'Vous êtes maintenant administrateur de $name.';
  }

  @override
  String get errorTransferInvalid =>
      'Ce code est invalide ou a expiré. Demandez-en un nouveau à l\'administrateur actuel.';

  @override
  String get errorTransferOwn => 'Vous gérez déjà cet immeuble.';
}
