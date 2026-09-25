import 'package:lynx_app/features/clients/data/models/client.dart';
import 'package:lynx_app/features/groups/data/models/group.dart';
import 'package:lynx_app/features/programs/data/models/session_exercise.dart';
import 'package:lynx_app/features/programs/data/models/training_session.dart';
import 'package:lynx_app/features/review/data/models/review_models.dart';
import 'package:lynx_app/features/training/data/models/active_assignment.dart';
import 'package:lynx_app/shared/models/app_user.dart';

AppUser appUserFixture() => const AppUser(
      personId: 'p1',
      tenantId: 't1',
      roles: {AppRole.client},
      locale: 'en',
      firstName: 'Alexandra',
    );

/// Mock data for render tests. Values are deliberately long-ish to stress layout.

TrainingExercise exerciseFixture([int i = 0]) => TrainingExercise(
      id: 'ae$i',
      exerciseId: 'ex$i',
      orderIndex: i,
      exerciseName: 'Bulgarian Split Squat (rear-foot elevated)',
      videoUrl: 'https://example.com/v',
      sets: 4,
      reps: '8-10 each side',
      weight: '2×24kg',
      rpe: '8',
      restSeconds: 120,
      setTypeNote: 'Superset with the next movement',
      coachNote: 'Keep the front shin vertical; control the descent.',
    );

/// A time-based exercise (sets the time field visible) to stress the 3-input row.
TrainingExercise exerciseTimedFixture() => const TrainingExercise(
      id: 'aeT',
      exerciseId: 'exT',
      orderIndex: 3,
      exerciseName: 'Plank hold',
      timeSeconds: 45,
      setTypeNote: 'Hold — brace hard',
    );

/// A single runner session (for SessionRunnerScreen render tests).
TrainingAssignmentSession runnerSessionFixture() => TrainingAssignmentSession(
      id: 's1',
      label: 'A1 · Squat focus',
      orderIndex: 0,
      exercises: [exerciseFixture(0), exerciseTimedFixture()],
    );

ActiveAssignment activeAssignmentFixture() => ActiveAssignment(
      id: 'a1',
      name: 'Lower Body Strength — Block A',
      sessions: [
        TrainingAssignmentSession(
          id: 's1',
          label: 'A1 · Squat focus',
          orderIndex: 0,
          lastCompletedAt: DateTime(2026, 9, 24, 18, 30),
          exercises: [exerciseFixture(0), exerciseFixture(1)],
        ),
        TrainingAssignmentSession(
          id: 's2',
          label: 'A2 · Hinge focus',
          orderIndex: 1,
          exercises: [exerciseFixture(2)],
        ),
      ],
    );

List<CompletedSession> completedSessionsFixture() => [
      CompletedSession(
        assignmentSessionId: 's1',
        label: 'A1 · Squat focus',
        assignmentName: 'Lower Body Strength — Block A',
        personId: 'p1',
        completedAt: DateTime(2026, 9, 24, 18, 30),
        personName: 'Alexandra Kovačević',
      ),
      CompletedSession(
        assignmentSessionId: 's2',
        label: 'A2 · Hinge focus',
        assignmentName: 'Lower Body Strength — Block A',
        personId: 'p2',
        completedAt: DateTime(2026, 9, 23, 7, 15),
        personName: 'Bob',
      ),
    ];

List<Group> groupsFixture() => const [
      Group(id: 'g1', name: 'Monday Morning Squad', memberCount: 8),
      Group(id: 'g2', name: 'Physio — return to sport', memberCount: 0),
    ];

/// A session (with exercises) for the SessionEditorScreen render test.
TrainingSession sessionEditorFixture() => const TrainingSession(
      id: 's1',
      label: 'A1 · Squat focus',
      orderIndex: 0,
      exercises: [
        SessionExercise(
          id: 'se1',
          exerciseId: 'ex1',
          orderIndex: 0,
          exerciseName: 'Back Squat',
          sets: 4,
          reps: '8-10',
          rpe: '8',
        ),
        SessionExercise(
          id: 'se2',
          exerciseId: 'ex2',
          orderIndex: 1,
          exerciseName: 'Romanian Deadlift with a very long descriptive name',
          sets: 3,
          reps: '10',
        ),
      ],
    );

List<Client> clientsFixture() => const [
      Client(
          id: 'p1',
          firstName: 'Alexandra',
          lastName: 'Kovačević',
          hasAccount: true),
      Client(id: 'p2', firstName: 'Bob', lastName: 'Novak', hasAccount: false),
    ];
