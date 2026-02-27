import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:dio/dio.dart';
import 'package:mobiking/app/services/group_service.dart';
import 'package:mobiking/app/data/group_model.dart';

import 'mocks.mocks.dart';
import 'mocks.mocks.mocks.dart'; // This should contain MockDio

void main() {
  group('GroupService', () {
    late GroupService service;
    late MockDio mockDio;

    setUp(() {
      mockDio = MockDio();
      service = GroupService();
      service.overrideDio(mockDio); // Add this method to GroupService
    });

    test('getAllGroups returns list of groups', () async {
      final dummyGroups = [
        {
          "_id": "group1",
          "name": "Mobiles",
          "sequenceNo": 1,
          "banner": "http://example.com/banner.jpg",
          "active": true,
          "products": ["prod1", "prod2"],
        },
      ];

      when(mockDio.get('/groups')).thenAnswer(
        (_) async => Response(
          data: dummyGroups,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/groups'),
        ),
      );

      final result = await service.getAllGroups();

      expect(result.length, 1);
      expect(result.first.name, 'Mobiles');
      expect(result.first.sequenceNo, 1);
      expect(result.first.banner, 'http://example.com/banner.jpg');
      expect(result.first.products.length, 2);
    });

    test('createGroup posts and returns group model', () async {
      final group = GroupModel(
        id: 'group1',
        name: 'Mobiles',
        sequenceNo: 1,
        banner: 'http://example.com/banner.jpg',
        active: true,
        products: ['prod1', 'prod2'],
      );

      when(mockDio.post('/groups', data: anyNamed('data'))).thenAnswer(
        (_) async => Response(
          data: group.toJson(),
          statusCode: 201,
          requestOptions: RequestOptions(path: '/groups'),
        ),
      );

      final result = await service.createGroup(group);

      expect(result.name, 'Mobiles');
      expect(result.sequenceNo, 1);
      expect(result.products.contains('prod1'), isTrue);
    });
  });
}
