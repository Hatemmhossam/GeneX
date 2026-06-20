import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @age.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get age;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @heightCm.
  ///
  /// In en, this message translates to:
  /// **'Height (cm)'**
  String get heightCm;

  /// No description provided for @weightKg.
  ///
  /// In en, this message translates to:
  /// **'Weight (kg)'**
  String get weightKg;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get alreadyHaveAccount;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @enterValidUsername.
  ///
  /// In en, this message translates to:
  /// **'Enter valid username'**
  String get enterValidUsername;

  /// No description provided for @minSixChars.
  ///
  /// In en, this message translates to:
  /// **'Min 6 chars'**
  String get minSixChars;

  /// No description provided for @orSignInWith.
  ///
  /// In en, this message translates to:
  /// **'or sign in with'**
  String get orSignInWith;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back!'**
  String get welcomeBack;

  /// No description provided for @welcomeBackMessage.
  ///
  /// In en, this message translates to:
  /// **'Welcome back! We are so happy to have you here. It\'s great to see you again. We hope you are safe.'**
  String get welcomeBackMessage;

  /// No description provided for @noAccountYet.
  ///
  /// In en, this message translates to:
  /// **'No account yet? Sign up.'**
  String get noAccountYet;

  /// No description provided for @accessDenied.
  ///
  /// In en, this message translates to:
  /// **'Access denied'**
  String get accessDenied;

  /// No description provided for @accountNoRole.
  ///
  /// In en, this message translates to:
  /// **'Your account has no role assigned.'**
  String get accountNoRole;

  /// No description provided for @roleNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Your role is not allowed to access this app.'**
  String get roleNotAllowed;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightMode;

  /// No description provided for @lightModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Always use light appearance'**
  String get lightModeSubtitle;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @darkModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Always use dark appearance'**
  String get darkModeSubtitle;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get systemDefault;

  /// No description provided for @systemThemeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Match your device appearance'**
  String get systemThemeSubtitle;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @followDeviceLanguage.
  ///
  /// In en, this message translates to:
  /// **'Follow your device language'**
  String get followDeviceLanguage;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @englishSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use English language'**
  String get englishSubtitle;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabic;

  /// No description provided for @arabicSubtitle.
  ///
  /// In en, this message translates to:
  /// **'استخدام اللغة العربية'**
  String get arabicSubtitle;

  /// No description provided for @doctorDashboard.
  ///
  /// In en, this message translates to:
  /// **'Doctor Dashboard'**
  String get doctorDashboard;

  /// No description provided for @assignedPatients.
  ///
  /// In en, this message translates to:
  /// **'Assigned Patients'**
  String get assignedPatients;

  /// No description provided for @pendingPatients.
  ///
  /// In en, this message translates to:
  /// **'Pending Patients'**
  String get pendingPatients;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @managePatients.
  ///
  /// In en, this message translates to:
  /// **'Manage Patients'**
  String get managePatients;

  /// No description provided for @viewPatientDirectory.
  ///
  /// In en, this message translates to:
  /// **'View full patient directory'**
  String get viewPatientDirectory;

  /// No description provided for @myPatients.
  ///
  /// In en, this message translates to:
  /// **'My Patients'**
  String get myPatients;

  /// No description provided for @viewMedicalLogs.
  ///
  /// In en, this message translates to:
  /// **'View patient medical logs'**
  String get viewMedicalLogs;

  /// No description provided for @twinSimulationReview.
  ///
  /// In en, this message translates to:
  /// **'Twin Simulation Review'**
  String get twinSimulationReview;

  /// No description provided for @reviewPatientSimulations.
  ///
  /// In en, this message translates to:
  /// **'Review patient simulations'**
  String get reviewPatientSimulations;

  /// No description provided for @patientMedicalFile.
  ///
  /// In en, this message translates to:
  /// **'Patient Medical File'**
  String get patientMedicalFile;

  /// No description provided for @coreHealthMetrics.
  ///
  /// In en, this message translates to:
  /// **'Core Health Metrics'**
  String get coreHealthMetrics;

  /// No description provided for @contactAdmin.
  ///
  /// In en, this message translates to:
  /// **'Contact Admin to change legal name'**
  String get contactAdmin;

  /// No description provided for @genderIdentity.
  ///
  /// In en, this message translates to:
  /// **'Gender Identity'**
  String get genderIdentity;

  /// No description provided for @currentAge.
  ///
  /// In en, this message translates to:
  /// **'Current Age'**
  String get currentAge;

  /// No description provided for @patientHeight.
  ///
  /// In en, this message translates to:
  /// **'Patient Height (cm)'**
  String get patientHeight;

  /// No description provided for @bodyWeight.
  ///
  /// In en, this message translates to:
  /// **'Body Weight (kg)'**
  String get bodyWeight;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @confirmUpdate.
  ///
  /// In en, this message translates to:
  /// **'Confirm Update'**
  String get confirmUpdate;

  /// No description provided for @medicalRecordUpdated.
  ///
  /// In en, this message translates to:
  /// **'Medical Record Updated Successfully'**
  String get medicalRecordUpdated;

  /// No description provided for @confirmLogout.
  ///
  /// In en, this message translates to:
  /// **'Confirm Logout'**
  String get confirmLogout;

  /// No description provided for @logoutMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out of the GeneX portal?'**
  String get logoutMessage;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @noPendingPatientsFound.
  ///
  /// In en, this message translates to:
  /// **'No pending patients found'**
  String get noPendingPatientsFound;

  /// No description provided for @searchPatients.
  ///
  /// In en, this message translates to:
  /// **'Search Patients'**
  String get searchPatients;

  /// No description provided for @searchByPatientUsername.
  ///
  /// In en, this message translates to:
  /// **'Search by patient username...'**
  String get searchByPatientUsername;

  /// No description provided for @results.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get results;

  /// No description provided for @statusIdle.
  ///
  /// In en, this message translates to:
  /// **'Status: idle'**
  String get statusIdle;

  /// No description provided for @startSearchingPatients.
  ///
  /// In en, this message translates to:
  /// **'Start searching for patients'**
  String get startSearchingPatients;

  /// No description provided for @typeUsernameToSearch.
  ///
  /// In en, this message translates to:
  /// **'Type a username in the search field above to see matching patients'**
  String get typeUsernameToSearch;

  /// No description provided for @patientRecords.
  ///
  /// In en, this message translates to:
  /// **'Patient Records'**
  String get patientRecords;

  /// No description provided for @patientMedicalHistory.
  ///
  /// In en, this message translates to:
  /// **'Patient Medical History'**
  String get patientMedicalHistory;

  /// No description provided for @reviewPatientHistory.
  ///
  /// In en, this message translates to:
  /// **'Review patient medical records and reports'**
  String get reviewPatientHistory;

  /// No description provided for @chatWithPatient.
  ///
  /// In en, this message translates to:
  /// **'Chat with Patient'**
  String get chatWithPatient;

  /// No description provided for @medicines.
  ///
  /// In en, this message translates to:
  /// **'Medicines'**
  String get medicines;

  /// No description provided for @symptoms.
  ///
  /// In en, this message translates to:
  /// **'Symptoms'**
  String get symptoms;

  /// No description provided for @testResults.
  ///
  /// In en, this message translates to:
  /// **'Test Results'**
  String get testResults;

  /// No description provided for @noSymptomsReported.
  ///
  /// In en, this message translates to:
  /// **'No symptoms reported'**
  String get noSymptomsReported;

  /// No description provided for @noTestResultsRecorded.
  ///
  /// In en, this message translates to:
  /// **'No test results recorded'**
  String get noTestResultsRecorded;

  /// No description provided for @twinSimulation.
  ///
  /// In en, this message translates to:
  /// **'Twin Simulation'**
  String get twinSimulation;

  /// No description provided for @drugToDrugInteraction.
  ///
  /// In en, this message translates to:
  /// **'Drug to Drug Interaction'**
  String get drugToDrugInteraction;

  /// No description provided for @drugToGeneInteraction.
  ///
  /// In en, this message translates to:
  /// **'Drug to Gene Interaction'**
  String get drugToGeneInteraction;

  /// No description provided for @uploadPatientCsv.
  ///
  /// In en, this message translates to:
  /// **'Upload Patient CSV'**
  String get uploadPatientCsv;

  /// No description provided for @drug1.
  ///
  /// In en, this message translates to:
  /// **'Drug 1'**
  String get drug1;

  /// No description provided for @drug2Optional.
  ///
  /// In en, this message translates to:
  /// **'Drug 2 (Optional)'**
  String get drug2Optional;

  /// No description provided for @evaluate.
  ///
  /// In en, this message translates to:
  /// **'Evaluate'**
  String get evaluate;

  /// No description provided for @noEvaluationYet.
  ///
  /// In en, this message translates to:
  /// **'No evaluation yet'**
  String get noEvaluationYet;

  /// No description provided for @runSimulationMessage.
  ///
  /// In en, this message translates to:
  /// **'Run the simulation and the results will appear here in a more readable format.'**
  String get runSimulationMessage;

  /// No description provided for @noAuthenticationTokenFound.
  ///
  /// In en, this message translates to:
  /// **'No authentication token found'**
  String get noAuthenticationTokenFound;

  /// No description provided for @doctorIdNotFound.
  ///
  /// In en, this message translates to:
  /// **'Doctor ID not found'**
  String get doctorIdNotFound;

  /// No description provided for @failedToOpenChat.
  ///
  /// In en, this message translates to:
  /// **'Failed to open chat: {error}'**
  String failedToOpenChat(Object error);

  /// No description provided for @unableToOpenChat.
  ///
  /// In en, this message translates to:
  /// **'Unable to open chat'**
  String get unableToOpenChat;

  /// No description provided for @accessDeniedOrError.
  ///
  /// In en, this message translates to:
  /// **'Access denied or error'**
  String get accessDeniedOrError;

  /// No description provided for @connectionError.
  ///
  /// In en, this message translates to:
  /// **'Connection error'**
  String get connectionError;

  /// No description provided for @addDoctorNote.
  ///
  /// In en, this message translates to:
  /// **'Add Doctor Note'**
  String get addDoctorNote;

  /// No description provided for @enterInstructions.
  ///
  /// In en, this message translates to:
  /// **'Enter instructions'**
  String get enterInstructions;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @noteSaved.
  ///
  /// In en, this message translates to:
  /// **'Note saved successfully'**
  String get noteSaved;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @positive.
  ///
  /// In en, this message translates to:
  /// **'Positive'**
  String get positive;

  /// No description provided for @negative.
  ///
  /// In en, this message translates to:
  /// **'Negative'**
  String get negative;

  /// No description provided for @noMedicinesRecorded.
  ///
  /// In en, this message translates to:
  /// **'No medicines recorded'**
  String get noMedicinesRecorded;

  /// No description provided for @unknownDrug.
  ///
  /// In en, this message translates to:
  /// **'Unknown drug'**
  String get unknownDrug;

  /// No description provided for @added.
  ///
  /// In en, this message translates to:
  /// **'Added'**
  String get added;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @severity.
  ///
  /// In en, this message translates to:
  /// **'Severity'**
  String get severity;

  /// No description provided for @frequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get frequency;

  /// No description provided for @doctorNotes.
  ///
  /// In en, this message translates to:
  /// **'Doctor Notes'**
  String get doctorNotes;

  /// No description provided for @unknownPrediction.
  ///
  /// In en, this message translates to:
  /// **'Unknown prediction'**
  String get unknownPrediction;

  /// No description provided for @confidence.
  ///
  /// In en, this message translates to:
  /// **'Confidence'**
  String get confidence;

  /// No description provided for @xaiExplanation.
  ///
  /// In en, this message translates to:
  /// **'XAI Explanation'**
  String get xaiExplanation;

  /// No description provided for @noExplanationAvailable.
  ///
  /// In en, this message translates to:
  /// **'No explanation available'**
  String get noExplanationAvailable;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @geneExpressionReports.
  ///
  /// In en, this message translates to:
  /// **'Gene Expression Reports'**
  String get geneExpressionReports;

  /// No description provided for @noGeneExpressionReportsRecorded.
  ///
  /// In en, this message translates to:
  /// **'No gene expression reports recorded'**
  String get noGeneExpressionReportsRecorded;

  /// No description provided for @unknownResult.
  ///
  /// In en, this message translates to:
  /// **'Unknown result'**
  String get unknownResult;

  /// No description provided for @risk.
  ///
  /// In en, this message translates to:
  /// **'Risk'**
  String get risk;

  /// No description provided for @precision.
  ///
  /// In en, this message translates to:
  /// **'Precision'**
  String get precision;

  /// No description provided for @recall.
  ///
  /// In en, this message translates to:
  /// **'Recall'**
  String get recall;

  /// No description provided for @f1Score.
  ///
  /// In en, this message translates to:
  /// **'F1-Score'**
  String get f1Score;

  /// No description provided for @fileName.
  ///
  /// In en, this message translates to:
  /// **'File name'**
  String get fileName;

  /// No description provided for @confidenceInterval.
  ///
  /// In en, this message translates to:
  /// **'Confidence Interval'**
  String get confidenceInterval;

  /// No description provided for @createdAt.
  ///
  /// In en, this message translates to:
  /// **'Created at'**
  String get createdAt;

  /// No description provided for @topAffectingGenes.
  ///
  /// In en, this message translates to:
  /// **'Top Affecting Genes'**
  String get topAffectingGenes;

  /// No description provided for @noGenesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No genes available'**
  String get noGenesAvailable;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong.'**
  String get somethingWentWrong;

  /// No description provided for @unknownError.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get unknownError;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @loadingPatientRecords.
  ///
  /// In en, this message translates to:
  /// **'Loading patient records...'**
  String get loadingPatientRecords;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @doctorDashboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your accepted patients and open their medical records quickly.'**
  String get doctorDashboardSubtitle;

  /// No description provided for @patients.
  ///
  /// In en, this message translates to:
  /// **'patients'**
  String get patients;

  /// No description provided for @searchByPatient.
  ///
  /// In en, this message translates to:
  /// **'Search by patient name or email'**
  String get searchByPatient;

  /// No description provided for @weight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weight;

  /// No description provided for @height.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get height;

  /// No description provided for @viewMedicalRecords.
  ///
  /// In en, this message translates to:
  /// **'View Medical Records'**
  String get viewMedicalRecords;

  /// No description provided for @patientIdMissing.
  ///
  /// In en, this message translates to:
  /// **'Error: Patient ID is missing'**
  String get patientIdMissing;

  /// No description provided for @loadingPatients.
  ///
  /// In en, this message translates to:
  /// **'Loading patients...'**
  String get loadingPatients;

  /// No description provided for @noAcceptedPatients.
  ///
  /// In en, this message translates to:
  /// **'No accepted patients yet'**
  String get noAcceptedPatients;

  /// No description provided for @patientsWillAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Once patients are assigned and accepted, you’ll see them here.'**
  String get patientsWillAppearHere;

  /// No description provided for @noPatientsMatchSearch.
  ///
  /// In en, this message translates to:
  /// **'No patients match your search.'**
  String get noPatientsMatchSearch;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @addPatient.
  ///
  /// In en, this message translates to:
  /// **'Add Patient'**
  String get addPatient;

  /// No description provided for @addPatientQuestion.
  ///
  /// In en, this message translates to:
  /// **'Do you want to send an add request to {username}?'**
  String addPatientQuestion(Object username);

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @sendingRequest.
  ///
  /// In en, this message translates to:
  /// **'Sending request...'**
  String get sendingRequest;

  /// No description provided for @requestSent.
  ///
  /// In en, this message translates to:
  /// **'Request sent to {username}!'**
  String requestSent(Object username);

  /// No description provided for @requestFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed. Request might already exist.'**
  String get requestFailed;

  /// No description provided for @noPatientsFound.
  ///
  /// In en, this message translates to:
  /// **'No patients found'**
  String get noPatientsFound;

  /// No description provided for @patientNotFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t find any patient matching \"{username}\".'**
  String patientNotFoundMessage(Object username);

  /// No description provided for @searchPatientsInstruction.
  ///
  /// In en, this message translates to:
  /// **'Type a username in the search field above to see matching patients.'**
  String get searchPatientsInstruction;

  /// No description provided for @noUsername.
  ///
  /// In en, this message translates to:
  /// **'(no username)'**
  String get noUsername;

  /// No description provided for @changeFile.
  ///
  /// In en, this message translates to:
  /// **'Change File'**
  String get changeFile;

  /// No description provided for @selectedFile.
  ///
  /// In en, this message translates to:
  /// **'Selected file: {fileName}'**
  String selectedFile(Object fileName);

  /// No description provided for @drug2.
  ///
  /// In en, this message translates to:
  /// **'Drug 2'**
  String get drug2;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @uploadPatientDescription.
  ///
  /// In en, this message translates to:
  /// **'Upload a patient file, enter the selected drug(s), and review the result in a cleaner structured layout.'**
  String get uploadPatientDescription;

  /// No description provided for @bestDrug.
  ///
  /// In en, this message translates to:
  /// **'Best Drug'**
  String get bestDrug;

  /// No description provided for @riskReduction.
  ///
  /// In en, this message translates to:
  /// **'Risk Reduction (%)'**
  String get riskReduction;

  /// No description provided for @noBestRecommendation.
  ///
  /// In en, this message translates to:
  /// **'No best recommendation found'**
  String get noBestRecommendation;

  /// No description provided for @noDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noDataAvailable;

  /// No description provided for @summary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get summary;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @enterFirstDrug.
  ///
  /// In en, this message translates to:
  /// **'Enter first drug'**
  String get enterFirstDrug;

  /// No description provided for @enterSecondDrug.
  ///
  /// In en, this message translates to:
  /// **'Enter second drug'**
  String get enterSecondDrug;

  /// No description provided for @checkInteraction.
  ///
  /// In en, this message translates to:
  /// **'Check Interaction'**
  String get checkInteraction;

  /// No description provided for @interactionResultPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'The interaction result will appear here.'**
  String get interactionResultPlaceholder;

  /// No description provided for @saveReport.
  ///
  /// In en, this message translates to:
  /// **'Save Report'**
  String get saveReport;

  /// No description provided for @reportSavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Report saved successfully'**
  String get reportSavedSuccessfully;

  /// No description provided for @pleaseUploadPatientCsv.
  ///
  /// In en, this message translates to:
  /// **'Please upload the patient CSV first.'**
  String get pleaseUploadPatientCsv;

  /// No description provided for @pleaseEnterDrug1.
  ///
  /// In en, this message translates to:
  /// **'Please enter at least Drug 1.'**
  String get pleaseEnterDrug1;

  /// No description provided for @fileSelectionFailed.
  ///
  /// In en, this message translates to:
  /// **'File selection failed: {error}'**
  String fileSelectionFailed(Object error);

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Save failed: {error}'**
  String saveFailed(Object error);

  /// No description provided for @pleaseEnterBothDrugNames.
  ///
  /// In en, this message translates to:
  /// **'Please enter both drug names.'**
  String get pleaseEnterBothDrugNames;

  /// No description provided for @interactionFound.
  ///
  /// In en, this message translates to:
  /// **'Interaction found:'**
  String get interactionFound;

  /// No description provided for @noInteractionFound.
  ///
  /// In en, this message translates to:
  /// **'No interaction found.'**
  String get noInteractionFound;

  /// No description provided for @errorMessage.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorMessage(Object error);

  /// No description provided for @item.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get item;

  /// No description provided for @dailySymptomTracker.
  ///
  /// In en, this message translates to:
  /// **'Daily Symptom Tracker'**
  String get dailySymptomTracker;

  /// No description provided for @dailySymptomTrackerDescription.
  ///
  /// In en, this message translates to:
  /// **'Tracking symptoms daily helps our AI calculate your risk score accurately.'**
  String get dailySymptomTrackerDescription;

  /// No description provided for @whatAreYouExperiencing.
  ///
  /// In en, this message translates to:
  /// **'What are you experiencing?'**
  String get whatAreYouExperiencing;

  /// No description provided for @severityLevel.
  ///
  /// In en, this message translates to:
  /// **'Severity Level'**
  String get severityLevel;

  /// No description provided for @mild.
  ///
  /// In en, this message translates to:
  /// **'Mild'**
  String get mild;

  /// No description provided for @unbearable.
  ///
  /// In en, this message translates to:
  /// **'Unbearable'**
  String get unbearable;

  /// No description provided for @howOften.
  ///
  /// In en, this message translates to:
  /// **'How often?'**
  String get howOften;

  /// No description provided for @additionalNotes.
  ///
  /// In en, this message translates to:
  /// **'Additional Notes (Triggers, duration, etc.)'**
  String get additionalNotes;

  /// No description provided for @notesHint.
  ///
  /// In en, this message translates to:
  /// **'Example: Pain increases after eating gluten...'**
  String get notesHint;

  /// No description provided for @logSymptom.
  ///
  /// In en, this message translates to:
  /// **'Log Symptom'**
  String get logSymptom;

  /// No description provided for @pleaseSelectSymptom.
  ///
  /// In en, this message translates to:
  /// **'Please select a symptom'**
  String get pleaseSelectSymptom;

  /// No description provided for @symptomReportedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Symptom reported successfully'**
  String get symptomReportedSuccessfully;

  /// No description provided for @failedToSaveReport.
  ///
  /// In en, this message translates to:
  /// **'Failed to save report. Check connection.'**
  String get failedToSaveReport;

  /// No description provided for @appointment.
  ///
  /// In en, this message translates to:
  /// **'Appointment'**
  String get appointment;

  /// No description provided for @aboutTheSystem.
  ///
  /// In en, this message translates to:
  /// **'About the System'**
  String get aboutTheSystem;

  /// No description provided for @purpose.
  ///
  /// In en, this message translates to:
  /// **'Purpose'**
  String get purpose;

  /// No description provided for @purposeContent.
  ///
  /// In en, this message translates to:
  /// **'This system is designed to help patients with the diagnosis process and provide quick connection with their doctors. Patients can access the descriptions and notes entered by their doctors.'**
  String get purposeContent;

  /// No description provided for @mainFeatures.
  ///
  /// In en, this message translates to:
  /// **'Main Features'**
  String get mainFeatures;

  /// No description provided for @mainFeaturesContent.
  ///
  /// In en, this message translates to:
  /// **'• Easy data entry for patients\n• Doctors can access patient data and enter prescriptions\n• Patients can track all taken medications\n• Import medical history to organize all information about medications and treatments'**
  String get mainFeaturesContent;

  /// No description provided for @howSystemWorks.
  ///
  /// In en, this message translates to:
  /// **'How the System Works'**
  String get howSystemWorks;

  /// No description provided for @howSystemWorksContent.
  ///
  /// In en, this message translates to:
  /// **'The system works by importing patient files, allowing doctors to view patient reports and select the best medications. It is designed to provide guidance with high accuracy in medication suggestions.'**
  String get howSystemWorksContent;

  /// No description provided for @limitations.
  ///
  /// In en, this message translates to:
  /// **'Limitations'**
  String get limitations;

  /// No description provided for @limitationsContent.
  ///
  /// In en, this message translates to:
  /// **'This system provides assistance and organization for medical information, but it cannot replace professional medical advice. The recommendations are supportive and should always be verified by a qualified doctor.'**
  String get limitationsContent;

  /// No description provided for @importantMedicalDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Important Medical Disclaimer'**
  String get importantMedicalDisclaimer;

  /// No description provided for @medicalDisclaimerContent.
  ///
  /// In en, this message translates to:
  /// **'This application is NOT a replacement for professional medical care. It helps patients organize their medical history, track medications, and communicate with their doctors, but it cannot diagnose or treat any condition. Always consult a qualified physician before making medical decisions.'**
  String get medicalDisclaimerContent;

  /// No description provided for @dnaModelVisualization.
  ///
  /// In en, this message translates to:
  /// **'DNA Model Visualization'**
  String get dnaModelVisualization;

  /// No description provided for @dnaModel.
  ///
  /// In en, this message translates to:
  /// **'DNA Model'**
  String get dnaModel;

  /// No description provided for @currentRiskLevel.
  ///
  /// In en, this message translates to:
  /// **'Current Risk Level'**
  String get currentRiskLevel;

  /// No description provided for @lowRisk.
  ///
  /// In en, this message translates to:
  /// **'Low Risk'**
  String get lowRisk;

  /// No description provided for @mediumRisk.
  ///
  /// In en, this message translates to:
  /// **'Medium Risk'**
  String get mediumRisk;

  /// No description provided for @highRisk.
  ///
  /// In en, this message translates to:
  /// **'High Risk'**
  String get highRisk;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @accessRequests.
  ///
  /// In en, this message translates to:
  /// **'Access Requests'**
  String get accessRequests;

  /// No description provided for @doctorRequests.
  ///
  /// In en, this message translates to:
  /// **'Doctor Requests'**
  String get doctorRequests;

  /// No description provided for @doctorName.
  ///
  /// In en, this message translates to:
  /// **'Doctor Name'**
  String get doctorName;

  /// No description provided for @action.
  ///
  /// In en, this message translates to:
  /// **'Action'**
  String get action;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @accepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get accepted;

  /// No description provided for @rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejected;

  /// No description provided for @noRequestsFound.
  ///
  /// In en, this message translates to:
  /// **'No requests found.'**
  String get noRequestsFound;

  /// No description provided for @requestAcceptedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Request accepted successfully!'**
  String get requestAcceptedSuccessfully;

  /// No description provided for @requestRejectedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Request rejected successfully!'**
  String get requestRejectedSuccessfully;

  /// No description provided for @failedToUpdateStatus.
  ///
  /// In en, this message translates to:
  /// **'Failed to update status. Check console.'**
  String get failedToUpdateStatus;

  /// No description provided for @unknownDoctor.
  ///
  /// In en, this message translates to:
  /// **'Unknown Doctor'**
  String get unknownDoctor;

  /// No description provided for @medicineHistory.
  ///
  /// In en, this message translates to:
  /// **'Medicine History'**
  String get medicineHistory;

  /// No description provided for @searchAddMedicine.
  ///
  /// In en, this message translates to:
  /// **'Search & Add Medicine'**
  String get searchAddMedicine;

  /// No description provided for @searchMedicineHint.
  ///
  /// In en, this message translates to:
  /// **'Search (e.g., Ibuprofen...)'**
  String get searchMedicineHint;

  /// No description provided for @patientMedicines.
  ///
  /// In en, this message translates to:
  /// **'Patient Medicines:'**
  String get patientMedicines;

  /// No description provided for @noMedicinesAdded.
  ///
  /// In en, this message translates to:
  /// **'No medicines added yet.'**
  String get noMedicinesAdded;

  /// No description provided for @medicineAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'This medicine is already in your list.'**
  String get medicineAlreadyExists;

  /// No description provided for @failedToAddMedicine.
  ///
  /// In en, this message translates to:
  /// **'Failed to add medicine. Please try again.'**
  String get failedToAddMedicine;

  /// No description provided for @deleteMedicine.
  ///
  /// In en, this message translates to:
  /// **'Delete Medicine'**
  String get deleteMedicine;

  /// No description provided for @removeMedicineQuestion.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove this medicine?'**
  String get removeMedicineQuestion;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @addedOn.
  ///
  /// In en, this message translates to:
  /// **'Added on'**
  String get addedOn;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @myDoctors.
  ///
  /// In en, this message translates to:
  /// **'My Doctors'**
  String get myDoctors;

  /// No description provided for @noAssignedDoctorsFound.
  ///
  /// In en, this message translates to:
  /// **'No assigned doctors found'**
  String get noAssignedDoctorsFound;

  /// No description provided for @chat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// No description provided for @patientIdInvalid.
  ///
  /// In en, this message translates to:
  /// **'Patient ID not found or invalid'**
  String get patientIdInvalid;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @medicalAnalysisHistory.
  ///
  /// In en, this message translates to:
  /// **'Medical Analysis History'**
  String get medicalAnalysisHistory;

  /// No description provided for @errorLoadingReports.
  ///
  /// In en, this message translates to:
  /// **'Error loading reports: {error}'**
  String errorLoadingReports(Object error);

  /// No description provided for @noReportsFound.
  ///
  /// In en, this message translates to:
  /// **'No reports found'**
  String get noReportsFound;

  /// No description provided for @uploadGeneFileMessage.
  ///
  /// In en, this message translates to:
  /// **'Upload a gene file to see results here.'**
  String get uploadGeneFileMessage;

  /// No description provided for @file.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get file;

  /// No description provided for @modelClassificationReport.
  ///
  /// In en, this message translates to:
  /// **'Model Classification Report'**
  String get modelClassificationReport;

  /// No description provided for @topGeneticDrivers.
  ///
  /// In en, this message translates to:
  /// **'Top Genetic Drivers (SHAP)'**
  String get topGeneticDrivers;

  /// No description provided for @geneImpactDescription.
  ///
  /// In en, this message translates to:
  /// **'Impact of specific genes on this prediction'**
  String get geneImpactDescription;

  /// No description provided for @noGeneImportanceData.
  ///
  /// In en, this message translates to:
  /// **'No gene importance data available'**
  String get noGeneImportanceData;

  /// No description provided for @logoutConfirmationMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out of the GeneX portal?'**
  String get logoutConfirmationMessage;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @upload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get upload;

  /// No description provided for @simulation.
  ///
  /// In en, this message translates to:
  /// **'Simulation'**
  String get simulation;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @meds.
  ///
  /// In en, this message translates to:
  /// **'Meds'**
  String get meds;

  /// No description provided for @doctors.
  ///
  /// In en, this message translates to:
  /// **'Doctors'**
  String get doctors;

  /// No description provided for @geneXMedicalPortal.
  ///
  /// In en, this message translates to:
  /// **'GeneX Medical Portal'**
  String get geneXMedicalPortal;

  /// No description provided for @systemOverview.
  ///
  /// In en, this message translates to:
  /// **'System Overview'**
  String get systemOverview;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No Data'**
  String get noData;

  /// No description provided for @vitalsStatus.
  ///
  /// In en, this message translates to:
  /// **'Vitals Status'**
  String get vitalsStatus;

  /// No description provided for @medicalAnalysisUpload.
  ///
  /// In en, this message translates to:
  /// **'Medical Analysis Upload'**
  String get medicalAnalysisUpload;

  /// No description provided for @chooseUploadType.
  ///
  /// In en, this message translates to:
  /// **'Choose upload type'**
  String get chooseUploadType;

  /// No description provided for @vcf.
  ///
  /// In en, this message translates to:
  /// **'VCF'**
  String get vcf;

  /// No description provided for @geneExpression.
  ///
  /// In en, this message translates to:
  /// **'Gene Expression'**
  String get geneExpression;

  /// No description provided for @tests.
  ///
  /// In en, this message translates to:
  /// **'Tests'**
  String get tests;

  /// No description provided for @mri.
  ///
  /// In en, this message translates to:
  /// **'MRI'**
  String get mri;

  /// No description provided for @uploadVCFFile.
  ///
  /// In en, this message translates to:
  /// **'Upload VCF File'**
  String get uploadVCFFile;

  /// No description provided for @uploadGeneExpressionFile.
  ///
  /// In en, this message translates to:
  /// **'Upload Gene Expression File'**
  String get uploadGeneExpressionFile;

  /// No description provided for @enterMedicalTests.
  ///
  /// In en, this message translates to:
  /// **'Enter Medical Tests'**
  String get enterMedicalTests;

  /// No description provided for @enterMRI.
  ///
  /// In en, this message translates to:
  /// **'Enter MRI'**
  String get enterMRI;

  /// No description provided for @uploadVCFInstruction.
  ///
  /// In en, this message translates to:
  /// **'Please upload your VCF file.'**
  String get uploadVCFInstruction;

  /// No description provided for @uploadGeneExpressionInstruction.
  ///
  /// In en, this message translates to:
  /// **'Please upload your Gene Expression file.'**
  String get uploadGeneExpressionInstruction;

  /// No description provided for @uploadMRIInstruction.
  ///
  /// In en, this message translates to:
  /// **'Please upload your MRI.'**
  String get uploadMRIInstruction;

  /// No description provided for @uploadVCF.
  ///
  /// In en, this message translates to:
  /// **'Upload VCF'**
  String get uploadVCF;

  /// No description provided for @uploadGeneExpression.
  ///
  /// In en, this message translates to:
  /// **'Upload Gene Expression'**
  String get uploadGeneExpression;

  /// No description provided for @uploadMRI.
  ///
  /// In en, this message translates to:
  /// **'Upload MRI'**
  String get uploadMRI;

  /// No description provided for @uploaded.
  ///
  /// In en, this message translates to:
  /// **'Uploaded'**
  String get uploaded;

  /// No description provided for @analysisResults.
  ///
  /// In en, this message translates to:
  /// **'Analysis Results'**
  String get analysisResults;

  /// No description provided for @rheumatoidProbability.
  ///
  /// In en, this message translates to:
  /// **'Rheumatoid Arthritis Probability:'**
  String get rheumatoidProbability;

  /// No description provided for @classification.
  ///
  /// In en, this message translates to:
  /// **'Classification'**
  String get classification;

  /// No description provided for @fixFormErrors.
  ///
  /// In en, this message translates to:
  /// **'Please fix the errors in the form.'**
  String get fixFormErrors;

  /// No description provided for @notLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'You are not logged in. Please sign in again.'**
  String get notLoggedIn;

  /// No description provided for @serverError.
  ///
  /// In en, this message translates to:
  /// **'Server Error'**
  String get serverError;

  /// No description provided for @connectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection Failed'**
  String get connectionFailed;

  /// No description provided for @result.
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get result;

  /// No description provided for @aiExplanation.
  ///
  /// In en, this message translates to:
  /// **'AI Explanation:'**
  String get aiExplanation;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @uploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed'**
  String get uploadFailed;

  /// No description provided for @fileDataInaccessible.
  ///
  /// In en, this message translates to:
  /// **'File data is inaccessible.'**
  String get fileDataInaccessible;

  /// No description provided for @noFileSelected.
  ///
  /// In en, this message translates to:
  /// **'No file selected'**
  String get noFileSelected;

  /// No description provided for @enterPatientDetails.
  ///
  /// In en, this message translates to:
  /// **'Enter patient details and test results.'**
  String get enterPatientDetails;

  /// No description provided for @isRequired.
  ///
  /// In en, this message translates to:
  /// **'is required'**
  String get isRequired;

  /// No description provided for @invalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Invalid number'**
  String get invalidNumber;

  /// No description provided for @pos.
  ///
  /// In en, this message translates to:
  /// **'Pos'**
  String get pos;

  /// No description provided for @neg.
  ///
  /// In en, this message translates to:
  /// **'Neg'**
  String get neg;

  /// No description provided for @websocketError.
  ///
  /// In en, this message translates to:
  /// **'WebSocket error'**
  String get websocketError;

  /// No description provided for @fileUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'File upload failed'**
  String get fileUploadFailed;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @attachment.
  ///
  /// In en, this message translates to:
  /// **'Attachment'**
  String get attachment;

  /// No description provided for @noMessagesYet.
  ///
  /// In en, this message translates to:
  /// **'No messages yet. Start the conversation.'**
  String get noMessagesYet;

  /// No description provided for @uploadFile.
  ///
  /// In en, this message translates to:
  /// **'Upload File'**
  String get uploadFile;

  /// No description provided for @typeMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get typeMessage;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar': return AppLocalizationsAr();
    case 'en': return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
