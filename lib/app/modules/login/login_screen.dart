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
                AppColors.primaryPurple,
                AppColors.darkPurple,
                AppColors.primaryPurple.withOpacity(0.9),
              ],
              stops: const [0.0, 0.6, 1.0],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Expanded(flex: 35, child: _buildHeader(context, textTheme)),
                Expanded(flex: 65, child: _buildMainContent(context, textTheme)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🌄 Header
  Widget _buildHeader(BuildContext context, TextTheme textTheme) {
    return Container(
      width: double.infinity,
      child: Stack(
        children: [
          Positioned(
            top: 20,
            right: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.white.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            top: 60,
            left: -30,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accentNeon.withOpacity(0.15),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.white.withOpacity(0.15),
                    border: Border.all(
                      color: AppColors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.storefront_rounded,
                    size: 40,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Mobiking",
                  style: textTheme.headlineLarge?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 32,
                    letterSpacing: 1.0,
                  ),
                ),
                Text(
                  "Wholesale",
                  style: textTheme.titleLarge?.copyWith(
                    color: AppColors.white.withOpacity(0.85),
                    fontWeight: FontWeight.w200,
                    fontSize: 18,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🎴 Main Content
  Widget _buildMainContent(BuildContext context, TextTheme textTheme) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            _buildCardHeader(textTheme),
            const SizedBox(height: 32),
            _buildPhoneInput(context, textTheme),
            const SizedBox(height: 24),
            _buildOtpButton(textTheme),
            const Spacer(),
            _buildFooter(textTheme),
          ],
        ),
      ),
    );
  }

  // Card Header
  Widget _buildCardHeader(TextTheme textTheme) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryPurple, AppColors.accentNeon],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          "Welcome Back",
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.textDark,
            fontSize: 26,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Enter your phone number to continue",
          style: textTheme.bodyLarge?.copyWith(
            color: AppColors.textLight,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  // 📱 Phone Input
  Widget _buildPhoneInput(BuildContext context, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Mobile Number",
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w400,
            color: AppColors.textDark,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryPurple.withOpacity(0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: loginController.phoneController,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w400,
              color: AppColors.textDark,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              counterText: "",
              filled: true,
              fillColor: AppColors.neutralBackground,
              hintText: "Enter 10-digit number",
              hintStyle: TextStyle(
                color: AppColors.textLight.withOpacity(0.6),
                fontSize: 15,
              ),
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.lightGreyBackground),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.primaryPurple, width: 1.5),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 🔐 OTP Button
  Widget _buildOtpButton(TextTheme textTheme) {
    return Obx(() => Container(
      width: double.infinity,
      height: 52,
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
        borderRadius: BorderRadius.circular(14),
        boxShadow: loginController.isOtpLoading.value
            ? []
            : [
          BoxShadow(
            color: AppColors.primaryPurple.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
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
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                color: AppColors.white,
                strokeWidth: 2.5,
              ),
            )
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Get OTP',
                  style: textTheme.titleLarge?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.sms_outlined,
                  color: AppColors.white,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }

  // Footer
  Widget _buildFooter(TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: textTheme.bodySmall?.copyWith(
            color: AppColors.textLight,
            height: 1.4,
            fontSize: 12,
          ),
          children: [
            const TextSpan(text: "By continuing, you agree to our "),
            TextSpan(
              text: "Terms of Service",
              style: TextStyle(
                color: AppColors.primaryPurple,
                fontWeight: FontWeight.w500,
              ),
            ),
            const TextSpan(text: " and "),
            TextSpan(
              text: "Privacy Policy",
              style: TextStyle(
                color: AppColors.primaryPurple,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
