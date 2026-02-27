import 'package:dio/dio.dart';

import '../data/group_model.dart';

class GroupService {
  Dio _dio = Dio(BaseOptions(baseUrl: 'https://boxbudy.com/api/v1'));

  void overrideDio(Dio dio) {
    _dio = dio;
  }

  Future<List<GroupModel>> getAllGroups() async {
    try {
      final response = await _dio.get('/groups');
      return (response.data as List)
          .map((json) => GroupModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error fetching groups: $e');
    }
  }

  Future<GroupModel> createGroup(GroupModel group) async {
    try {
      final response = await _dio.post('/groups', data: group.toJson());
      return GroupModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Error creating group: $e');
    }
  }
}
