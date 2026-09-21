// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Lynx';

  @override
  String get login => 'Log in';

  @override
  String get logout => 'Log out';

  @override
  String get loginTitle => 'Log in to Lynx';

  @override
  String get loginSubtitle => 'Members and coaches — sign in to continue.';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get continueWithApple => 'Continue with Apple';

  @override
  String get orDivider => 'or';

  @override
  String get emailLabel => 'Email';

  @override
  String get emailHint => 'you@email.com';

  @override
  String get sendMagicLink => 'Send magic link';

  @override
  String get magicLinkSent => 'Check your inbox for a sign-in link.';

  @override
  String get password => 'Password';

  @override
  String get somethingWentWrong => 'Something went wrong. Please try again.';

  @override
  String get finishSetupTitle => 'Almost there';

  @override
  String get finishSetupBody =>
      'Your account isn\'t linked to a studio yet. Ask your coach for an invite, or check back once it\'s set up.';

  @override
  String get navTrain => 'Train';

  @override
  String get navProgress => 'Progress';

  @override
  String get navProfile => 'Profile';

  @override
  String get navClients => 'Clients';

  @override
  String get navLibrary => 'Library';

  @override
  String get navReview => 'Review';

  @override
  String get trainTitle => 'Your training';

  @override
  String get progressTitle => 'Progress';

  @override
  String get profileTitle => 'Profile';

  @override
  String get clientsTitle => 'Clients';

  @override
  String get libraryTitle => 'Library';

  @override
  String get reviewTitle => 'Review';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSlovenian => 'Slovenščina';

  @override
  String get exercisesEmpty => 'No exercises yet. Add your first one.';

  @override
  String get newExercise => 'New exercise';

  @override
  String get editExercise => 'Edit exercise';

  @override
  String get exerciseName => 'Name';

  @override
  String get exerciseNameHint => 'e.g. Back squat';

  @override
  String get exerciseDescription => 'Description';

  @override
  String get exerciseVideoUrl => 'Video link';

  @override
  String get exerciseVideoUrlHint => 'https://…';

  @override
  String get watchVideo => 'Watch video';

  @override
  String get searchExercises => 'Search exercises';

  @override
  String get tags => 'Tags';

  @override
  String get addTag => 'Add tag';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get cancel => 'Cancel';

  @override
  String get deleteExerciseTitle => 'Delete exercise?';

  @override
  String get deleteExerciseBody =>
      'This removes it from your library. This cannot be undone.';

  @override
  String get filterAll => 'All';

  @override
  String get couldNotOpenVideo => 'Could not open the video link.';

  @override
  String get nameRequired => 'Name is required';

  @override
  String get catMovement => 'Movement';

  @override
  String get catMuscle => 'Muscle';

  @override
  String get catEquipment => 'Equipment';

  @override
  String get catTempo => 'Tempo';

  @override
  String get catOther => 'Other';

  @override
  String get programsTitle => 'Programs';

  @override
  String get programsEmpty => 'No programs yet. Create your first template.';

  @override
  String get newProgram => 'New program';

  @override
  String get editProgram => 'Edit program';

  @override
  String get programName => 'Program name';

  @override
  String get programNameHint => 'e.g. Beginner Strength';

  @override
  String get sessionsLabel => 'Sessions';

  @override
  String get addSession => 'Add session';

  @override
  String get sessionLabelHint => 'e.g. A1';

  @override
  String get renameSession => 'Rename session';

  @override
  String get deleteProgramTitle => 'Delete program?';

  @override
  String get deleteProgramBody =>
      'This removes the program and its sessions. This cannot be undone.';

  @override
  String sessionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sessions',
      one: '1 session',
      zero: 'No sessions',
    );
    return '$_temp0';
  }

  @override
  String exerciseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count exercises',
      one: '1 exercise',
      zero: 'No exercises',
    );
    return '$_temp0';
  }

  @override
  String get addExercise => 'Add exercise';

  @override
  String get pickExercise => 'Pick an exercise';

  @override
  String get prescription => 'Prescription';

  @override
  String get presSets => 'Sets';

  @override
  String get presReps => 'Reps';

  @override
  String get presWeight => 'Weight';

  @override
  String get presLoad => 'Load / intensity';

  @override
  String get presRpe => 'RPE';

  @override
  String get presTime => 'Time (s)';

  @override
  String get presTempo => 'Tempo';

  @override
  String get presRest => 'Rest (s)';

  @override
  String get presSetType => 'Set type note';

  @override
  String get presCoachNote => 'Coach note';

  @override
  String get remove => 'Remove';

  @override
  String get done => 'Done';

  @override
  String get clientsEmpty => 'No clients yet. Add your first one.';

  @override
  String get newClient => 'New client';

  @override
  String get firstName => 'First name';

  @override
  String get lastName => 'Last name';

  @override
  String get phone => 'Phone';

  @override
  String get accountLinked => 'Has app account';

  @override
  String get accountNone => 'Managed by staff (no login)';

  @override
  String get healthFlagsTitle => 'Safety flags';

  @override
  String get addHealthFlag => 'Add flag';

  @override
  String get noHealthFlags => 'No safety flags recorded.';

  @override
  String get assignmentsTitle => 'Assigned programs';

  @override
  String get assignProgram => 'Assign program';

  @override
  String get noAssignments => 'No programs assigned yet.';

  @override
  String get inviteToApp => 'Invite to app';

  @override
  String get inviteCodeTitle => 'Invite code';

  @override
  String get inviteCodeBody =>
      'Share this code with the client. After they sign in, they enter it to link their account.';

  @override
  String get flagValue => 'Value';

  @override
  String get flagNotes => 'Notes';

  @override
  String get haveInviteCode => 'Have an invite code?';

  @override
  String get enterInviteCode => 'Enter invite code';

  @override
  String get continueLabel => 'Continue';

  @override
  String get hfSmoking => 'Smoking';

  @override
  String get hfBloodPressure => 'Blood pressure';

  @override
  String get hfVertigo => 'Vertigo';

  @override
  String get hfMigraines => 'Migraines';

  @override
  String get hfMedications => 'Medications';

  @override
  String get hfAllergies => 'Allergies';

  @override
  String get hfAsthma => 'Asthma';

  @override
  String get hfOsteoporosis => 'Osteoporosis';

  @override
  String get hfJointPain => 'Joint pain';

  @override
  String get hfSpineCondition => 'Spine condition';

  @override
  String get hfOther => 'Other';
}
