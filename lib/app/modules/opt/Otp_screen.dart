// lib/app/modules/opt/Otp_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:mobiking/app/themes/app_theme.dart';
import 'package:mobiking/app/controllers/login_controller.dart';
import '../bottombar/Bottom_bar.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;

  const OtpVerificationScreen({super.key, required this.phoneNumber});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  TextEditingController otpController = TextEditingController();
  final LoginController _loginController = Get.find<LoginController>();

  @override
  void initState() {
    super.initState();
    // No need to send OTP here since it's already sent from phone auth screen
  }

  // Handle OTP verification using LoginController
  void _handleVerifyOtp() async {
    String otp = otpController.text.trim();

    if (otp.length == 6) {
      final success = await _loginController.verifyOtp(widget.phoneNumber, otp);

      if (!success) {
        otpController.clear();
      }
    } else {
      Get.snackbar(
        'Invalid OTP',
        'Please enter the complete 6-digit OTP.',
        backgroundColor: AppColors.danger,
        colorText: AppColors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
        icon: const Icon(Icons.error_outline, color: Colors.white),
      );
    }
  }

  // Handle resend OTP using LoginController
  void _resendOtp() async {
    await _loginController.resendOtp();
  }

  @override
  void dispose() {
    otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
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
              Expanded(flex: 40, child: _buildHeader(context, textTheme)),
              Expanded(flex: 60, child: _buildMainContent(context, textTheme)),
            ],
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
            top: 16,
            left: 16,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.white,
                  size: 20,
                ),
                onPressed: () => Get.back(),
              ),
            ),
          ),
          Positioned(
            top: 40,
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
            top: 80,
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
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.white.withOpacity(0.15),
                    border: Border.all(
                      color: AppColors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.lock_open_rounded,
                    size: 50,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Verify Account",
                  style: textTheme.headlineLarge?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 28,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      text: "Code sent to ",
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.white.withOpacity(0.85),
                      ),
                      children: [
                        TextSpan(
                          text: widget.phoneNumber,
                          style: TextStyle(
                            color: AppColors.accentNeon,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
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
            _buildOtpInput(context, textTheme),
            const SizedBox(height: 24),
            _buildVerifyButton(textTheme),
            const Spacer(),
            _buildResendSection(textTheme),
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
          "Enter Verification Code",
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
            fontSize: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Please enter the 6-digit code",
          style: textTheme.bodyLarge?.copyWith(
            color: AppColors.textLight,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  // OTP Input Field
  Widget _buildOtpInput(BuildContext context, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: PinCodeTextField(
        controller: otpController,
        appContext: context,
        length: 6,
        obscureText: false,
        animationType: AnimationType.scale,
        keyboardType: TextInputType.number,
        autoFocus: true,
        textStyle: textTheme.headlineSmall?.copyWith(
          color: AppColors.textDark,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
        pinTheme: PinTheme(
          shape: PinCodeFieldShape.box,
          borderRadius: BorderRadius.circular(12),
          fieldHeight: 50,
          fieldWidth: 45,
          activeColor: AppColors.primaryPurple,
          selectedColor: AppColors.primaryPurple,
          inactiveColor: AppColors.lightGreyBackground,
          activeFillColor: AppColors.neutralBackground,
          selectedFillColor: AppColors.lightPurple.withOpacity(0.1),
          inactiveFillColor: AppColors.neutralBackground,
          borderWidth: 1.5,
        ),
        animationDuration: const Duration(milliseconds: 200),
        enableActiveFill: true,
        onCompleted: (v) => _handleVerifyOtp(),
        onChanged: (value) {
          debugPrint(value);
        },
      ),
    );
  }

  // Verify Button
  Widget _buildVerifyButton(TextTheme textTheme) {
    return Obx(() => Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _loginController.isOtpLoading.value
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
        boxShadow: _loginController.isOtpLoading.value
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
          onTap: _loginController.isOtpLoading.value ? null : _handleVerifyOtp,
          child: Center(
            child: _loginController.isOtpLoading.value
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
                  'Verify Code',
                  style: textTheme.titleLarge?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.check_circle_outline,
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

  // Resend Section
  Widget _buildResendSection(TextTheme textTheme) {
    return Column(
      children: [
        Obx(() => _loginController.otpTimeRemaining.value > 0
            ? RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            text: "Resend code in ",
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.textLight,
              fontSize: 13,
            ),
            children: [
              TextSpan(
                text: _loginController.getFormattedTimeRemaining(),
                style: TextStyle(
                  color: AppColors.primaryPurple,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        )
            : Text(
          "Didn't receive the code?",
          style: textTheme.bodySmall?.copyWith(
            color: AppColors.textLight,
            fontSize: 13,
          ),
        )),
        const SizedBox(height: 8),
        Obx(() => TextButton(
          onPressed: _loginController.canResendOtp() ? _resendOtp : null,
          style: TextButton.styleFrom(
            foregroundColor: _loginController.canResendOtp()
                ? AppColors.primaryPurple
                : AppColors.textLight.withOpacity(0.5),
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: _loginController.isResendingOtp.value
              ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primaryPurple),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "Sending...",
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.primaryPurple,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          )
              : Text(
            "Resend OTP",
            style: textTheme.bodySmall?.copyWith(
              color: _loginController.canResendOtp()
                  ? AppColors.primaryPurple
                  : AppColors.textLight.withOpacity(0.5),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        )),
      ],
    );
  }
}
