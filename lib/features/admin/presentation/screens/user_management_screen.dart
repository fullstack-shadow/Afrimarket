import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserManagementScreen extends ConsumerWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Replace with actual data from a provider
    final users = List.generate(
      10,
      (index) => {
        'id': 'user_$index',
        'name': 'User ${index + 1}',
        'email': 'user$index@example.com',
        'role': index % 3 == 0 ? 'Admin' : 'User',
        'status': index % 2 == 0 ? 'Active' : 'Inactive',
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return ListTile(
            leading: CircleAvatar(
              child: Text(user['name']!.substring(0, 1)),
            ),
            title: Text(user['name']!),
            subtitle: Text(user['email']!),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Chip(
                  label: Text(
                    user['status']!,
                    style: TextStyle(
                      color: user['status'] == 'Active'
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                  backgroundColor: user['status'] == 'Active'
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: () {
              // TODO: Navigate to user details
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement add user
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
