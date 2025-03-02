import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../appstate.dart'; // Import your AppState

class ScanResultScreen extends StatelessWidget {
  const ScanResultScreen({super.key});

  // static const List<String> classifications = [
  //   'Healthy',
  //   'Rice Blast',
  //   'Sheath Blight'
  // ];

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    // String randomClassification =
    //     classifications[Random().nextInt(classifications.length)];
    String currentClassification =
        appState.currentImageClassification; // Update AppState

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green, // Green app bar
        title: const Text(
          'Result',
          style: TextStyle(color: Colors.white), // White text
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Container(
        color: Colors.white, // White background
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Image.asset(
                'assets/images/PaddyScanned.png', // Your image asset
                height: 200, // Adjust height as needed
              ),
              const SizedBox(height: 40),
              Text(
                currentClassification, // Display randomized classification
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/save_to_records');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
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

                  // Handle "Scan Again" action (e.g., navigate back)
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
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
