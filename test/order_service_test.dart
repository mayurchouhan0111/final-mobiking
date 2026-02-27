import 'package:flutter_test/flutter_test.dart';
import 'package:mobiking/app/data/order_model.dart';
import 'package:mobiking/app/data/cart_model.dart';
import 'package:mobiking/app/services/order_service.dart';
import 'package:mockito/mockito.dart';
import 'package:dio/dio.dart';

import 'mocks.mocks.dart';
import 'mocks.mocks.mocks.dart';

void main() {
  group('OrderService', () {
    late OrderService service;
    late MockDio mockDio;

    setUp(() {
      mockDio = MockDio();
      service = OrderService();
      service.overrideDio(mockDio); // Add this in your service
    });

    test('fetchOrders returns a list of orders', () async {
      final dummyOrders = [
        {
          "_id": "order1",
          "status": "pending",
          "type": "online",
          "abondonedOrder": false,
          "orderId": "ORD123",
          "orderAmount": 1000.0,
          "address": "123 Street",
          "deliveryCharge": 50.0,
          "discount": 100.0,
          "gst": 18.0,
          "subtotal": 900.0,
          "method": "COD",
          "userId": "user1",
          "items": [
            {"productId": "prod1", "quantity": 2, "price": 200.0},
          ],
        },
      ];

      when(mockDio.get('/orders')).thenAnswer(
        (_) async => Response(
          data: dummyOrders,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/orders'),
        ),
      );

      final orders = await service.fetchOrders();

      expect(orders.length, 1);
      expect(orders[0].orderId, 'ORD123');
      expect(orders[0].items[0].productId, 'prod1');
      expect(orders[0].items[0].price, 200.0);
    });

    test('placeOrder posts and returns an order model', () async {
      final order = OrderModel(
        status: "pending",
        type: "online",
        abondonedOrder: false,
        orderId: "ORD123",
        orderAmount: 1000.0,
        address: "123 Street",
        deliveryCharge: 50.0,
        discount: 100.0,
        gst: 18.0,
        subtotal: 900.0,
        method: "COD",
        userId: "user1",
        items: [CartModel(productId: "prod1", quantity: 2, price: 200.0)],
      );

      when(mockDio.post('/orders', data: anyNamed('data'))).thenAnswer(
        (_) async => Response(
          data: order.toJson(),
          statusCode: 201,
          requestOptions: RequestOptions(path: '/orders'),
        ),
      );

      final result = await service.placeOrder(order);

      expect(result.orderId, 'ORD123');
      expect(result.items.first.productId, 'prod1');
      expect(result.items.first.quantity, 2);
    });
  });
}
