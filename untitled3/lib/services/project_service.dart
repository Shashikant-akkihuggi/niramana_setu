import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/project.dart';

/// Service for managing project operations with Firestore
/// Handles CRUD operations and role-based queries
class ProjectService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user ID
  static String? get currentUserId => _auth.currentUser?.uid;

  /// Create a new project (Engineer only)
  static Future<String> createProject({
    required String projectName,
    required String ownerId,
    required String managerId,
  }) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    final project = Project(
      id: '', // Will be set by Firestore
      projectName: projectName,
      createdBy: currentUserId!,
      ownerId: ownerId,
      managerId: managerId,
      status: 'pending_owner_approval',
      createdAt: DateTime.now(),
    );

    final docRef = await _firestore
        .collection('projects')
        .add(project.toFirestore());

    return docRef.id;
  }

  /// Get projects for Engineer (created by current user)
  static Stream<List<Project>> getEngineerProjects() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('projects')
        .where('createdBy', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Project.fromFirestore(doc))
            .toList());
  }

  /// Get projects for Owner (where current user is owner)
  /// Show all projects for approval workflow
  static Stream<List<Project>> getOwnerProjects() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('projects')
        .where('ownerId', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Project.fromFirestore(doc))
            .toList());
  }

  /// Get projects for Manager (where current user is manager)
  /// Show all projects for acceptance workflow
  static Stream<List<Project>> getManagerProjects() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('projects')
        .where('managerId', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Project.fromFirestore(doc))
            .toList());
  }

  /// Owner approves project
  static Future<void> approveProject(String projectId) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    await _firestore.collection('projects').doc(projectId).update({
      'status': 'approved_by_owner',
      'ownerApprovedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Manager accepts project
  static Future<void> acceptProject(String projectId) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    await _firestore.collection('projects').doc(projectId).update({
      'status': 'active',
      'managerAcceptedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get project by ID
  static Future<Project?> getProject(String projectId) async {
    final doc = await _firestore.collection('projects').doc(projectId).get();
    if (doc.exists) {
      return Project.fromFirestore(doc);
    }
    return null;
  }

  /// Update project
  static Future<void> updateProject(String projectId, Map<String, dynamic> updates) async {
    await _firestore.collection('projects').doc(projectId).update(updates);
  }

  /// Delete project (Engineer only, and only if pending)
  static Future<void> deleteProject(String projectId) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    final project = await getProject(projectId);
    if (project == null) {
      throw Exception('Project not found');
    }

    if (project.createdBy != currentUserId) {
      throw Exception('Only the creator can delete this project');
    }

    if (project.isActive) {
      throw Exception('Cannot delete active projects');
    }

    await _firestore.collection('projects').doc(projectId).delete();
  }
}