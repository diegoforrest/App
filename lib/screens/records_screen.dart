import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database_helper.dart';
import 'dart:io';

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

enum FilterOption { Classification, Most_Recent, Least_Recent }

class _RecordsScreenState extends State<RecordsScreen> {
  late Future<List<Record>> _recordsFuture;
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  FilterOption _selectedFilter = FilterOption.Most_Recent;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    _recordsFuture = _databaseHelper.getRecords();
    setState(() {});
  }

  List<Record> _filterRecords(List<Record> records) {
    switch (_selectedFilter) {
      case FilterOption.Classification:
        records.sort((a, b) => a.classification.compareTo(b.classification));
        break;
      case FilterOption.Most_Recent:
        records.sort((a, b) => b.date.compareTo(a.date));
        break;
      case FilterOption.Least_Recent:
        records.sort((a, b) => a.date.compareTo(b.date));
        break;
    }
    return records;
  }

  Future<void> _deleteRecord(int id) async {
    await _databaseHelper.deleteRecord(id);
    _loadRecords(); // Refresh the record list
  }

  Future<void> _deleteAllRecords() async {
    await _databaseHelper.deleteAllRecords(); // Added this
    _loadRecords();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 221, 221, 192),
        title: const Text('Records', style: TextStyle(color: Colors.black)),
        actions: [
          IconButton(
            onPressed: _deleteAllRecords, // Call delete all function
            icon: const Icon(Icons.delete_forever, color: Colors.red),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<FilterOption>(
              decoration: const InputDecoration(labelText: 'Filter By'),
              value: _selectedFilter,
              onChanged: (newValue) {
                setState(() {
                  _selectedFilter = newValue!;
                });
              },
              items: FilterOption.values.map((filter) {
                return DropdownMenuItem<FilterOption>(
                  value: filter,
                  child: Text(filter.toString().split('.').last.replaceAll('_', ' ')),
                );
              }).toList(),
            ),
            Expanded(
              child: FutureBuilder<List<Record>>(
                future: _recordsFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    List<Record> records = snapshot.data!;
                    records = _filterRecords(records);
                    return ListView.builder(
                      itemCount: records.length,
                      itemBuilder: (context, index) {
                        final record = records[index];
                        return Card(
                          color: const Color.fromARGB(255, 245, 245, 220),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                if (record.pathToImage.isNotEmpty)
                                  Image.file(
                                    File(record.pathToImage),
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  )
                                else
                                  Container(
                                    width: 100,
                                    height: 100,
                                    color: Colors.grey[300],
                                    child:
                                    const Center(child: Text('No Image')),
                                  ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text('Record - ${record.id}'),
                                      Text(
                                          'Classification: ${record.classification}'),
                                      Text(
                                          'Date: ${DateFormat('MMMM d yyyy, h:mm a').format(record.date)}'),
                                      Text('Note: ${record.note}'),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  // Delete button for each record
                                  onPressed: () => _deleteRecord(record.id!),
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else {
                    return const Center(child: CircularProgressIndicator());
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}