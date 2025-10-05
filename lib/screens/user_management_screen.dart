import 'package:flutter/material.dart';

import '../models/admin_models.dart';
import '../services/admin_service.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final AdminService _adminService = AdminService();
  final TextEditingController _searchController = TextEditingController();
  
  List<AdminUser> _allUsers = [];
  List<AdminUser> _filteredUsers = [];
  bool _isLoading = true;
  String _selectedStatusFilter = 'All';
  String _selectedRoleFilter = 'All';
  bool _isSelectionMode = false;
  final Set<String> _selectedUsers = <String>{};

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _setupSearchListener();
  }

  void _setupSearchListener() {
    _searchController.addListener(() {
      _filterUsers();
    });
  }

  Future<void> _loadUsers() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final users = await _adminService.getAllUsers();
      
      setState(() {
        _allUsers = users;
        _filteredUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Failed to load users: $e');
    }
  }

  void _filterUsers() {
    String query = _searchController.text.toLowerCase();
    
    setState(() {
      _filteredUsers = _allUsers.where((user) {
        final matchesSearch = user.displayName.toLowerCase().contains(query) ||
            user.email.toLowerCase().contains(query) ||
            user.userId.toLowerCase().contains(query);
        
        final matchesStatus = _selectedStatusFilter == 'All' ||
            (_selectedStatusFilter == 'Active' && user.status == UserStatus.active) ||
            (_selectedStatusFilter == 'Banned' && user.status == UserStatus.banned) ||
            (_selectedStatusFilter == 'Suspended' && user.status == UserStatus.suspended);
        
        final matchesRole = _selectedRoleFilter == 'All' ||
            user.role.toString().split('.').last.toLowerCase() == 
            _selectedRoleFilter.toLowerCase();
        
        return matchesSearch && matchesStatus && matchesRole;
      }).toList();
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isSelectionMode 
            ? '${_selectedUsers.length} selected' 
            : 'User Management'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              onPressed: _selectedUsers.isNotEmpty ? _showBulkActions : null,
              icon: const Icon(Icons.more_vert),
              tooltip: 'Bulk Actions',
            ),
            IconButton(
              onPressed: _exitSelectionMode,
              icon: const Icon(Icons.close),
              tooltip: 'Cancel Selection',
            ),
          ] else ...[
            IconButton(
              onPressed: _loadUsers,
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
            ),
            IconButton(
              onPressed: _enterSelectionMode,
              icon: const Icon(Icons.checklist),
              tooltip: 'Select Multiple',
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Search and filters
          _buildSearchAndFilters(),
          
          // Users list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildUsersList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateUserDialog,
        backgroundColor: Colors.indigo,
        tooltip: 'Add User',
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search users by name, email, or ID...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                      },
                      icon: const Icon(Icons.clear),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.indigo),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Filters
          Row(
            children: [
              Expanded(
                child: _buildFilterDropdown(
                  'Status',
                  _selectedStatusFilter,
                  ['All', 'Active', 'Banned', 'Suspended'],
                  (value) {
                    setState(() {
                      _selectedStatusFilter = value!;
                    });
                    _filterUsers();
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildFilterDropdown(
                  'Role',
                  _selectedRoleFilter,
                  ['All', 'User', 'Moderator', 'Admin', 'SuperAdmin'],
                  (value) {
                    setState(() {
                      _selectedRoleFilter = value!;
                    });
                    _filterUsers();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(String label, String value, List<String> options, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: options.map((option) => DropdownMenuItem(
        value: option,
        child: Text(option),
      )).toList(),
    );
  }

  Widget _buildUsersList() {
    if (_filteredUsers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No users found', style: TextStyle(fontSize: 18, color: Colors.grey)),
            Text('Try adjusting your search or filters', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.builder(
        itemCount: _filteredUsers.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final user = _filteredUsers[index];
          return _buildUserCard(user);
        },
      ),
    );
  }

  Widget _buildUserCard(AdminUser user) {
    final isSelected = _selectedUsers.contains(user.userId);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isSelected ? 4 : 1,
      child: InkWell(
        onTap: _isSelectionMode ? () => _toggleUserSelection(user.userId) : () => _showUserDetails(user),
        onLongPress: !_isSelectionMode ? () => _toggleUserSelection(user.userId) : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isSelected ? Border.all(color: Colors.indigo, width: 2) : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Selection checkbox
                if (_isSelectionMode)
                  Checkbox(
                    value: isSelected,
                    onChanged: (_) => _toggleUserSelection(user.userId),
                  ),
                
                // Avatar
                CircleAvatar(
                  radius: 24,
                  backgroundColor: _getUserStatusColor(user.status).withOpacity(0.2),
                  child: user.profileImageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.network(
                            user.profileImageUrl!,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildAvatarFallback(user);
                            },
                          ),
                        )
                      : _buildAvatarFallback(user),
                ),
                
                const SizedBox(width: 16),
                
                // User info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        user.email,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildStatusChip(user.status),
                          const SizedBox(width: 8),
                          _buildRoleChip(user.role),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Action button
                if (!_isSelectionMode)
                  PopupMenuButton<String>(
                    onSelected: (action) => _handleUserAction(action, user),
                    itemBuilder: (context) => _buildUserMenuItems(user),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarFallback(AdminUser user) {
    return Text(
      user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : 'U',
      style: TextStyle(
        color: _getUserStatusColor(user.status),
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildStatusChip(UserStatus status) {
    Color color;
    String label;
    
    switch (status) {
      case UserStatus.active:
        color = Colors.green;
        label = 'Active';
        break;
      case UserStatus.banned:
        color = Colors.red;
        label = 'Banned';
        break;
      case UserStatus.suspended:
        color = Colors.orange;
        label = 'Suspended';
        break;
      case UserStatus.inactive:
        color = Colors.grey;
        label = 'Inactive';
        break;
      case UserStatus.pendingVerification:
        color = Colors.blueGrey;
        label = 'Pending Verification';
        break;
      case UserStatus.deleted:
        color = Colors.black54;
        label = 'Deleted';
        break;
    }
    
    return Chip(
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.white,
        ),
      ),
      backgroundColor: color,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildRoleChip(UserRole role) {
    return Chip(
      label: Text(
        role.toString().split('.').last.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          color: Colors.white,
        ),
      ),
      backgroundColor: Colors.indigo,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Color _getUserStatusColor(UserStatus status) {
    switch (status) {
      case UserStatus.active:
        return Colors.green;
      case UserStatus.banned:
        return Colors.red;
      case UserStatus.suspended:
        return Colors.orange;
      case UserStatus.inactive:
        return Colors.grey;
      case UserStatus.pendingVerification:
        return Colors.blueGrey;
      case UserStatus.deleted:
        return Colors.black54;
    }
  }

  List<PopupMenuEntry<String>> _buildUserMenuItems(AdminUser user) {
    final currentAdmin = _adminService.currentAdmin;
    final canModerate = currentAdmin != null && 
        _adminService.hasPermission(currentAdmin, AdminPermission.moderateUsers);
    final canManageRoles = currentAdmin != null && 
        _adminService.hasPermission(currentAdmin, AdminPermission.manageRoles);
    
    List<PopupMenuEntry<String>> items = [
      const PopupMenuItem(value: 'view', child: Text('View Details')),
    ];
    
    if (canModerate) {
      if (user.status == UserStatus.active) {
        items.addAll([
          const PopupMenuItem(value: 'suspend', child: Text('Suspend')),
          const PopupMenuItem(value: 'ban', child: Text('Ban')),
        ]);
      } else {
        items.add(const PopupMenuItem(value: 'unban', child: Text('Reactivate')));
      }
    }
    
    if (canManageRoles) {
      items.add(const PopupMenuItem(value: 'changeRole', child: Text('Change Role')));
    }
    
    items.add(const PopupMenuItem(value: 'message', child: Text('Send Message')));
    
    return items;
  }

  void _toggleUserSelection(String userId) {
    if (!_isSelectionMode) {
      _enterSelectionMode();
    }
    
    setState(() {
      if (_selectedUsers.contains(userId)) {
        _selectedUsers.remove(userId);
      } else {
        _selectedUsers.add(userId);
      }
    });
  }

  void _enterSelectionMode() {
    setState(() {
      _isSelectionMode = true;
      _selectedUsers.clear();
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedUsers.clear();
    });
  }

  void _handleUserAction(String action, AdminUser user) {
    switch (action) {
      case 'view':
        _showUserDetails(user);
        break;
      case 'suspend':
        _suspendUser(user);
        break;
      case 'ban':
        _banUser(user);
        break;
      case 'unban':
        _reactivateUser(user);
        break;
      case 'changeRole':
        _showChangeRoleDialog(user);
        break;
      case 'message':
        _sendMessage(user);
        break;
    }
  }

  void _showUserDetails(AdminUser user) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(20),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: _getUserStatusColor(user.status).withOpacity(0.2),
                    child: user.profileImageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: Image.network(
                              user.profileImageUrl!,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildAvatarFallback(user);
                              },
                            ),
                          )
                        : _buildAvatarFallback(user),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.displayName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          user.email,
                          style: const TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              _buildDetailRow('User ID', user.userId),
              _buildDetailRow('Status', user.status.toString().split('.').last),
              _buildDetailRow('Role', user.role.toString().split('.').last),
              _buildDetailRow('Created', _formatDateTime(user.createdAt)),
              _buildDetailRow('Last Active', user.lastActiveAt != null ? _formatDateTime(user.lastActiveAt!) : 'Never'),
              
              if (user.metadata != null && user.metadata!.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Additional Info:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...user.metadata!.entries.map((entry) => 
                  _buildDetailRow(entry.key, entry.value.toString())),
              ],
              
              const SizedBox(height: 20),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value ?? '-'),
          ),
        ],
      ),
    );
  }

  Future<void> _suspendUser(AdminUser user) async {
    final confirmed = await _showConfirmationDialog(
      'Suspend User',
      'Are you sure you want to suspend ${user.displayName}?',
    );
    
    if (confirmed) {
      try {
        await _adminService.suspendUser(user.userId, 'Suspended by admin');
        _showSuccess('${user.displayName} has been suspended');
        _loadUsers();
      } catch (e) {
        _showError('Failed to suspend user: $e');
      }
    }
  }

  Future<void> _banUser(AdminUser user) async {
    final confirmed = await _showConfirmationDialog(
      'Ban User',
      'Are you sure you want to ban ${user.displayName}? This action is more severe than suspension.',
    );
    
    if (confirmed) {
      try {
        await _adminService.banUser(user.userId, 'Banned by admin');
        _showSuccess('${user.displayName} has been banned');
        _loadUsers();
      } catch (e) {
        _showError('Failed to ban user: $e');
      }
    }
  }

  Future<void> _reactivateUser(AdminUser user) async {
    final confirmed = await _showConfirmationDialog(
      'Reactivate User',
      'Are you sure you want to reactivate ${user.displayName}?',
    );
    
    if (confirmed) {
      try {
        await _adminService.reactivateUser(user.userId);
        _showSuccess('${user.displayName} has been reactivated');
        _loadUsers();
      } catch (e) {
        _showError('Failed to reactivate user: $e');
      }
    }
  }

  void _showChangeRoleDialog(AdminUser user) {
    UserRole selectedRole = user.role;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Change Role for ${user.displayName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: UserRole.values.map((role) => RadioListTile<UserRole>(
              title: Text(role.toString().split('.').last.toUpperCase()),
              value: role,
              groupValue: selectedRole,
              onChanged: (value) {
                setState(() {
                  selectedRole = value!;
                });
              },
            )).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await _adminService.updateUserRole(user.userId, selectedRole);
                  _showSuccess('Role updated successfully');
                  _loadUsers();
                } catch (e) {
                  _showError('Failed to update role: $e');
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage(AdminUser user) {
    // TODO: Implement message sending
    _showSuccess('Message feature coming soon!');
  }

  void _showBulkActions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Bulk Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.block, color: Colors.red),
              title: const Text('Ban Selected Users'),
              onTap: () {
                Navigator.pop(context);
                _bulkBanUsers();
              },
            ),
            ListTile(
              leading: const Icon(Icons.pause, color: Colors.orange),
              title: const Text('Suspend Selected Users'),
              onTap: () {
                Navigator.pop(context);
                _bulkSuspendUsers();
              },
            ),
            ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: const Text('Reactivate Selected Users'),
              onTap: () {
                Navigator.pop(context);
                _bulkReactivateUsers();
              },
            ),
            ListTile(
              leading: const Icon(Icons.message),
              title: const Text('Send Message to Selected'),
              onTap: () {
                Navigator.pop(context);
                _bulkSendMessage();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _bulkBanUsers() async {
    final confirmed = await _showConfirmationDialog(
      'Ban Users',
      'Are you sure you want to ban ${_selectedUsers.length} selected users?',
    );
    
    if (confirmed) {
      // TODO: Implement bulk ban
      _showSuccess('${_selectedUsers.length} users banned');
      _exitSelectionMode();
      _loadUsers();
    }
  }

  Future<void> _bulkSuspendUsers() async {
    final confirmed = await _showConfirmationDialog(
      'Suspend Users',
      'Are you sure you want to suspend ${_selectedUsers.length} selected users?',
    );
    
    if (confirmed) {
      // TODO: Implement bulk suspend
      _showSuccess('${_selectedUsers.length} users suspended');
      _exitSelectionMode();
      _loadUsers();
    }
  }

  Future<void> _bulkReactivateUsers() async {
    final confirmed = await _showConfirmationDialog(
      'Reactivate Users',
      'Are you sure you want to reactivate ${_selectedUsers.length} selected users?',
    );
    
    if (confirmed) {
      // TODO: Implement bulk reactivate
      _showSuccess('${_selectedUsers.length} users reactivated');
      _exitSelectionMode();
      _loadUsers();
    }
  }

  void _bulkSendMessage() {
    // TODO: Implement bulk message
    _showSuccess('Bulk message feature coming soon!');
    _exitSelectionMode();
  }

  void _showCreateUserDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    UserRole selectedRole = UserRole.user;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create New User'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Display Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<UserRole>(
                value: selectedRole,
                onChanged: (value) {
                  setState(() {
                    selectedRole = value!;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                ),
                items: UserRole.values.map((role) => DropdownMenuItem(
                  value: role,
                  child: Text(role.toString().split('.').last.toUpperCase()),
                )).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty && emailController.text.isNotEmpty) {
                  Navigator.pop(context);
                  // TODO: Implement user creation
                  _showSuccess('User creation feature coming soon!');
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _showConfirmationDialog(String title, String message) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} '
           '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}