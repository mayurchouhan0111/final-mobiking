import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mobiking/app/services/category_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'category_service_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  group('CategoryService', () {
    late MockClient mockClient;
    late CategoryService categoryService;

    setUp(() {
      mockClient = MockClient();
      categoryService = CategoryService();
    });

    test('returns categories from API', () async {
      final dummyData = [
        {
          "_id": "123",
          "name": "Electronics",
          "active": true,
          "subCategories": ["sub1", "sub2"],
        },
        {"_id": "124", "name": "Fashion", "active": true, "subCategories": []},
      ];

      when(
        mockClient.get(Uri.parse('https://boxbudy.com/api/v1/categories')),
      ).thenAnswer(
        (_) async => http.Response(jsonEncode({'data': dummyData}), 200),
      );

      final result = await categoryService.getCategories(client: mockClient);

      expect(result.length, 2);
      expect(result[0].name, 'Electronics');
      expect(result[1].name, 'Fashion');
    });
  });
}
