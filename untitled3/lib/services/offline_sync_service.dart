import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class OfflineSyncService {
  static final OfflineSyncService _instance = OfflineSyncService._internal();
  factory OfflineSyncService() => _instance;
  OfflineSyncService._internal();

  late Box _dprBox;
  late Box _materialBox;
  final _uuid = const Uuid();

  // Stream subscription for connectivity
  StreamSubscription? _connectivitySubscription;

  Future<void> init() async {
    _dprBox = Hive.box('offline_dprs');
    _materialBox = Hive.box('offline_material_requests');

    // Check initial status
    _checkConnectivityAndSync();

    // Listen to changes
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
       // connectivity_plus 6.0 returns List<ConnectivityResult>
       if (results.any((r) => r != ConnectivityResult.none)) {
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
    // Basic check to avoid redundant syncs if already syncing? 
    // Ideally we'd have a _isSyncing flag, but for now simple is better.
    debugPrint("Attempting to sync offline data...");
    await _syncDprs();
    await _syncMaterialRequests();
  }

  Future<void> _syncDprs() async {
    if (_dprBox.isEmpty) return;
    
    final unsynced = _dprBox.values.where((e) => e['isSynced'] == false).toList();
    for (var entry in unsynced) {
      try {
        // Convert Map<dynamic, dynamic> to Map<String, dynamic> if needed
        final payload = Map<String, dynamic>.from(entry['payload'] as Map);
        
        await FirebaseFirestore.instance.collection('dpr_reports').add(payload);
        
        // Delete from Hive on success
        await _dprBox.delete(entry['id']);
        debugPrint("Synced DPR: ${entry['id']}");
      } catch (e) {
        debugPrint("Failed to sync DPR ${entry['id']}: $e");
      }
    }
  }

  Future<void> _syncMaterialRequests() async {
    if (_materialBox.isEmpty) return;

    final unsynced = _materialBox.values.where((e) => e['isSynced'] == false).toList();
    for (var entry in unsynced) {
      try {
        final payload = Map<String, dynamic>.from(entry['payload'] as Map);
        await FirebaseFirestore.instance.collection('material_requests').add(payload);
        
        await _materialBox.delete(entry['id']);
         debugPrint("Synced Material Request: ${entry['id']}");
      } catch (e) {
        debugPrint("Failed to sync Material Request ${entry['id']}: $e");
      }
    }
  }
}
