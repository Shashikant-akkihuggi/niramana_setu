import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:firebase_auth/firebase_auth.dart';
import '../common/models/project_model.dart';
import '../common/models/user_model.dart';
import '../common/services/firestore_service.dart';
import '../common/widgets/loading_overlay.dart';
import '../common/localization/app_localizations.dart';
import '../services/user_service.dart';

/// Create Project Screen for Engineers
/// Allows engineers to create new projects with owner and manager assignment
class CreateProjectScreen extends StatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> with LoadingStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _projectNameController = TextEditingController();
  final _ownerIdController = TextEditingController();
  final _managerIdController = TextEditingController();

  UserModel? _validatedOwner;
  UserModel? _validatedManager;
  bool _isValidatingIds = false;

  static const Color primary = Color(0xFF136DEC);
  static const Color accent = Color(0xFF7A5AF8);

  @override
  void dispose() {
    _projectNameController.dispose();
    _ownerIdController.dispose();
    _managerIdController.dispose();
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

                                  // Owner ID Input
                                  TextFormField(
                                    controller: _ownerIdController,
                                    decoration: InputDecoration(
                                      labelText: 'Owner ID',
                                      hintText: 'Enter owner ID (e.g., shas1234)',
                                      border: const OutlineInputBorder(),
                                      prefixIcon: const Icon(Icons.person),
                                      suffixIcon: _isValidatingIds
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: Padding(
                                                padding: EdgeInsets.all(12),
                                                child: CircularProgressIndicator(strokeWidth: 2),
                                              ),
                                            )
                                          : _validatedOwner != null
                                              ? const Icon(Icons.check_circle, color: Color(0xFF10B981))
                                              : null,
                                    ),
                                    onChanged: (value) {
                                      // Clear validation when user types
                                      if (_validatedOwner != null) {
                                        setState(() {
                                          _validatedOwner = null;
                                        });
                                      }
                                    },
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Please enter owner ID';
                                      }
                                      return null;
                                    },
                                  ),
                                  
                                  // Owner Preview
                                  if (_validatedOwner != null) ...[
                                    const SizedBox(height: 8),
                                    _buildUserPreview(_validatedOwner!, 'Owner'),
                                  ],
                                  
                                  const SizedBox(height: 16),

                                  // Manager ID Input
                                  TextFormField(
                                    controller: _managerIdController,
                                    decoration: InputDecoration(
                                      labelText: 'Manager ID',
                                      hintText: 'Enter manager ID (e.g., mana5678)',
                                      border: const OutlineInputBorder(),
                                      prefixIcon: const Icon(Icons.manage_accounts),
                                      suffixIcon: _isValidatingIds
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: Padding(
                                                padding: EdgeInsets.all(12),
                                                child: CircularProgressIndicator(strokeWidth: 2),
                                              ),
                                            )
                                          : _validatedManager != null
                                              ? const Icon(Icons.check_circle, color: Color(0xFF10B981))
                                              : null,
                                    ),
                                    onChanged: (value) {
                                      // Clear validation when user types
                                      if (_validatedManager != null) {
                                        setState(() {
                                          _validatedManager = null;
                                        });
                                      }
                                    },
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Please enter manager ID';
                                      }
                                      return null;
                                    },
                                  ),
                                  
                                  // Manager Preview
                                  if (_validatedManager != null) ...[
                                    const SizedBox(height: 8),
                                    _buildUserPreview(_validatedManager!, 'Manager'),
                                  ],
                                  
                                  const SizedBox(height: 16),

                                  // Validate IDs Button
                                  ElevatedButton.icon(
                                    onPressed: _isValidatingIds ? null : _validateIds,
                                    icon: _isValidatingIds
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : const Icon(Icons.search, size: 18),
                                    label: Text(_isValidatingIds ? 'Validating...' : 'Validate IDs'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF3B82F6),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
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

  Widget _buildUserPreview(UserModel user, String role) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFD4EDDA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFC3E6CB)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF155724), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$role: ${user.name}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF155724),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _canCreateProject() {
    return _validatedOwner != null && _validatedManager != null && !_isValidatingIds;
  }

  Future<void> _validateIds() async {
    if (_ownerIdController.text.trim().isEmpty || _managerIdController.text.trim().isEmpty) {
      _showError('Owner ID and Manager ID are required');
      return;
    }

    setState(() {
      _isValidatingIds = true;
      _validatedOwner = null;
      _validatedManager = null;
    });

    try {
      final result = await UserService.validateProjectUsers(
        ownerId: _ownerIdController.text.trim(),
        managerId: _managerIdController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _isValidatingIds = false;
        });

        if (result['success']) {
          setState(() {
            _validatedOwner = result['owner'];
            _validatedManager = result['manager'];
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('IDs validated successfully'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
        } else {
          _showError(result['error']);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isValidatingIds = false;
        });
        _showError('Failed to validate IDs: ${e.toString()}');
      }
    }
  }

  Future<void> _createProject() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (!_canCreateProject()) {
      _showError('Please validate Owner ID and Manager ID first');
      return;
    }

    await runWithLoading(() async {
      try {
        final currentUserId = FirestoreService.currentUserId;
        if (currentUserId == null) {
          throw Exception('User not authenticated');
        }

        // Debug logging (temporary)
        print('AUTH UID: ${FirebaseAuth.instance.currentUser!.uid}');
        print('ENGINEER ID IN PROJECT: $currentUserId');

        final project = ProjectModel(
          id: '', // Will be set by Firestore
          projectName: _projectNameController.text.trim(),
          createdBy: currentUserId,
          ownerId: _validatedOwner!.generatedId, // Store publicId for display
          managerId: _validatedManager!.generatedId, // Store publicId for display
          status: 'pending_owner_approval',
          createdAt: DateTime.now(),
          ownerUid: _validatedOwner!.uid, // Store Firebase UID for queries
          managerUid: _validatedManager!.uid, // Store Firebase UID for queries
          ownerName: _validatedOwner!.name, // Cache name for display
          managerName: _validatedManager!.name, // Cache name for display
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
}