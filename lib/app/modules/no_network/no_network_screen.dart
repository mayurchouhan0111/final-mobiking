import 'package:flutter/material.dart';
// If you are completely replacing GoogleFonts, you might remove this.
// However, if your AppTheme still uses GoogleFonts for its base styles, keep it.
// import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart'; // For animations, make sure it's in your pubspec.yaml
import 'package:get/get.dart'; // For using GetX themes if available, and snackbars.

import '../../themes/app_theme.dart'; // Assuming your AppColors and TextTheme are defined here

class NoNetworkScreen extends StatelessWidget {
  final VoidCallback onRetry;
  final String? message; // Optional custom message

  const NoNetworkScreen({Key? key, required this.onRetry, this.message})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme; // Get TextTheme

    return Scaffold(
      backgroundColor:
          AppColors.neutralBackground, // Use your app's background color
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Lottie Animation for network issue (like the coffee machine with ERR)
              Lottie.asset(
                'assets/animations/network_error.json', // Placeholder: Replace with your actual Lottie animation file
                width: 200,
                height: 200,
                fit: BoxFit.contain,
                repeat: true, // Animation repeats while user is on this screen
                errorBuilder: (context, error, stackTrace) {
                  // Fallback to a static icon if Lottie fails to load
                  debugPrint(
                    'Error loading Lottie animation for no network: $error',
                  );
                  return Icon(
                    Icons.cloud_off_rounded,
                    size: 150,
                    color: AppColors.textLight.withOpacity(
                      0.6,
                    ), // Use AppColors
                  );
                },
              ),
              const SizedBox(height: 40), // Increased spacing

              Text(
                message ??
                    'Your internet is a little wonky', // Default or custom message
                textAlign: TextAlign.center,
                style: textTheme.headlineMedium?.copyWith(
                  // Using headlineMedium
                  color: AppColors.textDark, // Use AppColors
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'Try switching to a different connection or\nreset your internet to place an order.',
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(
                  // Using bodyLarge
                  color: AppColors.textDark.withOpacity(0.7), // Use AppColors
                ),
              ),
              const SizedBox(height: 40), // Increased spacing

              ElevatedButton(
                onPressed: onRetry, // Calls the provided retry function
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      AppColors.primaryPurple, // Use your primary color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), // Rounded corners
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 16,
                  ),
                  elevation: 5, // Add subtle shadow
                ),
                child: Text(
                  'RETRY',
                  style: textTheme.labelLarge?.copyWith(
                    // Using labelLarge for button text
                    color: Colors.white,
                    letterSpacing: 1.5, // Keep letter spacing for effect
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
