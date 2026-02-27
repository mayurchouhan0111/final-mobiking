import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:mobiking/app/data/Policy_model.dart';
import 'package:mobiking/app/themes/app_theme.dart';
import 'package:intl/intl.dart';

class PolicyDetailScreen extends StatelessWidget {
  final Policy policy;

  const PolicyDetailScreen({super.key, required this.policy});

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text(
          policy.policyName,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
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
      body: Column(
        children: [
          // Header Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade100, width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  policy.heading,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.update, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Text(
                      'Last updated: ${policy.lastUpdated != null ? _formatDate(policy.lastUpdated!) : _formatDate(policy.updatedAt)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Content Section with Markdown
          Expanded(
            child: Markdown(
              data: policy.content,
              selectable: true,
              padding: const EdgeInsets.all(20),
              styleSheet: MarkdownStyleSheet(
                p: TextStyle(
                  fontSize: 16,
                  height: 1.7,
                  color: AppColors.textDark,
                ),
                h1: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
                h2: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
                h3: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
                strong: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
                em: const TextStyle(fontStyle: FontStyle.italic),
                listBullet: TextStyle(fontSize: 16, color: AppColors.textDark),
                tableBody: TextStyle(fontSize: 16, color: AppColors.textDark),
                a: TextStyle(
                  color: Colors.blue.shade700,
                  decoration: TextDecoration.underline,
                ),
                blockquote: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                  fontStyle: FontStyle.italic,
                ),
                blockquoteDecoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border(
                    left: BorderSide(color: Colors.grey.shade300, width: 4),
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
