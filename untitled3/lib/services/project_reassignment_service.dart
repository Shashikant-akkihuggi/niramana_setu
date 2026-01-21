import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_service.dart';

/// Service for handling project reassignment when users recreate accounts
/// Provides secure methods for engineers to reassign projects to new user UIDs
class ProjectReassignmentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user ID
  static String? get currentUserId => _auth.currentUser?.uid;

  /// Get projects that need reassignment (orphaned projects)
  /// These are projects where owner/manager UIDs don't exist in users collection
  static Future<List<Map<String, dynamic>>> getOrphanedProjects() async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Get all projects created by current engineer
      final projectsSnapshot = await _firestore
          .collection('projects')
          .where('createdBy', isEqualTo: currentUserId)
          .get();

      final orphanedProjects = <Map<String, dynamic>>[];

      for (final projectDoc in projectsSnapshot.docs) {
        final projectData = projectDoc.data();
        final ownerId = projectData['ownerId'] as String?;
        final managerId = projectData['managerId'] as String?;

        // Check if owner UID exists in users collection
        bool ownerExists = false;
        bool managerExists = false;

        if (ownerId != null && ownerId.isNotEmpty) {
          final ownerDoc = await _firestore
              .collection('users')
              .doc(ownerId)
              .get();
          ownerExists = ownerDoc.exists;
        }

        if (managerId != null && managerId.isNotEmpty) {
          final managerDoc = await _firestore
              .collection('users')
              .doc(managerId)
              .get();
          managerExists = managerDoc.exists;
        }

        // If either owner or manager doesn't exist, it's orphaned
        if (!ownerExists || !managerExists) {
          orphanedProjects.add({
            'projectId': projectDoc.id,
            'projectName': projectData['projectName'] ?? 'Unknown Project',
            'ownerId': ownerId,
            'managerId': managerId,
            'ownerExists': ownerExists,
            'managerExists': managerExists,
            'status': projectData['status'] ?? 'unknown',
            'createdAt': projectData['createdAt'],
          });
        }
      }

      return orphanedProjects;
    } catch (e) {
      print('ProjectReassignmentService.getOrphanedProjects error: $e');
      throw Exception('Failed to get orphaned projects: ${e.toString()}');
    }
  }

  /// Reassign project owner to a new user
  /// Only the project creator (engineer) can perform this action
  static Future<void> reassignProjectOwner({
    required String projectId,
    required String newOwnerPublicId,
  }) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Validate the new owner exists and has correct role
      final ownerValidation = await UserService.validateProjectUsers(
        ownerId: newOwnerPublicId,
        managerId: 'dummy', // We only need to validate owner
      );

      if (!ownerValidation['success'] && !ownerValidation['error'].contains('Manager ID')) {
        throw Exception(ownerValidation['error']);
      }

      final newOwner = ownerValidation['owner'];
      if (newOwner == null) {
        throw Exception('Owner not found');
      }

      // Verify the current user is the project creator
      final projectDoc = await _firestore
          .collection('projects')
          .doc(projectId)
          .get();

      if (!projectDoc.exists) {
        throw Exception('Project not found');
      }

      final projectData = projectDoc.data()!;
      if (projectData['createdBy'] != currentUserId) {
        throw Exception('Only the project creator can reassign projects');
      }

      // Update project with new owner information
      await _firestore.collection('projects').doc(projectId).update({
        'ownerId': newOwner.uid, // Store Firebase UID for queries
        'ownerPublicId': newOwner.publicId, // Store publicId for display
        'ownerName': newOwner.fullName, // Cache name for display
        'reassignedAt': FieldValue.serverTimestamp(),
        'reassignedBy': currentUserId,
      });

      print('✅ Project $projectId reassigned to owner: ${newOwner.fullName} (${newOwner.uid})');
    } catch (e) {
      print('ProjectReassignmentService.reassignProjectOwner error: $e');
      throw Exception('Failed to reassign project owner: ${e.toString()}');
    }
  }

  /// Reassign project manager to a new user
  /// Only the project creator (engineer) can perform this action
  static Future<void> reassignProjectManager({
    required String projectId,
    required String newManagerPublicId,
  }) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Validate the new manager exists and has correct role
      final managerValidation = await UserService.validateProjectUsers(
        ownerId: 'dummy', // We only need to validate manager
        managerId: newManagerPublicId,
      );

      if (!managerValidation['success'] && !managerValidation['error'].contains('Owner ID')) {
        throw Exception(managerValidation['error']);
      }

      final newManager = managerValidation['manager'];
      if (newManager == null) {
        throw Exception('Manager not found');
      }

      // Verify the current user is the project creator
      final projectDoc = await _firestore
          .collection('projects')
          .doc(projectId)
          .get();

      if (!projectDoc.exists) {
        throw Exception('Project not found');
      }

      final projectData = projectDoc.data()!;
      if (projectData['createdBy'] != currentUserId) {
        throw Exception('Only the project creator can reassign projects');
      }

      // Update project with new manager information
      await _firestore.collection('projects').doc(projectId).update({
        'managerId': newManager.uid, // Store Firebase UID for queries
        'managerPublicId': newManager.publicId, // Store publicId for display
        'managerName': newManager.fullName, // Cache name for display
        'reassignedAt': FieldValue.serverTimestamp(),
        'reassignedBy': currentUserId,
      });

      print('✅ Project $projectId reassigned to manager: ${newManager.fullName} (${newManager.uid})');
    } catch (e) {
      print('ProjectReassignmentService.reassignProjectManager error: $e');
      throw Exception('Failed to reassign project manager: ${e.toString()}');
    }
  }

  /// Get available users for reassignment by role
  static Future<List<UserData>> getAvailableUsersByRole(String role) async {
    try {
      final usersSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: role)
          .where('isActive', isEqualTo: true)
          .orderBy('fullName')
          .get();

      return usersSnapshot.docs
          .map((doc) => UserData.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('ProjectReassignmentService.getAvailableUsersByRole error: $e');
      return [];
    }
  }

  /// Batch reassign multiple projects
  static Future<void> batchReassignProjects({
    required List<String> projectIds,
    String? newOwnerPublicId,
    String? newManagerPublicId,
  }) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    if (newOwnerPublicId == null && newManagerPublicId == null) {
      throw Exception('At least one reassignment target must be provided');
    }

    try {
      // Validate users if provided
      UserData? newOwner;
      UserData? newManager;

      if (newOwnerPublicId != null) {
        final ownerValidation = await UserService.validateProjectUsers(
          ownerId: newOwnerPublicId,
          managerId: 'dummy',
        );
        if (!ownerValidation['success'] && !ownerValidation['error'].contains('Manager ID')) {
          throw Exception('Owner validation failed: ${ownerValidation['error']}');
        }
        newOwner = ownerValidation['owner'];
      }

      if (newManagerPublicId != null) {
        final managerValidation = await UserService.validateProjectUsers(
          ownerId: 'dummy',
          managerId: newManagerPublicId,
        );
        if (!managerValidation['success'] && !managerValidation['error'].contains('Owner ID')) {
          throw Exception('Manager validation failed: ${managerValidation['error']}');
        }
        newManager = managerValidation['manager'];
      }

      // Perform batch update using Firestore batch
      final batch = _firestore.batch();

      for (final projectId in projectIds) {
        final projectRef = _firestore.collection('projects').doc(projectId);
        
        final updateData = <String, dynamic>{
          'reassignedAt': FieldValue.serverTimestamp(),
          'reassignedBy': currentUserId,
        };

        if (newOwner != null) {
          updateData.addAll({
            'ownerId': newOwner.uid,
            'ownerPublicId': newOwner.publicId,
            'ownerName': newOwner.fullName,
          });
        }

        if (newManager != null) {
          updateData.addAll({
            'managerId': newManager.uid,
            'managerPublicId': newManager.publicId,
            'managerName': newManager.fullName,
          });
        }

        batch.update(projectRef, updateData);
      }

      await batch.commit();
      print('✅ Batch reassignment completed for ${projectIds.length} projects');
    } catch (e) {
      print('ProjectReassignmentService.batchReassignProjects error: $e');
      throw Exception('Failed to batch reassign projects: ${e.toString()}');
    }
  }
}