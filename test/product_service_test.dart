import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:mockito/mockito.dart';

import 'package:mobiking/app/services/product_service.dart';
import 'package:mobiking/app/data/product_model.dart';

import 'mocks.mocks.dart';
import 'mocks.mocks.mocks.dart';

void main() {
  group('ProductService', () {
    late ProductService productService;
    late MockDio mockDio;

    setUp(() {
      mockDio = MockDio();
      productService = ProductService();
      productService.overrideDio(mockDio); // Add this method in your service
    });

    test('getAllProducts returns list of ProductModel', () async {
      final mockResponseData = [
        {
          "_id": "1",
          "name": "Phone",
          "fullName": "Smartphone X",
          "slug": "smartphone-x",
          "description": "Latest model",
          "active": true,
          "newArrival": true,
          "liked": false,
          "bestSeller": false,
          "recommended": true,
          "sellingPrice": [
            {"price": 999.99},
          ],
          "category": "electronics",
          "stock": ["s1", "s2"],
          "orders": ["o1"],
          "groups": ["g1"],
        },
      ];

      when(mockDio.get('/products')).thenAnswer(
        (_) async => Response(
          data: mockResponseData,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/products'),
        ),
      );

      final result = await productService.getAllProducts();

      expect(result.length, 1);
      expect(result.first.name, "Phone");
      expect(result.first.sellingPrice.first.price, 999.99);
      expect(result.first.groups, contains("g1"));
    });

    test('createProduct posts product and returns ProductModel', () async {
      final product = ProductModel(
        name: "Tablet",
        fullName: "Pro Tablet 10",
        slug: "pro-tablet-10",
        description: "Lightweight and powerful",
        newArrival: true,
        sellingPrice: [SellingPrice(price: 499.99)],
        category: "gadgets",
        stock: ["stk123"],
        orders: [],
        groups: ["grp1"],
      );

      when(mockDio.post('/products', data: anyNamed('data'))).thenAnswer(
        (_) async => Response(
          data: product.toJson(),
          statusCode: 201,
          requestOptions: RequestOptions(path: '/products'),
        ),
      );

      final result = await productService.createProduct(product);

      expect(result.name, "Tablet");
      expect(result.sellingPrice.first.price, 499.99);
      expect(result.category, "gadgets");
      expect(result.groups, contains("grp1"));
    });
  });
}
