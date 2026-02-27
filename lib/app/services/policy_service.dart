import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobiking/app/data/CompanyDetail_model.dart';
import 'package:mobiking/app/data/Policy_model.dart';

class PolicyService {
  static const String _baseUrl = 'https://boxbudy.com/api/v1/';

  Future<List<Policy>> getPolicies() async {
    final response = await http.get(Uri.parse('${_baseUrl}policy'));

    if (response.statusCode == 200) {
      final policyResponse = PolicyResponse.fromJson(
        json.decode(response.body),
      );
      return policyResponse.data;
    } else {
      throw Exception('Failed to load policies');
    }
  }

  Future<CompanyDetails> getCompanyDetails() async {
    final response = await http.get(
      Uri.parse('${_baseUrl}policy/company-details'),
    );

    if (response.statusCode == 200) {
      final companyDetailsResponse = CompanyDetailsResponse.fromJson(
        json.decode(response.body),
      );
      return companyDetailsResponse.data;
    } else {
      throw Exception('Failed to load company details');
    }
  }
}
