import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import '../common/models/user_model.dart';

/// User service for handling user data operations
/// Provides offline-first caching with Hive + Firestore sync
class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _userCacheBoxName = 'user_cache';

  /// Get current user ID
  static String? get currentUserId => _auth.currentUser?.uid;

  /// Get current user data with offline caching
  static Future<UserModel?> getCurrentUser() async {
    final uid = currentUserId;
    if (uid == null) return null;

    try {
      // Try to get from cache first
      final box = await Hive.openBox<Map>(_userCacheBoxName);
      final cachedData = box.get(uid);
      
      // Try to fetch from Firestore
      final doc = await _firestore.collection('users').doc(uid).get();
      
      if (doc.exists) {
        final userData = doc.data()!;
        final user = UserModel(
          uid: uid,
          name: userData['name'] ?? '',
          email: userData['email'] ?? '',
          role: userData['role'] ?? '',
          generatedId: userData['publicId'] ?? userData['generatedId'] ?? '',
          createdAt: (userData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          lastLoginAt: (userData['lastLoginAt'] as Timestamp?)?.toDate(),
          isSynced: true,
        );
        
        // Cache the user data
        await box.put(uid, user.toMap());
        return user;
      } else if (cachedData != null) {
        // Return cached data if Firestore fails
        return UserModel.fromMap(Map<String, dynamic>.from(cachedData));
      }
      
      return null;
    } catch (e) {
      // If online fetch fails, try cache
      try {
        final box = await Hive.openBox<Map>(_userCacheBoxName);
        final cachedData = box.get(uid);
        if (cachedData != null) {
          return UserModel.fromMap(Map<String, dynamic>.from(cachedData));
        }
      } catch (_) {}
      
      throw Exception('Failed to load user data: ${e.toString()}');
    }
  }

  /// Get user by public ID (for project creation validation)
  static Future<UserModel?> getUserByPublicId(String publicId) async {
    if (publicId.trim().isEmpty) return null;

    try {
      // Query Firestore for user with matching publicId or generatedId (for backward compatibility)
      final query = await _firestore
          .collection('users')
          .where('publicId', isEqualTo: publicId.trim())
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        final userData = doc.data();
        
        return UserModel(
          uid: doc.id,
          name: userData['name'] ?? '',
          email: userData['email'] ?? '',
          role: userData['role'] ?? '',
          generatedId: userData['publicId'] ?? userData['generatedId'] ?? '',
          createdAt: (userData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          lastLoginAt: (userData['lastLoginAt'] as Timestamp?)?.toDate(),
          isSynced: true,
        );
      }

      // Fallback: try generatedId field for backward compatibility
      final fallbackQuery = await _firestore
          .collection('users')
          .where('generatedId', isEqualTo: publicId.trim())
          .limit(1)
          .get();

      if (fallbackQuery.docs.isNotEmpty) {
        final doc = fallbackQuery.docs.first;
        final userData = doc.data();
        
        return UserModel(
          uid: doc.id,
          name: userData['name'] ?? '',
          email: userData['email'] ?? '',
          role: userData['role'] ?? '',
          generatedId: userData['publicId'] ?? userData['generatedId'] ?? '',
          createdAt: (userData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          lastLoginAt: (userData['lastLoginAt'] as Timestamp?)?.toDate(),
          isSynced: true,
        );
      }
      
      return null;
    } catch (e) {
      throw Exception('Failed to find user with ID $publicId: ${e.toString()}');
    }
  }

  /// Validate user role matches expected role
  static bool validateUserRole(UserModel user, String expectedRole) {
    return user.role.toLowerCase() == expectedRole.toLowerCase();
  }

  /// Check if internet is available (simple check)
  static Future<bool> hasInternetConnection() async {
    try {
      // Try a simple Firestore read to check connectivity
      await _firestore.collection('users').limit(1).get();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Cache user data for offline use
  static Future<void> cacheUserData(UserModel user) async {
    try {
      final box = await Hive.openBox<Map>(_userCacheBoxName);
      await box.put(user.uid, user.toMap());
    } catch (e) {
      // Silently fail cache operations
    }
  }

  /// Get cached user data
  static Future<UserModel?> getCachedUser(String uid) async {
    try {
      final box = await Hive.openBox<Map>(_userCacheBoxName);
      final cachedData = box.get(uid);
      if (cachedData != null) {
        return UserModel.fromMap(Map<String, dynamic>.from(cachedData));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Clear user cache (for logout)
  static Future<void> clearUserCache() async {
    try {
      final box = await Hive.openBox<Map>(_userCacheBoxName);
      await box.clear();
    } catch (e) {
      // Silently fail cache operations
    }
  }

  /// Get current user's public ID with caching
  static Future<String?> getCurrentUserPublicId() async {
    try {
      final user = await getCurrentUser();
      return user?.generatedId;
    } catch (e) {
      return null;
    }
  }

  /// Batch validate owner and manager IDs
  static Future<Map<String, dynamic>> validateProjectUsers({
    required String ownerId,
    required String managerId,
  }) async {
    final Map<String, dynamic> result = <String, dynamic>{
      'success': false,
      'owner': null,
      'manager': null,
      'error': null,
    };

    try {
      // Check internet connection
      final hasInternet = await hasInternetConnection();
      if (!hasInternet) {
        result['error'] = 'Internet required to verify IDs';
        return result;
      }

      // Validate input
      if (ownerId.trim().isEmpty || managerId.trim().isEmpty) {
        result['error'] = 'Owner ID and Manager ID are required';
        return result;
      }

      // Fetch both users
      final owner = await getUserByPublicId(ownerId);
      final manager = await getUserByPublicId(managerId);

      // Check if users exist
      if (owner == null) {
        result['error'] = 'Owner ID not found';
        return result;
      }

      if (manager == null) {
        result['error'] = 'Manager ID not found';
        return result;
      }

      // Validate roles
      if (!validateUserRole(owner, 'ownerClient')) {
        result['error'] = 'Invalid Owner ID - user is not an owner';
        return result;
      }

      if (!validateUserRole(manager, 'fieldManager')) {
        result['error'] = 'Invalid Manager ID - user is not a manager';
        return result;
      }

      // Success
      result['success'] = true;
      result['owner'] = owner;
      result['manager'] = manager;
      
      return result;
    } catch (e) {
      result['error'] = 'Failed to validate users: ${e.toString()}';
      return result;
    }
  }
}