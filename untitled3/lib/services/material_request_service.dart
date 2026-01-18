import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MaterialRequestModel {
  final String id;
  final String projectId;
  final String material;
  final String quantity;
  final String priority;
  final DateTime dateNeeded;
  final String note;
  final String status; // 'pending', 'approved', 'rejected'
  final String requesterId; // Manager UID
  final String? reviewedBy; // Engineer UID
  final String? comment;
  final DateTime createdAt;
  final DateTime? reviewedAt;

  MaterialRequestModel({
    required this.id,
    required this.projectId,
    required this.material,
    required this.quantity,
    required this.priority,
    required this.dateNeeded,
    required this.note,
    required this.status,
    required this.requesterId,
    this.reviewedBy,
    this.comment,
    required this.createdAt,
    this.reviewedAt,
  });

  factory MaterialRequestModel.fromJson(Map<String, dynamic> json) {
    return MaterialRequestModel(
      id: json['id'] ?? '',
      projectId: json['projectId'] ?? '',
      material: json['material'] ?? '',
      quantity: json['quantity'] ?? '',
      priority: json['priority'] ?? 'Medium',
      dateNeeded: (json['dateNeeded'] as Timestamp?)?.toDate() ?? DateTime.now(),
      note: json['note'] ?? '',
      status: json['status'] ?? 'pending',
      requesterId: json['requesterId'] ?? '',
      reviewedBy: json['reviewedBy'],
      comment: json['comment'],
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reviewedAt: (json['reviewedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'projectId': projectId,
      'material': material,
      'quantity': quantity,
      'priority': priority,
      'dateNeeded': Timestamp.fromDate(dateNeeded),
      'note': note,
      'status': status,
      'requesterId': requesterId,
      'reviewedBy': reviewedBy,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
    };
  }

  MaterialRequestModel copyWith({
    String? id,
    String? projectId,
    String? material,
    String? quantity,
    String? priority,
    DateTime? dateNeeded,
    String? note,
    String? status,
    String? requesterId,
    String? reviewedBy,
    String? comment,
    DateTime? createdAt,
    DateTime? reviewedAt,
  }) {
    return MaterialRequestModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      material: material ?? this.material,
      quantity: quantity ?? this.quantity,
      priority: priority ?? this.priority,
      dateNeeded: dateNeeded ?? this.dateNeeded,
      note: note ?? this.note,
      status: status ?? this.status,
      requesterId: requesterId ?? this.requesterId,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
    );
  }
}

class MaterialRequestService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String? get currentUserId => _auth.currentUser?.uid;

  // Get material requests for Engineer review (from all their projects)
  static Stream<List<MaterialRequestModel>> getEngineerMaterialRequests() {
    if (currentUserId == null) return Stream.value([]);
    
    return _firestore
        .collection('projects')
        .where('engineerId', isEqualTo: currentUserId)
        .snapshots()
        .asyncExpand((projectSnapshot) {
          if (projectSnapshot.docs.isEmpty) {
            return Stream.value(<MaterialRequestModel>[]);
          }
          
          final projectIds = projectSnapshot.docs.map((doc) => doc.id).toList();
          
          return _firestore
              .collection('material_requests')
              .where('projectId', whereIn: projectIds)
              .orderBy('createdAt', descending: true)
              .snapshots()
              .map((snapshot) => snapshot.docs
                  .map((doc) => MaterialRequestModel.fromJson({...doc.data(), 'id': doc.id}))
                  .toList());
        });
  }

  // Get material requests for Manager (from their accepted projects)
  static Stream<List<MaterialRequestModel>> getManagerMaterialRequests(String projectId) {
    if (currentUserId == null) return Stream.value([]);
    
    return _firestore
        .collection('material_requests')
        .where('projectId', isEqualTo: projectId)
        .where('requesterId', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MaterialRequestModel.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // Get material requests for Owner (from their accepted projects)
  static Stream<List<MaterialRequestModel>> getOwnerMaterialRequests(String projectId) {
    return _firestore
        .collection('material_requests')
        .where('projectId', isEqualTo: projectId)
        .where('status', whereIn: ['approved', 'pending'])
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MaterialRequestModel.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // Create new material request (Manager)
  static Future<String> createMaterialRequest(MaterialRequestModel request) async {
    if (currentUserId == null) throw Exception('User not authenticated');
    
    final docRef = await _firestore.collection('material_requests').add(request.toJson());
    return docRef.id;
  }

  // Update material request status (Engineer approval/rejection)
  static Future<void> updateMaterialRequestStatus(String requestId, String status, String? comment) async {
    if (currentUserId == null) throw Exception('User not authenticated');
    
    await _firestore.collection('material_requests').doc(requestId).update({
      'status': status,
      'comment': comment,
      'reviewedBy': currentUserId,
      'reviewedAt': Timestamp.now(),
    });
  }

  // Update material request (Manager editing)
  static Future<void> updateMaterialRequest(String requestId, MaterialRequestModel request) async {
    if (currentUserId == null) throw Exception('User not authenticated');
    
    await _firestore.collection('material_requests').doc(requestId).update(request.toJson());
  }

  // Delete material request (Manager)
  static Future<void> deleteMaterialRequest(String requestId) async {
    if (currentUserId == null) throw Exception('User not authenticated');
    
    await _firestore.collection('material_requests').doc(requestId).delete();
  }

  // Get pending material requests count for Engineer
  static Stream<int> getEngineerPendingMaterialRequestsCount() {
    if (currentUserId == null) return Stream.value(0);
    
    return _firestore
        .collection('projects')
        .where('engineerId', isEqualTo: currentUserId)
        .snapshots()
        .asyncMap((projectSnapshot) async {
          if (projectSnapshot.docs.isEmpty) return 0;
          
          final projectIds = projectSnapshot.docs.map((doc) => doc.id).toList();
          
          final requests = await _firestore
              .collection('material_requests')
              .where('projectId', whereIn: projectIds)
              .where('status', isEqualTo: 'pending')
              .get();
          
          return requests.docs.length;
        });
  }

  // Get material request by ID
  static Future<MaterialRequestModel?> getMaterialRequestById(String requestId) async {
    final doc = await _firestore.collection('material_requests').doc(requestId).get();
    if (doc.exists) {
      return MaterialRequestModel.fromJson({...doc.data()!, 'id': doc.id});
    }
    return null;
  }

  // PROJECT-SCOPED METHODS (for use with ProjectContext.activeProjectId)
  
  // Get material requests for specific project
  static Stream<List<MaterialRequestModel>> getProjectMaterialRequests(String projectId) {
    return _firestore
        .collection('material_requests')
        .where('projectId', isEqualTo: projectId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MaterialRequestModel.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // Get pending material requests count for specific project
  static Stream<int> getProjectPendingMaterialRequestsCount(String projectId) {
    return _firestore
        .collection('material_requests')
        .where('projectId', isEqualTo: projectId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}