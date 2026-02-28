import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';

//Responsive Helper
class _ScannerResponsive {
  static double getWidth(BuildContext context) => MediaQuery.of(context).size.width;
  static double getHeight(BuildContext context) => MediaQuery.of(context).size.height;
  static bool isMobile(BuildContext context) => getWidth(context) < 600;
  static bool isTablet(BuildContext context) => getWidth(context) >= 600 && getWidth(context) < 1200;
  static bool isDesktop(BuildContext context) => getWidth(context) >= 1200;

  static double getPadding(BuildContext context) => isMobile(context) ? 16 : 24;
  static double getFontSize(BuildContext context, double mobileSize) =>
      isMobile(context) ? mobileSize : mobileSize * (isTablet(context) ? 1.1 : 1.25);

  static double getQrFrameSize(BuildContext context) {
    final width = getWidth(context);
    final height = getHeight(context);
    final shorterSide = width < height ? width : height;
    return (shorterSide * 0.65).clamp(200.0, 400.0);
  }

  static double getBorderRadius(BuildContext context) => isMobile(context) ? 20 : 28;
  static double getButtonHeight(BuildContext context) => isMobile(context) ? 50 : 56;
}

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> with SingleTickerProviderStateMixin {
  bool _isScanning = true;
  String? _scannedValue;
  bool _isUrl = false;
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = _ScannerResponsive.isMobile(context);

    return Scaffold(
      // Background - Transparent scaffold
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,

      appBar: AppBar(
        title: Text(
          'Scan QR Code',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: _ScannerResponsive.getFontSize(context, 20),
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back_ios_new, size: 18),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      // Background - Stack with gradient as base layer
      body: Stack(
        children: [
          //Gradient Background
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
              ),
            ),
          ),

          // Main Content with SafeArea
          SafeArea(
            child: _isScanning
                ? _buildScannerView(context)
                : _buildResultView(context),
          ),
        ],
      ),
    );
  }

  // Responsive Camera View
  Widget _buildScannerView(BuildContext context) {
    final isMobile = _ScannerResponsive.isMobile(context);
    final frameSize = _ScannerResponsive.getQrFrameSize(context);
    final padding = _ScannerResponsive.getPadding(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // Camera Feed
            MobileScanner(
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                if (barcodes.isNotEmpty && _isScanning) {
                  final String? value = barcodes.first.rawValue;
                  if (value != null) {
                    setState(() {
                      _scannedValue = value;
                      _isUrl = _isValidUrl(value);
                      _isScanning = false;
                    });
                    HapticFeedback.lightImpact();
                  }
                }
              },
            ),

            // Dark Overlay with Cutout
            Positioned.fill(
              child: CustomPaint(
                painter: ScannerOverlayPainter(
                  cutoutSize: Size(frameSize, frameSize),
                  overlayColor: Colors.black.withOpacity(0.5),
                ),
              ),
            ),

            // Animated Scanner Frame
            Positioned.fill(
              child: Center(
                child: ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    width: frameSize,
                    height: frameSize,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white.withOpacity(0.9),
                        width: isMobile ? 2.5 : 3,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.deepPurple.withOpacity(0.5),
                          blurRadius: isMobile ? 25 : 30,
                          spreadRadius: 2,
                        ),
                        BoxShadow(
                          color: Colors.cyan.withOpacity(0.3),
                          blurRadius: isMobile ? 15 : 20,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        _buildCornerAccent(true, true, isMobile),
                        _buildCornerAccent(true, false, isMobile),
                        _buildCornerAccent(false, true, isMobile),
                        _buildCornerAccent(false, false, isMobile),
                        Positioned(
                          left: isMobile ? 3 : 4,
                          right: isMobile ? 3 : 4,
                          child: _buildScanningLine(frameSize),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Instruction Text
            Positioned(
              bottom: isMobile ? 30 : 40,
              left: padding,
              right: padding,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : 20,
                  vertical: isMobile ? 12 : 14,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.black54, Colors.transparent],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.center_focus_strong,
                      color: Colors.white.withOpacity(0.9),
                      size: isMobile ? 18 : 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Align QR code within the frame',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.95),
                        fontSize: _ScannerResponsive.getFontSize(context, 14),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Flash Button (Show on tablet/landscape)
            if (!isMobile || MediaQuery.of(context).orientation == Orientation.landscape)
              Positioned(
                top: isMobile ? 90 : 100,
                right: padding,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.flash_on, color: Colors.white, size: 22),
                    onPressed: () {
                      // Flash toggle logic
                    },
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // Corner Accent
  Widget _buildCornerAccent(bool isTop, bool isLeft, bool isMobile) {
    final size = isMobile ? 22.0 : 30.0;
    final width = isMobile ? 3.0 : 4.0;

    return Positioned(
      top: isTop ? 0 : null,
      bottom: !isTop ? 0 : null,
      left: isLeft ? 0 : null,
      right: !isLeft ? 0 : null,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.deepPurpleAccent, width: isTop ? width : 0),
            bottom: BorderSide(color: Colors.deepPurpleAccent, width: !isTop ? width : 0),
            left: BorderSide(color: Colors.deepPurpleAccent, width: isLeft ? width : 0),
            right: BorderSide(color: Colors.deepPurpleAccent, width: !isLeft ? width : 0),
          ),
          borderRadius: BorderRadius.only(
            topLeft: isTop && isLeft ? const Radius.circular(20) : Radius.zero,
            topRight: isTop && !isLeft ? const Radius.circular(20) : Radius.zero,
            bottomLeft: !isTop && isLeft ? const Radius.circular(20) : Radius.zero,
            bottomRight: !isTop && !isLeft ? const Radius.circular(20) : Radius.zero,
          ),
        ),
      ),
    );
  }

  // Scanning Line Animation
  Widget _buildScanningLine(double frameSize) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Positioned(
          top: value * (frameSize - 6),
          child: Container(
            width: double.infinity,
            height: 2.5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.deepPurpleAccent.withOpacity(0),
                  Colors.deepPurpleAccent,
                  Colors.cyanAccent,
                  Colors.deepPurpleAccent.withOpacity(0),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(2),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepPurpleAccent.withOpacity(0.5),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Result View
  Widget _buildResultView(BuildContext context) {
    final isMobile = _ScannerResponsive.isMobile(context);
    final padding = _ScannerResponsive.getPadding(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: isMobile ? 30 : 40),

          // Animated Success Icon
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 500),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  padding: EdgeInsets.all(isMobile ? 18 : 24),
                  decoration: BoxDecoration(
                    gradient: _isUrl
                        ? const LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)])
                        : const LinearGradient(colors: [Color(0xFF11998e), Color(0xFF38ef7d)]),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (_isUrl ? Colors.deepPurple : Colors.teal).withOpacity(0.4),
                        blurRadius: isMobile ? 15 : 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    _isUrl ? Icons.link_rounded : Icons.text_fields_rounded,
                    size: isMobile ? 32 : 40,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // Title
          Text(
            _isUrl ? 'URL Detected' : 'Content Scanned',
            style: TextStyle(
              fontSize: _ScannerResponsive.getFontSize(context, 22),
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 6),

          Text(
            _isUrl ? 'Tap Open to visit the link' : 'Tap Copy to save the text',
            style: TextStyle(
              fontSize: _ScannerResponsive.getFontSize(context, 13),
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: isMobile ? 24 : 32),

          // Scanned Content Card
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(isMobile ? 16 : 20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _isUrl ? Icons.link : Icons.text_fields,
                        size: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isUrl ? 'Link' : 'Text',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.7),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SelectableText(
                  _scannedValue ?? '',
                  style: TextStyle(
                    fontSize: _ScannerResponsive.getFontSize(context, 15),
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: isMobile ? 28 : 36),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: _buildModernActionButton(
                  context,
                  label: 'Copy',
                  icon: Icons.content_copy_rounded,
                  gradient: const LinearGradient(colors: [Color(0xFF4b6cb7), Color(0xFF182848)]),
                  onTap: _copyToClipboard,
                ),
              ),
              const SizedBox(width: 12),
              if (_isUrl)
                Expanded(
                  child: _buildModernActionButton(
                    context,
                    label: 'Open',
                    icon: Icons.open_in_new_rounded,
                    gradient: const LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)]),
                    onTap: _openUrl,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 20),

          // Scan Again Button
          TextButton.icon(
            onPressed: () {
              HapticFeedback.selectionClick();
              setState(() {
                _isScanning = true;
                _scannedValue = null;
                _isUrl = false;
              });
            },
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(
              'Scan Another Code',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: _ScannerResponsive.getFontSize(context, 13),
              ),
            ),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white.withOpacity(0.9),
              backgroundColor: Colors.white.withOpacity(0.1),
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 20 : 24,
                vertical: isMobile ? 12 : 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Colors.white.withOpacity(0.2)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Modern Action Button
  Widget _buildModernActionButton(
      BuildContext context, {
        required String label,
        required IconData icon,
        required LinearGradient gradient,
        required VoidCallback onTap,
      }) {
    final isMobile = _ScannerResponsive.isMobile(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: Colors.white.withOpacity(0.2),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: isMobile ? 14 : 16),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: gradient.colors.first.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: isMobile ? 18 : 20),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: _ScannerResponsive.getFontSize(context, 14),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // URL Validation
  bool _isValidUrl(String value) {
    return value.startsWith('http://') ||
        value.startsWith('https://') ||
        value.startsWith('mailto:') ||
        value.startsWith('tel:') ||
        value.startsWith('sms:') ||
        RegExp(r'^[a-z]+://').hasMatch(value);
  }

  // Copy to Clipboard
  Future<void> _copyToClipboard() async {
    if (_scannedValue != null) {
      await Clipboard.setData(ClipboardData(text: _scannedValue!));
      HapticFeedback.mediumImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          _buildModernSnackBar('Copied to clipboard', Colors.green[700]!, Icons.check_rounded, context),
        );
      }
    }
  }

  // Open URL
  Future<void> _openUrl() async {
    if (_scannedValue == null) return;
    try {
      final Uri uri = Uri.parse(_scannedValue!);
      if (await canLaunchUrl(uri)) {
        HapticFeedback.mediumImpact();
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showError('Could not open this link');
      }
    } catch (e) {
      _showError('Invalid URL format');
    }
  }

  // Show Error
  void _showError(String message) {
    if (!mounted) return;
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      _buildModernSnackBar(message, Colors.red[700]!, Icons.error_rounded, context),
    );
  }

  // Modern SnackBar
  SnackBar _buildModernSnackBar(String message, Color bgColor, IconData icon, BuildContext context) {
    final isMobile = _ScannerResponsive.isMobile(context);
    return SnackBar(
      content: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: _ScannerResponsive.getFontSize(context, 13),
              ),
            ),
          ),
        ],
      ),
      backgroundColor: bgColor,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.all(isMobile ? 12 : 16),
    );
  }
}

// Custom Painter for Scanner Overlay
class ScannerOverlayPainter extends CustomPainter {
  final Size cutoutSize;
  final Color overlayColor;

  ScannerOverlayPainter({required this.cutoutSize, required this.overlayColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = overlayColor..style = PaintingStyle.fill;
    final path = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final cutoutRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: cutoutSize.width,
      height: cutoutSize.height,
    );
    path.addRect(cutoutRect);
    path.fillType = PathFillType.evenOdd;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}