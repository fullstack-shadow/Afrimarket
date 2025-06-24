import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/localization_service.dart';
import '../../../../core/themming/theme_manager.dart';
import '../../../../widgets/shared/app_bar.dart';
import '../controllers/admin_controller.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  UserFilter _currentFilter = UserFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeManager.currentTheme;
    final loc = LocalizationService.of(context);
    final controller = context.watch<AdminController>();

    return Scaffold(
      appBar: AdminAppBar(
        title: loc.translate('user_management_title'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt_outlined),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: loc.translate('search_users'),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          controller.searchUsers('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) => controller.searchUsers(value),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: controller.refreshUsers,
              child: _buildUserList(controller, theme, loc),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList(
    AdminController controller,
    ThemeData theme,
    LocalizationService loc,
  ) {
    if (controller.isLoadingUsers) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.filteredUsers.isEmpty) {
      return Center(
        child: Text(loc.translate('no_users_found')),
      );
    }

    return ListView.builder(
      itemCount: controller.filteredUsers.length,
      itemBuilder: (context, index) {
        final user = controller.filteredUsers[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.primaryColor.withOpacity(0.1),
              child: Icon(
                user.isSeller ? Icons.store_outlined : Icons.person_outline,
                color: theme.primaryColor,
              ),
            ),
            title: Text(user.name),
            subtitle: Text(user.email),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (user.isActive)
                  Icon(Icons.check_circle, color: Colors.green)
                else
                  Icon(Icons.block, color: Colors.red),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'toggle',
                      child: Text(
                        user.isActive
                            ? loc.translate('deactivate_user')
                            : loc.translate('activate_user'),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'view',
                      child: Text(loc.translate('view_details')),
                    ),
                    if (user.isSeller)
                      PopupMenuItem(
                        value: 'products',
                        child: Text(loc.translate('view_products')),
                      ),
                  ],
                  onSelected: (value) => _handleUserAction(
                    value,
                    user.id,
                    controller,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showFilterDialog() async {
    final loc = LocalizationService.of(context);
    final controller = context.read<AdminController>();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(loc.translate('filter_users')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: UserFilter.values.map((filter) {
              return RadioListTile<UserFilter>(
                title: Text(loc.translate(filter.name)),
                value: filter,
                groupValue: _currentFilter,
                onChanged: (value) {
                  setState(() => _currentFilter = value!);
                  controller.filterUsers(value!);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _handleUserAction(
    String action,
    String userId,
    AdminController controller,
  ) async {
    switch (action) {
      case 'toggle':
        await controller.toggleUserStatus(userId);
        break;
      case 'view':
        // Navigate to user details
        break;
      case 'products':
        // Navigate to user products
        break;
    }
  }
}

enum UserFilter { all, active, inactive, sellers, buyers }