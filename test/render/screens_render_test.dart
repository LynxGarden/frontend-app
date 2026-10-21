import 'package:lynx_app/features/auth/presentation/forgot_password_screen.dart';
import 'package:lynx_app/features/auth/presentation/login_screen.dart';
import 'package:lynx_app/features/auth/presentation/reset_password_screen.dart';
import 'package:lynx_app/features/auth/presentation/signup_screen.dart';
import 'package:lynx_app/features/auth/presentation/verify_email_screen.dart';
import 'package:lynx_app/features/auth/presentation/welcome_screen.dart';
import 'package:lynx_app/features/clients/presentation/clients_list_screen.dart';
import 'package:lynx_app/features/clients/providers/clients_provider.dart';
import 'package:lynx_app/features/groups/presentation/groups_list_screen.dart';
import 'package:lynx_app/features/groups/providers/groups_provider.dart';
import 'package:lynx_app/features/programs/presentation/session_editor_screen.dart';
import 'package:lynx_app/features/programs/providers/programs_provider.dart';
import 'package:lynx_app/features/review/presentation/client_review_screen.dart';
import 'package:lynx_app/features/review/presentation/review_screen.dart';
import 'package:lynx_app/features/review/providers/review_provider.dart';
import 'package:lynx_app/features/settings/presentation/settings_screen.dart';
import 'package:lynx_app/features/home/presentation/client_home_screen.dart';
import 'package:lynx_app/features/home/providers/home_providers.dart';
import 'package:lynx_app/features/progress/data/models/progress_models.dart';
import 'package:lynx_app/features/progress/providers/progress_provider.dart';
import 'package:lynx_app/features/training/data/models/active_assignment.dart';
import 'package:lynx_app/features/training/presentation/session_runner_screen.dart';
import 'package:lynx_app/features/training/providers/training_provider.dart';
import 'package:lynx_app/shared/providers/current_user_provider.dart';
import 'package:lynx_app/shared/widgets/skeleton_list.dart';

import '../support/fixtures.dart';
import '../support/render_harness.dart';

void main() {
  forEachDevice('ShellSkeleton renders without overflow', (tester, device) async {
    await pumpScreen(tester, const ShellSkeleton(), device: device);
  });

  forEachDevice('WelcomeScreen renders without overflow', (tester, device) async {
    await pumpScreen(tester, const WelcomeScreen(), device: device);
  });

  forEachDevice('LoginScreen renders without overflow', (tester, device) async {
    await pumpScreen(tester, const LoginScreen(), device: device);
  });

  forEachDevice('SignupScreen renders without overflow', (tester, device) async {
    await pumpScreen(tester, const SignupScreen(), device: device);
  });

  forEachDevice('VerifyEmailScreen renders without overflow', (tester, device) async {
    await pumpScreen(
        tester, const VerifyEmailScreen(email: 'coach@lynx.si'), device: device);
  });

  forEachDevice('ForgotPasswordScreen renders without overflow', (tester, device) async {
    await pumpScreen(tester, const ForgotPasswordScreen(), device: device);
  });

  forEachDevice('ResetPasswordScreen renders without overflow', (tester, device) async {
    await pumpScreen(
        tester, const ResetPasswordScreen(email: 'coach@lynx.si'), device: device);
  });

  forEachDevice('ClientHomeScreen renders without overflow', (tester, device) async {
    await pumpScreen(
      tester,
      const ClientHomeScreen(),
      device: device,
      overrides: [
        activeAssignmentProvider
            .overrideWith((ref) => Stream.value(activeAssignmentFixture())),
        progressSummaryProvider.overrideWith((ref) async => ProgressSummary(
            visitsThisWeek: 2, weekStreak: 3, hasAnyData: true)),
        stepsWeekProvider.overrideWith((ref) async => const []),
        caloriesTodayProvider.overrideWith((ref) async => null),
        heartRateTodayProvider.overrideWith((ref) async => const []),
      ],
    );
  });

  forEachDevice('SessionRunnerScreen renders without overflow', (tester, device) async {
    await pumpScreen(
      tester,
      const SessionRunnerScreen(assignmentId: 'a1', sessionId: 's1'),
      device: device,
      overrides: [
        currentUserProvider.overrideWith((ref) async => appUserFixture()),
        sessionRunnerProvider.overrideWith((ref, key) async => runnerSessionFixture()),
        lastEntriesProvider.overrideWith((ref, id) async => const <LoggedEntry>[]),
      ],
    );
  });

  forEachDevice('SessionEditorScreen renders without overflow', (tester, device) async {
    await pumpScreen(
      tester,
      const SessionEditorScreen(programId: 'pr1', sessionId: 's1'),
      device: device,
      overrides: [
        currentUserProvider.overrideWith((ref) async => appUserFixture()),
        sessionEditorProvider.overrideWith((ref, key) async => sessionEditorFixture()),
      ],
    );
  });

  forEachDevice('ReviewScreen renders without overflow', (tester, device) async {
    await pumpScreen(
      tester,
      const ReviewScreen(),
      device: device,
      overrides: [
        reviewFeedProvider.overrideWith((ref) async => completedSessionsFixture()),
      ],
    );
  });

  forEachDevice('ClientReviewScreen renders without overflow', (tester, device) async {
    await pumpScreen(
      tester,
      const ClientReviewScreen(personId: 'p1', clientName: 'Alexandra Kovačević'),
      device: device,
      overrides: [
        clientCompletedProvider('p1')
            .overrideWith((ref) async => completedSessionsFixture()),
      ],
    );
  });

  forEachDevice('SettingsScreen renders without overflow', (tester, device) async {
    await pumpScreen(
      tester,
      const SettingsScreen(),
      device: device,
      overrides: [
        currentUserProvider.overrideWith((ref) async => appUserFixture()),
      ],
    );
  });

  forEachDevice('ClientsListScreen renders without overflow', (tester, device) async {
    await pumpScreen(
      tester,
      const ClientsListScreen(),
      device: device,
      overrides: [
        clientsProvider.overrideWith((ref) async => clientsFixture()),
      ],
    );
  });

  forEachDevice('GroupsListScreen renders without overflow', (tester, device) async {
    await pumpScreen(
      tester,
      const GroupsListScreen(),
      device: device,
      overrides: [
        groupsProvider.overrideWith((ref) async => groupsFixture()),
      ],
    );
  });
}
