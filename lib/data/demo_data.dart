import 'package:uuid/uuid.dart';
import '../models/deadline.dart';

class DemoData {
  DemoData._();

  static List<Deadline> getSampleDeadlines([DateTime? baseTime]) {
    final now = baseTime ?? DateTime.now();

    return [
      Deadline(
        id: const Uuid().v4(),
        title: 'Machine Learning Project',
        description: 'Complete data preprocessing, model tuning, and evaluation matrix.',
        category: DeadlineCategory.project,
        priority: DeadlinePriority.high,
        createdAt: now.subtract(const Duration(days: 4)),
        deadlineDateTime: now.add(const Duration(hours: 18, minutes: 30)),
        subtasks: [
          Subtask(id: 's1', title: 'Collect dataset', isCompleted: true),
          Subtask(id: 's2', title: 'Clean data', isCompleted: true),
          Subtask(id: 's3', title: 'Train model', isCompleted: false),
          Subtask(id: 's4', title: 'Create presentation', isCompleted: false),
          Subtask(id: 's5', title: 'Submit project', isCompleted: false),
        ],
      ),
      Deadline(
        id: const Uuid().v4(),
        title: 'Distributed Systems Exam',
        description: 'Review Paxos, Raft consensus, two-phase commits, and vector clocks.',
        category: DeadlineCategory.exam,
        priority: DeadlinePriority.high,
        createdAt: now.subtract(const Duration(days: 3)),
        deadlineDateTime: now.add(const Duration(days: 2, hours: 4)),
        subtasks: [
          Subtask(id: 's6', title: 'Review lecture slide decks', isCompleted: true),
          Subtask(id: 's7', title: 'Solve 2024 past paper problem sets', isCompleted: false),
        ],
      ),
      Deadline(
        id: const Uuid().v4(),
        title: 'Global Hackathon Prototype',
        description: 'Record video demo, write documentation, and deploy cloud service.',
        category: DeadlineCategory.hackathon,
        priority: DeadlinePriority.medium,
        createdAt: now.subtract(const Duration(days: 1)),
        deadlineDateTime: now.add(const Duration(days: 5, hours: 12)),
        subtasks: [
          Subtask(id: 's8', title: 'Record 3-minute video demo', isCompleted: false),
          Subtask(id: 's9', title: 'Deploy backend staging instance', isCompleted: true),
        ],
      ),
    ];
  }
}
