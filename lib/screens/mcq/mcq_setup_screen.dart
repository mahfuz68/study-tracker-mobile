import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/mcq_provider.dart';
import '../../providers/navigation_controller.dart';
import 'mcq_exam_screen.dart';

class McqSetupScreen extends StatefulWidget {
  const McqSetupScreen({super.key});

  @override
  State<McqSetupScreen> createState() => _McqSetupScreenState();
}

class _McqSetupScreenState extends State<McqSetupScreen> {
  int _questionCount = 10;
  bool _requestApplied = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mcq = context.read<McqProvider>();
      mcq.resetExam();
      mcq.loadSubjects();
      _applyRequest();
    });
  }

  void _applyRequest() {
    if (_requestApplied) return;
    final request = context.read<NavigationController>().pendingMcq;
    if (request != null) {
      if (request.subject != null) {
        context.read<McqProvider>().selectSubject(request.subject!);
      }
      if (request.topic != null) {
        context.read<McqProvider>().selectTopic(request.topic!);
      }
      context.read<NavigationController>().consumeMcqRequest();
      _requestApplied = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Exam Setup',
                  style: AppTheme.display(22, weight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(
                'Configure your MCQ exam parameters below.',
                style: AppTheme.body(13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 24),
              _SubjectDropdown(),
              const SizedBox(height: 12),
              _TopicDropdown(),
              const SizedBox(height: 28),
              Text('Number of Questions',
                  style: AppTheme.body(14, weight: FontWeight.w600)),
              const SizedBox(height: 14),
              _StepperCounter(
                value: _questionCount,
                min: 1,
                max: 50,
                step: 1,
                onChanged: (v) => setState(() => _questionCount = v),
              ),
              const SizedBox(height: 32),
              Consumer<McqProvider>(
                builder: (context, mcq, _) {
                  return _StartExamButton(
                    loading: mcq.isLoading,
                    onPressed: () => _startExam(context),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startExam(BuildContext context) async {
    final mcq = context.read<McqProvider>();
    await mcq.startExam(
      subject: mcq.selectedSubject,
      topic: mcq.selectedTopic,
      limit: _questionCount,
    );
    if (mcq.error == null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const McqExamScreen()),
      );
    }
  }
}

class _SubjectDropdown extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<McqProvider>(
      builder: (context, mcq, _) {
        return DropdownButtonFormField<String>(
          value: mcq.selectedSubject,
          decoration: const InputDecoration(
            labelText: 'Subject',
            prefixIcon: Icon(Icons.book_outlined, size: 20),
          ),
          items: [
            const DropdownMenuItem(value: null, child: Text('All Subjects')),
            ...mcq.subjects.map((s) =>
                DropdownMenuItem(value: s, child: Text(s))),
          ],
          onChanged: (v) => mcq.selectSubject(v),
        );
      },
    );
  }
}

class _TopicDropdown extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<McqProvider>(
      builder: (context, mcq, _) {
        return DropdownButtonFormField<String>(
          value: mcq.selectedTopic,
          decoration: const InputDecoration(
            labelText: 'Topic',
            prefixIcon: Icon(Icons.topic_outlined, size: 20),
          ),
          items: [
            const DropdownMenuItem(value: null, child: Text('All Topics')),
            ...mcq.topics.map((t) =>
                DropdownMenuItem(value: t, child: Text(t))),
          ],
          onChanged: (v) => mcq.selectTopic(v),
        );
      },
    );
  }
}

class _StepperCounter extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final int step;
  final ValueChanged<int> onChanged;

  const _StepperCounter({
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.remove_rounded, size: 20),
            onPressed: value > min
                ? () => onChanged(value - step)
                : null,
          ),
          const Spacer(),
          Text('$value',
              style: AppTheme.display(22, weight: FontWeight.w800)),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.add_rounded, size: 20),
            onPressed: value < max
                ? () => onChanged(value + step)
                : null,
          ),
        ],
      ),
    );
  }
}

class _StartExamButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onPressed;

  const _StartExamButton({
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        gradient: AppTheme.startExamGradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2.4, color: Colors.white))
            : Text('Start Exam',
                style: AppTheme.body(16,
                    weight: FontWeight.w700, color: Colors.white)),
      ),
    );
  }
}