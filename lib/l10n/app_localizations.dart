import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_sl.dart';

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('sl'),
  ];

  /// Product name
  ///
  /// In en, this message translates to:
  /// **'Lynx'**
  String get appName;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get login;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logout;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Log in to Lynx'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Members and coaches — sign in to continue.'**
  String get loginSubtitle;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @continueWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get continueWithApple;

  /// No description provided for @orDivider.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get orDivider;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'you@email.com'**
  String get emailHint;

  /// No description provided for @firstNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Alex'**
  String get firstNameHint;

  /// No description provided for @lastNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Novak'**
  String get lastNameHint;

  /// No description provided for @phoneHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. +386 40 123 456'**
  String get phoneHint;

  /// No description provided for @sendMagicLink.
  ///
  /// In en, this message translates to:
  /// **'Send magic link'**
  String get sendMagicLink;

  /// No description provided for @magicLinkSent.
  ///
  /// In en, this message translates to:
  /// **'Check your inbox for a sign-in link.'**
  String get magicLinkSent;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get somethingWentWrong;

  /// No description provided for @finishSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Almost there'**
  String get finishSetupTitle;

  /// No description provided for @finishSetupBody.
  ///
  /// In en, this message translates to:
  /// **'Your account isn\'t linked to a studio yet. Ask your coach for an invite, or check back once it\'s set up.'**
  String get finishSetupBody;

  /// No description provided for @navTrain.
  ///
  /// In en, this message translates to:
  /// **'Train'**
  String get navTrain;

  /// No description provided for @navProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get navProgress;

  /// No description provided for @navChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get navChat;

  /// No description provided for @chatTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chatTitle;

  /// No description provided for @openChat.
  ///
  /// In en, this message translates to:
  /// **'Open chat'**
  String get openChat;

  /// No description provided for @noMessagesYet.
  ///
  /// In en, this message translates to:
  /// **'No messages yet. Say hi 👋'**
  String get noMessagesYet;

  /// No description provided for @typing.
  ///
  /// In en, this message translates to:
  /// **'typing…'**
  String get typing;

  /// No description provided for @messagePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Message…'**
  String get messagePlaceholder;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @chatNoCoach.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have a coach assigned yet.'**
  String get chatNoCoach;

  /// No description provided for @careTeam.
  ///
  /// In en, this message translates to:
  /// **'Care team'**
  String get careTeam;

  /// No description provided for @assignStaff.
  ///
  /// In en, this message translates to:
  /// **'Assign staff'**
  String get assignStaff;

  /// No description provided for @noCareTeam.
  ///
  /// In en, this message translates to:
  /// **'No staff assigned yet.'**
  String get noCareTeam;

  /// No description provided for @seeNewMessages.
  ///
  /// In en, this message translates to:
  /// **'See new messages'**
  String get seeNewMessages;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @navClients.
  ///
  /// In en, this message translates to:
  /// **'Clients'**
  String get navClients;

  /// No description provided for @navLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get navLibrary;

  /// No description provided for @navReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get navReview;

  /// No description provided for @trainTitle.
  ///
  /// In en, this message translates to:
  /// **'Your training'**
  String get trainTitle;

  /// No description provided for @progressTitle.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progressTitle;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @clientsTitle.
  ///
  /// In en, this message translates to:
  /// **'Clients'**
  String get clientsTitle;

  /// No description provided for @libraryTitle.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get libraryTitle;

  /// No description provided for @reviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get reviewTitle;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @sessionsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No sessions added yet. Add your first session.'**
  String get sessionsEmpty;

  /// No description provided for @sessionExercisesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No exercises added yet. Add your first exercise.'**
  String get sessionExercisesEmpty;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageSlovenian.
  ///
  /// In en, this message translates to:
  /// **'Slovenščina'**
  String get languageSlovenian;

  /// No description provided for @exercisesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No exercises yet. Add your first one.'**
  String get exercisesEmpty;

  /// No description provided for @newExercise.
  ///
  /// In en, this message translates to:
  /// **'New exercise'**
  String get newExercise;

  /// No description provided for @editExercise.
  ///
  /// In en, this message translates to:
  /// **'Edit exercise'**
  String get editExercise;

  /// No description provided for @exerciseName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get exerciseName;

  /// No description provided for @exerciseNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Back squat'**
  String get exerciseNameHint;

  /// No description provided for @exerciseDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get exerciseDescription;

  /// No description provided for @exerciseVideoUrl.
  ///
  /// In en, this message translates to:
  /// **'Video link'**
  String get exerciseVideoUrl;

  /// No description provided for @exerciseVideoUrlHint.
  ///
  /// In en, this message translates to:
  /// **'https://…'**
  String get exerciseVideoUrlHint;

  /// No description provided for @watchVideo.
  ///
  /// In en, this message translates to:
  /// **'Watch video'**
  String get watchVideo;

  /// No description provided for @searchExercises.
  ///
  /// In en, this message translates to:
  /// **'Search exercises'**
  String get searchExercises;

  /// No description provided for @tags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tags;

  /// No description provided for @addTag.
  ///
  /// In en, this message translates to:
  /// **'Add tag'**
  String get addTag;

  /// No description provided for @tagName.
  ///
  /// In en, this message translates to:
  /// **'Tag name'**
  String get tagName;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @profileSettings.
  ///
  /// In en, this message translates to:
  /// **'Profile settings'**
  String get profileSettings;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get lastName;

  /// No description provided for @dateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get dateOfBirth;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @avatar.
  ///
  /// In en, this message translates to:
  /// **'Avatar'**
  String get avatar;

  /// No description provided for @chooseAvatar.
  ///
  /// In en, this message translates to:
  /// **'Choose profile picture'**
  String get chooseAvatar;

  /// No description provided for @buildAvatar.
  ///
  /// In en, this message translates to:
  /// **'Build avatar'**
  String get buildAvatar;

  /// No description provided for @editAvatar.
  ///
  /// In en, this message translates to:
  /// **'Edit avatar'**
  String get editAvatar;

  /// No description provided for @uploadPhoto.
  ///
  /// In en, this message translates to:
  /// **'Upload photo'**
  String get uploadPhoto;

  /// No description provided for @removePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removePhoto;

  /// No description provided for @shuffle.
  ///
  /// In en, this message translates to:
  /// **'Shuffle'**
  String get shuffle;

  /// No description provided for @saveAvatar.
  ///
  /// In en, this message translates to:
  /// **'Save avatar'**
  String get saveAvatar;

  /// No description provided for @avNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get avNone;

  /// No description provided for @avHair.
  ///
  /// In en, this message translates to:
  /// **'Hair'**
  String get avHair;

  /// No description provided for @avEyes.
  ///
  /// In en, this message translates to:
  /// **'Eyes'**
  String get avEyes;

  /// No description provided for @avEyebrows.
  ///
  /// In en, this message translates to:
  /// **'Eyebrows'**
  String get avEyebrows;

  /// No description provided for @avMouth.
  ///
  /// In en, this message translates to:
  /// **'Mouth'**
  String get avMouth;

  /// No description provided for @avNose.
  ///
  /// In en, this message translates to:
  /// **'Nose'**
  String get avNose;

  /// No description provided for @avGlasses.
  ///
  /// In en, this message translates to:
  /// **'Glasses'**
  String get avGlasses;

  /// No description provided for @avBeard.
  ///
  /// In en, this message translates to:
  /// **'Beard'**
  String get avBeard;

  /// No description provided for @avClothing.
  ///
  /// In en, this message translates to:
  /// **'Clothing'**
  String get avClothing;

  /// No description provided for @avGender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get avGender;

  /// No description provided for @genderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get genderMale;

  /// No description provided for @genderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get genderFemale;

  /// No description provided for @onboardingNameTitle.
  ///
  /// In en, this message translates to:
  /// **'What\'s your name?'**
  String get onboardingNameTitle;

  /// No description provided for @onboardingNameSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This is how you\'ll appear to your coach.'**
  String get onboardingNameSubtitle;

  /// No description provided for @onboardingNameSubtitleStaff.
  ///
  /// In en, this message translates to:
  /// **'This is how you\'ll appear to your clients.'**
  String get onboardingNameSubtitleStaff;

  /// No description provided for @onboardingAvatarTitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a profile picture'**
  String get onboardingAvatarTitle;

  /// No description provided for @onboardingAvatarSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Build one or upload a photo. You can change it anytime.'**
  String get onboardingAvatarSubtitle;

  /// No description provided for @onboardingDobTitle.
  ///
  /// In en, this message translates to:
  /// **'Your date of birth'**
  String get onboardingDobTitle;

  /// No description provided for @onboardingDobSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Optional — helps your coach tailor your training.'**
  String get onboardingDobSubtitle;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @deleteExerciseTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete exercise?'**
  String get deleteExerciseTitle;

  /// No description provided for @deleteExerciseBody.
  ///
  /// In en, this message translates to:
  /// **'This removes it from your library. This cannot be undone.'**
  String get deleteExerciseBody;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @couldNotOpenVideo.
  ///
  /// In en, this message translates to:
  /// **'Could not open the video link.'**
  String get couldNotOpenVideo;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameRequired;

  /// No description provided for @catMovement.
  ///
  /// In en, this message translates to:
  /// **'Movement'**
  String get catMovement;

  /// No description provided for @catMuscle.
  ///
  /// In en, this message translates to:
  /// **'Muscle'**
  String get catMuscle;

  /// No description provided for @catEquipment.
  ///
  /// In en, this message translates to:
  /// **'Equipment'**
  String get catEquipment;

  /// No description provided for @catTempo.
  ///
  /// In en, this message translates to:
  /// **'Tempo'**
  String get catTempo;

  /// No description provided for @catOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get catOther;

  /// No description provided for @programsTitle.
  ///
  /// In en, this message translates to:
  /// **'Programs'**
  String get programsTitle;

  /// No description provided for @programsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No programs yet. Create your first template.'**
  String get programsEmpty;

  /// No description provided for @newProgram.
  ///
  /// In en, this message translates to:
  /// **'New program'**
  String get newProgram;

  /// No description provided for @editProgram.
  ///
  /// In en, this message translates to:
  /// **'Edit program'**
  String get editProgram;

  /// No description provided for @programSaved.
  ///
  /// In en, this message translates to:
  /// **'Program saved'**
  String get programSaved;

  /// No description provided for @programName.
  ///
  /// In en, this message translates to:
  /// **'Program name'**
  String get programName;

  /// No description provided for @programNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Beginner Strength'**
  String get programNameHint;

  /// No description provided for @sessionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get sessionsLabel;

  /// No description provided for @addSession.
  ///
  /// In en, this message translates to:
  /// **'Add session'**
  String get addSession;

  /// No description provided for @sessionLabelHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. A1'**
  String get sessionLabelHint;

  /// No description provided for @renameSession.
  ///
  /// In en, this message translates to:
  /// **'Rename session'**
  String get renameSession;

  /// No description provided for @deleteProgramTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete program?'**
  String get deleteProgramTitle;

  /// No description provided for @deleteProgramBody.
  ///
  /// In en, this message translates to:
  /// **'This removes the program and its sessions. This cannot be undone.'**
  String get deleteProgramBody;

  /// No description provided for @sessionCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No sessions} =1{1 session} other{{count} sessions}}'**
  String sessionCount(int count);

  /// No description provided for @exerciseCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No exercises} =1{1 exercise} other{{count} exercises}}'**
  String exerciseCount(int count);

  /// No description provided for @addExercise.
  ///
  /// In en, this message translates to:
  /// **'Add exercise'**
  String get addExercise;

  /// No description provided for @pickExercise.
  ///
  /// In en, this message translates to:
  /// **'Pick an exercise'**
  String get pickExercise;

  /// No description provided for @prescription.
  ///
  /// In en, this message translates to:
  /// **'Prescription'**
  String get prescription;

  /// No description provided for @noMetricFields.
  ///
  /// In en, this message translates to:
  /// **'This exercise has no custom fields. Add some in the exercise, or pick a method above.'**
  String get noMetricFields;

  /// No description provided for @presSets.
  ///
  /// In en, this message translates to:
  /// **'Sets'**
  String get presSets;

  /// No description provided for @presReps.
  ///
  /// In en, this message translates to:
  /// **'Reps'**
  String get presReps;

  /// No description provided for @presWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get presWeight;

  /// No description provided for @presLoad.
  ///
  /// In en, this message translates to:
  /// **'Load / intensity'**
  String get presLoad;

  /// No description provided for @presRpe.
  ///
  /// In en, this message translates to:
  /// **'RPE'**
  String get presRpe;

  /// No description provided for @presTime.
  ///
  /// In en, this message translates to:
  /// **'Time (s)'**
  String get presTime;

  /// No description provided for @presTempo.
  ///
  /// In en, this message translates to:
  /// **'Tempo'**
  String get presTempo;

  /// No description provided for @presRest.
  ///
  /// In en, this message translates to:
  /// **'Rest (s)'**
  String get presRest;

  /// No description provided for @presSetType.
  ///
  /// In en, this message translates to:
  /// **'Set type note'**
  String get presSetType;

  /// No description provided for @presCoachNote.
  ///
  /// In en, this message translates to:
  /// **'Coach note'**
  String get presCoachNote;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @clientsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No clients yet. Add your first one.'**
  String get clientsEmpty;

  /// No description provided for @newClient.
  ///
  /// In en, this message translates to:
  /// **'New client'**
  String get newClient;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @accountLinked.
  ///
  /// In en, this message translates to:
  /// **'Has app account'**
  String get accountLinked;

  /// No description provided for @accountNone.
  ///
  /// In en, this message translates to:
  /// **'Managed by staff (no login)'**
  String get accountNone;

  /// No description provided for @healthFlagsTitle.
  ///
  /// In en, this message translates to:
  /// **'Safety flags'**
  String get healthFlagsTitle;

  /// No description provided for @addHealthFlag.
  ///
  /// In en, this message translates to:
  /// **'Add flag'**
  String get addHealthFlag;

  /// No description provided for @noHealthFlags.
  ///
  /// In en, this message translates to:
  /// **'No safety flags recorded.'**
  String get noHealthFlags;

  /// No description provided for @assignmentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Assigned programs'**
  String get assignmentsTitle;

  /// No description provided for @assignProgram.
  ///
  /// In en, this message translates to:
  /// **'Assign program'**
  String get assignProgram;

  /// No description provided for @noAssignments.
  ///
  /// In en, this message translates to:
  /// **'No programs assigned yet.'**
  String get noAssignments;

  /// No description provided for @pushLatest.
  ///
  /// In en, this message translates to:
  /// **'Push latest'**
  String get pushLatest;

  /// No description provided for @assignmentSynced.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Added 1 session} other{Added {count} sessions}}'**
  String assignmentSynced(int count);

  /// No description provided for @assignmentUpToDate.
  ///
  /// In en, this message translates to:
  /// **'Already up to date'**
  String get assignmentUpToDate;

  /// No description provided for @inviteToApp.
  ///
  /// In en, this message translates to:
  /// **'Invite to app'**
  String get inviteToApp;

  /// No description provided for @inviteCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Invite code'**
  String get inviteCodeTitle;

  /// No description provided for @inviteCodeBody.
  ///
  /// In en, this message translates to:
  /// **'Share this code with the client. After they sign in, they enter it to link their account.'**
  String get inviteCodeBody;

  /// No description provided for @flagValue.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get flagValue;

  /// No description provided for @flagNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get flagNotes;

  /// No description provided for @haveInviteCode.
  ///
  /// In en, this message translates to:
  /// **'Have an invite code?'**
  String get haveInviteCode;

  /// No description provided for @enterInviteCode.
  ///
  /// In en, this message translates to:
  /// **'Enter invite code'**
  String get enterInviteCode;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @hfSmoking.
  ///
  /// In en, this message translates to:
  /// **'Smoking'**
  String get hfSmoking;

  /// No description provided for @hfBloodPressure.
  ///
  /// In en, this message translates to:
  /// **'Blood pressure'**
  String get hfBloodPressure;

  /// No description provided for @hfVertigo.
  ///
  /// In en, this message translates to:
  /// **'Vertigo'**
  String get hfVertigo;

  /// No description provided for @hfMigraines.
  ///
  /// In en, this message translates to:
  /// **'Migraines'**
  String get hfMigraines;

  /// No description provided for @hfMedications.
  ///
  /// In en, this message translates to:
  /// **'Medications'**
  String get hfMedications;

  /// No description provided for @hfAllergies.
  ///
  /// In en, this message translates to:
  /// **'Allergies'**
  String get hfAllergies;

  /// No description provided for @hfAsthma.
  ///
  /// In en, this message translates to:
  /// **'Asthma'**
  String get hfAsthma;

  /// No description provided for @hfOsteoporosis.
  ///
  /// In en, this message translates to:
  /// **'Osteoporosis'**
  String get hfOsteoporosis;

  /// No description provided for @hfJointPain.
  ///
  /// In en, this message translates to:
  /// **'Joint pain'**
  String get hfJointPain;

  /// No description provided for @hfSpineCondition.
  ///
  /// In en, this message translates to:
  /// **'Spine condition'**
  String get hfSpineCondition;

  /// No description provided for @hfOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get hfOther;

  /// No description provided for @noProgramAssigned.
  ///
  /// In en, this message translates to:
  /// **'No program assigned yet'**
  String get noProgramAssigned;

  /// No description provided for @noProgramAssignedBody.
  ///
  /// In en, this message translates to:
  /// **'Your coach hasn\'t assigned a program yet. Check back soon.'**
  String get noProgramAssignedBody;

  /// No description provided for @offlineTraining.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Training needs a connection.'**
  String get offlineTraining;

  /// No description provided for @targetLabel.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get targetLabel;

  /// No description provided for @lastTime.
  ///
  /// In en, this message translates to:
  /// **'Last time'**
  String get lastTime;

  /// No description provided for @noHistoryYet.
  ///
  /// In en, this message translates to:
  /// **'No history yet'**
  String get noHistoryYet;

  /// No description provided for @logSet.
  ///
  /// In en, this message translates to:
  /// **'Log set'**
  String get logSet;

  /// No description provided for @addSet.
  ///
  /// In en, this message translates to:
  /// **'Add set'**
  String get addSet;

  /// No description provided for @setN.
  ///
  /// In en, this message translates to:
  /// **'Set {n}'**
  String setN(int n);

  /// No description provided for @setsLabel.
  ///
  /// In en, this message translates to:
  /// **'Sets'**
  String get setsLabel;

  /// No description provided for @repsLabel.
  ///
  /// In en, this message translates to:
  /// **'Reps'**
  String get repsLabel;

  /// No description provided for @weightLabel.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weightLabel;

  /// No description provided for @timeSecLabel.
  ///
  /// In en, this message translates to:
  /// **'Time (s)'**
  String get timeSecLabel;

  /// No description provided for @markComplete.
  ///
  /// In en, this message translates to:
  /// **'Mark complete'**
  String get markComplete;

  /// No description provided for @finishSessionTitle.
  ///
  /// In en, this message translates to:
  /// **'Finish session'**
  String get finishSessionTitle;

  /// No description provided for @finishSessionBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ve reached the end. Mark the session complete when you\'re done.'**
  String get finishSessionBody;

  /// No description provided for @exerciseCounter.
  ///
  /// In en, this message translates to:
  /// **'{current} of {total}'**
  String exerciseCounter(int current, int total);

  /// No description provided for @completedBadge.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completedBadge;

  /// No description provided for @swapExercise.
  ///
  /// In en, this message translates to:
  /// **'Swap exercise'**
  String get swapExercise;

  /// No description provided for @setLoggedToast.
  ///
  /// In en, this message translates to:
  /// **'Set logged'**
  String get setLoggedToast;

  /// No description provided for @sessionDoneToast.
  ///
  /// In en, this message translates to:
  /// **'Session complete — great work!'**
  String get sessionDoneToast;

  /// No description provided for @exerciseSwappedToast.
  ///
  /// In en, this message translates to:
  /// **'Exercise swapped'**
  String get exerciseSwappedToast;

  /// No description provided for @coachNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Coach note'**
  String get coachNoteLabel;

  /// No description provided for @navGroups.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get navGroups;

  /// No description provided for @groupsTitle.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get groupsTitle;

  /// No description provided for @newGroup.
  ///
  /// In en, this message translates to:
  /// **'New group'**
  String get newGroup;

  /// No description provided for @groupNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Monday Squad'**
  String get groupNameHint;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @noGroups.
  ///
  /// In en, this message translates to:
  /// **'No groups yet'**
  String get noGroups;

  /// No description provided for @members.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get members;

  /// No description provided for @addMember.
  ///
  /// In en, this message translates to:
  /// **'Add member'**
  String get addMember;

  /// No description provided for @noMembers.
  ///
  /// In en, this message translates to:
  /// **'No members yet'**
  String get noMembers;

  /// No description provided for @noClientsToAdd.
  ///
  /// In en, this message translates to:
  /// **'No more clients to add'**
  String get noClientsToAdd;

  /// No description provided for @memberCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No members} =1{1 member} other{{count} members}}'**
  String memberCount(int count);

  /// No description provided for @groupAssigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned to {count, plural, =1{1 athlete} other{{count} athletes}}'**
  String groupAssigned(int count);

  /// No description provided for @deleteGroupTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete group?'**
  String get deleteGroupTitle;

  /// No description provided for @deleteGroupBody.
  ///
  /// In en, this message translates to:
  /// **'This removes the group and its roster. Assigned programs already sent to members are kept. This cannot be undone.'**
  String get deleteGroupBody;

  /// No description provided for @completedSessions.
  ///
  /// In en, this message translates to:
  /// **'Completed sessions'**
  String get completedSessions;

  /// No description provided for @reviewEmpty.
  ///
  /// In en, this message translates to:
  /// **'No completed sessions yet'**
  String get reviewEmpty;

  /// No description provided for @noneLogged.
  ///
  /// In en, this message translates to:
  /// **'Nothing logged'**
  String get noneLogged;

  /// No description provided for @sendCode.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get sendCode;

  /// No description provided for @codeLabel.
  ///
  /// In en, this message translates to:
  /// **'6-digit code'**
  String get codeLabel;

  /// No description provided for @verifyCode.
  ///
  /// In en, this message translates to:
  /// **'Verify & continue'**
  String get verifyCode;

  /// No description provided for @changeEmail.
  ///
  /// In en, this message translates to:
  /// **'Use a different email'**
  String get changeEmail;

  /// No description provided for @codeSentTo.
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit code to {email}'**
  String codeSentTo(String email);

  /// No description provided for @demoVideo.
  ///
  /// In en, this message translates to:
  /// **'Demo video'**
  String get demoVideo;

  /// No description provided for @uploadVideo.
  ///
  /// In en, this message translates to:
  /// **'Upload video'**
  String get uploadVideo;

  /// No description provided for @videoUploaded.
  ///
  /// In en, this message translates to:
  /// **'Video uploaded'**
  String get videoUploaded;

  /// No description provided for @thumbnail.
  ///
  /// In en, this message translates to:
  /// **'Thumbnail'**
  String get thumbnail;

  /// No description provided for @addThumbnail.
  ///
  /// In en, this message translates to:
  /// **'Add thumbnail'**
  String get addThumbnail;

  /// No description provided for @changeThumbnail.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get changeThumbnail;

  /// No description provided for @thumbnailRequired.
  ///
  /// In en, this message translates to:
  /// **'A thumbnail is required.'**
  String get thumbnailRequired;

  /// No description provided for @thumbnailHint.
  ///
  /// In en, this message translates to:
  /// **'Tap to add a cover image'**
  String get thumbnailHint;

  /// No description provided for @welcomeTagline.
  ///
  /// In en, this message translates to:
  /// **'Train. Log. Progress.'**
  String get welcomeTagline;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your training and physio, in one place.'**
  String get welcomeSubtitle;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get getStarted;

  /// No description provided for @welcomeTerms.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to our Terms of Service and Privacy Policy.'**
  String get welcomeTerms;

  /// No description provided for @loginHeading.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get loginHeading;

  /// No description provided for @loginHeadingSub.
  ///
  /// In en, this message translates to:
  /// **'Log in to continue.'**
  String get loginHeadingSub;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get passwordHint;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @noAccountPrompt.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get noAccountPrompt;

  /// No description provided for @signUpLink.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUpLink;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// No description provided for @incorrectCredentials.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password.'**
  String get incorrectCredentials;

  /// No description provided for @signupTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get signupTitle;

  /// No description provided for @signupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Let\'s get you set up.'**
  String get signupSubtitle;

  /// No description provided for @createPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Create a password'**
  String get createPasswordHint;

  /// No description provided for @repeatPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Repeat password'**
  String get repeatPasswordLabel;

  /// No description provided for @repeatPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Confirm your password'**
  String get repeatPasswordHint;

  /// No description provided for @passwordsDontMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords don\'t match.'**
  String get passwordsDontMatch;

  /// No description provided for @emailInUse.
  ///
  /// In en, this message translates to:
  /// **'An account with this email already exists.'**
  String get emailInUse;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get alreadyHaveAccount;

  /// No description provided for @createAccountButton.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccountButton;

  /// No description provided for @verifyEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your email'**
  String get verifyEmailTitle;

  /// No description provided for @verifyEmailBody.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code we sent to {email}.'**
  String verifyEmailBody(String email);

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get resendCode;

  /// No description provided for @codeResent.
  ///
  /// In en, this message translates to:
  /// **'We sent a new code.'**
  String get codeResent;

  /// No description provided for @forgotTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotTitle;

  /// No description provided for @forgotBody.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and we\'ll send you a reset code.'**
  String get forgotBody;

  /// No description provided for @sendResetCode.
  ///
  /// In en, this message translates to:
  /// **'Send reset code'**
  String get sendResetCode;

  /// No description provided for @resetTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get resetTitle;

  /// No description provided for @resetCodeBody.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code we sent to {email}, then choose a new password.'**
  String resetCodeBody(String email);

  /// No description provided for @newPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPasswordLabel;

  /// No description provided for @resetSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password updated. Please log in.'**
  String get resetSuccess;

  /// No description provided for @backToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to log in'**
  String get backToLogin;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @secProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get secProfile;

  /// No description provided for @secGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get secGeneral;

  /// No description provided for @secSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get secSecurity;

  /// No description provided for @secAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get secAccount;

  /// No description provided for @roleLabel.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get roleLabel;

  /// No description provided for @roleOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get roleOwner;

  /// No description provided for @roleCoach.
  ///
  /// In en, this message translates to:
  /// **'Coach'**
  String get roleCoach;

  /// No description provided for @rolePhysio.
  ///
  /// In en, this message translates to:
  /// **'Physio'**
  String get rolePhysio;

  /// No description provided for @roleClient.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get roleClient;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePassword;

  /// No description provided for @logoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get logoutTitle;

  /// No description provided for @logoutBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ll need to sign in again to use the app.'**
  String get logoutBody;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account?'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountBody.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes your account and all your data. This cannot be undone.'**
  String get deleteAccountBody;

  /// No description provided for @accountDeleted.
  ///
  /// In en, this message translates to:
  /// **'Your account was deleted.'**
  String get accountDeleted;

  /// No description provided for @couldNotDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Could not delete your account. Please try again.'**
  String get couldNotDeleteAccount;

  /// No description provided for @navPrograms.
  ///
  /// In en, this message translates to:
  /// **'Programs'**
  String get navPrograms;

  /// No description provided for @allExercises.
  ///
  /// In en, this message translates to:
  /// **'All exercises'**
  String get allExercises;

  /// No description provided for @viewAsList.
  ///
  /// In en, this message translates to:
  /// **'List view'**
  String get viewAsList;

  /// No description provided for @viewAsGrid.
  ///
  /// In en, this message translates to:
  /// **'Grid view'**
  String get viewAsGrid;

  /// No description provided for @phasesLabel.
  ///
  /// In en, this message translates to:
  /// **'Phases'**
  String get phasesLabel;

  /// No description provided for @addPhase.
  ///
  /// In en, this message translates to:
  /// **'Add phase'**
  String get addPhase;

  /// No description provided for @renamePhase.
  ///
  /// In en, this message translates to:
  /// **'Rename phase'**
  String get renamePhase;

  /// No description provided for @phaseName.
  ///
  /// In en, this message translates to:
  /// **'Phase name'**
  String get phaseName;

  /// No description provided for @phaseNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Phase 1'**
  String get phaseNameHint;

  /// No description provided for @phasesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No phases yet. Add your first phase.'**
  String get phasesEmpty;

  /// No description provided for @deletePhaseTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete phase?'**
  String get deletePhaseTitle;

  /// No description provided for @deletePhaseBody.
  ///
  /// In en, this message translates to:
  /// **'This removes the phase and its sessions. This cannot be undone.'**
  String get deletePhaseBody;

  /// No description provided for @phaseCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No phases} =1{1 phase} other{{count} phases}}'**
  String phaseCount(int count);

  /// No description provided for @editSession.
  ///
  /// In en, this message translates to:
  /// **'Edit session'**
  String get editSession;

  /// No description provided for @duplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get duplicate;

  /// No description provided for @duplicateProgram.
  ///
  /// In en, this message translates to:
  /// **'Duplicate program'**
  String get duplicateProgram;

  /// No description provided for @deleteSessionTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete session?'**
  String get deleteSessionTitle;

  /// No description provided for @deleteSessionBody.
  ///
  /// In en, this message translates to:
  /// **'This removes the session and its exercises. This cannot be undone.'**
  String get deleteSessionBody;

  /// No description provided for @duplicatedToast.
  ///
  /// In en, this message translates to:
  /// **'Duplicated'**
  String get duplicatedToast;

  /// No description provided for @movement.
  ///
  /// In en, this message translates to:
  /// **'Movement'**
  String get movement;

  /// No description provided for @movementRequired.
  ///
  /// In en, this message translates to:
  /// **'Pick at least one movement.'**
  String get movementRequired;

  /// No description provided for @movementStrength.
  ///
  /// In en, this message translates to:
  /// **'Strength'**
  String get movementStrength;

  /// No description provided for @movementHypertrophy.
  ///
  /// In en, this message translates to:
  /// **'Hypertrophy'**
  String get movementHypertrophy;

  /// No description provided for @movementPower.
  ///
  /// In en, this message translates to:
  /// **'Power'**
  String get movementPower;

  /// No description provided for @movementPlyometric.
  ///
  /// In en, this message translates to:
  /// **'Plyometric'**
  String get movementPlyometric;

  /// No description provided for @movementCardio.
  ///
  /// In en, this message translates to:
  /// **'Cardio'**
  String get movementCardio;

  /// No description provided for @movementMobility.
  ///
  /// In en, this message translates to:
  /// **'Mobility'**
  String get movementMobility;

  /// No description provided for @movementRehab.
  ///
  /// In en, this message translates to:
  /// **'Rehab'**
  String get movementRehab;

  /// No description provided for @movementWarmup.
  ///
  /// In en, this message translates to:
  /// **'Warm-up'**
  String get movementWarmup;

  /// No description provided for @loggingFields.
  ///
  /// In en, this message translates to:
  /// **'Logging fields'**
  String get loggingFields;

  /// No description provided for @loggingFieldsHint.
  ///
  /// In en, this message translates to:
  /// **'What the client logs for this exercise.'**
  String get loggingFieldsHint;

  /// No description provided for @noLoggingFields.
  ///
  /// In en, this message translates to:
  /// **'No custom fields — the client logs reps & weight.'**
  String get noLoggingFields;

  /// No description provided for @addField.
  ///
  /// In en, this message translates to:
  /// **'Add field'**
  String get addField;

  /// No description provided for @fieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get fieldLabel;

  /// No description provided for @fieldLabelHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Weight, Pace, Incline'**
  String get fieldLabelHint;

  /// No description provided for @fieldType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get fieldType;

  /// No description provided for @fieldUnit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get fieldUnit;

  /// No description provided for @fieldUnitHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. kg, km/h, %, cm'**
  String get fieldUnitHint;

  /// No description provided for @fieldOptions.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get fieldOptions;

  /// No description provided for @fieldOptionsHint.
  ///
  /// In en, this message translates to:
  /// **'Comma-separated'**
  String get fieldOptionsHint;

  /// No description provided for @fieldIntensity.
  ///
  /// In en, this message translates to:
  /// **'Intensity unit'**
  String get fieldIntensity;

  /// No description provided for @metricTypeNumber.
  ///
  /// In en, this message translates to:
  /// **'Number'**
  String get metricTypeNumber;

  /// No description provided for @metricTypeDecimal.
  ///
  /// In en, this message translates to:
  /// **'Decimal'**
  String get metricTypeDecimal;

  /// No description provided for @metricTypeDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get metricTypeDuration;

  /// No description provided for @metricTypeText.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get metricTypeText;

  /// No description provided for @metricTypeEnum.
  ///
  /// In en, this message translates to:
  /// **'Choice'**
  String get metricTypeEnum;

  /// No description provided for @intensityNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get intensityNone;

  /// No description provided for @trainingMethod.
  ///
  /// In en, this message translates to:
  /// **'Method'**
  String get trainingMethod;

  /// No description provided for @methodNeedsMultiple.
  ///
  /// In en, this message translates to:
  /// **'This method needs 2 or more exercises.'**
  String get methodNeedsMultiple;

  /// No description provided for @addToGroup.
  ///
  /// In en, this message translates to:
  /// **'Add exercise to group'**
  String get addToGroup;

  /// No description provided for @methodNone.
  ///
  /// In en, this message translates to:
  /// **'No method'**
  String get methodNone;

  /// No description provided for @methodStraight.
  ///
  /// In en, this message translates to:
  /// **'Straight sets'**
  String get methodStraight;

  /// No description provided for @methodSuperset.
  ///
  /// In en, this message translates to:
  /// **'Superset'**
  String get methodSuperset;

  /// No description provided for @methodDropset.
  ///
  /// In en, this message translates to:
  /// **'Drop set'**
  String get methodDropset;

  /// No description provided for @methodMechanicalDropset.
  ///
  /// In en, this message translates to:
  /// **'Mechanical drop set'**
  String get methodMechanicalDropset;

  /// No description provided for @methodMyo.
  ///
  /// In en, this message translates to:
  /// **'Myo reps'**
  String get methodMyo;

  /// No description provided for @methodMyoMatch.
  ///
  /// In en, this message translates to:
  /// **'Myo-match reps'**
  String get methodMyoMatch;

  /// No description provided for @methodEmom.
  ///
  /// In en, this message translates to:
  /// **'EMOM'**
  String get methodEmom;

  /// No description provided for @methodE2mom.
  ///
  /// In en, this message translates to:
  /// **'E2MOM'**
  String get methodE2mom;

  /// No description provided for @methodE3mom.
  ///
  /// In en, this message translates to:
  /// **'E3MOM'**
  String get methodE3mom;

  /// No description provided for @methodRestPause.
  ///
  /// In en, this message translates to:
  /// **'Rest-pause'**
  String get methodRestPause;

  /// No description provided for @methodRamp.
  ///
  /// In en, this message translates to:
  /// **'Ramp'**
  String get methodRamp;

  /// No description provided for @methodBackOff.
  ///
  /// In en, this message translates to:
  /// **'Back-off'**
  String get methodBackOff;

  /// No description provided for @methodCluster.
  ///
  /// In en, this message translates to:
  /// **'Cluster'**
  String get methodCluster;

  /// No description provided for @methodContrast.
  ///
  /// In en, this message translates to:
  /// **'Contrast / PAP'**
  String get methodContrast;

  /// No description provided for @methodTempo.
  ///
  /// In en, this message translates to:
  /// **'Tempo'**
  String get methodTempo;

  /// No description provided for @methodDescNone.
  ///
  /// In en, this message translates to:
  /// **'Free logging using the exercise\'s own fields'**
  String get methodDescNone;

  /// No description provided for @methodDescStraight.
  ///
  /// In en, this message translates to:
  /// **'Classic sets with full rest between them'**
  String get methodDescStraight;

  /// No description provided for @methodDescSuperset.
  ///
  /// In en, this message translates to:
  /// **'2+ exercises back to back, no rest between them'**
  String get methodDescSuperset;

  /// No description provided for @methodDescDropset.
  ///
  /// In en, this message translates to:
  /// **'3–4 sets of the same exercise, lowering the weight, no rest (10RM → AMRAP @ 90% → AMRAP @ 75%)'**
  String get methodDescDropset;

  /// No description provided for @methodDescMechanicalDropset.
  ///
  /// In en, this message translates to:
  /// **'3–4 different exercises for the same muscle, hardest to easiest, no rest'**
  String get methodDescMechanicalDropset;

  /// No description provided for @methodDescMyo.
  ///
  /// In en, this message translates to:
  /// **'1 pre-fatigue set of 10–15 reps, then 4 × 3–5 reps with 15 s rests — all at the same weight'**
  String get methodDescMyo;

  /// No description provided for @methodDescMyoMatch.
  ///
  /// In en, this message translates to:
  /// **'3 sets matching the same rep count, with short 10 s intra-set pauses; 120 s between sets'**
  String get methodDescMyoMatch;

  /// No description provided for @methodDescEmom.
  ///
  /// In en, this message translates to:
  /// **'Start a set every full minute — the reps dictate the rest'**
  String get methodDescEmom;

  /// No description provided for @methodDescE2mom.
  ///
  /// In en, this message translates to:
  /// **'Start a set every 2 minutes'**
  String get methodDescE2mom;

  /// No description provided for @methodDescE3mom.
  ///
  /// In en, this message translates to:
  /// **'Start a set every 3 minutes'**
  String get methodDescE3mom;

  /// No description provided for @methodDescRestPause.
  ///
  /// In en, this message translates to:
  /// **'1 × 3–10RM, 2–3 min rest, then 4 × AMRAP @ 80% with 20 s rests'**
  String get methodDescRestPause;

  /// No description provided for @methodDescRamp.
  ///
  /// In en, this message translates to:
  /// **'2 exercises for the same muscle group, ramping RPE 4 → 6-7 → 8+'**
  String get methodDescRamp;

  /// No description provided for @methodDescBackOff.
  ///
  /// In en, this message translates to:
  /// **'1 heavy set (3–5 reps), then 3–4 sets @ 80–85% (5–8 reps), 2–3 min rest'**
  String get methodDescBackOff;

  /// No description provided for @methodDescCluster.
  ///
  /// In en, this message translates to:
  /// **'One set broken into mini-clusters, e.g. 3 reps, 20 s pause, then 2 reps'**
  String get methodDescCluster;

  /// No description provided for @methodDescContrast.
  ///
  /// In en, this message translates to:
  /// **'Heavy strength set straight into an explosive exercise, no rest'**
  String get methodDescContrast;

  /// No description provided for @methodDescTempo.
  ///
  /// In en, this message translates to:
  /// **'Controlled tempo work — set the tempo (e.g. 3-1-0-1)'**
  String get methodDescTempo;

  /// No description provided for @chooseMethodFirst.
  ///
  /// In en, this message translates to:
  /// **'Pick the training method, then choose the exercise.'**
  String get chooseMethodFirst;

  /// No description provided for @restNSeconds.
  ///
  /// In en, this message translates to:
  /// **'Rest: {n} s'**
  String restNSeconds(int n);

  /// No description provided for @startTimer.
  ///
  /// In en, this message translates to:
  /// **'Start timer'**
  String get startTimer;

  /// No description provided for @sessionDifficultyTitle.
  ///
  /// In en, this message translates to:
  /// **'How hard was this session?'**
  String get sessionDifficultyTitle;

  /// No description provided for @sessionDifficultyEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get sessionDifficultyEasy;

  /// No description provided for @sessionDifficultyHard.
  ///
  /// In en, this message translates to:
  /// **'Max effort'**
  String get sessionDifficultyHard;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTitle;

  /// No description provided for @nextSession.
  ///
  /// In en, this message translates to:
  /// **'Next session'**
  String get nextSession;

  /// No description provided for @startSession.
  ///
  /// In en, this message translates to:
  /// **'Start session'**
  String get startSession;

  /// No description provided for @homeSessions.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get homeSessions;

  /// No description provided for @healthSection.
  ///
  /// In en, this message translates to:
  /// **'Health & activity'**
  String get healthSection;

  /// No description provided for @seeMore.
  ///
  /// In en, this message translates to:
  /// **'See more'**
  String get seeMore;

  /// No description provided for @stepsToday.
  ///
  /// In en, this message translates to:
  /// **'Steps today'**
  String get stepsToday;

  /// No description provided for @caloriesToday.
  ///
  /// In en, this message translates to:
  /// **'Active kcal'**
  String get caloriesToday;

  /// No description provided for @stepsLast7Days.
  ///
  /// In en, this message translates to:
  /// **'Steps — last 7 days'**
  String get stepsLast7Days;

  /// No description provided for @heartRateToday.
  ///
  /// In en, this message translates to:
  /// **'Heart rate — today'**
  String get heartRateToday;

  /// No description provided for @noHealthData.
  ///
  /// In en, this message translates to:
  /// **'No health data yet. Sync Apple Health or Strava to see your steps, heart rate and calories.'**
  String get noHealthData;

  /// No description provided for @noHeartRateData.
  ///
  /// In en, this message translates to:
  /// **'No heart-rate data today.'**
  String get noHeartRateData;

  /// No description provided for @allSessionsDone.
  ///
  /// In en, this message translates to:
  /// **'All sessions done — train any of them again!'**
  String get allSessionsDone;

  /// No description provided for @stepsLabel.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get stepsLabel;

  /// No description provided for @caloriesLabel.
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get caloriesLabel;

  /// No description provided for @sessionRatingLabel.
  ///
  /// In en, this message translates to:
  /// **'Session difficulty'**
  String get sessionRatingLabel;

  /// No description provided for @weekTag.
  ///
  /// In en, this message translates to:
  /// **'Week tag'**
  String get weekTag;

  /// No description provided for @weekTagHint.
  ///
  /// In en, this message translates to:
  /// **'Coach-only, e.g. Week 1'**
  String get weekTagHint;

  /// No description provided for @presRir.
  ///
  /// In en, this message translates to:
  /// **'RIR'**
  String get presRir;

  /// No description provided for @intervalSeconds.
  ///
  /// In en, this message translates to:
  /// **'Interval (sec)'**
  String get intervalSeconds;

  /// No description provided for @exerciseDetails.
  ///
  /// In en, this message translates to:
  /// **'Exercise'**
  String get exerciseDetails;

  /// No description provided for @timer.
  ///
  /// In en, this message translates to:
  /// **'Timer'**
  String get timer;

  /// No description provided for @timerStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get timerStart;

  /// No description provided for @timerStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get timerStop;

  /// No description provided for @timerReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get timerReset;

  /// No description provided for @myNotes.
  ///
  /// In en, this message translates to:
  /// **'My notes'**
  String get myNotes;

  /// No description provided for @myNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Private notes for this exercise — visible only to you.'**
  String get myNotesHint;

  /// No description provided for @noteSaved.
  ///
  /// In en, this message translates to:
  /// **'Note saved'**
  String get noteSaved;

  /// No description provided for @saveNote.
  ///
  /// In en, this message translates to:
  /// **'Save note'**
  String get saveNote;

  /// No description provided for @noDescription.
  ///
  /// In en, this message translates to:
  /// **'No description.'**
  String get noDescription;

  /// No description provided for @aboutTraining.
  ///
  /// In en, this message translates to:
  /// **'About this training'**
  String get aboutTraining;

  /// No description provided for @progressTitle2.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progressTitle2;

  /// No description provided for @progressStreak.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get progressStreak;

  /// No description provided for @progressThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get progressThisWeek;

  /// No description provided for @progressVisits.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No visits} =1{1 visit} other{{count} visits}}'**
  String progressVisits(int count);

  /// No description provided for @personalBests.
  ///
  /// In en, this message translates to:
  /// **'Personal bests'**
  String get personalBests;

  /// No description provided for @progressVolume.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get progressVolume;

  /// No description provided for @progressResults.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get progressResults;

  /// No description provided for @weeklyVolume.
  ///
  /// In en, this message translates to:
  /// **'Weekly volume'**
  String get weeklyVolume;

  /// No description provided for @bestWeight.
  ///
  /// In en, this message translates to:
  /// **'Best weight'**
  String get bestWeight;

  /// No description provided for @bestReps.
  ///
  /// In en, this message translates to:
  /// **'Best reps'**
  String get bestReps;

  /// No description provided for @bestSeries.
  ///
  /// In en, this message translates to:
  /// **'Best series'**
  String get bestSeries;

  /// No description provided for @bestVolume.
  ///
  /// In en, this message translates to:
  /// **'Best volume'**
  String get bestVolume;

  /// No description provided for @noProgressYet.
  ///
  /// In en, this message translates to:
  /// **'No data yet — log a few sessions to see your progress.'**
  String get noProgressYet;

  /// No description provided for @progressNoExercises.
  ///
  /// In en, this message translates to:
  /// **'Nothing logged yet. Your tracked exercises will appear here.'**
  String get progressNoExercises;

  /// No description provided for @progressPickExercise.
  ///
  /// In en, this message translates to:
  /// **'Pick an exercise'**
  String get progressPickExercise;

  /// No description provided for @navCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get navCalendar;

  /// No description provided for @calendarTitle.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendarTitle;

  /// No description provided for @calendarBook.
  ///
  /// In en, this message translates to:
  /// **'Book'**
  String get calendarBook;

  /// No description provided for @calendarActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get calendarActivity;

  /// No description provided for @calendarHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get calendarHistory;

  /// No description provided for @bookTraining.
  ///
  /// In en, this message translates to:
  /// **'Book training'**
  String get bookTraining;

  /// No description provided for @book.
  ///
  /// In en, this message translates to:
  /// **'Book'**
  String get book;

  /// No description provided for @cancelBooking.
  ///
  /// In en, this message translates to:
  /// **'Cancel booking'**
  String get cancelBooking;

  /// No description provided for @bookedLabel.
  ///
  /// In en, this message translates to:
  /// **'Booked'**
  String get bookedLabel;

  /// No description provided for @slotFull.
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get slotFull;

  /// No description provided for @placesLeft.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Full} =1{1 place left} other{{count} places left}}'**
  String placesLeft(int count);

  /// No description provided for @yourBooking.
  ///
  /// In en, this message translates to:
  /// **'Your booking'**
  String get yourBooking;

  /// No description provided for @noBookingThisWeek.
  ///
  /// In en, this message translates to:
  /// **'No booking this week.'**
  String get noBookingThisWeek;

  /// No description provided for @coachLabel.
  ///
  /// In en, this message translates to:
  /// **'Coach'**
  String get coachLabel;

  /// No description provided for @bookingConfirmed.
  ///
  /// In en, this message translates to:
  /// **'You\'re booked!'**
  String get bookingConfirmed;

  /// No description provided for @bookingCancelled.
  ///
  /// In en, this message translates to:
  /// **'Booking cancelled'**
  String get bookingCancelled;

  /// No description provided for @bookConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Book this slot?'**
  String get bookConfirmTitle;

  /// No description provided for @bookConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'You can book one training per day and cancel up to 2 hours before.'**
  String get bookConfirmBody;

  /// No description provided for @finishedTrainings.
  ///
  /// In en, this message translates to:
  /// **'Finished trainings'**
  String get finishedTrainings;

  /// No description provided for @noFinishedTrainings.
  ///
  /// In en, this message translates to:
  /// **'No finished trainings yet.'**
  String get noFinishedTrainings;

  /// No description provided for @healthLogs.
  ///
  /// In en, this message translates to:
  /// **'Health logs'**
  String get healthLogs;

  /// No description provided for @addLog.
  ///
  /// In en, this message translates to:
  /// **'Add log'**
  String get addLog;

  /// No description provided for @logSleep.
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get logSleep;

  /// No description provided for @logMeal.
  ///
  /// In en, this message translates to:
  /// **'Meal'**
  String get logMeal;

  /// No description provided for @logActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get logActivity;

  /// No description provided for @logWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get logWeight;

  /// No description provided for @logWater.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get logWater;

  /// No description provided for @logValue.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get logValue;

  /// No description provided for @logNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get logNotes;

  /// No description provided for @logSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get logSaved;

  /// No description provided for @noLogsYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing logged yet.'**
  String get noLogsYet;

  /// No description provided for @importFromHealth.
  ///
  /// In en, this message translates to:
  /// **'Import from Health'**
  String get importFromHealth;

  /// No description provided for @importFromStrava.
  ///
  /// In en, this message translates to:
  /// **'Import from Strava'**
  String get importFromStrava;

  /// No description provided for @connectStrava.
  ///
  /// In en, this message translates to:
  /// **'Connect Strava'**
  String get connectStrava;

  /// No description provided for @imported.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Nothing to import} =1{Imported 1 entry} other{Imported {count} entries}}'**
  String imported(int count);

  /// No description provided for @importUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Import isn\'t available on this device yet.'**
  String get importUnavailable;

  /// No description provided for @reminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get reminders;

  /// No description provided for @addReminder.
  ///
  /// In en, this message translates to:
  /// **'Add reminder'**
  String get addReminder;

  /// No description provided for @reminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get reminderTitle;

  /// No description provided for @reminderTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get reminderTime;

  /// No description provided for @reminderMeasureWeight.
  ///
  /// In en, this message translates to:
  /// **'Measure weight'**
  String get reminderMeasureWeight;

  /// No description provided for @reminderDrinkWater.
  ///
  /// In en, this message translates to:
  /// **'Drink water'**
  String get reminderDrinkWater;

  /// No description provided for @noReminders.
  ///
  /// In en, this message translates to:
  /// **'No reminders yet.'**
  String get noReminders;

  /// No description provided for @addToCalendar.
  ///
  /// In en, this message translates to:
  /// **'Add to calendar'**
  String get addToCalendar;

  /// No description provided for @addedToCalendar.
  ///
  /// In en, this message translates to:
  /// **'Added to your calendar'**
  String get addedToCalendar;

  /// No description provided for @resetPhase.
  ///
  /// In en, this message translates to:
  /// **'Reset phase'**
  String get resetPhase;

  /// No description provided for @resetPhaseTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset this phase?'**
  String get resetPhaseTitle;

  /// No description provided for @resetPhaseBody.
  ///
  /// In en, this message translates to:
  /// **'This clears completion for every session in the phase so the client restarts it.'**
  String get resetPhaseBody;

  /// No description provided for @phaseReset.
  ///
  /// In en, this message translates to:
  /// **'Phase reset'**
  String get phaseReset;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet.'**
  String get noNotifications;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get markAllRead;

  /// No description provided for @unreadCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No unread} =1{1 unread} other{{count} unread}}'**
  String unreadCount(int count);

  /// No description provided for @rateDifficulty.
  ///
  /// In en, this message translates to:
  /// **'How hard was it?'**
  String get rateDifficulty;

  /// No description provided for @difficulty.
  ///
  /// In en, this message translates to:
  /// **'Difficulty'**
  String get difficulty;

  /// No description provided for @difficultyVeryEasy.
  ///
  /// In en, this message translates to:
  /// **'Very easy'**
  String get difficultyVeryEasy;

  /// No description provided for @difficultyEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get difficultyEasy;

  /// No description provided for @difficultyModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get difficultyModerate;

  /// No description provided for @difficultyHard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get difficultyHard;

  /// No description provided for @difficultyMax.
  ///
  /// In en, this message translates to:
  /// **'All-out'**
  String get difficultyMax;

  /// No description provided for @ratingSaved.
  ///
  /// In en, this message translates to:
  /// **'Rating saved'**
  String get ratingSaved;

  /// No description provided for @addComment.
  ///
  /// In en, this message translates to:
  /// **'Add a comment'**
  String get addComment;

  /// No description provided for @commentHint.
  ///
  /// In en, this message translates to:
  /// **'Write a comment…'**
  String get commentHint;

  /// No description provided for @comments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get comments;

  /// No description provided for @noComments.
  ///
  /// In en, this message translates to:
  /// **'No comments yet.'**
  String get noComments;

  /// No description provided for @commentPosted.
  ///
  /// In en, this message translates to:
  /// **'Comment posted'**
  String get commentPosted;

  /// No description provided for @likeAction.
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get likeAction;

  /// No description provided for @likedLabel.
  ///
  /// In en, this message translates to:
  /// **'Liked'**
  String get likedLabel;

  /// No description provided for @personalBest.
  ///
  /// In en, this message translates to:
  /// **'Personal best'**
  String get personalBest;

  /// No description provided for @noPersonalBest.
  ///
  /// In en, this message translates to:
  /// **'No personal best yet.'**
  String get noPersonalBest;

  /// No description provided for @billingTitle.
  ///
  /// In en, this message translates to:
  /// **'Billing'**
  String get billingTitle;

  /// No description provided for @billing.
  ///
  /// In en, this message translates to:
  /// **'Billing'**
  String get billing;

  /// No description provided for @noInvoices.
  ///
  /// In en, this message translates to:
  /// **'No invoices yet.'**
  String get noInvoices;

  /// No description provided for @invoicePaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get invoicePaid;

  /// No description provided for @invoicePending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get invoicePending;

  /// No description provided for @paidOn.
  ///
  /// In en, this message translates to:
  /// **'Paid {date}'**
  String paidOn(String date);
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
      <String>['en', 'sl'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'sl':
      return AppLocalizationsSl();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
