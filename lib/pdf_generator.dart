import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../database_helper.dart';

class PDFGenerator {
  final DatabaseHelper dbHelper = DatabaseHelper();

  Future<File> generatePDF(List<Record> records) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final filename =
        'PaddyScan_Record_${DateFormat('MMM dd, yyyy – h:mm a').format(now)}.pdf';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        header: (pw.Context context) {
          // will be shown at the top of each page
          return pw.Text(
            'PaddyScan Records',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          );
        },
        build: (pw.Context context) {
          // build the table rows for all records
          final tableHeaders = ['ID', 'Image', 'Classification', 'Note', 'Date'];
          final tableData = records.map((r) {
            return [
              r.id.toString(),
              r.pathToImage.isNotEmpty
                  ? pw.Container(
                width: 60,
                height: 60,
                child: pw.Image(
                  pw.MemoryImage(File(r.pathToImage).readAsBytesSync()),
                  fit: pw.BoxFit.cover,
                ),
              )
                  : 'No Image',
              r.classification,
              r.note,
              DateFormat('MMM dd, yyyy h:mm a').format(r.date),
            ];
          }).toList();

          return [
            pw.Table.fromTextArray(
              headers: tableHeaders,
              data: tableData,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignment: pw.Alignment.centerLeft,
              cellHeight: 60,
              columnWidths: {
                0: pw.FixedColumnWidth(30),
                1: pw.FixedColumnWidth(60),
                2: pw.FlexColumnWidth(2),
                3: pw.FlexColumnWidth(3),
                4: pw.FlexColumnWidth(2),
              },
              border: pw.TableBorder.all(width: 0.5),
            ),
          ];
        },
      ),
    );


    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  Future<List<FileSystemEntity>> getGeneratedPDFs() async {
    final dir = await getApplicationDocumentsDirectory();
    return dir.list().where((f) => f.path.endsWith('.pdf')).toList();
  }
}
