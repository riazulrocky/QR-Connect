import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/services.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';

class GeneratorPage extends StatefulWidget {
  const GeneratorPage({super.key});

  @override
  State<GeneratorPage> createState() => _GeneratorPageState();
}

class _GeneratorPageState extends State<GeneratorPage>
    with SingleTickerProviderStateMixin {
  String _selectedType = 'URL';
  final List<String> _qrTypes = ['URL', 'Plain Text'];

  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _textController = TextEditingController();

  String _qrData = '';
  final GlobalKey _qrKey = GlobalKey();

  // ✅ Animation variables
  late AnimationController _qrAnimationController;
  late Animation<double> _qrFadeAnimation;

  @override
  void initState() {
    super.initState();

    // ✅ FIX: Initialize animations FIRST before using them
    _qrAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _qrFadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _qrAnimationController, curve: Curves.easeInOut),
    );

    // ✅ THEN call _generateQR (which uses the animation controller)
    _generateQR();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _textController.dispose();
    _qrAnimationController.dispose();
    super.dispose();
  }

  void _generateQR() {
    // ✅ Safe reset: only if controller is ready
    if (_qrAnimationController.isAnimating || _qrAnimationController.value == 1) {
      _qrAnimationController.reset();
    }

    setState(() {
      if (_selectedType == 'URL') {
        String url = _urlController.text.trim();
        if (url.isNotEmpty) {
          if (!url.startsWith('http://') && !url.startsWith('https://')) {
            url = 'https://$url';
          }
          _qrData = url;
        } else {
          _qrData = '';
        }
      } else {
        _qrData = _textController.text.isEmpty
            ? 'Enter some text to generate QR'
            : _textController.text;
      }
    });

    _qrAnimationController.forward();
  }

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: _qrData));
    HapticFeedback.lightImpact();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        _buildModernSnackBar('✓ Copied to clipboard', Colors.green[700]!, Icons.check_rounded),
      );
    }
  }

  Future<void> _saveQRCode() async {
    HapticFeedback.mediumImpact();
    try {
      if (Platform.isAndroid) {
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
        }
        if (!status.isGranted) {
          _showError('Storage permission required');
          return;
        }
      }

      final boundary = _qrKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final result = await ImageGallerySaver.saveImage(pngBytes);

      if (result != null && result['isSuccess']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            _buildModernSnackBar('✓ QR Code saved to gallery', Colors.green[700]!, Icons.download_rounded),
          );
        }
      } else {
        _showError('Failed to save image');
      }
    } catch (e) {
      _showError('Error: ${e.toString()}');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      _buildModernSnackBar('❌ $message', Colors.red[700]!, Icons.error_rounded),
    );
  }

  SnackBar _buildModernSnackBar(String message, Color bgColor, IconData icon) {
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
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ),
        ],
      ),
      backgroundColor: bgColor,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    );
  }

  Widget _buildInputFields() {
    final isURL = _selectedType == 'URL';

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.2, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: isURL
          ? Column(
        key: const ValueKey('url-input'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildModernTextField(
            controller: _urlController,
            label: 'Enter URL',
            hint: 'example.com or https://example.com',
            icon: Icons.link_rounded,
            keyboardType: TextInputType.url,
            onChanged: (_) => _generateQR(),
          ),
        ],
      )
          : _buildModernTextField(
        key: const ValueKey('text-input'),
        controller: _textController,
        label: 'Enter Text',
        hint: 'Type anything here...',
        icon: null,
        keyboardType: TextInputType.multiline,
        maxLines: 4,
        alignLabelWithHint: true,
        onChanged: (_) => _generateQR(),
      ),
    );
  }

  Widget _buildModernTextField({
    Key? key,
    required TextEditingController controller,
    required String label,
    required String hint,
    IconData? icon,
    TextInputType? keyboardType,
    int? maxLines = 1,
    bool alignLabelWithHint = false,
    required ValueChanged<String> onChanged,
  }) {
    return TextField(
      key: key,
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white, fontSize: 14),
        labelStyle: const TextStyle(color: Colors.white, fontSize: 14),
        prefixIcon: icon != null
            ? Icon(icon, color: Colors.white, size: 20)
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.teal, width: 2),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        alignLabelWithHint: alignLabelWithHint,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,

      appBar: AppBar(
        title: const Text(
          'Generate QR Code',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
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

      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF11998e), Color(0xFF38ef7d), Color(0xFF1abc9c)],
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  _buildModernChipSelector(),
                  const SizedBox(height: 25),

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: _buildInputFields(),
                  ),

                  const SizedBox(height: 30),

                  FadeTransition(
                    opacity: _qrFadeAnimation,
                    child: Container(
                      key: _qrKey,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.teal.withOpacity(0.3),
                            blurRadius: 25,
                            spreadRadius: 2,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          QrImageView(
                            semanticsLabel: _qrData,
                            version: QrVersions.auto,
                            size: 200,
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            eyeStyle: const QrEyeStyle(
                              color: Color(0xFF11998e),
                              eyeShape: QrEyeShape.circle,
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              color: Colors.black87,
                              dataModuleShape: QrDataModuleShape.circle,
                            ),
                            data: _qrData.isEmpty ? ' ' : _qrData,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  Row(
                    children: [
                      Expanded(
                        child: _buildGradientButton(
                          label: 'Copy',
                          icon: Icons.content_copy_rounded,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4b6cb7), Color(0xFF182848)],
                          ),
                          onTap: _copyToClipboard,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildGradientButton(
                          label: 'Save',
                          icon: Icons.download_rounded,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
                          ),
                          onTap: _saveQRCode,
                        ),
                      ),
                    ],
                  ),

                  // ✅ CHANGED: Removed the info box Container with "Scanning this QR..." text

                  const SizedBox(height: 15),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernChipSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _qrTypes.map((type) {
          final isSelected = _selectedType == type;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _selectedType = type;
                _generateQR();
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                  colors: [Colors.white, Colors.grey[100]!],
                )
                    : null,
                color: isSelected ? null : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                boxShadow: isSelected
                    ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
                    : null,
              ),
              child: Text(
                type,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF11998e) : Colors.white,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGradientButton({
    required String label,
    required IconData icon,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: Colors.white.withOpacity(0.2),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: gradient.colors.first.withOpacity(0.35),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 19),
              const SizedBox(width: 7),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}