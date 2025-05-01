import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../appstate.dart';

class ScanResultScreen extends StatelessWidget {
  const ScanResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final currentClassification = appState.currentImageClassification;
    final imagePath = appState.currentImagePath;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text(
          'Result',
          style: TextStyle(color: Colors.white),
        ),
        leading: BackButton(
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/scan');
          },
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Container(
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (imagePath.isNotEmpty && File(imagePath).existsSync())
                Image.file(
                  File(imagePath),
                  height: 400,
                  fit: BoxFit.cover,
                )
              else
                Image.asset(
                  'assets/images/PaddyScanned.png',
                  height: 400,
                ),
              const SizedBox(height: 20),
              Text(
                currentClassification,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/save_to_records');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  textStyle: const TextStyle(fontSize: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Save to Records',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/scan');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  textStyle: const TextStyle(fontSize: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Scan Again',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
