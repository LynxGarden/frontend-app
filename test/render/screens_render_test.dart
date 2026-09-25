import 'package:lynx_app/features/auth/presentation/login_screen.dart';
import 'package:lynx_app/features/clients/presentation/clients_list_screen.dart';
import 'package:lynx_app/features/clients/providers/clients_provider.dart';
import 'package:lynx_app/features/groups/presentation/groups_list_screen.dart';
import 'package:lynx_app/features/groups/providers/groups_provider.dart';
import 'package:lynx_app/features/review/presentation/client_review_screen.dart';
import 'package:lynx_app/features/review/presentation/review_screen.dart';
import 'package:lynx_app/features/review/providers/review_provider.dart';
import 'package:lynx_app/features/training/data/models/active_assignment.dart';
import 'package:lynx_app/features/training/presentation/session_runner_screen.dart';
import 'package:lynx_app/features/training/presentation/train_screen.dart';
import 'package:lynx_app/features/training/providers/training_provider.dart';
import 'package:lynx_app/shared/providers/current_user_provider.dart';

import '../support/fixtures.dart';
import '../support/render_harness.dart';

void main() {
  forEachDevice('LoginScreen renders without overflow', (tester, device) async {
    await pumpScreen(tester, const LoginScreen(), device: device);
  });

  forEachDevice('TrainScreen renders without overflow', (tester, device) async {
    await pumpScreen(
      tester,
      const TrainScreen(),
      device: device,
      overrides: [
        activeAssignmentProvider.overrideWith((ref) async => activeAssignmentFixture()),
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
