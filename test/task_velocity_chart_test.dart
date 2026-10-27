import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:innoveity_app/models/app_models.dart';
import 'package:innoveity_app/widgets/task_velocity_chart_card.dart';

void main() {
  testWidgets('TaskVelocityChartCard renders accurately with empty tasks list', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TaskVelocityChartCard(
            tasks: [],
            isDark: false,
          ),
        ),
      ),
    );

    // Verify Title and elements
    expect(find.text('Task Velocity & Deliverables'), findsOneWidget);
    expect(find.text('0'), findsNWidgets(2)); // Total task count '0' + Y-axis baseline tick '0'
    expect(find.text('Tasks'), findsOneWidget);
    expect(find.text('0 completed (0%)'), findsOneWidget);

    // Verify X-axis status categories
    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('In Progress'), findsOneWidget);
    expect(find.text('Review'), findsOneWidget);
    expect(find.text('Approved'), findsOneWidget);
    expect(find.text('Rejected'), findsOneWidget);
  });

  testWidgets('TaskVelocityChartCard accurately categorizes task statuses and calculates completion percentage', (WidgetTester tester) async {
    final sampleTasks = [
      TaskItem(
        id: 'T1',
        title: 'Task 1',
        description: 'Desc',
        category: 'Cat',
        status: 'Pending',
        priority: 'High',
        progress: 0.0,
        dueDate: 'Today',
      ),
      TaskItem(
        id: 'T2',
        title: 'Task 2',
        description: 'Desc',
        category: 'Cat',
        status: 'In Progress',
        priority: 'Medium',
        progress: 0.5,
        dueDate: 'Tomorrow',
      ),
      TaskItem(
        id: 'T3',
        title: 'Task 3',
        description: 'Desc',
        category: 'Cat',
        status: 'In Review',
        priority: 'Normal',
        progress: 0.9,
        dueDate: 'Soon',
      ),
      TaskItem(
        id: 'T4',
        title: 'Task 4',
        description: 'Desc',
        category: 'Cat',
        status: 'Completed',
        priority: 'Urgent',
        progress: 1.0,
        dueDate: 'Yesterday',
      ),
      TaskItem(
        id: 'T5',
        title: 'Task 5',
        description: 'Desc',
        category: 'Cat',
        status: 'Rejected',
        priority: 'Low',
        progress: 0.0,
        dueDate: 'None',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TaskVelocityChartCard(
            tasks: sampleTasks,
            isDark: true,
          ),
        ),
      ),
    );

    // Verify 5 total tasks and 1 completed (20%)
    expect(find.text('5'), findsOneWidget);
    expect(find.text('Tasks'), findsOneWidget);
    expect(find.text('1 completed (20%)'), findsOneWidget);

    // Verify each category is displayed
    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('In Progress'), findsOneWidget);
    expect(find.text('Review'), findsOneWidget);
    expect(find.text('Approved'), findsOneWidget);
    expect(find.text('Rejected'), findsOneWidget);
  });
}
