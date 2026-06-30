import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/invoice_data.dart';

// Import conditionnel pour dart:html (uniquement sur le Web)
// ignore: unused_import
import 'dart:html' as html if (dart.library.html) '';

class InvoiceScreen extends StatefulWidget {
  final InvoiceData invoiceData;

  const InvoiceScreen({super.key, required this.invoiceData});

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFfcf9f8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1b1c1c)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Facture',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1b1c1c),
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: _buildReceiptCard(),
        ),
      ),
    );
  }

  Widget _buildReceiptCard() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 30,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildSuccessMessage(),
            const SizedBox(height: 24),
            _buildTicketDetails(),
            const SizedBox(height: 24),
            _buildPerforatedDivider(),
            const SizedBox(height: 24),
            // _buildTicketMeta() ← SUPPRIMÉ
            _buildPerforatedEdge(),
            const SizedBox(height: 16),
            _buildBarcode(),
            const SizedBox(height: 16),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Facture',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1b1c1c),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.invoiceData.numeroFacture,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1b1c1c),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.invoiceData.date,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF6f7a6b),
              ),
            ),
            Text(
              widget.invoiceData.adresse,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: const Color(0xFF6f7a6b),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSuccessMessage() {
    return Column(
      children: [
        Icon(
          Icons.celebration,
          size: 50,
          color: const Color(0xFFfe6b00),
        ),
        const SizedBox(height: 8),
        Text(
          'Merci !',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1b1c1c),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Votre commande a été validée avec succès',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF6f7a6b),
          ),
        ),
      ],
    );
  }

  Widget _buildTicketDetails() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFf6f3f2),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ...widget.invoiceData.items.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.nom,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1b1c1c),
                      ),
                    ),
                    Text(
                      'x${item.quantite}',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: const Color(0xFF6f7a6b),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${item.formattedTotal} Ar',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1b1c1c),
                  ),
                ),
              ],
            ),
          )),
          const Divider(
            color: Color(0xFFbecab9),
            thickness: 1,
            height: 20,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1b1c1c),
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                '${widget.invoiceData.total.toStringAsFixed(2)} Ar',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFfe6b00),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerforatedDivider() {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: const Color(0xFFbecab9).withOpacity(0.5),
                  width: 1,
                  style: BorderStyle.solid,
                ),
              ),
            ),
          ),
        ),
        Container(
          width: 16,
          height: 16,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }

  Widget _buildPerforatedEdge() {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: const BoxDecoration(
            color: Color(0xFFfcf9f8),
            shape: BoxShape.circle,
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: const Color(0xFFbecab9).withOpacity(0.5),
                  width: 1,
                  style: BorderStyle.solid,
                ),
              ),
            ),
          ),
        ),
        Container(
          width: 16,
          height: 16,
          decoration: const BoxDecoration(
            color: Color(0xFFfcf9f8),
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }

  Widget _buildBarcode() {
    return Column(
      children: [
        Container(
          height: 40,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF1b1c1c).withOpacity(0.9),
          ),
          child: Row(
            children: List.generate(
              60,
              (index) => Flexible(
                child: Container(
                  height: 40,
                  width: 2,
                  color: index % 2 == 0 ? Colors.black : Colors.transparent,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          widget.invoiceData.barcode,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: const Color(0xFF1b1c1c),
            letterSpacing: 4,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, size: 20),
            label: const Text('Fermer'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1b1c1c),
              side: BorderSide(color: const Color(0xFFbecab9).withOpacity(0.5)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _printInvoice(context),
            icon: const Icon(Icons.print, size: 20),
            label: const Text('Imprimer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1b1c1c),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // Impression PDF (sans ticket meta en bas)
  // ------------------------------------------------------------
  Future<void> _printInvoice(BuildContext context) async {
    try {
      final pdfBytes = await _generatePdf();
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
      );
    } catch (e) {
      if (kIsWeb) {
        _showDownloadDialog(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur impression : ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<Uint8List> _generatePdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: pw.EdgeInsets.all(8),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // En-tête
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Facture',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          font: pw.Font.helvetica(),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        widget.invoiceData.numeroFacture,
                        style: pw.TextStyle(
                          fontSize: 12,
                          font: pw.Font.helvetica(),
                        ),
                      ),
                      pw.Text(
                        widget.invoiceData.date,
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                          font: pw.Font.helvetica(),
                        ),
                      ),
                      pw.Text(
                        widget.invoiceData.adresse,
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                          font: pw.Font.helvetica(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'Merci !',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        font: pw.Font.helvetica(),
                      ),
                    ),
                    pw.Text(
                      'Votre commande a été validée avec succès',
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey700,
                        font: pw.Font.helvetica(),
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Container(
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey200,
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                padding: pw.EdgeInsets.all(12),
                child: pw.Column(
                  children: [
                    ...widget.invoiceData.items.map((item) => pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              item.nom,
                              style: pw.TextStyle(
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold,
                                font: pw.Font.helvetica(),
                              ),
                            ),
                            pw.Text(
                              'x${item.quantite}',
                              style: pw.TextStyle(
                                fontSize: 8,
                                color: PdfColors.grey700,
                                font: pw.Font.helvetica(),
                              ),
                            ),
                          ],
                        ),
                        pw.Text(
                          '${item.formattedTotal} Ar',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            font: pw.Font.helvetica(),
                          ),
                        ),
                      ],
                    )),
                    pw.Divider(),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Total',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            font: pw.Font.helvetica(),
                          ),
                        ),
                        pw.Text(
                          '${widget.invoiceData.total.toStringAsFixed(2)} Ar',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.orange,
                            font: pw.Font.helvetica(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),
              // Perforation 1 (divider)
              pw.Row(
                children: [
                  pw.Container(
                    width: 10,
                    height: 10,
                    decoration: pw.BoxDecoration(
                      shape: pw.BoxShape.circle,
                      color: PdfColors.white,
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Divider(
                      color: PdfColors.grey400,
                      thickness: 0.5,
                    ),
                  ),
                  pw.Container(
                    width: 10,
                    height: 10,
                    decoration: pw.BoxDecoration(
                      shape: pw.BoxShape.circle,
                      color: PdfColors.white,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
              // Perforation 2 (edge)
              pw.Row(
                children: [
                  pw.Container(
                    width: 10,
                    height: 10,
                    decoration: pw.BoxDecoration(
                      shape: pw.BoxShape.circle,
                      color: PdfColors.white,
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Divider(
                      color: PdfColors.grey400,
                      thickness: 0.5,
                    ),
                  ),
                  pw.Container(
                    width: 10,
                    height: 10,
                    decoration: pw.BoxDecoration(
                      shape: pw.BoxShape.circle,
                      color: PdfColors.white,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
              // Barcode
              pw.Container(
                height: 30,
                width: double.infinity,
                decoration: pw.BoxDecoration(
                  color: PdfColors.black,
                ),
                child: pw.Row(
                  children: List.generate(
                    60,
                    (index) => pw.Container(
                      width: 2,
                      color: index % 2 == 0 ? PdfColors.black : PdfColors.white,
                    ),
                  ),
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Center(
                child: pw.Text(
                  widget.invoiceData.barcode,
                  style: pw.TextStyle(
                    fontSize: 8,
                    letterSpacing: 4,
                    font: pw.Font.helvetica(),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return await pdf.save();
  }

  // ------------------------------------------------------------
  // Fallback Web : téléchargement PDF
  // ------------------------------------------------------------
  void _showDownloadDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Impression indisponible'),
        content: const Text('Voulez-vous télécharger la facture en PDF ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              if (!kIsWeb) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Téléchargement disponible uniquement sur le Web'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              try {
                final pdfBytes = await _generatePdf();
                final blob = html.Blob([pdfBytes], 'application/pdf');
                final url = html.Url.createObjectUrlFromBlob(blob);
                final anchor = html.AnchorElement(href: url)
                  ..download = 'Facture_${widget.invoiceData.numeroFacture}.pdf'
                  ..click();
                html.Url.revokeObjectUrl(url);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erreur de téléchargement : $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Télécharger'),
          ),
        ],
      ),
    );
  }
}