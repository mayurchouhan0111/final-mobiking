import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:dio/dio.dart';
import 'package:mobiking/app/services/user_service.dart';
import 'package:mobiking/app/data/login_model.dart';
import 'package:mobiking/app/data/cart_model.dart';

import 'mocks.mocks.dart';
import 'mocks.mocks.mocks.dart'; // make sure this includes MockDio

void main() {
  group('UserService', () {
    late UserService service;
    late MockDio mockDio;

    setUp(() {
      mockDio = MockDio();
      service = UserService();
      service.overrideDio(mockDio); // add this method in UserService
    });

    test('createUser posts and returns a UserModel', () async {
      final user = UserModel(
        name: 'John Doe',
        email: 'john@example.com',
        phoneNo: '1234567890',
        role: 'customer',
        profilePicture: 'http://example.com/image.jpg',
        departments: ['sales', 'support'],
        documents: ['doc1', 'doc2'],
        permissions: {'canOrder': true},
        cart: [CartModel(productId: 'p1', quantity: 2, price: 100.0)],
      );

      when(mockDio.post('/users', data: anyNamed('data'))).thenAnswer(
        (_) async => Response(
          data: user.toJson(),
          statusCode: 201,
          requestOptions: RequestOptions(path: '/users'),
        ),
      );

      final result = await service.createUser(user);

      expect(result.name, 'John Doe');
      expect(result.cart.length, 1);
      expect(result.cart.first.productId, 'p1');
      expect(result.permissions?['canOrder'], true);
    });

    test('getUserById returns a UserModel', () async {
      final userJson = {
        "_id": "u1",
        "name": "Jane Smith",
        "email": "jane@example.com",
        "phoneNo": "9876543210",
        "role": "admin",
        "profilePicture": "http://example.com/avatar.jpg",
        "departments": ["admin"],
        "documents": ["docX", "docY"],
        "permissions": {"canEdit": true},
        "cart": [
          {"productId": "prod1", "quantity": 1, "price": 150.0},
        ],
      };

      when(mockDio.get('/users/u1')).thenAnswer(
        (_) async => Response(
          data: userJson,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/users/u1'),
        ),
      );

      final result = await service.getUserById("u1");

      expect(result.id, 'u1');
      expect(result.name, 'Jane Smith');
      expect(result.permissions?['canEdit'], true);
      expect(result.cart.first.productId, 'prod1');
    });
  });
}
