import 'package:dio/dio.dart';

import '../data/stock_model.dart';


class StockService {
  Dio _dio;

  StockService() : _dio = Dio(BaseOptions(baseUrl: 'https://boxbudy.com/api/v1'));

  // For test injection
  void overrideDio(Dio dio) {
    _dio = dio;
  }


  Future<List<StockModel>> getAllStocks() async {
    try {
      final response = await _dio.get('/stocks');
      return (response.data as List)
          .map((json) => StockModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error fetching stocks: $e');
    }
  }

  Future<StockModel> createStock(StockModel stock) async {
    try {
      final response = await _dio.post('/stocks', data: stock.toJson());
      return StockModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Error creating stock: $e');
    }
  }
}
