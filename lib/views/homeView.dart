import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:external_path/external_path.dart'; 
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path; 
import 'package:online_pdf_reader_app/views/pdf_viewer.dart'; 
import 'package:http/http.dart' as http; 
import 'package:path_provider/path_provider.dart'; 

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final List<Map<String, String>> _pdfFiles = []; 
  List<Map<String, String>> _filteredFiles = []; 
  bool _isSearching = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    loadAllPdfs(); 
  }

  Future<void> loadAllPdfs() async {
    setState(() => _isLoading = true);
    _pdfFiles.clear();

    await loadExternalPdfs(); 
    await loadAssetPdfs(); 

    setState(() {
      _filteredFiles = List.from(_pdfFiles);
      _isLoading = false;
    });
  }

  Future<void> loadExternalPdfs() async {
    
    PermissionStatus permissionStatus = await Permission.storage.request();
    if (permissionStatus.isGranted) {
      var rootDirectories = await ExternalPath.getExternalStorageDirectories();
      if (rootDirectories != null && rootDirectories.isNotEmpty) {
        await fetchExternalFiles(rootDirectories.first); 
      }
    }
  }

  Future<void> fetchExternalFiles(String directoryPath) async {
    try {
      var rootDirectory = Directory(directoryPath);
      if (await rootDirectory.exists()) {
        var directories = rootDirectory.list(recursive: false);

        await for (var element in directories) {
          if (element is File && element.path.endsWith('.pdf')) {
            _pdfFiles.add({"name": path.basename(element.path), "path": element.path});
          } else if (element is Directory) {
            await fetchExternalFiles(element.path);
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching external PDFs: $e");
    }
  }

  Future<void> loadAssetPdfs() async {
    try {
      final manifestJson = await rootBundle.loadString('AssetManifest.json'); // Load asset manifest
      final List<String> assetFiles = manifestJson.split('\n').where((line) => line.contains('.pdf')).toList();
      for (String assetPath in assetFiles) {
        _pdfFiles.add({"name": path.basename(assetPath), "path": assetPath});
      }
    } catch (e) {
      debugPrint("Error fetching asset PDFs: $e");
    }
  }

  Future<void> downloadPdfFromInternet(String url, String filename) async {
    try {
      var response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        Directory directory = await getApplicationDocumentsDirectory();
        File file = File('${directory.path}/$filename');
        await file.writeAsBytes(response.bodyBytes);

        setState(() {
          _pdfFiles.add({"name": filename, "path": file.path});
          _filteredFiles = List.from(_pdfFiles);
        });

        debugPrint("PDF Downloaded: ${file.path}");
      }
    } catch (e) {
      debugPrint("Error downloading PDF: $e");
    }
  }

  void _filterFiles(String query) {
    setState(() {
      _filteredFiles = query.isEmpty
          ? List.from(_pdfFiles)
          : _pdfFiles.where((file) => file["name"]!.toLowerCase().contains(query.toLowerCase())).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: !_isSearching
            ? const Text(
                "PDF Reader",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              )
            : TextField(
                decoration: const InputDecoration(
                  hintText: "Search PDFs",
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  _filterFiles(value);
                },
              ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            iconSize: 30,
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                _filteredFiles = _pdfFiles;
              });
            },
            icon: Icon(_isSearching ? Icons.cancel : Icons.search),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // Showing loading indicator
          : _filteredFiles.isEmpty
              ? const Center(
                  child: Text(
                    "No PDF files found",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                )
              : ListView.builder(
                  itemCount: _filteredFiles.length,
                  itemBuilder: (context, index) {
                    String fileName = _filteredFiles[index]["name"]!;
                    String filePath = _filteredFiles[index]["path"]!;
                    return Card(
                      color: Colors.white,
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        title: Text(
                          fileName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        leading: const Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 30),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PdfViewerScreen(pdfName: fileName, pdfPath: filePath),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          loadAllPdfs(); // Reload PDFs when FAB is pressed
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
