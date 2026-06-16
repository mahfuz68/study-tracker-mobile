import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/admin_provider.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _adminTile(
            context,
            icon: Icons.quiz,
            title: 'MCQ Questions',
            subtitle: 'Manage question bank',
            onTap: () => Navigator.pushNamed(context, '/admin/questions'),
          ),
          const SizedBox(height: 12),
          _adminTile(
            context,
            icon: Icons.calendar_today,
            title: 'Study Routine',
            subtitle: 'Manage study days and topics',
            onTap: () => Navigator.pushNamed(context, '/admin/routine'),
          ),
          const SizedBox(height: 12),
          _adminTile(
            context,
            icon: Icons.extension,
            title: 'Puzzles',
            subtitle: 'Manage puzzle library',
            onTap: () => Navigator.pushNamed(context, '/admin/puzzles'),
          ),
          const SizedBox(height: 12),
          _adminTile(
            context,
            icon: Icons.people,
            title: 'Users',
            subtitle: 'Manage user accounts',
            onTap: () => Navigator.pushNamed(context, '/admin/users'),
          ),
        ],
      ),
    );
  }

  Widget _adminTile(BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppTheme.primaryGreen, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}

class AdminQuestionsScreen extends StatefulWidget {
  const AdminQuestionsScreen({super.key});

  @override
  State<AdminQuestionsScreen> createState() => _AdminQuestionsScreenState();
}

class _AdminQuestionsScreenState extends State<AdminQuestionsScreen> {
  String? _selectedSubject;
  String? _selectedTopic;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadQuestions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MCQ Questions')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddQuestionDialog(context),
        backgroundColor: AppTheme.primaryGreen,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // Filter row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Consumer<AdminProvider>(
                    builder: (context, admin, _) {
                      return DropdownButton<String>(
                        value: _selectedSubject,
                        hint: const Text('All Subjects'),
                        isExpanded: true,
                        dropdownColor: AppTheme.card,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        items: admin.subjects
                            .map((s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(s),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() => _selectedSubject = value);
                          admin.loadQuestions(
                            subject: value,
                            topic: _selectedTopic,
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Consumer<AdminProvider>(
                    builder: (context, admin, _) {
                      return DropdownButton<String>(
                        value: _selectedTopic,
                        hint: const Text('All Topics'),
                        isExpanded: true,
                        dropdownColor: AppTheme.card,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        items: admin.topics
                            .map((t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(t),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() => _selectedTopic = value);
                          admin.loadQuestions(
                            subject: _selectedSubject,
                            topic: value,
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Questions list
          Expanded(
            child: Consumer<AdminProvider>(
              builder: (context, admin, _) {
                if (admin.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                return ListView.builder(
                  itemCount: admin.questions.length,
                  itemBuilder: (context, index) {
                    final q = admin.questions[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: AppTheme.primaryGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      title: Text(
                        q.question,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text('${q.subject} • ${q.topic}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _confirmDelete(context, q.id),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddQuestionDialog(BuildContext context) {
    final subjectController = TextEditingController();
    final topicController = TextEditingController();
    final questionController = TextEditingController();
    final optionAController = TextEditingController();
    final optionBController = TextEditingController();
    final optionCController = TextEditingController();
    final optionDController = TextEditingController();
    int correctAnswer = 0;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: const Text('Add Question'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: subjectController,
                      decoration: const InputDecoration(
                        labelText: 'Subject',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: topicController,
                      decoration: const InputDecoration(
                        labelText: 'Topic',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: questionController,
                      decoration: const InputDecoration(
                        labelText: 'Question',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: optionAController,
                      decoration: const InputDecoration(labelText: 'Option A'),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: optionBController,
                      decoration: const InputDecoration(labelText: 'Option B'),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: optionCController,
                      decoration: const InputDecoration(labelText: 'Option C'),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: optionDController,
                      decoration: const InputDecoration(labelText: 'Option D'),
                    ),
                    const SizedBox(height: 8),
                    DropdownButton<int>(
                      value: correctAnswer,
                      items: const [
                        DropdownMenuItem(value: 0, child: Text('A')),
                        DropdownMenuItem(value: 1, child: Text('B')),
                        DropdownMenuItem(value: 2, child: Text('C')),
                        DropdownMenuItem(value: 3, child: Text('D')),
                      ],
                      onChanged: (value) {
                        setState(() => correctAnswer = value!);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    final admin = context.read<AdminProvider>();
                    await admin.addQuestion(
                      subject: subjectController.text,
                      topic: topicController.text,
                      question: questionController.text,
                      options: [
                        optionAController.text,
                        optionBController.text,
                        optionCController.text,
                        optionDController.text,
                      ],
                      correct: correctAnswer,
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, int id) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Delete Question'),
          content: const Text('Are you sure you want to delete this question?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final admin = context.read<AdminProvider>();
                await admin.deleteQuestion(id);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Delete', style: TextStyle(color: AppTheme.errorRed)),
            ),
          ],
        );
      },
    );
  }
}

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Users')),
      body: Consumer<AdminProvider>(
        builder: (context, admin, _) {
          if (admin.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView.builder(
            itemCount: admin.users.length,
            itemBuilder: (context, index) {
              final u = admin.users[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                  child: Text(
                    u.name.isNotEmpty ? u.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: AppTheme.primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                title: Text(u.name),
                subtitle: Text(u.email),
                trailing: DropdownButton<String>(
                  value: u.role,
                  items: const [
                    DropdownMenuItem(value: 'USER', child: Text('User')),
                    DropdownMenuItem(value: 'ADMIN', child: Text('Admin')),
                  ],
                  onChanged: (value) async {
                    if (value != null) {
                      await admin.updateUserRole(u.id, value);
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class AdminRoutineScreen extends StatelessWidget {
  const AdminRoutineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Study Routine')),
      body: const Center(
        child: Text(
          'Routine management coming soon',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      ),
    );
  }
}

class AdminPuzzlesScreen extends StatelessWidget {
  const AdminPuzzlesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Puzzle Management')),
      body: const Center(
        child: Text(
          'Puzzle management coming soon',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      ),
    );
  }
}
