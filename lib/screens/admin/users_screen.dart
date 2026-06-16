import 'package:flutter/material.dart';
import '../../config/theme.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => _showUserDialog(context, null),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _userCard('Admin User', 'admin@studytrack.com', 'ADMIN'),
          _userCard('Test User', 'user@studytrack.com', 'USER'),
        ],
      ),
    );
  }

  Widget _userCard(String name, String email, String role) {
    final isAdmin = role == 'ADMIN';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isAdmin
              ? AppTheme.accentGold.withOpacity(0.15)
              : AppTheme.primaryGreen.withOpacity(0.15),
          child: Text(
            name.substring(0, 1).toUpperCase(),
            style: TextStyle(
              color: isAdmin ? AppTheme.accentGold : AppTheme.primaryGreen,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        title: Text(name,
            style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w500)),
        subtitle: Text(email,
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isAdmin
                    ? AppTheme.accentGold.withOpacity(0.15)
                    : AppTheme.primaryGreen.withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                role,
                style: TextStyle(
                  color: isAdmin
                      ? AppTheme.accentGold
                      : AppTheme.primaryGreen,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert,
                  color: AppTheme.textSecondary, size: 18),
              onSelected: (value) {},
              itemBuilder: (_) => [
                const PopupMenuItem(
                    value: 'edit', child: Text('Edit User')),
                const PopupMenuItem(
                    value: 'toggle', child: Text('Toggle Role')),
                const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete',
                        style: TextStyle(color: AppTheme.errorRed))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showUserDialog(BuildContext context, int? index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(index == null ? 'Create User' : 'Edit User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            if (index == null) ...[
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
            ],
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: 'USER',
              decoration: const InputDecoration(labelText: 'Role'),
              items: const [
                DropdownMenuItem(value: 'USER', child: Text('User')),
                DropdownMenuItem(value: 'ADMIN', child: Text('Admin')),
              ],
              onChanged: (_) {},
            ),
          ],
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
