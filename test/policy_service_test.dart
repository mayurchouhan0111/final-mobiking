
import 'package:flutter_test/flutter_test.dart';
import 'package:mobiking/app/services/policy_service.dart';

void main() {
  group('PolicyService', () {
    test('getPolicies returns a list of policies', () async {
      final policyService = PolicyService();
      final policies = await policyService.getPolicies();
      expect(policies, isNotNull);
      expect(policies, isNotEmpty);
    });

    test('getCompanyDetails returns company details', () async {
      final policyService = PolicyService();
      final companyDetails = await policyService.getCompanyDetails();
      expect(companyDetails, isNotNull);
    });
  });
}
