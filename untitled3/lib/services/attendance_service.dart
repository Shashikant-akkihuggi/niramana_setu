import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WorkerAttendance {
  final String name;
  final String role;
  final bool present;
  final String? faceId; // For face recognition
  final Map<String, dynamic>? geoLocation;
  final DateTime? checkInTime;
  final String? photoUrl;

  WorkerAttendance({
    required this.name,
    required this.role,
    required this.present,
    this.faceId,
    this.geoLocation,
    this.checkInTime,
    this.photoUrl,
  });

  factory WorkerAttendance.fromJson(Map<String, dynamic> json) {
    return WorkerAttendance(
      name: json['name'] ?? '',
      role: json['role'] ?? '',
      present: json['present'] ?? false,
      faceId: json['faceId'],
      geoLocation: json['geoLocation'] as Map<String, dynamic>?,
      checkInTime: (json['checkInTime'] as Timestamp?)?.toDate(),
      photoUrl: json['photoUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'role': role,
      'present': present,
      'faceId': faceId,
      'geoLocation': geoLocation,
      'checkInTime': checkInTime != null ? Timestamp.fromDate(checkInTime!) : null,
      'photoUrl': photoUrl,
    };
  }

  WorkerAttendance copyWith({
    String? name,
    String? role,
    bool? present,
    String? faceId,
    Map<String, dynamic>? geoLocation,
    DateTime? checkInTime,
    String? photoUrl,
  }) {
    return WorkerAttendance(
      name: name ?? this.name,
      role: role ?? this.role,
      present: present ?? this.present,
      faceId: faceId ?? this.faceId,
      geoLocation: geoLocation ?? this.geoLocation,
      checkInTime: checkInTime ?? this.checkInTime,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}

class AttendanceRecord {
  final String id;
  final String projectId;
  final String date; // YYYY-MM-DD format
  final List<WorkerAttendance> workers;
  final String recordedBy; // Manager UID
  final DateTime createdAt;
  final DateTime? updatedAt;

  AttendanceRecord({
    required this.id,
    required this.projectId,
    required this.date,
    required this.workers,
    required this.recordedBy,
    required this.createdAt,
    this.updatedAt,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'] ?? '',
      projectId: json['projectId'] ?? '',
      date: json['date'] ?? '',
      workers: (json['workers'] as List<dynamic>?)
          ?.map((w) => WorkerAttendance.fromJson(w as Map<String, dynamic>))
          .toList() ?? [],
      recordedBy: json['recordedBy'] ?? '',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'projectId': projectId,
      'date': date,
      'workers': workers.map((w) => w.toJson()).toList(),
      'recordedBy': recordedBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  AttendanceRecord copyWith({
    String? id,
    String? projectId,
    String? date,
    List<WorkerAttendance>? workers,
    String? recordedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      date: date ?? this.date,
      workers: workers ?? this.workers,
      recordedBy: recordedBy ?? this.recordedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class AttendanceService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String? get currentUserId => _auth.currentUser?.uid;

  // Get attendance record for a specific project and date
  static Future<AttendanceRecord?> getAttendanceRecord(String projectId, String date) async {
    final query = await _firestore
        .collection('attendance')
        .where('projectId', isEqualTo: projectId)
        .where('date', isEqualTo: date)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      final doc = query.docs.first;
      return AttendanceRecord.fromJson({...doc.data(), 'id': doc.id});
    }
    return null;
  }

  // Save or update attendance record
  static Future<String> saveAttendanceRecord(AttendanceRecord record) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    // Check if record already exists for this project and date
    final existing = await getAttendanceRecord(record.projectId, record.date);
    
    if (existing != null) {
      // Update existing record
      await _firestore.collection('attendance').doc(existing.id).update({
        ...record.toJson(),
        'updatedAt': Timestamp.now(),
      });
      return existing.id;
    } else {
      // Create new record
      final docRef = await _firestore.collection('attendance').add(record.toJson());
      return docRef.id;
    }
  }

  // Get attendance records for a project (Manager view)
  static Stream<List<AttendanceRecord>> getProjectAttendanceRecords(String projectId) {
    return _firestore
        .collection('attendance')
        .where('projectId', isEqualTo: projectId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AttendanceRecord.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // Get attendance records for all Manager's projects
  static Stream<List<AttendanceRecord>> getManagerAttendanceRecords() {
    if (currentUserId == null) return Stream.value([]);
    
    return _firestore
        .collection('projects')
        .where('managerId', isEqualTo: currentUserId)
        .where('managerStatus', isEqualTo: 'accepted')
        .snapshots()
        .asyncExpand((projectSnapshot) {
          if (projectSnapshot.docs.isEmpty) {
            return Stream.value(<AttendanceRecord>[]);
          }
          
          final projectIds = projectSnapshot.docs.map((doc) => doc.id).toList();
          
          return _firestore
              .collection('attendance')
              .where('projectId', whereIn: projectIds)
              .orderBy('date', descending: true)
              .snapshots()
              .map((snapshot) => snapshot.docs
                  .map((doc) => AttendanceRecord.fromJson({...doc.data(), 'id': doc.id}))
                  .toList());
        });
  }

  // Get today's attendance for Manager's projects
  static Stream<List<AttendanceRecord>> getManagerTodayAttendance() {
    if (currentUserId == null) return Stream.value([]);
    
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    
    return _firestore
        .collection('projects')
        .where('managerId', isEqualTo: currentUserId)
        .where('managerStatus', isEqualTo: 'accepted')
        .snapshots()
        .asyncExpand((projectSnapshot) {
          if (projectSnapshot.docs.isEmpty) {
            return Stream.value(<AttendanceRecord>[]);
          }
          
          final projectIds = projectSnapshot.docs.map((doc) => doc.id).toList();
          
          return _firestore
              .collection('attendance')
              .where('projectId', whereIn: projectIds)
              .where('date', isEqualTo: todayKey)
              .snapshots()
              .map((snapshot) => snapshot.docs
                  .map((doc) => AttendanceRecord.fromJson({...doc.data(), 'id': doc.id}))
                  .toList());
        });
  }

  // Get total workers count for today (Manager)
  static Stream<int> getManagerTodayWorkersCount() {
    return getManagerTodayAttendance().map((records) {
      int totalWorkers = 0;
      for (var record in records) {
        totalWorkers += record.workers.where((w) => w.present).length;
      }
      return totalWorkers;
    });
  }

  // Get attendance statistics for Owner
  static Stream<Map<String, int>> getOwnerAttendanceStats(String projectId) {
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    
    return _firestore
        .collection('attendance')
        .where('projectId', isEqualTo: projectId)
        .where('date', isEqualTo: todayKey)
        .snapshots()
        .map((snapshot) {
          int totalWorkers = 0;
          int presentWorkers = 0;
          
          for (var doc in snapshot.docs) {
            final record = AttendanceRecord.fromJson({...doc.data(), 'id': doc.id});
            totalWorkers += record.workers.length;
            presentWorkers += record.workers.where((w) => w.present).length;
          }
          
          return {
            'total': totalWorkers,
            'present': presentWorkers,
            'absent': totalWorkers - presentWorkers,
          };
        });
  }

  // Delete attendance record
  static Future<void> deleteAttendanceRecord(String recordId) async {
    if (currentUserId == null) throw Exception('User not authenticated');
    
    await _firestore.collection('attendance').doc(recordId).delete();
  }

  // Get default workers list for a project (can be customized per project)
  static Future<List<WorkerAttendance>> getDefaultWorkers(String projectId) async {
    // This could be fetched from a project-specific workers collection
    // For now, return empty list - Manager will add workers manually
    return [];
  }

  // Add worker to project
  static Future<void> addWorkerToProject(String projectId, WorkerAttendance worker) async {
    if (currentUserId == null) throw Exception('User not authenticated');
    
    // This could save to a project_workers collection for reuse
    // For now, workers are added per attendance record
  }
}