import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart'; // Import GetStorage
import '../data/Home_model.dart';
import '../data/group_model.dart';

class HomeService {
  static const String _baseUrl = 'https://boxbudy.com/api/v1';
  final GetStorage _box; // GetStorage instance

  HomeService(this._box); // Constructor to receive GetStorage

  void _log(String message) {
    print('[HomeService] $message');
  }

  /// Get home layout with comprehensive error handling
  Future<HomeLayoutModel?> getHomeLayout({bool forceRefresh = false}) async {
    const String cacheKey = 'homeLayoutCache';
    const String timestampKey = 'homeLayoutTimestamp';
    const Duration cacheDuration = Duration(
      minutes: 10,
    ); // Reduced to 10 minutes for better responsiveness

    // 1. Try to load from cache first (if not forcing refresh)
    if (!forceRefresh) {
      final cachedData = _box.read(cacheKey);
      final cachedTimestamp = _box.read(timestampKey);

      if (cachedData != null && cachedTimestamp != null) {
        final DateTime lastFetchTime = DateTime.parse(cachedTimestamp);
        if (DateTime.now().difference(lastFetchTime) < cacheDuration) {
          _log('✅ Loading home layout from cache.');
          try {
            return HomeLayoutModel.fromJson(jsonDecode(cachedData));
          } catch (e) {
            _log('❌ Error decoding cached home layout: $e');
            // If cache is corrupted, proceed to fetch from network
          }
        } else {
          _log('⏳ Cached home layout is stale. Fetching new data.');
        }
      } else {
        _log(
          '📦 No home layout in cache or timestamp missing. Fetching new data.',
        );
      }
    } else {
      _log('🔄 Force refresh requested. Fetching new data from network.');
    }

    // 2. Fetch from network if cache is not available or stale
    try {
      final url = Uri.parse('$_baseUrl/home/');
      _log('Fetching home layout from: $url (Timeout: 45s)');

      final response = await http
          .get(url)
          .timeout(
            const Duration(seconds: 45),
            onTimeout: () {
              _log('⚠️ Request timeout while fetching home layout');
              return http.Response('Request timeout', 408);
            },
          );

      _log('Home layout response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        try {
          final jsonData = jsonDecode(response.body);
          if (jsonData != null && jsonData is Map<String, dynamic>) {
            final dynamic dataField = jsonData['data'];

            if (dataField != null && dataField is Map<String, dynamic>) {
              final homeLayout = HomeLayoutModel.fromJson(dataField);
              
              // 3. Store in cache
              _box.write(cacheKey, jsonEncode(dataField));
              _box.write(timestampKey, DateTime.now().toIso8601String());
              _log('💾 Successfully fetched and cached new home layout.');
              return homeLayout;
            }
          }
        } catch (e) {
          _log('❌ Error parsing new network data: $e');
        }
      }

      // 4. FALLBACK: If network failed (timeout, 500, etc.), try to return stale cache
      _log('🔄 Network fetch unsuccessful/stale. Checking for fallback cache...');
      final staleData = _box.read(cacheKey);
      if (staleData != null) {
        _log('✅ Serving stale cache as fallback to prevent 408 breakdown.');
        return HomeLayoutModel.fromJson(jsonDecode(staleData));
      }

      return null;
    } catch (e) {
      _log('❌ Exception during home layout fetch: $e');
      // Final fallback to cache on exception
      final staleData = _box.read(cacheKey);
      if (staleData != null) {
        _log('✅ Serving stale cache after exception.');
        return HomeLayoutModel.fromJson(jsonDecode(staleData));
      }
      return null;
    }
  }

  // Health check method
  Future<bool> checkServiceHealth() async {
    try {
      _log('Performing health check...');
      final url = Uri.parse('$_baseUrl/home/');

      final response = await http
          .get(url)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => http.Response('Timeout', 408),
          );

      final isHealthy = response.statusCode == 200;
      _log(
        'Service health check: ${isHealthy ? 'Healthy' : 'Unhealthy'} (Status: ${response.statusCode})',
      );
      return isHealthy;
    } catch (e) {
      _log('Health check failed: $e');
      return false;
    }
  }

  // Get groups by multiple categories
  /*Future<Map<String, List<GroupModel>>> getGroupsByMultipleCategories(List<String> categoryIds) async {
    if (categoryIds.isEmpty) {
      _log('Error: No category IDs provided');
      return <String, List<GroupModel>>{};
    }

    _log('Fetching groups for ${categoryIds.length} categories');
    final Map<String, List<GroupModel>> result = {};

    for (final categoryId in categoryIds) {
      if (categoryId.trim().isNotEmpty) {
        try {
          final groups = await getGroupsByCategory(categoryId);
          result[categoryId] = groups;
          _log('✅ Fetched ${groups.length} groups for category: $categoryId');
        } catch (e) {
          _log('❌ Error fetching groups for category $categoryId: $e');
          result[categoryId] = <GroupModel>[];
        }
      }
    }

    _log('✅ Completed fetching groups for ${result.length} categories');

    // Show success message for multiple categories fetch
    int totalGroups = result.values.fold(0, (sum, list) => sum + list.length);
    if (totalGroups > 0) {
     */ /* Get.snackbar('Success', 'Loaded $totalGroups products across ${result.length} categories!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade600,
          colorText: Colors.white);*/ /*
    }

    return result;
  }
*/
  // Get group by ID with error handling
  Future<GroupModel?> getGroupById(String groupId) async {
    if (groupId.trim().isEmpty) {
      _log('Error: Group ID is required');
      return null;
    }

    try {
      final url = Uri.parse('$_baseUrl/groups/${groupId.trim()}');
      _log('Fetching group by ID: $groupId');

      final response = await http
          .get(url)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => http.Response('Request timeout', 408),
          );

      if (response.statusCode == 200) {
        try {
          final jsonData = jsonDecode(response.body);

          if (jsonData is Map<String, dynamic>) {
            final dataField = jsonData['data'] ?? jsonData;
            if (dataField is Map<String, dynamic>) {
              final group = GroupModel.fromJson(dataField);
              _log('✅ Successfully fetched group: ${group.id}');

              /*      // Show success message for successful group fetch
              Get.snackbar('Success', 'Product details loaded successfully!',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.green.shade600,
                  colorText: Colors.white);*/

              return group;
            }
          }

          _log('❌ Invalid response format for group ID: $groupId');
          return null;
        } catch (jsonError) {
          _log('❌ JSON parsing error for group ID $groupId: $jsonError');
          return null;
        }
      } else {
        _log(
          '❌ Failed to fetch group ID $groupId. Status: ${response.statusCode}',
        );
        return null;
      }
    } catch (e) {
      _log('❌ Exception fetching group ID $groupId: $e');
      return null;
    }
  }

  // Search groups with error handling
  Future<List<GroupModel>> searchGroups(String query) async {
    if (query.trim().isEmpty) {
      _log('Empty search query provided');
      return <GroupModel>[];
    }

    try {
      final url = Uri.parse(
        '$_baseUrl/groups/search?q=${Uri.encodeComponent(query.trim())}',
      );
      _log('Searching groups with query: ${query.trim()}');

      final response = await http
          .get(url)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => http.Response('Request timeout', 408),
          );

      if (response.statusCode == 200) {
        try {
          final jsonData = jsonDecode(response.body);

          if (jsonData is Map<String, dynamic>) {
            final dataField = jsonData['data'];
            if (dataField is List) {
              final List<GroupModel> groups = [];
              for (int i = 0; i < dataField.length; i++) {
                try {
                  final item = dataField[i];
                  if (item is Map<String, dynamic>) {
                    final group = GroupModel.fromJson(item);
                    groups.add(group);
                  }
                } catch (e) {
                  _log('Error parsing search result at index $i: $e');
                }
              }

              _log(
                '✅ Found ${groups.length} groups matching query: ${query.trim()}',
              );

              // Show success message for successful search
              if (groups.isNotEmpty) {
                /*  Get.snackbar('Success', 'Found ${groups.length} products matching "${query.trim()}"!',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.green.shade600,
                    colorText: Colors.white);*/
              }

              return groups;
            }
          }

          _log('❌ Invalid search response format');
          return <GroupModel>[];
        } catch (jsonError) {
          _log('❌ JSON parsing error in searchGroups: $jsonError');
          return <GroupModel>[];
        }
      } else {
        _log('❌ Group search failed. Status: ${response.statusCode}');
        return <GroupModel>[];
      }
    } catch (e) {
      _log('❌ Exception during group search: $e');
      return <GroupModel>[];
    }
  }
}
