import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../../utils/theme_utils.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          /// Background animation
          Positioned.fill(
            child: Lottie.asset(
              'assets/animations/landing_animation.json',
              fit: BoxFit.cover,
              repeat: true,
              animate: true,
            ),
          ),

          /// Gradient overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: themeProvider.isDarkMode
                      ? [
                          Colors.black.withOpacity(0.8),
                          Colors.black.withOpacity(0.5)
                        ]
                      : [
                          Colors.white.withOpacity(0.7),
                          Colors.white.withOpacity(0.4)
                        ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          /// Scrollable content
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ---------------- Headline ----------------
                Text(
                  'Welcome to KhonoRecruit',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent.shade700,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Connecting top digital talent with companies worldwide. '
                  'We specialize in Web Developers, Database Technicians, '
                  'Data Analysts, Designers, Cloud Practitioners, and more.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, color: Colors.white70),
                ),
                const SizedBox(height: 40),

                // ---------------- Visual Focus ----------------
                SizedBox(
                  width: size.width * 0.8,
                  child: Lottie.asset(
                    'assets/animations/profile.json',
                    repeat: true,
                  ),
                ),
                const SizedBox(height: 60),

                // ---------------- Benefits ----------------
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Why Choose KhonoRecruit?',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent),
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 24,
                      runSpacing: 16,
                      children: [
                        _buildBenefitCard('Fast Hiring', Icons.speed,
                            'Hire top talent quickly and efficiently.'),
                        _buildBenefitCard('Verified Candidates', Icons.verified,
                            'All candidates are vetted and qualified.'),
                        _buildBenefitCard('Expert Matching', Icons.people_alt,
                            'We match the right talent with the right role.'),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 60),

                // ---------------- Social Proof ----------------
                Column(
                  children: [
                    const Text(
                      'What Companies Say',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 220,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildTestimonialCard('ACME Corp',
                              '“KhonoRecruit helped us find our lead developer in just 2 weeks!”'),
                          _buildTestimonialCard('Tech Solutions',
                              '“Highly recommend for data analysts and cloud experts.”'),
                          _buildTestimonialCard('Creative Agency',
                              '“Exceptional designers and UI/UX professionals!”'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 60),

                // ---------------- Storytelling / Our Story ----------------
                Column(
                  children: [
                    const Text(
                      'Our Story',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Image.asset(
                            'assets/images/about_us.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Text(
                            'Khonology was founded to bridge the gap between talented digital professionals '
                            'and companies in need of skilled workforce. Our platform focuses on building long-term relationships '
                            'between talent and employers across multiple industries.',
                            style: const TextStyle(
                                fontSize: 18, color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 60),

                // ---------------- Guarantee ----------------
                Column(
                  children: [
                    const Text(
                      'Our Guarantee',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'We guarantee top-quality, verified candidates for all your projects. '
                      'If you are not satisfied, we work until the perfect match is found.',
                      textAlign: TextAlign.center,
                      style:
                          const TextStyle(fontSize: 18, color: Colors.white70),
                    ),
                  ],
                ),
                const SizedBox(height: 60),

                // ---------------- Call to Action ----------------
                Column(
                  children: [
                    const Text(
                      'Ready to Get Started?',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent),
                    ),
                    const SizedBox(height: 24),

                    // Login Button
                    SizedBox(
                      width: size.width * 0.6,
                      height: 60,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent.shade700,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 6,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const LoginScreen()),
                          );
                        },
                        child: const Text('Login',
                            style:
                                TextStyle(fontSize: 20, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Register Button
                    SizedBox(
                      width: size.width * 0.6,
                      height: 60,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black87,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 6,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const RegisterScreen()),
                          );
                        },
                        child: const Text('Register',
                            style:
                                TextStyle(fontSize: 20, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Theme toggle button below CTA
                    IconButton(
                      icon: Icon(
                        themeProvider.isDarkMode
                            ? Icons.wb_sunny
                            : Icons.dark_mode,
                        color: Colors.redAccent,
                        size: 36,
                      ),
                      onPressed: () => themeProvider.toggleTheme(),
                    ),
                    const SizedBox(height: 60),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitCard(String title, IconData icon, String subtitle) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.redAccent, size: 48),
          const SizedBox(height: 12),
          Text(title,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 8),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildTestimonialCard(String company, String feedback) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(company,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent)),
          const SizedBox(height: 12),
          Text(feedback,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.white70)),
        ],
      ),
    );
  }
}
