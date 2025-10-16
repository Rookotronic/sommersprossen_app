import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import '../models/lottery.dart';
import '../models/child.dart';
import '../models/child.dart' show GroupName, GroupNameDisplay;
import '../utils/date_utils.dart' as custom_date_utils;

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
        final sortedChildren = [...children]..sort((a, b) => a.nachname.compareTo(b.nachname));
        // Info section
        pdf.addPage(
          pw.Page(
            build: (context) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Lotterie Details', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.Text(custom_date_utils.DateUtils.formatWeekdayDate(lottery.date)),
                pw.Text('Gruppe: ${lottery.group == 'Beide' ? 'Beide' : GroupName.values.firstWhere((g) => g.name == lottery.group).displayName}'),
                pw.Text('Zeit: ${lottery.endFirstPartOfDay}'),
                pw.Text('Zu ziehende Kinder: ${lottery.nrOfChildrenToPick}'),
                if (lottery.information.isNotEmpty) ...[
                  pw.SizedBox(height: 12),
                  pw.Text(lottery.information, style: pw.TextStyle(fontSize: 12, color: PdfColors.grey800)),
                  pw.SizedBox(height: 8),
                ],
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
                      final showGezogen = lottery.finished && entry.picked;
                      return pw.TableRow(
                        decoration: showGezogen
                            ? const pw.BoxDecoration(color: PdfColors.pink100)
                            : null,
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              '${child.vorname} ${child.nachname}${showGezogen ? ' (gezogen)' : ''}',
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
