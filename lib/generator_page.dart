import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class GeneratorPage extends StatefulWidget {
  const GeneratorPage({super.key});

  @override
  State<GeneratorPage> createState() => _GeneratorPageState();
}

class _GeneratorPageState extends State<GeneratorPage> {
  final TextEditingController _controller = TextEditingController();
  String _qrData = "https://flutter.dev"; // Default value

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate QR Code'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // QR Code Display
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 5,
                  ),
                ],
              ),
              child: QrImageView(
                semanticsLabel: _qrData,
                version: QrVersions.auto,
                size: 200.0,
                backgroundColor: Colors.white, data: '',
              ),
            ),
            const SizedBox(height: 30),
            // Input Field
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Enter text or URL',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: () {
                    setState(() {
                      _qrData = _controller.text.isEmpty
                          ? "https://flutter.dev"
                          : _controller.text;
                    });
                  },
                ),
              ),
              onSubmitted: (value) {
                setState(() {
                  _qrData = value.isEmpty ? "https://flutter.dev" : value;
                });
              },
            ),
            const SizedBox(height: 10),
            const Text(
              'Press Enter or the Check button to update',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}