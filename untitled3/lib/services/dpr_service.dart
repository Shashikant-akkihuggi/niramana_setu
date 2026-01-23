import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/dpr_model.dart';

class DPRService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String? get currentUserId => _auth.currentUser?.uid;

  // Get DPRs for Engineer review (from all their projects)
  static Stream<List<DPRModel>> getEngineerDPRs() {
    if (currentUserId == null) return Stream.value([]);
    
    print('🔍 DPRService.getEngineerDPRs - Using individual project queries');
    return _firestore
        .collection('projects')
        .where('engineerId', isEqualTo: currentUserId)
        .snapshots()
        .asyncMap((projectSnapshot) async {
          if (projectSnapshot.docs.isEmpty) {
            return <DPRModel>[];
          }
          
          final allDPRs = <DPRModel>[];
          
          // Query each project's dprs subcollection individually
          for (final projectDoc in projectSnapshot.docs) {
            final projectId = projectDoc.id;
            final dprSnapshot = await _firestore
                .collection('projects')
                .doc(projectId)
                .collection('dprs')
                .orderBy('createdAt', descending: true)
                .get();
            
            final dprs = dprSnapshot.docs
                .map((doc) => DPRModel.fromJson({...doc.data(), 'id': doc.id}))
                .toList();
            
            allDPRs.addAll(dprs);
          }
          
          // Sort all DPRs by creation date
          allDPRs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return allDPRs;
        });
  }

  // Get DPRs for Manager (from their accepted projects)
  static Stream<List<DPRModel>> getManagerDPRs(String projectId) {
    if (currentUserId == null) return Stream.value([]);
    
    print('🔍 DPRService.getManagerDPRs - Using subcollection: projects/$projectId/dprs');
    return _firestore
        .collection('projects')
        .doc(projectId)
        .collection('dprs')
        .where('submittedBy', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DPRModel.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // Get DPRs for Owner (from their accepted projects)
  static Stream<List<DPRModel>> getOwnerDPRs(String projectId) {
    print('🔍 DPRService.getOwnerDPRs - Using subcollection: projects/$projectId/dprs');
    return _firestore
        .collection('projects')
        .doc(projectId)
        .collection('dprs')
        .where('status', whereIn: ['approved', 'pending'])
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DPRModel.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // Create new DPR (Manager)
  static Future<String> createDPR(DPRModel dpr) async {
    if (currentUserId == null) throw Exception('User not authenticated');
    
    print('🔍 DPRService.createDPR - Using subcollection: projects/${dpr.projectId}/dprs');
    final docRef = await _firestore
        .collection('projects')
        .doc(dpr.projectId)
        .collection('dprs')
        .add(dpr.toJson());
    return docRef.id;
  }

  // Update DPR status (Engineer approval/rejection)
  static Future<void> updateDPRStatus(String projectId, String dprId, String status, String? comment) async {
    if (currentUserId == null) throw Exception('User not authenticated');
    
    print('🔍 DPRService.updateDPRStatus - Using subcollection: projects/$projectId/dprs');
    await _firestore
        .collection('projects')
        .doc(projectId)
        .collection('dprs')
        .doc(dprId)
        .update({
      'status': status,
      'comment': comment,
      'reviewedBy': currentUserId,
      'reviewedAt': Timestamp.now(),
    });
  }

  // Update DPR (Manager editing)
  static Future<void> updateDPR(String dprId, DPRModel dpr) async {
    if (currentUserId == null) throw Exception('User not authenticated');
    
    print('🔍 DPRService.updateDPR - Using subcollection: projects/${dpr.projectId}/dprs');
    await _firestore
        .collection('projects')
        .doc(dpr.projectId)
        .collection('dprs')
        .doc(dprId)
        .update(dpr.toJson());
  }

  // Delete DPR (Manager)
  static Future<void> deleteDPR(String projectId, String dprId) async {
    if (currentUserId == null) throw Exception('User not authenticated');
    
    print('🔍 DPRService.deleteDPR - Using subcollection: projects/$projectId/dprs');
    await _firestore
        .collection('projects')
        .doc(projectId)
        .collection('dprs')
        .doc(dprId)
        .delete();
  }

  // Get pending DPRs count for Engineer
  static Stream<int> getEngineerPendingDPRsCount() {
    if (currentUserId == null) return Stream.value(0);
    
    print('🔍 DPRService.getEngineerPendingDPRsCount - Using individual project queries');
    return _firestore
        .collection('projects')
        .where('engineerId', isEqualTo: currentUserId)
        .snapshots()
        .asyncMap((projectSnapshot) async {
          if (projectSnapshot.docs.isEmpty) return 0;
          
          int totalCount = 0;
          
          // Query each project's dprs subcollection individually
          for (final projectDoc in projectSnapshot.docs) {
            final projectId = projectDoc.id;
            final dprSnapshot = await _firestore
                .collection('projects')
                .doc(projectId)
                .collection('dprs')
                .where('status', isEqualTo: 'pending')
                .get();
            
            totalCount += dprSnapshot.docs.length;
          }
          
          return totalCount;
        });
  }

  // Get DPR by ID
  static Future<DPRModel?> getDPRById(String projectId, String dprId) async {
    print('🔍 DPRService.getDPRById - Using subcollection: projects/$projectId/dprs');
    final doc = await _firestore
        .collection('projects')
        .doc(projectId)
        .collection('dprs')
        .doc(dprId)
        .get();
    if (doc.exists) {
      return DPRModel.fromJson({...doc.data()!, 'id': doc.id});
    }
    return null;
  }

  // PROJECT-SCOPED METHODS (for use with ProjectContext.activeProjectId)
  
  // Get DPRs for specific project
  static Stream<List<DPRModel>> getProjectDPRs(String projectId) {
    print('🔍 DPRService.getProjectDPRs - Using subcollection: projects/$projectId/dprs');
    return _firestore
        .collection('projects')
        .doc(projectId)
        .collection('dprs')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DPRModel.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // Get pending DPRs count for specific project
  static Stream<int> getProjectPendingDPRsCount(String projectId) {
    print('🔍 DPRService.getProjectPendingDPRsCount - Using subcollection: projects/$projectId/dprs');
    return _firestore
        .collection('projects')
        .doc(projectId)
        .collection('dprs')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}