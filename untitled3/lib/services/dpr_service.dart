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
    
    return _firestore
        .collection('projects')
        .where('engineerId', isEqualTo: currentUserId)
        .snapshots()
        .asyncExpand((projectSnapshot) {
          if (projectSnapshot.docs.isEmpty) {
            return Stream.value(<DPRModel>[]);
          }
          
          final projectIds = projectSnapshot.docs.map((doc) => doc.id).toList();
          
          return _firestore
              .collection('dprs')
              .where('projectId', whereIn: projectIds)
              .orderBy('createdAt', descending: true)
              .snapshots()
              .map((snapshot) => snapshot.docs
                  .map((doc) => DPRModel.fromJson({...doc.data(), 'id': doc.id}))
                  .toList());
        });
  }

  // Get DPRs for Manager (from their accepted projects)
  static Stream<List<DPRModel>> getManagerDPRs(String projectId) {
    if (currentUserId == null) return Stream.value([]);
    
    return _firestore
        .collection('dprs')
        .where('projectId', isEqualTo: projectId)
        .where('submittedBy', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DPRModel.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // Get DPRs for Owner (from their accepted projects)
  static Stream<List<DPRModel>> getOwnerDPRs(String projectId) {
    return _firestore
        .collection('dprs')
        .where('projectId', isEqualTo: projectId)
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
    
    final docRef = await _firestore.collection('dprs').add(dpr.toJson());
    return docRef.id;
  }

  // Update DPR status (Engineer approval/rejection)
  static Future<void> updateDPRStatus(String dprId, String status, String? comment) async {
    if (currentUserId == null) throw Exception('User not authenticated');
    
    await _firestore.collection('dprs').doc(dprId).update({
      'status': status,
      'comment': comment,
      'reviewedBy': currentUserId,
      'reviewedAt': Timestamp.now(),
    });
  }

  // Update DPR (Manager editing)
  static Future<void> updateDPR(String dprId, DPRModel dpr) async {
    if (currentUserId == null) throw Exception('User not authenticated');
    
    await _firestore.collection('dprs').doc(dprId).update(dpr.toJson());
  }

  // Delete DPR (Manager)
  static Future<void> deleteDPR(String dprId) async {
    if (currentUserId == null) throw Exception('User not authenticated');
    
    await _firestore.collection('dprs').doc(dprId).delete();
  }

  // Get pending DPRs count for Engineer
  static Stream<int> getEngineerPendingDPRsCount() {
    if (currentUserId == null) return Stream.value(0);
    
    return _firestore
        .collection('projects')
        .where('engineerId', isEqualTo: currentUserId)
        .snapshots()
        .asyncMap((projectSnapshot) async {
          if (projectSnapshot.docs.isEmpty) return 0;
          
          final projectIds = projectSnapshot.docs.map((doc) => doc.id).toList();
          
          final dprs = await _firestore
              .collection('dprs')
              .where('projectId', whereIn: projectIds)
              .where('status', isEqualTo: 'pending')
              .get();
          
          return dprs.docs.length;
        });
  }

  // Get DPR by ID
  static Future<DPRModel?> getDPRById(String dprId) async {
    final doc = await _firestore.collection('dprs').doc(dprId).get();
    if (doc.exists) {
      return DPRModel.fromJson({...doc.data()!, 'id': doc.id});
    }
    return null;
  }

  // PROJECT-SCOPED METHODS (for use with ProjectContext.activeProjectId)
  
  // Get DPRs for specific project
  static Stream<List<DPRModel>> getProjectDPRs(String projectId) {
    return _firestore
        .collection('dprs')
        .where('projectId', isEqualTo: projectId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DPRModel.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // Get pending DPRs count for specific project
  static Stream<int> getProjectPendingDPRsCount(String projectId) {
    return _firestore
        .collection('dprs')
        .where('projectId', isEqualTo: projectId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}