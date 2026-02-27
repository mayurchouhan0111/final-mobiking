import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../themes/app_theme.dart';

typedef DeliveryCheckCallback = Future<bool> Function(String postalCode);

class DeliveryCheckButton extends StatelessWidget {
  final DeliveryCheckCallback onCheckDelivery;

  const DeliveryCheckButton({Key? key, required this.onCheckDelivery})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2BAE66), // Blinkit green
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 4,
          shadowColor: Colors.greenAccent.shade100,
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        child: const Text('Check Delivery Availability'),
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) =>
                DeliveryCheckDialog(onCheckDelivery: onCheckDelivery),
          );
        },
      ),
    );
  }
}

class DeliveryCheckDialog extends StatefulWidget {
  final DeliveryCheckCallback onCheckDelivery;

  const DeliveryCheckDialog({Key? key, required this.onCheckDelivery})
    : super(key: key);

  @override
  State<DeliveryCheckDialog> createState() => _DeliveryCheckDialogState();
}

class _DeliveryCheckDialogState extends State<DeliveryCheckDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _pinController = TextEditingController();
  bool? _isAvailable;
  bool _isLoading = false;
  String? _errorText;

  Future<void> _checkAvailability() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorText = null;
      _isAvailable = null;
    });

    try {
      bool result = await widget.onCheckDelivery(_pinController.text.trim());

      setState(() {
        _isAvailable = result;
      });
    } catch (e) {
      setState(() {
        _errorText = 'Error checking delivery: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 10,
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Check Delivery Availability',
              style: TextStyle(
                color: const Color(0xFF2BAE66),
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Enter PIN code',
                  hintText: 'e.g. 560001',
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFF2BAE66),
                      width: 2,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Colors.grey.shade300,
                      width: 1.5,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Colors.redAccent,
                      width: 2,
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Colors.redAccent,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a PIN code';
                  }
                  if (value.trim().length != 6) {
                    return 'PIN code must be 6 digits';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 20),
            if (_isLoading) ...[
              const SizedBox(height: 20),
              const CircularProgressIndicator(color: Color(0xFF2BAE66)),
              const SizedBox(height: 20),
            ],
            if (_errorText != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _errorText!,
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            if (_isAvailable != null && !_isLoading)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _isAvailable!
                      ? 'Delivery available to this PIN code'
                      : 'Delivery not available',
                  style: TextStyle(
                    color: _isAvailable!
                        ? const Color(0xFF2BAE66)
                        : Colors.redAccent,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isLoading ? null : _checkAvailability,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 4,
                    shadowColor: Colors.greenAccent.shade100,
                    textStyle: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  child: const Text('Check'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
