import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database_helper.dart';
import 'dart:io';
import 'package:photo_view/photo_view.dart';
import '../pdf_generator.dart';
import 'package:open_filex/open_filex.dart';

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
  List<FileSystemEntity> _pdfFiles = [];

  @override
  void initState() {
    super.initState();
    _loadRecords();
    _loadPDFs();
  }

  Future<void> _loadRecords() async {
    _recordsFuture = _databaseHelper.getRecords();
    setState(() {});
  }

  Future<void> _loadPDFs() async {
    final pdfs = await PDFGenerator().getGeneratedPDFs();
    pdfs.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
    setState(() {
      _pdfFiles = pdfs;
    });
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Record'),
        content: const Text('Are you sure you want to delete this record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _databaseHelper.deleteRecord(id);
      _loadRecords();
    }
  }

  Future<void> _deleteAllRecords() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Records'),
        content: const Text(
            'Are you sure you want to delete all records? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _databaseHelper.deleteAllRecords();
      _loadRecords();
    }
  }

  void _showFullImage(String imagePath) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(10),
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              PhotoView(
                imageProvider: FileImage(File(imagePath)),
                backgroundDecoration: const BoxDecoration(
                  color: Colors.transparent,
                ),
                minScale: PhotoViewComputedScale.contained * 1,
                maxScale: PhotoViewComputedScale.covered * 3,
              ),
              Positioned(
                top: 80,
                right: 20,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 221, 221, 192),
        title: const Text('Records', style: TextStyle(color: Colors.black)),
        actions: [
          IconButton(
            onPressed: _deleteAllRecords,
            icon: const Icon(Icons.delete_forever, color: Colors.red),
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Generate PDF',
            onPressed: () async {
              final records = await _databaseHelper.getRecords();
              final pdfFile = await PDFGenerator().generatePDF(records);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('PDF saved: ${pdfFile.path}'),
              ));
              await _loadPDFs();
            },
          ),
          IconButton(
            icon: const Icon(Icons.folder),
            tooltip: 'View PDFs',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return StatefulBuilder(
                    builder: (context, setState) => AlertDialog(
                      title: const Text('PaddyScan PDFs'),
                      content: SizedBox(
                        width: double.maxFinite,
                        child: ListView.builder(
                          itemCount: _pdfFiles.length,
                          itemBuilder: (context, index) {
                            final file = _pdfFiles[index];
                            return ListTile(
                              title: Text(file.path.split('/').last),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.open_in_new),
                                    onPressed: () async {
                                      final result = await OpenFilex.open(file.path);
                                      if (result.type != ResultType.done) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Could not open PDF: ${result.message}')),
                                        );
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () async {
                                      // Ask the user for confirmation before deleting the PDF
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Delete PDF'),
                                          content: const Text('Are you sure you want to delete this PDF?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.of(context).pop(false),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.of(context).pop(true),
                                              child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirm == true) {
                                        await file.delete();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Deleted PDF: ${file.path.split('/').last}')),
                                        );
                                        final updatedPDFs = await PDFGenerator().getGeneratedPDFs();
                                        updatedPDFs.sort((a, b) =>
                                            b.statSync().modified.compareTo(a.statSync().modified));
                                        setState(() {
                                          _pdfFiles = updatedPDFs;
                                        });
                                      }
                                    },
                                  )
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              );
            },
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
                                  GestureDetector(
                                    onTap: () => _showFullImage(record.pathToImage),
                                    child: Image.file(
                                      File(record.pathToImage),
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                else
                                  Container(
                                    width: 100,
                                    height: 100,
                                    color: Colors.grey[300],
                                    child: const Center(child: Text('No Image')),
                                  ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Record - ${record.id}'),
                                      Text('Classification: ${record.classification}'),
                                      Text('Date: ${DateFormat('yyyy-MM-dd').format(record.date)}'),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteRecord(record.id!),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  return const Center(child: CircularProgressIndicator());
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
