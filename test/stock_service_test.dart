import 'package:flutter_test/flutter_test.dart';
import 'package:mobiking/app/data/stock_model.dart';
import 'package:mobiking/app/services/stock_service.dart';
import 'package:mockito/mockito.dart';
import 'package:dio/dio.dart';

import 'mocks.mocks.dart';
import 'mocks.mocks.mocks.dart';

void main() {
  group('StockService', () {
    late StockService service;
    late MockDio mockDio;

    setUp(() {
      mockDio = MockDio();
      service = StockService();
      service.overrideDio(
        mockDio,
      ); // Make sure your StockService has this method
    });

    test('getAllStocks returns a list of stocks', () async {
      final dummyStockData = [
        {
          "_id": "stock1",
          "productId": "prod1",
          "quantity": "50",
          "variantName": "prod1",
          "purchasePrice": 100,
        },
      ];

      when(mockDio.get('/stocks')).thenAnswer(
        (_) async => Response(
          data: dummyStockData,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/stocks'),
        ),
      );

      final stocks = await service.getAllStocks();

      expect(stocks.length, 1);
      expect(stocks[0].productId, 'prod1');
    });

    test('createStock posts and returns a stock model', () async {
      final stock = StockModel(
        id: 'stock1',
        productId: 'prod1',
        quantity: "100",
        variantName: 'prod1',
        purchasePrice: 100,
      );

      when(mockDio.post('/stocks', data: anyNamed('data'))).thenAnswer(
        (_) async => Response(
          data: stock.toJson(),
          statusCode: 201,
          requestOptions: RequestOptions(path: '/stocks'),
        ),
      );

      final result = await service.createStock(stock);

      expect(result.productId, 'prod1');
      expect(result.quantity, "100");
    });
  });
}
