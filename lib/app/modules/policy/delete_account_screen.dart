import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobiking/app/controllers/login_controller.dart';
import 'package:mobiking/app/themes/app_theme.dart';

void showDeleteAccountDialog(BuildContext context) {
  final LoginController loginController = Get.find<LoginController>();
  final TextTheme textTheme = Theme.of(context).textTheme;

  showDialog(
    context: context,
    barrierDismissible: false, // Prevent dismissing by tapping outside
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: AppColors.white,
        title: Row(
          children: [
            Icon(
              Icons.warning_rounded,
              color: AppColors.danger,
              size: 24,
            ),
            SizedBox(width: 8),
            Text(
              'Delete Account',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete your account?',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textDark,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.danger.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This action will permanently:',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  _buildWarningItem('Delete all your personal data', textTheme),
                  _buildWarningItem('Remove your account from all services', textTheme),
                  _buildWarningItem('Cancel any active subscriptions', textTheme),
                  SizedBox(height: 8),
                  Text(
                    'This action cannot be undone.',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: <Widget>[
          // Cancel Button
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Cancel',
              style: textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.primaryPurple,
              ),
            ),
          ),

          // Delete Button with loading state
          Obx(() => ElevatedButton(
            onPressed: loginController.isDeletingAccount.value
                ? null
                : () async {
              // Show confirmation dialog first
              final confirmed = await _showFinalConfirmationDialog(context);
              if (confirmed == true) {
                Navigator.of(context).pop(); // Close current dialog

                // Call delete account method
                final success = await loginController.deleteAccount();

                if (!success) {
                  // Error handling is done in the controller via snackbar
                  // No additional action needed here
                  print('Delete account failed - error shown via controller');
                }
                // Success case is handled in controller (navigation to login)
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: AppColors.white,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: loginController.isDeletingAccount.value
                ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'Deleting...',
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ),
              ],
            )
                : Text(
              'Delete Account',
              style: textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.white,
              ),
            ),
          )),
        ],
        actionsPadding: EdgeInsets.fromLTRB(16, 0, 16, 16),
      );
    },
  );
}

// Helper widget for warning items
Widget _buildWarningItem(String text, TextTheme textTheme) {
  return Padding(
    padding: EdgeInsets.only(bottom: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(top: 6),
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.danger,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.danger,
            ),
          ),
        ),
      ],
    ),
  );
}

// Final confirmation dialog with text input
Future<bool?> _showFinalConfirmationDialog(BuildContext context) {
  final TextEditingController confirmationController = TextEditingController();
  final TextTheme textTheme = Theme.of(context).textTheme;

  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: AppColors.white,
        title: Text(
          'Final Confirmation',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'To confirm account deletion, please type DELETE in the field below:',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textLight,
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: confirmationController,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'Type DELETE to confirm',
                hintStyle: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textLight.withOpacity(0.6),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.danger),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.danger.withOpacity(0.5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.danger, width: 2),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              ),
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Cancel',
              style: textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.primaryPurple,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final confirmation = confirmationController.text.trim().toUpperCase();
              if (confirmation == 'DELETE') {
                Navigator.of(context).pop(true);
              } else {
                // Show error for incorrect confirmation
                Get.snackbar(
                  'Invalid Confirmation',
                  'Please type "DELETE" exactly to confirm account deletion.',
                  backgroundColor: AppColors.danger,
                  colorText: AppColors.white,
                  snackPosition: SnackPosition.TOP,
                  duration: Duration(seconds: 3),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: AppColors.white,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: Text(
              'Confirm Delete',
              style: textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.white,
              ),
            ),
          ),
        ],
        actionsPadding: EdgeInsets.fromLTRB(16, 0, 16, 16),
      );
    },
  );
}
