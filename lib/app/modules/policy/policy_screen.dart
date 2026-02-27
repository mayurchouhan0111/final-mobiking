import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobiking/app/data/Policy_model.dart';
import 'package:mobiking/app/modules/policy/policy_detail_screen.dart';
import 'package:mobiking/app/services/policy_service.dart';
import 'package:mobiking/app/themes/app_theme.dart';

class PolicyScreen extends StatefulWidget {
  const PolicyScreen({super.key});

  @override
  State<PolicyScreen> createState() => _PolicyScreenState();
}

class _PolicyScreenState extends State<PolicyScreen> {
  late Future<List<Policy>> _policiesFuture;

  @override
  void initState() {
    super.initState();
    _policiesFuture = PolicyService().getPolicies();
  }

  void _refreshPolicies() {
    setState(() {
      _policiesFuture = PolicyService().getPolicies();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Policies',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textDark,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
      ),
      body: FutureBuilder<List<Policy>>(
        future: _policiesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primaryPurple ?? Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading policies...',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            print('Error fetching policies: ${snapshot.error}');
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 64,
                      color: Colors.red.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Oops! Something went wrong',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Unable to load policies. Please try again.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _refreshPolicies,
                      icon: const Icon(Icons.refresh, size: 20),
                      label: const Text('Try Again'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPurple ?? Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          } else if (snapshot.hasData) {
            final policies = snapshot.data!;

            if (policies.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 64,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Policies Available',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'There are no policies to display at the moment.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      TextButton.icon(
                        onPressed: _refreshPolicies,
                        icon: const Icon(Icons.refresh, size: 20),
                        label: const Text('Refresh'),
                        style: TextButton.styleFrom(
                          foregroundColor:
                              AppColors.primaryPurple ?? Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                _refreshPolicies();
                await _policiesFuture;
              },
              color: AppColors.primaryPurple ?? Colors.blue,
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                itemCount: policies.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final policy = policies[index];
                  return _buildPolicyCard(context, policy);
                },
              ),
            );
          } else {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 64,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Data Available',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildPolicyCard(BuildContext context, Policy policy) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 0,
      child: InkWell(
        onTap: () {
          Get.to(
            () => PolicyDetailScreen(policy: policy),
            transition: Transition.cupertino,
            duration: const Duration(milliseconds: 300),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200, width: 1),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon Container
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: (AppColors.primaryPurple ?? Colors.blue).withOpacity(
                    0.1,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getPolicyIcon(policy.policyName),
                  color: AppColors.primaryPurple ?? Colors.blue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),

              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      policy.policyName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      policy.heading,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Arrow Icon
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getPolicyIcon(String policyName) {
    final lowerName = policyName.toLowerCase();
    if (lowerName.contains('privacy')) {
      return Icons.privacy_tip_outlined;
    } else if (lowerName.contains('return') || lowerName.contains('refund')) {
      return Icons.assignment_return_outlined;
    } else if (lowerName.contains('terms') || lowerName.contains('condition')) {
      return Icons.article_outlined;
    } else if (lowerName.contains('shipping') ||
        lowerName.contains('delivery')) {
      return Icons.local_shipping_outlined;
    } else {
      return Icons.description_outlined;
    }
  }
}
