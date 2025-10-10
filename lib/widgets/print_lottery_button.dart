import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import '../models/lottery.dart';
import '../models/child.dart';
import '../utils/date_format.dart';

/// Button to print the details of a finished lottery as a PDF.
/// The PDF layout closely matches the detail screen.
class PrintLotteryButton extends StatelessWidget {
  final Lottery lottery;
  final List<Child> children;

  const PrintLotteryButton({super.key, required this.lottery, required this.children});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.print),
      label: const Text('Drucken'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      onPressed: () async {
        final pdf = pw.Document();
        // Sort children by surname
        final sortedChildren = [...children]..sort((a, b) => a.nachname.compareTo(b.nachname));
        pdf.addPage(
          pw.Page(
            build: (context) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Lotterie Details', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.Text('Datum: ${formatDate(lottery.date)}'),
                pw.Text('Zeit: ${lottery.timeOfDay}'),
                pw.Text('Zu ziehende Kinder: ${lottery.nrOfChildrenToPick}'),
                pw.SizedBox(height: 16),
                pw.Text('Kinder:', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey),
                  children: [
                    pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Name', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Benachrichtigt', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Geantwortet', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Bedarf', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold))),
                      ],
                    ),
                    ...sortedChildren.map((child) {
                      final entry = lottery.children.firstWhere((e) => e.childId == child.id);
                      final isPicked = entry.picked;
                      return pw.TableRow(
                        decoration: isPicked
                            ? const pw.BoxDecoration(color: PdfColors.grey300)
                            : null,
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              '${child.nachname}, ${child.vorname}${isPicked ? ' (Gezogen)' : ''}',
                              style: pw.TextStyle(fontSize: 11),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(entry.notified ? 'Ja' : 'Nein', style: pw.TextStyle(fontSize: 11)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(entry.responded ? 'Ja' : 'Nein', style: pw.TextStyle(fontSize: 11)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              (entry.need == true) ? 'Ja' : (entry.need == false) ? 'Nein' : '-',
                              style: pw.TextStyle(fontSize: 11),
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
        );
        await Printing.layoutPdf(onLayout: (format) => pdf.save());
      },
    );
  }
}
