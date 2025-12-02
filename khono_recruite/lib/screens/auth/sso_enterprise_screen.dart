import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SsoEnterpriseScreen extends StatelessWidget {
  const SsoEnterpriseScreen({super.key});

  // Launch SSO provider
  void _launchSsoProvider(String provider) async {
    final urls = {
      'Azure': 'https://your-domain.auth.microsoft.com',
      'Okta': 'https://your-domain.okta.com',
      'Google Workspace': 'https://accounts.google.com',
      // Link to your backend SSO route
      'Other SAML': 'http://127.0.0.1:5000/api/auth/sso',
    };

    final url = urls[provider];
    if (url != null) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('Could not launch $url');
      }
    }
  }

  // SSO button builder
  Widget _buildSsoButton({
    required String imagePath,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Image.asset(imagePath, height: 36, width: 36),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  color: Colors.white60, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
                "assets/images/dark.png"), // Add your background image path
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 400),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "ENTERPRISE SSO",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Select your identity provider",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  _buildSsoButton(
                    imagePath: "assets/icons/microsoft.png",
                    title: "Azure Active Directory",
                    subtitle: "Microsoft Enterprise SSO",
                    onTap: () => _launchSsoProvider('Azure'),
                  ),
                  const SizedBox(height: 16),
                  _buildSsoButton(
                    imagePath: "assets/icons/okta.png",
                    title: "Okta",
                    subtitle: "Enterprise Identity Cloud",
                    onTap: () => _launchSsoProvider('Okta'),
                  ),
                  const SizedBox(height: 16),
                  _buildSsoButton(
                    imagePath: "assets/icons/google.png",
                    title: "Google Workspace",
                    subtitle: "Google Cloud Identity",
                    onTap: () => _launchSsoProvider('Google Workspace'),
                  ),
                  const SizedBox(height: 16),
                  _buildSsoButton(
                    imagePath: "assets/icons/saml.png",
                    title: "Other SAML Provider",
                    subtitle: "Keycloak / Custom SAML 2.0",
                    onTap: () => _launchSsoProvider('Other SAML'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
