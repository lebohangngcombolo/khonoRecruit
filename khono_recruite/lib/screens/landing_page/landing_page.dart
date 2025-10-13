import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../auth/login_screen.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final accentRed = const Color(0xFFE50914);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                // -------------------- Section 1: Hero --------------------
                Container(
                  height: size.height,
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 60,
                    vertical: 40,
                  ),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0D0D0D), Color(0xFF1A1A1A)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    image: DecorationImage(
                      image: AssetImage('assets/images/bg1.jpg'),
                      fit: BoxFit.cover,
                      opacity: 0.15,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Image.asset(
                            'assets/images/logo2.png',
                            width: 320,
                            height: 120,
                            fit: BoxFit.contain,
                          ),
                          Row(
                            children: [
                              _navItem("Khonology"),
                              _navItem("Interview Mock up"),
                              _navItem("Resume Generator"),
                              _navItem("IPQ"),
                              _navItem("Join Us"),
                              _navItem("About Us"),
                              _navItem("Contact"),
                            ],
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        "WELCOME TO",
                        style: GoogleFonts.poppins(
                          fontSize: 48,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        "KHONTALENT",
                        style: GoogleFonts.poppins(
                          fontSize: 72,
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "CONNECT | MATCH | SUCCEED",
                        style: GoogleFonts.poppins(
                          color: accentRed,
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 40),
                      Center(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentRed,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            "Get Started",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Scroll ↓",
                            style: GoogleFonts.poppins(color: Colors.white70),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),

                // -------------------- Section 2: Unlocking Value --------------------
                _buildSection(
                  context,
                  title: "UNLOCKING VALUE USING OUR DIGITAL SOLUTIONS",
                  description:
                      "The key traits that are non-negotiable for businesses to succeed are improving client experience, automating business processes, and streamlining regulatory reporting.\n\nAutomation and digitisation can unlock immense opportunities for businesses.",
                  backgroundImage: 'assets/images/bg.jpg',
                  child: Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    children: const [
                      _FeatureCard(
                        title: "IMPROVING CLIENT EXPERIENCE",
                        description:
                            "Our solutions maximise lifetime value for clients and ensure competitiveness in a dynamic, technology-driven market.",
                      ),
                      _FeatureCard(
                        title: "STREAMLINING REGULATORY REPORTING",
                        description:
                            "By digitising workflows and reporting processes, clients prevent regulatory risks and protect their brand.",
                      ),
                      _FeatureCard(
                        title: "AUTOMATING BUSINESS PROCESSES",
                        description:
                            "Our automation journey blends customer insights and data-led strategies for agility and efficiency.",
                      ),
                    ],
                  ),
                ),

                // -------------------- Section 3: Clients --------------------
                _buildSection(
                  context,
                  title: "OUR CLIENTS",
                  description: "",
                  backgroundImage: 'assets/images/bg2.jpg',
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: List.generate(6, (i) {
                        double logoWidth = size.width * 0.12;
                        double logoHeight = logoWidth * 0.5;
                        logoWidth = logoWidth.clamp(80, 120);
                        logoHeight = logoHeight.clamp(40, 60);

                        return Image.asset(
                          'assets/images/client$i.png',
                          width: logoWidth,
                          height: logoHeight,
                          fit: BoxFit.contain,
                        );
                      }),
                    ),
                  ),
                ),

                // -------------------- Section 4: Team --------------------
                _buildSection(
                  context,
                  title: "MEET OUR TEAM",
                  description:
                      "Our team is made up of diverse talents committed to delivering innovative digital solutions.",
                  backgroundImage: 'assets/images/bg4.jpg',
                  child: Center(
                    child: Wrap(
                      spacing: 20,
                      runSpacing: 20,
                      children: List.generate(6, (i) {
                        double photoWidth = size.width * 0.18;
                        photoWidth = photoWidth.clamp(120, 160);

                        return ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            'assets/images/team$i.jpg',
                            width: photoWidth,
                            height: photoWidth,
                            fit: BoxFit.cover,
                          ),
                        );
                      }),
                    ),
                  ),
                ),

                // -------------------- Section 5: About Us --------------------
                _buildSection(
                  context,
                  title: "ABOUT US",
                  description:
                      "Established in 2013, Khonology is a B-BBEE Level 2 technology service provider that has the vision of becoming Africa's leading digital enabler.Khonology aspires to continue to rise into Africa’s leading data and digital enabler that empowers our continent’s businesses and people to unlock their full potential through technology.",
                  backgroundImage: 'assets/images/bg3.jpeg',
                ),

                // -------------------- Section 6: Join Us --------------------
                _buildSection(
                  context,
                  title: "JOIN US",
                  description:
                      "We are always looking for talented individuals to join our growing team. Explore our career opportunities and become part of our journey.",
                  backgroundImage: 'assets/images/bg.jpg',
                ),

                // -------------------- Section 7: Contact --------------------
                _buildSection(
                  context,
                  title: "CONTACT US",
                  description:
                      "Reach out to us for collaborations, inquiries, or digital transformation solutions.",
                  backgroundImage: 'assets/images/bg4.jpg',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          _socialIcon(
                            'assets/icons/Instagram.png',
                            'https://www.instagram.com/yourprofile',
                          ),
                          _socialIcon(
                            'assets/icons/x1.png',
                            'https://x.com/yourprofile',
                          ),
                          _socialIcon(
                            'assets/icons/Linkedin.png',
                            'https://www.linkedin.com/in/yourprofile',
                          ),
                          _socialIcon(
                            'assets/icons/facebook.png',
                            'https://www.facebook.com/yourprofile',
                          ),
                          _socialIcon(
                            'assets/icons/YouTube.png',
                            'https://www.youtube.com/yourchannel',
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          width: 600,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Column(
                            children: [
                              _textField("Name"),
                              const SizedBox(height: 16),
                              _textField("Surname"),
                              const SizedBox(height: 16),
                              _textField("Email"),
                              const SizedBox(height: 16),
                              _textField("Message", maxLines: 4),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: () {
                                  // TODO: Form submission logic
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: accentRed,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 40,
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  "Send",
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // -------------------- Footer --------------------
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 60,
                    vertical: 40,
                  ),
                  color: const Color(0xFF111111),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/logo3.png',
                        width: 220,
                        height: 120,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _socialIcon(
                            'assets/icons/Instagram1.png',
                            'https://www.instagram.com/yourprofile',
                          ),
                          _socialIcon(
                            'assets/icons/x1.png',
                            'https://x.com/yourprofile',
                          ),
                          _socialIcon(
                            'assets/icons/Linkedin1.png',
                            'https://www.linkedin.com/in/yourprofile',
                          ),
                          _socialIcon(
                            'assets/icons/facebook1.png',
                            'https://www.facebook.com/yourprofile',
                          ),
                          _socialIcon(
                            'assets/icons/YouTube1.png',
                            'https://www.youtube.com/yourchannel',
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "© 2025 Khonology. All rights reserved.",
                        style: GoogleFonts.poppins(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Floating Chat Button
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.extended(
              onPressed: () async {
                final Uri url = Uri.parse("mailto:info@khonology.com");
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                }
              },
              backgroundColor: accentRed,
              label: const Text("Looking to digitise? Let's chat"),
              icon: const Icon(Icons.chat_bubble_outline),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------- Helper Widgets --------------------
  Widget _navItem(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Text(
          label,
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
        ),
      ),
    );
  }

  Widget _textField(String hint, {int maxLines = 1}) {
    return TextField(
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: Colors.white10,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }

  Widget _socialIcon(String assetPath, String url) {
    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: InkWell(
        onTap: () async {
          final Uri uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
          }
        },
        child: Image.asset(
          assetPath,
          width: 32,
          height: 32,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required String description,
    required String backgroundImage,
    Widget? child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 80),
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(backgroundImage),
          fit: BoxFit.cover,
          opacity: 0.1,
        ),
        gradient: const LinearGradient(
          colors: [Color(0xFF111111), Color(0xFF0D0D0D)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 24,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              description,
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 16,
                height: 1.6,
              ),
            ),
          ],
          if (child != null) ...[const SizedBox(height: 50), child],
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String title;
  final String description;

  const _FeatureCard({Key? key, required this.title, required this.description})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            border: Border.all(color: Colors.white10),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
