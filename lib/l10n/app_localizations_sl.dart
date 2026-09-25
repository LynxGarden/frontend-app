// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Slovenian (`sl`).
class AppLocalizationsSl extends AppLocalizations {
  AppLocalizationsSl([String locale = 'sl']) : super(locale);

  @override
  String get appName => 'Lynx';

  @override
  String get login => 'Prijava';

  @override
  String get logout => 'Odjava';

  @override
  String get loginTitle => 'Prijava v Lynx';

  @override
  String get loginSubtitle =>
      'Člani in trenerji — prijavite se za nadaljevanje.';

  @override
  String get continueWithGoogle => 'Nadaljuj z Google';

  @override
  String get continueWithApple => 'Nadaljuj z Apple';

  @override
  String get orDivider => 'ali';

  @override
  String get emailLabel => 'E-pošta';

  @override
  String get emailHint => 'ti@epošta.si';

  @override
  String get sendMagicLink => 'Pošlji povezavo';

  @override
  String get magicLinkSent => 'Preveri e-pošto za povezavo za prijavo.';

  @override
  String get password => 'Geslo';

  @override
  String get somethingWentWrong => 'Nekaj je šlo narobe. Poskusi znova.';

  @override
  String get finishSetupTitle => 'Še malo';

  @override
  String get finishSetupBody =>
      'Tvoj račun še ni povezan s studiem. Prosi svojega trenerja za povabilo ali se vrni, ko bo nastavljeno.';

  @override
  String get navTrain => 'Trening';

  @override
  String get navProgress => 'Napredek';

  @override
  String get navProfile => 'Profil';

  @override
  String get navClients => 'Stranke';

  @override
  String get navLibrary => 'Knjižnica';

  @override
  String get navReview => 'Pregled';

  @override
  String get trainTitle => 'Tvoj trening';

  @override
  String get progressTitle => 'Napredek';

  @override
  String get profileTitle => 'Profil';

  @override
  String get clientsTitle => 'Stranke';

  @override
  String get libraryTitle => 'Knjižnica';

  @override
  String get reviewTitle => 'Pregled';

  @override
  String get comingSoon => 'Kmalu na voljo';

  @override
  String get settings => 'Nastavitve';

  @override
  String get language => 'Jezik';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSlovenian => 'Slovenščina';

  @override
  String get exercisesEmpty => 'Še ni vaj. Dodaj prvo.';

  @override
  String get newExercise => 'Nova vaja';

  @override
  String get editExercise => 'Uredi vajo';

  @override
  String get exerciseName => 'Ime';

  @override
  String get exerciseNameHint => 'npr. Počep z ročko';

  @override
  String get exerciseDescription => 'Opis';

  @override
  String get exerciseVideoUrl => 'Povezava do videa';

  @override
  String get exerciseVideoUrlHint => 'https://…';

  @override
  String get watchVideo => 'Poglej video';

  @override
  String get searchExercises => 'Išči vaje';

  @override
  String get tags => 'Oznake';

  @override
  String get addTag => 'Dodaj oznako';

  @override
  String get save => 'Shrani';

  @override
  String get delete => 'Izbriši';

  @override
  String get cancel => 'Prekliči';

  @override
  String get deleteExerciseTitle => 'Izbrišem vajo?';

  @override
  String get deleteExerciseBody =>
      'To jo odstrani iz tvoje knjižnice. Tega ni mogoče razveljaviti.';

  @override
  String get filterAll => 'Vse';

  @override
  String get couldNotOpenVideo => 'Povezave do videa ni bilo mogoče odpreti.';

  @override
  String get nameRequired => 'Ime je obvezno';

  @override
  String get catMovement => 'Gib';

  @override
  String get catMuscle => 'Mišica';

  @override
  String get catEquipment => 'Oprema';

  @override
  String get catTempo => 'Tempo';

  @override
  String get catOther => 'Drugo';

  @override
  String get programsTitle => 'Programi';

  @override
  String get programsEmpty => 'Še ni programov. Ustvari prvo predlogo.';

  @override
  String get newProgram => 'Nov program';

  @override
  String get editProgram => 'Uredi program';

  @override
  String get programName => 'Ime programa';

  @override
  String get programNameHint => 'npr. Moč za začetnike';

  @override
  String get sessionsLabel => 'Treningi';

  @override
  String get addSession => 'Dodaj trening';

  @override
  String get sessionLabelHint => 'npr. A1';

  @override
  String get renameSession => 'Preimenuj trening';

  @override
  String get deleteProgramTitle => 'Izbrišem program?';

  @override
  String get deleteProgramBody =>
      'To odstrani program in njegove treninge. Tega ni mogoče razveljaviti.';

  @override
  String sessionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count treningov',
      few: '$count treningi',
      two: '$count treninga',
      one: '1 trening',
      zero: 'Ni treningov',
    );
    return '$_temp0';
  }

  @override
  String exerciseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vaj',
      few: '$count vaje',
      two: '$count vaji',
      one: '1 vaja',
      zero: 'Ni vaj',
    );
    return '$_temp0';
  }

  @override
  String get addExercise => 'Dodaj vajo';

  @override
  String get pickExercise => 'Izberi vajo';

  @override
  String get prescription => 'Predpis';

  @override
  String get presSets => 'Serije';

  @override
  String get presReps => 'Ponovitve';

  @override
  String get presWeight => 'Teža';

  @override
  String get presLoad => 'Obremenitev / intenzivnost';

  @override
  String get presRpe => 'RPE';

  @override
  String get presTime => 'Čas (s)';

  @override
  String get presTempo => 'Tempo';

  @override
  String get presRest => 'Počitek (s)';

  @override
  String get presSetType => 'Opomba o tipu serije';

  @override
  String get presCoachNote => 'Opomba trenerja';

  @override
  String get remove => 'Odstrani';

  @override
  String get done => 'Končaj';

  @override
  String get clientsEmpty => 'Še ni strank. Dodaj prvo.';

  @override
  String get newClient => 'Nova stranka';

  @override
  String get firstName => 'Ime';

  @override
  String get lastName => 'Priimek';

  @override
  String get phone => 'Telefon';

  @override
  String get accountLinked => 'Ima račun v aplikaciji';

  @override
  String get accountNone => 'Vodi osebje (brez prijave)';

  @override
  String get healthFlagsTitle => 'Varnostne oznake';

  @override
  String get addHealthFlag => 'Dodaj oznako';

  @override
  String get noHealthFlags => 'Ni zabeleženih varnostnih oznak.';

  @override
  String get assignmentsTitle => 'Dodeljeni programi';

  @override
  String get assignProgram => 'Dodeli program';

  @override
  String get noAssignments => 'Še ni dodeljenih programov.';

  @override
  String get inviteToApp => 'Povabi v aplikacijo';

  @override
  String get inviteCodeTitle => 'Koda povabila';

  @override
  String get inviteCodeBody =>
      'Deli to kodo s stranko. Ko se prijavi, jo vnese za povezavo računa.';

  @override
  String get flagValue => 'Vrednost';

  @override
  String get flagNotes => 'Opombe';

  @override
  String get haveInviteCode => 'Imaš kodo povabila?';

  @override
  String get enterInviteCode => 'Vnesi kodo povabila';

  @override
  String get continueLabel => 'Nadaljuj';

  @override
  String get hfSmoking => 'Kajenje';

  @override
  String get hfBloodPressure => 'Krvni tlak';

  @override
  String get hfVertigo => 'Vrtoglavica';

  @override
  String get hfMigraines => 'Migrene';

  @override
  String get hfMedications => 'Zdravila';

  @override
  String get hfAllergies => 'Alergije';

  @override
  String get hfAsthma => 'Astma';

  @override
  String get hfOsteoporosis => 'Osteoporoza';

  @override
  String get hfJointPain => 'Bolečine v sklepih';

  @override
  String get hfSpineCondition => 'Stanje hrbtenice';

  @override
  String get hfOther => 'Drugo';

  @override
  String get noProgramAssigned => 'Program še ni dodeljen';

  @override
  String get noProgramAssignedBody =>
      'Tvoj trener ti še ni dodelil programa. Preveri pozneje.';

  @override
  String get offlineTraining =>
      'Nisi povezan. Za trening je potrebna povezava.';

  @override
  String get targetLabel => 'Cilj';

  @override
  String get lastTime => 'Zadnjič';

  @override
  String get noHistoryYet => 'Še ni zgodovine';

  @override
  String get logSet => 'Zabeleži serijo';

  @override
  String get addSet => 'Dodaj serijo';

  @override
  String setN(int n) {
    return 'Serija $n';
  }

  @override
  String get setsLabel => 'Serije';

  @override
  String get repsLabel => 'Ponovitve';

  @override
  String get weightLabel => 'Teža';

  @override
  String get timeSecLabel => 'Čas (s)';

  @override
  String get markComplete => 'Označi kot dokončano';

  @override
  String get completedBadge => 'Dokončano';

  @override
  String get swapExercise => 'Zamenjaj vajo';

  @override
  String get setLoggedToast => 'Serija zabeležena';

  @override
  String get sessionDoneToast => 'Serija zaključena — odlično!';

  @override
  String get exerciseSwappedToast => 'Vaja zamenjana';

  @override
  String get coachNoteLabel => 'Opomba trenerja';

  @override
  String get navGroups => 'Skupine';

  @override
  String get groupsTitle => 'Skupine';

  @override
  String get newGroup => 'Nova skupina';

  @override
  String get groupNameHint => 'npr. Ponedeljkova ekipa';

  @override
  String get create => 'Ustvari';

  @override
  String get view => 'Poglej';

  @override
  String get noGroups => 'Ni skupin';

  @override
  String get members => 'Člani';

  @override
  String get addMember => 'Dodaj člana';

  @override
  String get noMembers => 'Ni članov';

  @override
  String get noClientsToAdd => 'Ni več strank za dodajanje';

  @override
  String memberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count članov',
      few: '$count člani',
      two: '$count člana',
      one: '1 član',
      zero: 'Ni članov',
    );
    return '$_temp0';
  }

  @override
  String groupAssigned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count športnikom',
      few: '$count športnikom',
      two: '$count športnikoma',
      one: '1 športniku',
    );
    return 'Dodeljeno $_temp0';
  }

  @override
  String get deleteGroupTitle => 'Izbriši skupino?';

  @override
  String get deleteGroupBody =>
      'To odstrani skupino in njen seznam. Programi, že dodeljeni članom, ostanejo. Tega ni mogoče razveljaviti.';

  @override
  String get completedSessions => 'Zaključeni treningi';

  @override
  String get reviewEmpty => 'Ni zaključenih treningov';

  @override
  String get noneLogged => 'Nič zabeleženega';
}
