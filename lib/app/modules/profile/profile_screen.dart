import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobiking/app/controllers/user_controller.dart';
import 'package:mobiking/app/data/Policy_model.dart';
import 'package:mobiking/app/modules/address/AddressPage.dart';
import 'package:mobiking/app/modules/about/about_screen.dart';
import 'package:mobiking/app/modules/policy/policy_detail_screen.dart';
import 'package:mobiking/app/modules/profile/wishlist/Wish_list_screen.dart';
import 'package:mobiking/app/services/policy_service.dart';
import 'package:mobiking/app/themes/app_theme.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mobiking/app/widgets/profile_reusable_widget.dart';
import '../orders/order_screen.dart' show OrderHistoryScreen;
import '../policy/logout_screen.dart';
import '../policy/delete_account_screen.dart';
import 'package:mobiking/app/controllers/login_controller.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<List<Policy>> _policiesFuture;

  @override
  void initState() {
    super.initState();
    _policiesFuture = PolicyService().getPolicies();
  }

  @override
  Widget build(BuildContext context) {
    final LoginController loginController = Get.find<LoginController>();
    final TextTheme textTheme = Theme.of(context).textTheme;
    final UserController userController = Get.find<UserController>();

    return Scaffold(
      backgroundColor: AppColors.neutralBackground,
      appBar: AppBar(
        title: Text(
          "My Profile",
          style: textTheme.bodyMedium?.copyWith(
            color: AppColors.textDark,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
        backgroundColor: AppColors.white,
        elevation: 0.5,
        foregroundColor: AppColors.textDark,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Info Section
              Obx(() {
                final userName = userController.userName.value;
                final userMap = loginController.currentUser.value;
                String phoneNumber = '';

                if (userMap != null) {
                  phoneNumber = userMap['phoneNo'] as String? ?? '';
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName.isNotEmpty
                          ? userName
                          : (phoneNumber.isNotEmpty
                                ? phoneNumber
                                : 'Guest User'),
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                );
              }),
              const SizedBox(height: 24),

              // ✅ Updated Top Action Boxes: Your Orders, Address, Wishlist, User
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: InfoBox(
                      icon: Icons.shopping_bag_outlined,
                      title: 'Orders',
                      onPressed: () {
                        Get.to(
                          () => const OrderHistoryScreen(),
                          transition: Transition.rightToLeftWithFade,
                          duration: const Duration(milliseconds: 300),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InfoBox(
                      icon: Icons.location_on_outlined,
                      title: 'Address',
                      onPressed: () {
                        Get.to(
                          () => AddressPage(),
                          transition: Transition.rightToLeftWithFade,
                          duration: const Duration(milliseconds: 300),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InfoBox(
                      icon: Icons.person_outline,
                      title: 'User',
                      onPressed: () {
                        Get.to(
                          () => AddressPage(initialShowUserSection: true),
                          transition: Transition.rightToLeftWithFade,
                          duration: const Duration(milliseconds: 300),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InfoBox(
                      icon: Icons.favorite_border_outlined,
                      title: 'Wishlist',
                      onPressed: () {
                        Get.to(
                          WishlistScreen(),
                          transition: Transition.rightToLeftWithFade,
                          duration: const Duration(milliseconds: 300),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // ✅ YOUR INFORMATION Section
              Text(
                'YOUR INFORMATION',
                style: textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textLight,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),

              ProfileListTile(
                icon: Icons.share_outlined,
                title: 'Share The App',
                onTap: () {
                  Share.share(
                    'Check out Mobiking for wholesale mobile phones and accessories: [Your App Store Link Here]',
                    subject: 'Discover Mobiking!',
                  );
                },
              ),

              const SizedBox(height: 24),

              // ✅ SOCIAL Section
              Text(
                'SOCIAL',
                style: textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textLight,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),

              /*   ProfileListTile(
                icon: Icons.chat_bubble_outline,
                title: 'WhatsApp',
                onTap: () {
                  _launchWhatsApp();
                },
              ),*/
              ProfileListTile(
                icon: Icons.info_outline,
                title: 'About Us',
                onTap: () {
                  Get.to(() => const AboutScreen());
                },
              ),

              const SizedBox(height: 24),

              // ✅ POLICIES Section
              Text(
                'POLICIES',
                style: textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textLight,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),

              FutureBuilder<List<Policy>>(
                future: _policiesFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final policies = snapshot.data!;
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: policies.length,
                      itemBuilder: (context, index) {
                        final policy = policies[index];
                        return ProfileListTile(
                          icon: _getPolicyIcon(policy.policyName),
                          title: policy.policyName,
                          onTap: () {
                            Get.to(() => PolicyDetailScreen(policy: policy));
                          },
                        );
                      },
                    );
                  } else if (snapshot.hasError) {
                    return const Text('Error loading policies');
                  }
                  return const Center(child: CircularProgressIndicator());
                },
              ),

              const SizedBox(height: 32),

              // Logout Button (Full Width)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    showLogoutDialog(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    'Logout',
                    style: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
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

  // ✅ User Settings Bottom Sheet
  void _showUserBottomSheet(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textLight.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'User Settings',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 24),

            // Delete Account Button (Styled as per original theme)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close bottom sheet first
                  showDeleteAccountDialog(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.textDark,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  'Delete Account',
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ✅ WhatsApp Launch Function
  void _launchWhatsApp() async {
    const phoneNumber = "+1234567890"; // Replace with your WhatsApp number
    const message = "Hello! I need help with Mobiking app.";

    final whatsappUrl =
        "https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}";

    try {
      if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
        await launchUrl(
          Uri.parse(whatsappUrl),
          mode: LaunchMode.externalApplication,
        );
      } else {
        /*
        Get.snackbar(
          'Error',
          'WhatsApp is not installed on your device',
          backgroundColor: AppColors.danger,
          colorText: AppColors.white,
        );*/
      }
    } catch (e) {
      /*Get.snackbar(
        'Error',
        'Could not open WhatsApp',
        backgroundColor: AppColors.danger,
        colorText: AppColors.white,
      );*/
    }
  }
}
