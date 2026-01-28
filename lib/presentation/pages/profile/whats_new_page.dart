import 'package:flutter/material.dart';

class WhatsNewPage extends StatelessWidget {
  const WhatsNewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("What's New", style: TextStyle(color: Colors.yellow)),
      ),
      body: const Center(
        child: Text(
          "🚀 Stay tuned for updates!",
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
