import 'package:flutter_test/flutter_test.dart';
import 'package:mobiking/app/services/sub_category_service.dart';
import 'package:mockito/mockito.dart';
import 'package:dio/dio.dart';
import 'mocks.mocks.dart';
import 'mocks.mocks.mocks.dart';

void main() {
  group('SubCategoryService', () {
    late SubCategoryService service;
    late MockDio mockDio;

    setUp(() {
      mockDio = MockDio();
      service = SubCategoryService();
      service.overrideDio(mockDio);
    });

    test('fetchSubCategories returns list of subcategories', () async {
      final dummyData = [
        {
          "_id": "sub1",
          "name": "Mobiles",
          "slug": "mobiles",
          "sequenceNo": 1,
          "upperBanner": "banner1.jpg",
          "lowerBanner": "banner2.jpg",
          "active": true,
          "featured": true,
          "deliveryCharge": 20,
          "minOrderAmount": 100,
          "minFreeDeliveryOrderAmount": 500,
          "photos": ["photo1.jpg"],
          "parentCategory": "cat1",
          "products": ["prod1"],
        },
      ];

      when(mockDio.get('/subcategories')).thenAnswer(
        (_) async => Response(
          data: dummyData,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/subcategories'),
        ),
      );

      final result = await service.fetchSubCategories();

      expect(result.length, 1);
      expect(result[0].name, 'Mobiles');
    });
  });
}
