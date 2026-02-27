import 'package:dio/dio.dart';
import '../data/login_model.dart';

class UserService {
  final Dio _dio;
  final String _baseUrl = 'https://boxbudy.com/api/v1/users';

  UserService(this._dio); // Inject Dio instance

  void _log(String message) {
    print('[UserService] $message');
  }

  Future<UserModel> createUser(UserModel user) async {
    try {
      _log('Creating user: ${user.toJson()}');
      final response = await _dio.post('$_baseUrl', data: user.toJson());
      _log(
        'Create user response: Status ${response.statusCode}, Data: ${response.data}',
      );
      return UserModel.fromJson(response.data);
    } on DioException catch (e) {
      _log(
        'Error creating user: ${e.response?.statusCode} - ${e.response?.data}',
      );
      throw Exception(
        'Failed to create user: ${e.response?.data?['message'] ?? e.message}',
      );
    } catch (e) {
      _log('Unexpected error creating user: $e');
      throw Exception('Failed to create user: $e');
    }
  }

  Future<UserModel?> getUserByPhone(String phoneNo) async {
    try {
      _log('Fetching user by phone: $phoneNo');
      final response = await _dio.get(
        '$_baseUrl',
        queryParameters: {'phoneNo': phoneNo},
      );
      _log(
        'Get user by phone response: Status ${response.statusCode}, Data: ${response.data}',
      );
      if (response.statusCode == 200 &&
          response.data != null &&
          response.data['data'] != null) {
        // Assuming the API returns a list of users, and we expect at most one for a phone number
        if (response.data['data'] is List && response.data['data'].isNotEmpty) {
          return UserModel.fromJson(response.data['data'][0]);
        } else if (response.data['data'] is Map) {
          // If it returns a single user object directly
          return UserModel.fromJson(response.data['data']);
        }
      }
      _log('User with phone $phoneNo not found in response data.');
      return null; // User not found
    } on DioException catch (e) {
      _log(
        'Error fetching user by phone: ${e.response?.statusCode} - ${e.response?.data}',
      );
      if (e.response?.statusCode == 404) {
        return null; // User not found
      }
      throw Exception(
        'Failed to fetch user by phone: ${e.response?.data?['message'] ?? e.message}',
      );
    } catch (e) {
      _log('Unexpected error fetching user by phone: $e');
      throw Exception('Failed to fetch user by phone: $e');
    }
  }

  Future<UserModel> getUserById(String id) async {
    try {
      _log('Fetching user by ID: $id');
      final response = await _dio.get('$_baseUrl/$id');
      _log(
        'Get user by ID response: Status ${response.statusCode}, Data: ${response.data}',
      );
      return UserModel.fromJson(response.data);
    } on DioException catch (e) {
      _log(
        'Error fetching user by ID: ${e.response?.statusCode} - ${e.response?.data}',
      );
      throw Exception(
        'Failed to fetch user: ${e.response?.data?['message'] ?? e.message}',
      );
    } catch (e) {
      _log('Unexpected error fetching user by ID: $e');
      throw Exception('Failed to fetch user: $e');
    }
  }
}
