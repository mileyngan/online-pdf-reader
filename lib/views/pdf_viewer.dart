import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

class PdfViewerScreen extends StatefulWidget {
  final String pdfPath;
  final String pdfName;
  const PdfViewerScreen({super.key, required this.pdfName, required this.pdfPath});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  
  int totaPages = 0;
  int currentPage = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(widget.pdfName),),

        body: PDFView(
          filePath: widget.pdfPath,
          pageFling: false,
          autoSpacing: false,
          onRender: (pages) {
            setState(() {
              totaPages = pages!;
            });
          },
          onPageChanged: (page, total) {
            setState(() {
              currentPage = page!;
            });
          },
        ),
    );
  }
}