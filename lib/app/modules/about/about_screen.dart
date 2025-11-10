import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mobiking/app/data/CompanyDetail_model.dart';
import 'package:mobiking/app/services/policy_service.dart';
import 'package:mobiking/app/themes/app_theme.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  late Future<CompanyDetails> _companyDetailsFuture;

  @override
  void initState() {
    super.initState();
    _companyDetailsFuture = PolicyService().getCompanyDetails();
  }

  void _refreshCompanyDetails() {
    setState(() {
      _companyDetailsFuture = PolicyService().getCompanyDetails();
    });
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open link')),
        );
      }
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri uri = Uri.parse('tel:$phoneNumber');
    if (!await launchUrl(uri)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not make phone call')),
        );
      }
    }
  }

  Future<void> _sendEmail(String email) async {
    final Uri uri = Uri.parse('mailto:$email');
    if (!await launchUrl(uri)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open email app')),
        );
      }
    }
  }

  Future<void> _openWhatsApp(String phoneNumber) async {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri uri = Uri.parse('https://wa.me/$cleanNumber');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'About Us',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        elevation: 0,
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textDark,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.grey.shade200,
            height: 1,
          ),
        ),
      ),
      body: FutureBuilder<CompanyDetails>(
        future: _companyDetailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primaryPurple ?? Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading company details...',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            print('Error fetching company details: ${snapshot.error}');
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 64,
                      color: Colors.red.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Oops! Something went wrong',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Unable to load company details. Please try again.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _refreshCompanyDetails,
                      icon: const Icon(Icons.refresh, size: 20),
                      label: const Text('Try Again'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPurple ?? Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          } else if (snapshot.hasData) {
            final details = snapshot.data!;
            return RefreshIndicator(
              onRefresh: () async {
                _refreshCompanyDetails();
                await _companyDetailsFuture;
              },
              color: AppColors.primaryPurple ?? Colors.blue,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Company Logo (if available)
                    if (details.logoImage != null)
                      Center(
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.grey.shade200,
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              details.logoImage!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.business,
                                  size: 60,
                                  color: Colors.grey.shade400,
                                );
                              },
                            ),
                          ),
                        ),
                      ),

                    // Contact Information Section
                    _buildSectionCard(
                      title: 'Contact Information',
                      icon: Icons.contact_phone_outlined,
                      children: [
                        _buildContactItem(
                          icon: Icons.location_on_outlined,
                          title: 'Address',
                          value: details.address,
                          onTap: null,
                        ),
                        _buildContactItem(
                          icon: Icons.phone_outlined,
                          title: 'Phone',
                          value: details.phoneNo,
                          onTap: () => _makePhoneCall(details.phoneNo),
                        ),
                        _buildContactItem(
                          icon: Icons.email_outlined,
                          title: 'Email',
                          value: details.email,
                          onTap: () => _sendEmail(details.email),
                        ),
                        if (details.whatsappNo.isNotEmpty)
                          _buildContactItem(
                            icon: Icons.chat_outlined,
                            title: 'WhatsApp',
                            value: details.whatsappNo,
                            onTap: () => _openWhatsApp(details.whatsappNo),
                          ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Social Media Section
                    _buildSectionCard(
                      title: 'Follow Us',
                      icon: Icons.share_outlined,
                      children: [
                        _buildSocialMediaGrid(details),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // App Links Section
                    if (details.androidAppLink.isNotEmpty || details.iosAppLink != null)
                      _buildSectionCard(
                        title: 'Download Our App',
                        icon: Icons.smartphone_outlined,
                        children: [
                          if (details.androidAppLink.isNotEmpty)
                            _buildAppDownloadButton(
                              icon: Icons.android,
                              label: 'Get it on Google Play',
                              color: Colors.green,
                              onTap: () => _launchUrl(details.androidAppLink),
                            ),
                          if (details.androidAppLink.isNotEmpty && details.iosAppLink != null)
                            const SizedBox(height: 12),
                          if (details.iosAppLink != null)
                            _buildAppDownloadButton(
                              icon: Icons.apple,
                              label: 'Download on App Store',
                              color: Colors.black87,
                              onTap: () => _launchUrl(details.iosAppLink!),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          } else {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 64,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No company details found',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (AppColors.primaryPurple ?? Colors.blue).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: AppColors.primaryPurple ?? Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String value,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: AppColors.primaryPurple ?? Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Colors.grey.shade400,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialMediaGrid(CompanyDetails details) {
    final socialMedia = [
      if (details.instaLink.isNotEmpty)
        {
          'icon': Icons.camera_alt,
          'label': 'Instagram',
          'url': details.instaLink,
          'color': const Color(0xFFE4405F),
        },
      if (details.facebookLink != null)
        {
          'icon': Icons.facebook,
          'label': 'Facebook',
          'url': details.facebookLink!,
          'color': const Color(0xFF1877F2),
        },
      if (details.twitterLink != null)
        {
          'icon': Icons.flutter_dash,
          'label': 'Twitter',
          'url': details.twitterLink!,
          'color': const Color(0xFF1DA1F2),
        },
      if (details.websiteLink != null)
        {
          'icon': Icons.language,
          'label': 'Website',
          'url': details.websiteLink!,
          'color': Colors.grey.shade700,
        },
    ];

    if (socialMedia.isEmpty) {
      return Text(
        'No social media links available',
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey.shade600,
        ),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: socialMedia.map((social) {
        return InkWell(
          onTap: () => _launchUrl(social['url'] as String),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: (MediaQuery.of(context).size.width - 80) / 2,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: BoxDecoration(
              color: (social['color'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (social['color'] as Color).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  social['icon'] as IconData,
                  color: social['color'] as Color,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    social['label'] as String,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: social['color'] as Color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAppDownloadButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: color,
            ),
          ],
        ),
      ),
    );
  }
}
