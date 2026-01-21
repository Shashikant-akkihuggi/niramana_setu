import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../common/models/project_model.dart';
import '../common/services/firestore_service.dart';
import '../common/widgets/loading_overlay.dart';
import '../services/user_service.dart';
import '../services/project_reassignment_service.dart';

/// Create Project Screen for Engineers
/// Allows engineers to create new projects by selecting from existing users
class CreateProjectScreen extends StatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> with LoadingStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _projectNameController = TextEditingController();

  UserData? _selectedOwner;
  UserData? _selectedManager;
  List<UserData> _availableOwners = [];
  List<UserData> _availableManagers = [];
  bool _isLoadingUsers = false;

  static const Color primary = Color(0xFF136DEC);
  static const Color accent = Color(0xFF7A5AF8);

  @override
  void initState() {
    super.initState();
    _loadAvailableUsers();
  }

  Future<void> _loadAvailableUsers() async {
    setState(() => _isLoadingUsers = true);

    try {
      final results = await Future.wait([
        ProjectReassignmentService.getAvailableUsersByRole('owner'),
        ProjectReassignmentService.getAvailableUsersByRole('manager'),
      ]);

      if (mounted) {
        setState(() {
          _availableOwners = results[0];
          _availableManagers = results[1];
          _isLoadingUsers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingUsers = false);
        _showError('Failed to load users: ${e.toString()}');
      }
    }
  }

  @override
  void dispose() {
    _projectNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: isLoading,
      message: 'Creating project...',
      child: Scaffold(
        body: Stack(
          children: [
            // Background gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primary.withValues(alpha: 0.12),
                    accent.withValues(alpha: 0.10),
                    Colors.white,
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.arrow_back),
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Create New Project',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Form
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
                            ),
                            padding: const EdgeInsets.all(24),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Text(
                                    'Project Details',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1F2937),
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Project Name
                                  TextFormField(
                                    controller: _projectNameController,
                                    decoration: const InputDecoration(
                                      labelText: 'Project Name',
                                      hintText: 'Enter project name',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.apartment),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Please enter a project name';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),

                                  // Owner Selection
                                  _buildUserDropdown(
                                    label: 'Select Owner',
                                    icon: Icons.person,
                                    users: _availableOwners,
                                    selectedUser: _selectedOwner,
                                    onChanged: (user) => setState(() => _selectedOwner = user),
                                    isLoading: _isLoadingUsers,
                                  ),
                                  const SizedBox(height: 16),

                                  // Manager Selection
                                  _buildUserDropdown(
                                    label: 'Select Manager',
                                    icon: Icons.manage_accounts,
                                    users: _availableManagers,
                                    selectedUser: _selectedManager,
                                    onChanged: (user) => setState(() => _selectedManager = user),
                                    isLoading: _isLoadingUsers,
                                  ),
                                  const SizedBox(height: 24),

                                  // Info Note
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE0F2FE),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFBAE6FD)),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.info, color: Color(0xFF0369A1)),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Validate IDs first to ensure they exist and have correct roles. The project will be created with "Pending Owner Approval" status.',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF0369A1),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Create Button
                                  LoadingButton(
                                    isLoading: isLoading,
                                    onPressed: _canCreateProject() ? _createProject : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _canCreateProject() ? primary : Colors.grey,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text(
                                      'Create Project',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canCreateProject() {
    return _selectedOwner != null && _selectedManager != null && !_isLoadingUsers;
  }

  Future<void> _createProject() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (!_canCreateProject()) {
      _showError('Please select both Owner and Manager');
      return;
    }

    await runWithLoading(() async {
      try {
        final currentUserId = FirestoreService.currentUserId;
        if (currentUserId == null) {
          throw Exception('User not authenticated');
        }

        // DEBUG: Log current user UID
        print('🔐 CREATE PROJECT - Engineer UID: $currentUserId');
        print('👤 CREATE PROJECT - Selected Owner: ${_selectedOwner!.fullName} (${_selectedOwner!.uid})');
        print('👤 CREATE PROJECT - Selected Manager: ${_selectedManager!.fullName} (${_selectedManager!.uid})');

        final project = ProjectModel(
          id: '', // Will be set by Firestore
          projectName: _projectNameController.text.trim(),
          createdBy: currentUserId,
          ownerId: _selectedOwner!.publicId ?? _selectedOwner!.uid, // Store publicId for display
          managerId: _selectedManager!.publicId ?? _selectedManager!.uid, // Store publicId for display
          status: 'pending_owner_approval',
          createdAt: DateTime.now(),
          ownerUid: _selectedOwner!.uid, // Store Firebase UID for queries
          managerUid: _selectedManager!.uid, // Store Firebase UID for queries
          ownerName: _selectedOwner!.fullName, // Cache name for display
          managerName: _selectedManager!.fullName, // Cache name for display
        );

        final projectId = await FirestoreService.createProject(project);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Project "${project.projectName}" created successfully!'),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          _showError('Failed to create project: ${e.toString()}');
        }
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFEF4444),
      ),
    );
  }

  Widget _buildUserDropdown({
    required String label,
    required IconData icon,
    required List<UserData> users,
    required UserData? selectedUser,
    required ValueChanged<UserData?> onChanged,
    required bool isLoading,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: isLoading
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text('Loading users...'),
                    ],
                  ),
                )
              : users.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange[600]),
                          const SizedBox(width: 12),
                          Text('No ${label.toLowerCase()}s available'),
                        ],
                      ),
                    )
                  : DropdownButtonFormField<UserData>(
                      value: selectedUser,
                      decoration: InputDecoration(
                        prefixIcon: Icon(icon),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                      ),
                      hint: Text('Select ${label.toLowerCase()}'),
                      items: users.map((user) {
                        return DropdownMenuItem<UserData>(
                          value: user,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                user.fullName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (user.publicId != null)
                                Text(
                                  'ID: ${user.publicId}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: onChanged,
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a ${label.toLowerCase()}';
                        }
                        return null;
                      },
                    ),
        ),
      ],
    );
  }
}