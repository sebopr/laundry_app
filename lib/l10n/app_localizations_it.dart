// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get navBookings => 'Prenotazioni';

  @override
  String get navNeighbours => 'Vicini';

  @override
  String get navAdmin => 'Admin';

  @override
  String get navSettings => 'Impostazioni';

  @override
  String get appName => 'Lavaplan';

  @override
  String get appTagline => 'Prenota la tua fascia oraria';

  @override
  String get loginTitle => 'Bentornato';

  @override
  String get loginSubtitle => 'Accedi per continuare';

  @override
  String get fieldEmail => 'E-mail';

  @override
  String get fieldPassword => 'Password';

  @override
  String get fieldConfirmPassword => 'Conferma password';

  @override
  String get btnSignIn => 'Accedi';

  @override
  String get btnSignUp => 'Registrati';

  @override
  String get btnCreateAccount => 'Crea account';

  @override
  String get btnContinueGoogle => 'Continua con Google';

  @override
  String get btnContinueApple => 'Continua con Apple';

  @override
  String get loginNoAccount => 'Non hai un account?';

  @override
  String get registerHaveAccount => 'Hai già un account?';

  @override
  String get registerTitle => 'Crea account';

  @override
  String get registerSubtitle =>
      'Unisciti al sistema di lavanderia del tuo edificio';

  @override
  String get errorPasswordMismatch => 'Le password non corrispondono.';

  @override
  String get errorWrongCredentials => 'E-mail o password non corretti.';

  @override
  String get errorInvalidEmail => 'Inserisci un\'e-mail valida.';

  @override
  String get errorEmailInUse => 'Esiste già un account con questa e-mail.';

  @override
  String get errorWeakPassword =>
      'La password deve contenere almeno 6 caratteri.';

  @override
  String get errorNoInternet => 'Nessuna connessione internet.';

  @override
  String get errorTooManyRequests => 'Troppi tentativi. Riprova più tardi.';

  @override
  String get errorGeneric => 'Qualcosa è andato storto. Riprova.';

  @override
  String get somethingWentWrong => 'Qualcosa è andato storto';

  @override
  String get btnSave => 'Salva';

  @override
  String get btnCancel => 'Annulla';

  @override
  String get btnContinue => 'Continua';

  @override
  String get btnPrint => 'Stampa';

  @override
  String get btnRemove => 'Rimuovi';

  @override
  String get btnBook => 'Prenota';

  @override
  String get settingsTitle => 'Impostazioni';

  @override
  String get sectionAppearance => 'Aspetto';

  @override
  String get sectionHousehold => 'Famiglia';

  @override
  String get sectionAccount => 'Account';

  @override
  String get darkMode => 'Modalità scura';

  @override
  String get language => 'Lingua';

  @override
  String get signOut => 'Esci';

  @override
  String get leaveBuilding => 'Lascia l\'edificio';

  @override
  String get leaveBuildingContent =>
      'Perderai l\'accesso al sistema di prenotazione e alla chat di questo edificio. Se sei il capofamiglia, la gestione passa a un altro membro (o il nucleo familiare viene rimosso se sei l\'unico membro). Le tue prenotazioni future verranno annullate.';

  @override
  String get deleteAccount => 'Elimina account';

  @override
  String get deleteAccountContent =>
      'Questo elimina definitivamente il tuo account e tutti i suoi dati. Questa azione non può essere annullata. Se gestisci degli edifici, dovrai prima trasferirli o eliminarli.';

  @override
  String get setupHousehold => 'Configura famiglia';

  @override
  String get youManageHousehold => 'Gestisci questa famiglia';

  @override
  String get memberLabel => 'Membro';

  @override
  String get myHousehold => 'La mia famiglia';

  @override
  String get householdMembers => 'Membri';

  @override
  String get inviteHouseholdMember => 'Invita un membro';

  @override
  String get inviteScanText => 'Fai scansionare per unirsi alla tua famiglia.';

  @override
  String get youLabel => 'Tu';

  @override
  String get editProfile => 'Modifica profilo';

  @override
  String get displayNameLabel => 'Nome visualizzato';

  @override
  String get yourFirstName => 'Il tuo nome';

  @override
  String get shownToNeighbours =>
      'Questo viene mostrato ai tuoi vicini nell\'app.';

  @override
  String get neighboursTitle => 'Vicini';

  @override
  String get noNeighboursYet => 'Nessun vicino ancora';

  @override
  String get onbWhatsYourName => 'Come ti chiami?';

  @override
  String get onbNameSubtitle => 'Così ti vedranno i tuoi vicini.';

  @override
  String get onbNameHint => 'es. Anna';

  @override
  String get onbHowWillYouUse => 'Come userai questa app?';

  @override
  String get onbChangeInSettings => 'Puoi cambiarlo nelle Impostazioni.';

  @override
  String get onbImAResident => 'Sono un residente';

  @override
  String get onbResidentSubtitle =>
      'Vivo nell\'edificio e voglio prenotare le macchine';

  @override
  String get onbIManageBuildings => 'Gestisco edifici';

  @override
  String get onbManagerSubtitle => 'Sono responsabile della lavanderia';

  @override
  String get onbAlsoLive => 'Vivo anche in uno di questi edifici';

  @override
  String get onbAlsoLiveSubtitle =>
      'Potrai anche prenotare macchine come residente';

  @override
  String get onbJoinYourBuilding => 'Unisciti al tuo edificio';

  @override
  String get onbCreateOrScan =>
      'Crea un nuovo edificio o scansiona un QR esistente.';

  @override
  String get onbScanQrRoom => 'Scansiona il QR nella lavanderia.';

  @override
  String get onbCreateNewBuilding => 'Crea un nuovo edificio';

  @override
  String get onbCreateBuildingSubtitle =>
      'Configura un edificio e ottieni il suo QR';

  @override
  String get onbScanExisting => 'Scansiona QR edificio esistente';

  @override
  String get onbScanExistingSubtitle =>
      'Unisciti a un edificio già configurato';

  @override
  String get onbScanQrCode => 'Scansiona QR';

  @override
  String get onbYourHousehold => 'La tua famiglia';

  @override
  String get onbSetUpHousehold =>
      'Configura chi condivide la lavanderia con te.';

  @override
  String get onbFirstFromHousehold => 'Primo della mia famiglia';

  @override
  String get onbFirstSubtitle =>
      'Crea una nuova famiglia e invita gli altri dopo';

  @override
  String get onbJoinExisting => 'Unisciti a una famiglia esistente';

  @override
  String get onbJoinSubtitle => 'Scansiona il QR d\'invito del tuo membro';

  @override
  String get onbNameOnMailbox => 'Nome sulla cassetta delle lettere';

  @override
  String get onbMailboxHint => 'es. Müller';

  @override
  String get onbCreateHousehold => 'Crea famiglia';

  @override
  String get onbNotHouseholdQr => 'Questo non è un QR d\'invito famiglia.';

  @override
  String get onbNotBuildingQr => 'Non sembra un QR dell\'edificio. Riprova.';

  @override
  String get onbRequestPendingTitle => 'In attesa di approvazione';

  @override
  String get onbBuildingRequestPendingSubtitle =>
      'L\'amministratore dell\'edificio è stato avvisato e deve accettare la tua richiesta prima che tu possa continuare.';

  @override
  String get onbHouseholdRequestPendingSubtitle =>
      'L\'amministratore dell\'edificio è stato avvisato e deve accettare il tuo nucleo familiare prima che tu possa continuare.';

  @override
  String get onbBuildingRequestRejected =>
      'La tua richiesta di adesione è stata rifiutata. Puoi scansionare di nuovo il codice o provare un altro edificio.';

  @override
  String get onbHouseholdRequestRejected =>
      'La tua richiesta per il nucleo familiare è stata rifiutata. Puoi riprovare.';

  @override
  String get scanQrCode => 'Scansiona QR';

  @override
  String get adminTitle => 'Admin';

  @override
  String get addBuilding => 'Aggiungi edificio';

  @override
  String get noBuildingsYet => 'Nessun edificio ancora';

  @override
  String get tapToAddBuilding => 'Premi + Aggiungi edificio per iniziare.';

  @override
  String residentsCount(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString residenti',
      one: '1 residente',
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
      other: '$countString macchine in manutenzione',
      one: '1 macchina in manutenzione',
    );
    return '$_temp0';
  }

  @override
  String get residentsTab => 'Residenti';

  @override
  String get machinesTab => 'Macchine';

  @override
  String get noResidentsYet => 'Nessun residente ancora';

  @override
  String get noHousehold => 'Nessuna famiglia';

  @override
  String get removeResident => 'Rimuovi residente';

  @override
  String get removeResidentContent =>
      'Il residente verrà rimosso dall\'edificio. Dovrà ri-scansionare il QR per rientrare.';

  @override
  String pendingRequestsTitle(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString richieste in sospeso',
      one: '1 richiesta in sospeso',
    );
    return '$_temp0';
  }

  @override
  String get joinRequestBuildingLabel => 'Vuole unirsi a questo edificio';

  @override
  String joinRequestHouseholdLabel(String name) {
    return 'Vuole creare il nucleo familiare \"$name\"';
  }

  @override
  String get btnApprove => 'Approva';

  @override
  String get btnReject => 'Rifiuta';

  @override
  String get machinesDescription =>
      'Attiva/disattiva le macchine, aggiungile o rimuovile.';

  @override
  String get removeMachineTitle => 'Rimuovere la macchina?';

  @override
  String removeMachineContent(int number) {
    return 'La macchina $number verrà rimossa. Le prenotazioni esistenti non verranno cancellate automaticamente.';
  }

  @override
  String get addMachine => 'Aggiungi macchina';

  @override
  String get headLabel => 'Capo';

  @override
  String get activeStatus => 'Attiva';

  @override
  String get maintenanceStatus => 'Manutenzione';

  @override
  String get removeMachineTooltip => 'Rimuovi macchina';

  @override
  String get removeFromBuilding => 'Rimuovi dall\'edificio';

  @override
  String get buildingQrTooltip => 'QR edificio';

  @override
  String machineN(int number) {
    return 'Macchina $number';
  }

  @override
  String get newBuilding => 'Nuovo edificio';

  @override
  String get buildingNameOrAddress => 'Nome o indirizzo edificio';

  @override
  String get buildingNameHint => 'es. Via Roma 12';

  @override
  String get createBuilding => 'Crea edificio';

  @override
  String get buildingCreatedMsg =>
      'Edificio creato. Affiggi questo QR nella lavanderia.';

  @override
  String get scanToJoin => 'Scansiona per unirti al sistema di prenotazione';

  @override
  String get buildingQrCode => 'QR edificio';

  @override
  String get postInLaundryRoom => 'Affiggi nella lavanderia';

  @override
  String get residentsCanScan => 'I residenti lo scansionano per iscriversi.';

  @override
  String get printQr => 'Stampa QR';

  @override
  String get laundryRoomScanToJoin => 'Lavanderia — Scansiona per unirti';

  @override
  String get scanWithApp => 'Scansiona con l\'app per prenotare le macchine.';

  @override
  String get buildingJoined => 'Edificio raggiunto con successo.';

  @override
  String get householdJoined => 'Famiglia raggiunta con successo.';

  @override
  String get unrecognisedQr => 'QR non riconosciuto.';

  @override
  String get calendarTitle => 'Lavanderia';

  @override
  String get todayBtn => 'Oggi';

  @override
  String get tomorrowBtn => 'Domani';

  @override
  String get slotMorning => 'Mattina';

  @override
  String get slotAfternoon => 'Pomeriggio';

  @override
  String get yourBookingToday => 'La tua prenotazione oggi';

  @override
  String get machineOutOfService =>
      'Questa macchina è temporaneamente fuori servizio.';

  @override
  String get statusYourBooking => 'La tua prenotazione';

  @override
  String get statusTaken => 'Occupato';

  @override
  String get statusPassed => 'Passato';

  @override
  String get statusAvailable => 'Disponibile';

  @override
  String get legendAvailable => 'Disponibile';

  @override
  String get legendPartlyBooked => 'Parzialmente prenotato';

  @override
  String get legendFull => 'Completo';

  @override
  String get calMonthNames =>
      'Gennaio,Febbraio,Marzo,Aprile,Maggio,Giugno,Luglio,Agosto,Settembre,Ottobre,Novembre,Dicembre';

  @override
  String get calShortMonths =>
      'Gen,Feb,Mar,Apr,Mag,Giu,Lug,Ago,Set,Ott,Nov,Dic';

  @override
  String get calShortDays => 'Lun,Mar,Mer,Gio,Ven,Sab,Dom';

  @override
  String get calDayLabels => 'L,M,M,G,V,S,D';

  @override
  String get profilePhotosComingSoon =>
      'Le foto del profilo arriveranno presto.';

  @override
  String get orDivider => 'oppure';

  @override
  String get verifyEmailTitle => 'Conferma la tua email';

  @override
  String get verifyEmailBodyPrefix => 'Abbiamo inviato un codice a 6 cifre a ';

  @override
  String get verifyEmailBodySuffix => '. Inseriscilo qui sotto.';

  @override
  String get btnVerify => 'Verifica';

  @override
  String get btnResendCode => 'Invia di nuovo il codice';

  @override
  String btnResendCodeCooldown(int seconds) {
    return 'Invia di nuovo il codice (${seconds}s)';
  }

  @override
  String get useDifferentAccount => 'Usa un altro account';

  @override
  String get checkSpamFolder => 'Controlla la cartella spam se non è arrivato.';

  @override
  String get codeSentSnackbar => 'Codice di verifica inviato.';

  @override
  String get sessionExpired => 'La tua sessione è scaduta. Accedi di nuovo.';

  @override
  String get signedOutElsewhere =>
      'Sei stato disconnesso perché questo account è stato aperto su un altro dispositivo.';

  @override
  String get addressLabel => 'Indirizzo';

  @override
  String get onbContactDetailsTitle => 'I tuoi contatti';

  @override
  String get onbContactDetailsSubtitle =>
      'Condivisi con i tuoi vicini per poterti contattare.';

  @override
  String get fieldStreet => 'Via';

  @override
  String get fieldHouseNumber => 'N.';

  @override
  String get fieldPostalCode => 'CAP';

  @override
  String get fieldCity => 'Città';

  @override
  String get fieldCanton => 'Cantone';

  @override
  String get fieldPhoneNumber => 'Numero di telefono';

  @override
  String get greetingMorning => 'Buongiorno';

  @override
  String get greetingAfternoon => 'Buon pomeriggio';

  @override
  String get greetingEvening => 'Buonasera';

  @override
  String get machineOpenStatus => 'Libera';

  @override
  String isTypingText(String name) {
    return '$name sta scrivendo...';
  }

  @override
  String get typeYourMessage => 'Scrivi un messaggio';

  @override
  String get yesterdayLabel => 'Ieri';

  @override
  String sayHelloTo(String name) {
    return 'Saluta $name';
  }

  @override
  String messageHint(String name) {
    return 'Messaggio a $name';
  }

  @override
  String get nudgeButtonTooltip => 'Promemoria rapido';

  @override
  String get nudgeForgotLaundryLabel => 'Bucato dimenticato';

  @override
  String get nudgeForgotLaundryMessage =>
      '🧺 Ciao, sembra che tu abbia dimenticato il bucato in lavatrice!';

  @override
  String get nudgeCleanDetergentLabel => 'Pulisci la vaschetta del detersivo';

  @override
  String get nudgeCleanDetergentMessage =>
      '🧴 Ciao, potresti pulire la vaschetta del detersivo dopo l\'uso?';
}
