import 'package:flutter/material.dart';
import 'scanner_page.dart';
import 'generator_page.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: HomePage(),
  ));
}

// Responsive Helper Class
class _Responsive {
  static double getWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;
  static double getHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  static bool isMobile(BuildContext context) => getWidth(context) < 600;
  static bool isTablet(BuildContext context) =>
      getWidth(context) >= 600 && getWidth(context) < 1200;
  static bool isDesktop(BuildContext context) => getWidth(context) >= 1200;

  static double getPadding(BuildContext context) =>
      isMobile(context) ? 16 : 24;
  static double getFontSize(BuildContext context, double mobileSize) =>
      isMobile(context) ? mobileSize : mobileSize * (isTablet(context) ? 1.15 : 1.3);
  static double getBorderRadius(BuildContext context) =>
      isMobile(context) ? 20 : 28;
  static double getCardMaxWidth(BuildContext context) {
    final width = getWidth(context);
    if (isDesktop(context)) return 700.0;
    if (isTablet(context)) return 550.0;
    return double.infinity;
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = _Responsive.isMobile(context);
    final padding = _Responsive.getPadding(context);
    final cardPadding = isMobile ? 20.0 : 24.0;

    // Color Scheme
    const primaryGradient = LinearGradient(
      colors: [Color(0xFF667eea), Color(0xFF764ba2)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Scaffold(
      // Gradient Background
      body: Container(
        decoration: const BoxDecoration(gradient: primaryGradient),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: EdgeInsets.all(padding),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - (padding * 2),
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        // AppBar
                        _buildAppBar(context),

                        const Spacer(),

                        // Main Content Card
                        Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: _Responsive.getCardMaxWidth(context),
                            ),
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(cardPadding),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(
                                  _Responsive.getBorderRadius(context),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: isMobile ? 20 : 30,
                                    offset: Offset(0, isMobile ? 10 : 15),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Header Text
                                  Text(
                                    'Get Started',
                                    style: TextStyle(
                                      fontSize: _Responsive.getFontSize(context, 22),
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF2D3748),
                                    ),
                                  ),
                                  SizedBox(height: isMobile ? 6 : 8),
                                  Text(
                                    'Scan or create QR codes instantly',
                                    style: TextStyle(
                                      fontSize: _Responsive.getFontSize(context, 14),
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  SizedBox(height: isMobile ? 24 : 30),

                                  // Scanner Button
                                  _buildModernButton(
                                    context,
                                    title: 'Scan QR Code',
                                    subtitle: 'Point camera to scan any QR code',
                                    icon: Icons.qr_code_scanner_rounded,
                                    gradient: primaryGradient,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => const ScannerPage()),
                                      );
                                    },
                                  ),

                                  SizedBox(height: isMobile ? 12 : 16),

                                  // Generator Button
                                  _buildModernButton(
                                    context,
                                    title: 'Generate QR Code',
                                    subtitle: 'Create QR for URL, text & more',
                                    icon: Icons.add_box_rounded,
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
                                    ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => const GeneratorPage()),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const Spacer(),

                        // Footer
                        _buildFooter(context),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // AppBar
  Widget _buildAppBar(BuildContext context) {
    final isMobile = _Responsive.isMobile(context);
    final padding = _Responsive.getPadding(context);

    return Padding(
      padding: EdgeInsets.all(padding),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 10 : 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.qr_code_2_rounded,
              color: Colors.white,
              size: isMobile ? 26 : 30,
            ),
          ),
          SizedBox(width: isMobile ? 10 : 12),
          Text(
            'QR Connect',
            style: TextStyle(
              color: Colors.white,
              fontSize: _Responsive.getFontSize(context, 24),
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernButton(
      BuildContext context, {
        required String title,
        required String subtitle,
        required IconData icon,
        required LinearGradient gradient,
        required VoidCallback onTap,
      }) {
    final isMobile = _Responsive.isMobile(context);
    final padding = isMobile ? 14.0 : 16.0;
    final iconSize = isMobile ? 22.0 : 24.0;
    final arrowSize = isMobile ? 13.0 : 14.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: Colors.grey.withOpacity(0.1),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: gradient.colors.first.withOpacity(0.3),
                blurRadius: isMobile ? 10 : 12,
                offset: Offset(0, isMobile ? 4 : 5),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon with Background
              Container(
                padding: EdgeInsets.all(isMobile ? 9 : 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: iconSize),
              ),
              SizedBox(width: isMobile ? 14 : 16),
              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: _Responsive.getFontSize(context, 16),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: _Responsive.getFontSize(context, 13),
                      ),
                    ),
                  ],
                ),
              ),
              // Arrow Icon
              Container(
                padding: EdgeInsets.all(isMobile ? 5 : 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                  size: arrowSize,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Footer
  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: _Responsive.getPadding(context)),
      child: Text(
        'Developed by • Riazul Hasan Rocky',
        style: TextStyle(
          color: Colors.white.withOpacity(0.8),
          fontSize: _Responsive.getFontSize(context, 13),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}