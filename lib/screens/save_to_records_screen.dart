import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../appstate.dart'; // Import your AppState
import '../database_helper.dart'; // Import your DatabaseHelper class

class SaveToRecordsScreen extends StatefulWidget {
  const SaveToRecordsScreen({super.key});

  @override
  State<SaveToRecordsScreen> createState() => _SaveToRecordsScreenState();
}

class _SaveToRecordsScreenState extends State<SaveToRecordsScreen> {
  final _noteController = TextEditingController();
  final _databaseHelper =
      DatabaseHelper(); // Create an instance of DatabaseHelper

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final imagePath = appState.currentImagePath;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text('Save To Records',
            style: TextStyle(color: Colors.white)),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (imagePath.isNotEmpty)
                Image.file(
                  File(imagePath),
                  height: 400,
                  fit: BoxFit.fitHeight,
                )
              else
                Container(
                  height: 200,
                  color: Colors.grey[300],
                  child: const Center(child: Text('No image selected')),
                ),
              const SizedBox(height: 20),
              TextField(
                controller: _noteController,
                maxLines: 4,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Add notes...',
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      //goes back to home
                      Navigator.pushNamed(context, '/');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 12),
                      textStyle: const TextStyle(fontSize: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Cancel',
                        style: TextStyle(color: Colors.white)),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (imagePath.isNotEmpty) {
                        final newRecord = Record(
                          classification: appState
                              .currentImageClassification, // Replace with actual classification logic
                          note: _noteController.text,
                          pathToImage: imagePath,
                          date: DateTime.now(), // Get current date and time
                        );

                        int id = await _databaseHelper.insertRecord(newRecord);

                        print("inserted id: $id");
                        appState.currentImagePath = '';
                        Navigator.pushNamed(context, '/');
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Please select an image')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 12),
                      textStyle: const TextStyle(fontSize: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Save',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
