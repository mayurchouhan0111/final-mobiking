import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../themes/app_theme.dart';

void showSupportDialog(BuildContext context) {
  final String supportEmail =
      'support@mobiking.com'; // Your actual support email

  Get.dialog(
    AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Contact Support',
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark, // Use your app's dark text color
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.email_outlined,
            size: 60,
            color: AppColors.primaryPurple,
          ), // App-themed icon
          const SizedBox(height: 16),
          Text(
            'For any assistance or queries, please feel free to email us at:',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textLight, // Use your app's light text color
            ),
          ),
          const SizedBox(height: 8),
          Text(
            supportEmail,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.accentNeon, // Highlight email with accent color
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Get.back(); // Close the dialog
          },
          child: Text(
            'Close',
            style: GoogleFonts.poppins(
              color: AppColors.textLight,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            final Uri emailLaunchUri = Uri(
              scheme: 'mailto',
              path: supportEmail,
              queryParameters: {
                'subject':
                    'Support Request from Mobiking App', // Pre-fill subject
                'body': 'Dear Mobiking Support Team,\n\n', // Pre-fill body
              },
            );

            /*   if (await canLaunchUrl(emailLaunchUri)) {
              await launchUrl(emailLaunchUri);
              Get.back(); // Close the dialog after attempting to launch email
            } else {
              Get.snackbar(
                'Error',
                'Could not open email client. Please copy the email address.',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.red.withOpacity(0.8),
                colorText: Colors.white,
                icon: const Icon(Icons.error_outline, color: Colors.white),
                margin: const EdgeInsets.all(10),
                borderRadius: 10,
              );
            }*/
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors
                .primaryPurple, // Use your primary color for action button
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          child: Text(
            'Send Email',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
      actionsAlignment:
          MainAxisAlignment.spaceEvenly, // Distribute buttons horizontally
    ),
  );
}
