import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobiking/app/themes/app_theme.dart';

// ============================================
// SMOOTH KEYBOARD TRANSITION INPUT WIDGET
// ============================================
class OptimizedMessageInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSending;
  final VoidCallback onSend;

  const OptimizedMessageInput({
    Key? key,
    required this.controller,
    required this.focusNode,
    required this.isSending,
    required this.onSend,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
          top: BorderSide(color: AppColors.lightGreyBackground, width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 44, maxHeight: 100),
              decoration: BoxDecoration(
                color: AppColors.neutralBackground,
                borderRadius: BorderRadius.circular(22),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                decoration: const InputDecoration(
                  hintText: 'Type your message...',
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
                // 🔥 CRITICAL PERFORMANCE SETTINGS
                autocorrect: false,
                enableSuggestions: false,
                enableIMEPersonalizedLearning: false,
                smartDashesType: SmartDashesType.disabled,
                smartQuotesType: SmartQuotesType.disabled,
                textCapitalization: TextCapitalization.sentences,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.send,
                maxLines: 5,
                minLines: 1,
                maxLength: 500,
                buildCounter:
                    (
                      _, {
                      required currentLength,
                      maxLength,
                      required isFocused,
                    }) => null,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  decoration: TextDecoration.none,
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 44,
            height: 44,
            child: Material(
              color: isSending ? AppColors.textLight : AppColors.primaryPurple,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: isSending ? null : onSend,
                customBorder: const CircleBorder(),
                child: Center(
                  child: isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : const Icon(
                          Icons.send_rounded,
                          color: AppColors.white,
                          size: 20,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
