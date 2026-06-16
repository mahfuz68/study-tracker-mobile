import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/puzzle_provider.dart';

class PuzzlesAdminScreen extends StatefulWidget {
  const PuzzlesAdminScreen({super.key});

  @override
  State<PuzzlesAdminScreen> createState() => _PuzzlesAdminScreenState();
}

class _PuzzlesAdminScreenState extends State<PuzzlesAdminScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PuzzleProvider>().loadPuzzles();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Puzzles'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showPuzzleDialog(context, null),
          ),
        ],
      ),
      body: Consumer<PuzzleProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final puzzles = provider.puzzles;
          if (puzzles.isEmpty) {
            return const Center(
              child: Text('No puzzles yet',
                  style: TextStyle(color: AppTheme.textSecondary)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: puzzles.length,
            itemBuilder: (context, index) {
              final p = puzzles[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: ListTile(
                  title: Text(p.title,
                      style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w500)),
                  subtitle: Text(
                    '${p.topic} • ${p.status} • ${p.questions.length} questions',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: p.status == 'PUBLISHED'
                              ? AppTheme.successGreen.withOpacity(0.15)
                              : AppTheme.warningAmber.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          p.status,
                          style: TextStyle(
                            color: p.status == 'PUBLISHED'
                                ? AppTheme.successGreen
                                : AppTheme.warningAmber,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit,
                            color: AppTheme.textSecondary, size: 18),
                        onPressed: () =>
                            _showPuzzleDialog(context, index),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete,
                            color: AppTheme.errorRed, size: 18),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showPuzzleDialog(BuildContext context, int? index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(index == null ? 'Create Puzzle' : 'Edit Puzzle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(labelText: 'Topic'),
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Scenario Paragraph',
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Time Limit (minutes)',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
