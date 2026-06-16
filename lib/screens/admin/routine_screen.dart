import 'package:flutter/material.dart';
import '../../config/theme.dart';

class RoutineScreen extends StatefulWidget {
  const RoutineScreen({super.key});

  @override
  State<RoutineScreen> createState() => _RoutineScreenState();
}

class _RoutineScreenState extends State<RoutineScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Routine Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Add topic (simulated)')),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: List.generate(4, (dayIndex) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: ExpansionTile(
              title: Text('Day ${dayIndex + 1}',
                  style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600)),
              subtitle: Text('Week ${dayIndex + 1}',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12)),
              initiallyExpanded: true,
              children: List.generate(4, (topicIndex) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      ReorderableDragStartListener(
                        index: topicIndex,
                        child: const Icon(Icons.drag_handle,
                            color: AppTheme.textSecondary),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _subjects[topicIndex],
                              style: const TextStyle(
                                  color: AppTheme.primaryGreenLight,
                                  fontSize: 12),
                            ),
                            Text(
                              _topics[topicIndex],
                              style: const TextStyle(
                                  color: AppTheme.textPrimary),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${_durations[topicIndex]}m',
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.edit,
                            color: AppTheme.textSecondary, size: 18),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete,
                            color: AppTheme.errorRed, size: 18),
                        onPressed: () {},
                      ),
                    ],
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }
}

const _subjects = [
  'Bangla',
  'English',
  'Vocabulary',
  'Math',
];
const _topics = [
  'বাস্তব সংখ্যা',
  'Grammar',
  'Word List 1',
  'Algebra',
];
const _durations = [45, 30, 20, 60];
