import 'package:flutter/material.dart';
import '../../config/theme.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Panel')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Admin Dashboard',
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text(
              'Manage your study platform',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 24),
            _card(
              context,
              Icons.view_list,
              'Routine Management',
              'Add, edit, reorder study topics',
              AppTheme.primaryGreen,
              '/admin/routine',
            ),
            _card(
              context,
              Icons.help,
              'Question Bank',
              'Manage MCQ questions',
              AppTheme.infoBlue,
              '/admin/questions',
            ),
            _card(
              context,
              Icons.extension,
              'Puzzles',
              'Create and manage logic puzzles',
              AppTheme.accentGold,
              '/admin/puzzles',
            ),
            _card(
              context,
              Icons.people,
              'Users',
              'Manage user accounts and roles',
              AppTheme.errorRed,
              '/admin/users',
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    Color color,
    String route,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(title,
            style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle,
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 12)),
        trailing: const Icon(Icons.chevron_right,
            color: AppTheme.textSecondary),
        onTap: () => Navigator.pushNamed(context, route),
      ),
    );
  }
}
