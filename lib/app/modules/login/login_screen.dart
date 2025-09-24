import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mobiking/app/controllers/login_controller.dart';
import 'package:mobiking/app/modules/opt/Otp_screen.dart';
import 'package:mobiking/app/themes/app_theme.dart';
import 'package:mobiking/app/controllers/system_ui_controller.dart';

class PhoneAuthScreen extends StatelessWidget {
  PhoneAuthScreen({Key? key}) : super(key: key);

  final LoginController loginController = Get.find();
  final SystemUIController systemUiController = Get.find();

  // Sample product images - replace with your actual product images
  final List<String> productImages = [
    'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=400&h=400&fit=crop', // Vegetables
    'https://images.unsplash.com/photo-1560472354-b33ff0c44a43?w=400&h=400&fit=crop', // Grocery items
    'https://images.unsplash.com/photo-1542838132-92c53300491e?w=400&h=400&fit=crop', // Fruits
    'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400&h=400&fit=crop', // Snacks
    'https://images.unsplash.com/photo-1574071318508-1cdbab80d002?w=400&h=400&fit=crop', // Dairy
    'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400&h=400&fit=crop', // Beverages
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUIController.authScreenStyle,
        child: Container(
          height: screenHeight,
          width: screenWidth,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryPurple.withOpacity(0.08),
                AppColors.white,
                AppColors.primaryPurple.withOpacity(0.03),
              ],
              stops: const [0.0, 0.6, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // Minimal Product Showcase Background (only upper half)
              _buildProductShowcase(screenHeight, screenWidth),
              // Professional Login Form
              _buildGradientOverlay(context, textTheme, screenHeight),
            ],
          ),
        ),
      ),
    );
  }

  // Refined Product Showcase - Limited to upper half only
  Widget _buildProductShowcase(double screenHeight, double screenWidth) {
    return Container(
      height: screenHeight * 0.5, // Restrict to upper half only
      width: screenWidth,
      child: Stack(
        children: [
          _buildRandomProductLayout(screenWidth, screenHeight * 0.5), // Pass restricted height
          _buildFloatingParticles(screenWidth, screenHeight * 0.5),
        ],
      ),
    );
  }

  // Reduced and refined product layout - Only 8 products
  Widget _buildRandomProductLayout(double screenWidth, double screenHeight) {
    final List<Map<String, dynamic>> randomPositions = [
      // Top left area
      {'top': 50.0, 'left': 70.0, 'size': 60.0, 'rotation': -0.1, 'delay': 0},

      // Top center area
      {'top': 90.0, 'left': screenWidth * 0.35, 'size': 65.0, 'rotation': 0.12, 'delay': 300},

      // Top right area
      {'top': 200.0, 'left': screenWidth * 0.8, 'size': 58.0, 'rotation': -0.08, 'delay': 600},

      // Middle left area
      {'top': 200.0, 'left': 100.0, 'size': 68.0, 'rotation': 0.15, 'delay': 200},

      // Middle right area
      {'top': screenHeight * 0.18, 'left': screenWidth * 0.75, 'size': 62.0, 'rotation': -0.12, 'delay': 800},

      // Lower left area
      {'top': screenHeight * 0.32, 'left': 20.0, 'size': 64.0, 'rotation': 0.08, 'delay': 400},

      // Lower center area
      {'top': screenHeight * 0.35, 'left': screenWidth * 0.5, 'size': 66.0, 'rotation': -0.06, 'delay': 1000},

      // Lower right area
      {'top': screenHeight * 0.42, 'left': screenWidth * 0.90, 'size': 60.0, 'rotation': 0.1, 'delay': 1200},
    ];

    return Stack(
      children: randomPositions.asMap().entries.map((entry) {
        int index = entry.key;
        Map<String, dynamic> position = entry.value;

        return TweenAnimationBuilder(
          duration: Duration(milliseconds: 1200 + (position['delay'] as int)),
          tween: Tween<double>(begin: 0, end: 1),
          builder: (context, double value, child) {
            return Positioned(
              top: position['top'],
              left: position['left'],
              child: Transform.rotate(
                angle: (position['rotation'] as double) * value,
                child: Transform.scale(
                  scale: 0.6 + (0.4 * value),
                  child: Opacity(
                    opacity: (value * 0.4).clamp(0.0, 1.0),
                    child: _buildProductCard(index % productImages.length, position['size'] as double),
                  ),
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }


  // Refined Product Card with minimal styling
  Widget _buildProductCard(int index, [double? size]) {
    final cardSize = size ?? 65.0;
    return Container(
      width: cardSize,
      height: cardSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.6),
        border: Border.all(
          color: Colors.white.withOpacity(0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _getProductColor(index).withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _getProductColor(index).withOpacity(0.08),
                _getProductColor(index).withOpacity(0.03),
              ],
            ),
          ),
          child: Center(
            child: Icon(
              _getProductIcon(index),
              size: cardSize * 0.4,
              color: _getProductColor(index).withOpacity(0.8),
            ),
          ),
        ),
      ),
    );
  }

  // Minimal floating particles
  Widget _buildFloatingParticles(double screenWidth, double screenHeight) {
    return Stack(
      children: List.generate(4, (index) { // Reduced to 4 particles
        return TweenAnimationBuilder(
          duration: Duration(milliseconds: 3000 + (index * 400)),
          tween: Tween<double>(begin: 0, end: 1),
          builder: (context, double value, child) {
            return Positioned(
              top: (screenHeight * 0.15) + (index * 60.0) + (15.0 * value),
              left: (screenWidth * 0.85) + (8.0 * value),
              child: Opacity(
                opacity: (0.2 * (1 - value)).clamp(0.0, 1.0),
                child: Container(
                  width: (3 + index).toDouble(),
                  height: (3 + index).toDouble(),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryPurple.withOpacity(0.2),
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  // Get product colors for variety
  Color _getProductColor(int index) {
    final colors = [
      const Color(0xFF4CAF50), // Green
      const Color(0xFFFF9800), // Orange
      const Color(0xFFE91E63), // Pink
      const Color(0xFF9C27B0), // Purple
      const Color(0xFF2196F3), // Blue
      const Color(0xFF00BCD4), // Cyan
      const Color(0xFFFFEB3B), // Yellow
      const Color(0xFFFF5722), // Deep Orange
    ];
    return colors[index % colors.length];
  }

  // Get product icons
  IconData _getProductIcon(int index) {
    final icons = [
      Icons.local_grocery_store_rounded,
      Icons.shopping_basket_rounded,
      Icons.apple_rounded,
      Icons.cookie_rounded,
      Icons.local_drink_rounded,
      Icons.bakery_dining_rounded,
      Icons.shopping_cart_rounded,
      Icons.fastfood_rounded,
    ];
    return icons[index % icons.length];
  }

  // Professional Login Form Overlay
  Widget _buildGradientOverlay(BuildContext context, TextTheme textTheme, double screenHeight) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: screenHeight * 0.62,
        child: _buildLoginForm(context, textTheme),
      ),
    );
  }

  // Professional Glassmorphic Login Form [web:2][web:3]
  Widget _buildLoginForm(BuildContext context, TextTheme textTheme) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.fromLTRB(32, 40, 32, 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.25),
            Colors.white.withOpacity(0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 15),
            spreadRadius: -5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Professional blur level [web:2]
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFormHeader(textTheme),
              const SizedBox(height: 36),
              _buildPhoneInput(context, textTheme),
              const SizedBox(height: 28),
              _buildOtpButton(textTheme),
              const SizedBox(height: 10),
              _buildSimpleFooter(textTheme),
            ],
          ),
        ),
      ),
    );
  }

  // Clean Form Header
  Widget _buildFormHeader(TextTheme textTheme) {
    return Column(
      children: [
        // App branding
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Mobiking",
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                    fontSize: 28,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  "India's best electronics Store",
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.primaryPurple,
                    fontSize: 12,
                    letterSpacing: 0.3,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 28),
        Text(
          "Welcome back!",
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
            fontSize: 22,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "Log in or sign up to continue",
          style: textTheme.bodySmall?.copyWith(
            color: AppColors.textLight,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  // Clean Phone Input
  Widget _buildPhoneInput(BuildContext context, TextTheme textTheme) {
    return TextFormField(
      controller: loginController.phoneController,
      keyboardType: TextInputType.phone,
      maxLength: 10,
      style: textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w500,
        color: AppColors.textDark,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        counterText: "",
        filled: true,
        fillColor: Colors.white.withOpacity(0.8),
        prefixIcon: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.phone_android_rounded,
                color: AppColors.primaryPurple,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '+91',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark,
                  fontSize: 16,
                ),
              ),
              Container(
                width: 1,
                height: 20,
                margin: const EdgeInsets.only(left: 8),
                color: AppColors.textLight.withOpacity(0.3),
              ),
            ],
          ),
        ),
        hintText: "Enter mobile number",
        hintStyle: TextStyle(
          color: AppColors.textLight.withOpacity(0.6),
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.lightGreyBackground.withOpacity(0.4),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.primaryPurple,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.danger, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.danger, width: 2),
        ),
      ),
    );
  }

  // Professional OTP Button
  Widget _buildOtpButton(TextTheme textTheme) {
    return Obx(() => Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: loginController.isOtpLoading.value
              ? [
            AppColors.textLight.withOpacity(0.5),
            AppColors.textLight.withOpacity(0.7),
          ]
              : [
            AppColors.primaryPurple,
            AppColors.darkPurple,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: loginController.isOtpLoading.value
            ? []
            : [
          BoxShadow(
            color: AppColors.primaryPurple.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: loginController.isOtpLoading.value
              ? null
              : () async {
            final phone = loginController.phoneController.text.trim();

            // Validate phone number
            if (phone.length != 10 || !GetUtils.isNumericOnly(phone)) {
              Get.snackbar(
                "Invalid Phone Number",
                "Please enter a valid 10-digit mobile number.",
                backgroundColor: AppColors.danger,
                colorText: AppColors.white,
                margin: const EdgeInsets.all(16),
                borderRadius: 12,
                icon: const Icon(Icons.error_outline, color: Colors.white),
              );
              return;
            }

            final otpSent = await loginController.sendOtp(phone);

            if (otpSent) {
              Get.to(() => OtpVerificationScreen(phoneNumber: phone));
            }
          },
          child: Center(
            child: loginController.isOtpLoading.value
                ? SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: AppColors.white,
                strokeWidth: 2.5,
              ),
            )
                : Text(
              'Continue',
              style: textTheme.titleLarge?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    ));
  }

  // Clean Footer
  Widget _buildSimpleFooter(TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: textTheme.bodySmall?.copyWith(
            color: AppColors.textLight,
            height: 1.5,
            fontSize: 13,
          ),
          children: [
            const TextSpan(text: "By continuing, you agree to our "),
            TextSpan(
              text: "Terms of Service",
              style: TextStyle(
                color: AppColors.primaryPurple,
                fontWeight: FontWeight.w600,
              ),
            ),
            const TextSpan(text: " & "),
            TextSpan(
              text: "Privacy Policy",
              style: TextStyle(
                color: AppColors.primaryPurple,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
