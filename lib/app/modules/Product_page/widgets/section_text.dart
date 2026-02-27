import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobiking/app/themes/app_theme.dart';

class SectionText extends StatelessWidget {
  final String title;
  final String content;

  const SectionText({super.key, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    final headingStyle = GoogleFonts.poppins(
      fontSize: 16,
      fontWeight: FontWeight.bold,
    );
    final labelStyle = GoogleFonts.poppins(fontSize: 14, color: Colors.black87);

    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: AppColors.neutralBackground,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: headingStyle),
          const SizedBox(height: 6),
          Text(content, style: labelStyle),
        ],
      ),
    );
  }
}
