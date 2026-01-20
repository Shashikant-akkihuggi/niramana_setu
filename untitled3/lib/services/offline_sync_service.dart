import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/offline_dpr_model.dart';
import 'cloudinary_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OfflineSyncService {
  static final OfflineSyncService _instance = OfflineSyncService._internal();
  factory OfflineSyncService() => _instance;
  OfflineSyncService._internal();

  late Box _dprBox;
  late Box<OfflineDprModel> _offlineDprBox;
  late Box _materialBox;
  final _uuid = const Uuid();

  // Stream subscription for connectivity
  StreamSubscription? _connectivitySubscription;
  bool _isSyncing = false;

  Future<void> init() async {
    _dprBox = Hive.box('offline_dprs');
    _offlineDprBox = Hive.box<OfflineDprModel>('offline_dpr_models');
    _materialBox = Hive.box('offline_material_requests');

    // Check initial status
    _checkConnectivityAndSync();

    // Listen to changes
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
       // connectivity_plus 6.0 returns List<ConnectivityResult>
       if (results.any((r) => r != ConnectivityResult.none)) {
         debugPrint('OfflineSync: Connectivity restored, starting sync...');
         syncAll();
       }
    });
  }
  
  void dispose() {
    _connectivitySubscription?.cancel();
  }

  Future<void> _checkConnectivityAndSync() async {
    final results = await Connectivity().checkConnectivity();
    if (results.any((r) => r != ConnectivityResult.none)) {
      syncAll();
    }
  }

  // --- Save Logic ---

  /// Save DPR offline using the new OfflineDprModel
  Future<void> saveDprOfflineNew({
    required String workDone,
    required String materialsUsed,
    required String workersPresent,
    required List<String> localImagePaths,
    String? projectId,
  }) async {
    final id = _uuid.v4();
    final currentUser = FirebaseAuth.instance.currentUser;
    
    final offlineDpr = OfflineDprModel(
      id: id,
      projectId: projectId,
      workDone: workDone,
      materialsUsed: materialsUsed,
      workersPresent: workersPresent,
      localImagePaths: localImagePaths,
      createdAt: DateTime.now(),
      createdBy: currentUser?.uid,
      isSynced: false,
    );
    
    await _offlineDprBox.put(id, offlineDpr);
    debugPrint('OfflineSync: DPR saved offline with ID: $id');
  }

  Future<void> saveDprOffline(Map<String, dynamic> data) async {
    final id = _uuid.v4();
    final entry = {
      'id': id,
      'payload': data,
      'createdAt': DateTime.now().toIso8601String(),
      'isSynced': false,
    };
    await _dprBox.put(id, entry);
  }

  Future<void> saveMaterialRequestOffline(Map<String, dynamic> data) async {
    final id = _uuid.v4();
    final entry = {
      'id': id,
      'payload': data,
      'createdAt': DateTime.now().toIso8601String(),
      'isSynced': false,
    };
    await _materialBox.put(id, entry);
  }

  // --- Sync Logic ---

  Future<void> syncAll() async {
    if (_isSyncing) {
      debugPrint('OfflineSync: Sync already in progress, skipping...');
      return;
    }
    
    _isSyncing = true;
    debugPrint("OfflineSync: Starting sync of all offline data...");
    
    try {
      await _syncOfflineDprs();
      await _syncDprs();
      await _syncMaterialRequests();
      debugPrint("OfflineSync: All sync operations completed");
    } catch (e) {
      debugPrint("OfflineSync: Sync error: $e");
    } finally {
      _isSyncing = false;
    }
  }

  /// Sync new OfflineDprModel entries
  Future<void> _syncOfflineDprs() async {
    if (_offlineDprBox.isEmpty) {
      debugPrint('OfflineSync: No offline DPRs to sync');
      return;
    }
    
    debugPrint('OfflineSync: Syncing ${_offlineDprBox.length} offline DPRs...');
    
    final unsyncedDprs = _offlineDprBox.values.where((dpr) => !dpr.isSynced).toList();
    
    for (var dpr in unsyncedDprs) {
      try {
        debugPrint('OfflineSync: Processing pending DPR ${dpr.id}...');
        
        // Step 1: Upload images to Cloudinary first
        List<String> cloudinaryUrls = [];
        if (dpr.localImagePaths.isNotEmpty) {
          debugPrint('OfflineSync: Uploading ${dpr.localImagePaths.length} images to Cloudinary...');
          
          final imageFiles = dpr.localImagePaths
              .map((path) => File(path))
              .where((file) => file.existsSync())
              .toList();
          
          if (imageFiles.isNotEmpty) {
            // Use the improved CloudinaryService with compression and retry
            cloudinaryUrls = await CloudinaryService.uploadMultipleImages(imageFiles) ?? [];
            debugPrint('OfflineSync: ${cloudinaryUrls.length}/${imageFiles.length} images uploaded successfully');
            
            if (cloudinaryUrls.length != imageFiles.length) {
              debugPrint('OfflineSync: Image upload incomplete for DPR ${dpr.id}, skipping for now');
              continue; // Skip this DPR and try again later
            }
          }
        }
        
        // Step 2: Save to Firestore with Cloudinary URLs
        final firestoreData = dpr.toFirestoreMap(cloudinaryUrls: cloudinaryUrls);
        await FirebaseFirestore.instance.collection('dpr_reports').add(firestoreData);
        
        // Step 3: Delete from Hive on success
        await _offlineDprBox.delete(dpr.key);
        debugPrint("OfflineSync: DPR ${dpr.id} synced successfully and removed from offline storage");
        
      } catch (e, stackTrace) {
        debugPrint("OfflineSync: Failed to sync DPR ${dpr.id}: $e");
        debugPrint("OfflineSync: Stack trace: $stackTrace");
        // Don't delete the entry, let it retry on next sync
      }
    }
  }

  Future<void> _syncDprs() async {
    if (_dprBox.isEmpty) return;
    
    debugPrint('OfflineSync: Syncing legacy DPR entries...');
    final unsynced = _dprBox.values.where((e) => e['isSynced'] == false).toList();
    for (var entry in unsynced) {
      try {
        // Convert Map<dynamic, dynamic> to Map<String, dynamic> if needed
        final payload = Map<String, dynamic>.from(entry['payload'] as Map);
        
        await FirebaseFirestore.instance.collection('dpr_reports').add(payload);
        
        // Delete from Hive on success
        await _dprBox.delete(entry['id']);
        debugPrint("OfflineSync: Legacy DPR synced: ${entry['id']}");
      } catch (e) {
        debugPrint("OfflineSync: Failed to sync legacy DPR ${entry['id']}: $e");
      }
    }
  }

  Future<void> _syncMaterialRequests() async {
    if (_materialBox.isEmpty) return;

    debugPrint('OfflineSync: Syncing material requests...');
    final unsynced = _materialBox.values.where((e) => e['isSynced'] == false).toList();
    for (var entry in unsynced) {
      try {
        final payload = Map<String, dynamic>.from(entry['payload'] as Map);
        await FirebaseFirestore.instance.collection('material_requests').add(payload);
        
        await _materialBox.delete(entry['id']);
        debugPrint("OfflineSync: Material Request synced: ${entry['id']}");
      } catch (e) {
        debugPrint("OfflineSync: Failed to sync Material Request ${entry['id']}: $e");
      }
    }
  }

  /// Get count of pending offline DPRs
  int getPendingDprCount() {
    return _offlineDprBox.values.where((dpr) => !dpr.isSynced).length +
           _dprBox.values.where((e) => e['isSynced'] == false).length;
  }

  /// Check if there are any pending syncs
  bool hasPendingSyncs() {
    return getPendingDprCount() > 0 || 
           _materialBox.values.any((e) => e['isSynced'] == false);
  }
}
