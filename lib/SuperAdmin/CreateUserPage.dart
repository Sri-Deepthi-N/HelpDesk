import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:college/Auth/AuthFunctions.dart';
import 'package:college/SuperAdmin/superadmin.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:csv/csv.dart'; // CSV parsing package
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart'; // For getting storage directory

class Createuser extends StatefulWidget {
  const Createuser({Key? key}) : super(key: key);

  @override
  State<Createuser> createState() => _CreateuserState();
}

class _CreateuserState extends State<Createuser> {
  List<Map<String, dynamic>> Data= [];// To store the parsed CSV data
  // Function to pick a CSV file
  String? selectedFileName;

  Future<void> uploadCsvToFirestore() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],  // Only allow CSV files
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        selectedFileName = result.files.first.name; // Update the file name
      });
      File file = File(result.files.single.path!);
      // Validate the file extension
      if (file.path.endsWith('.csv')) {
        // Step 2: Read the CSV file
        String csvData = await file.readAsString();
        List<List<dynamic>> rows = const CsvToListConverter().convert(csvData);

        // Step 3: Prepare data and upload to Firestore
        for (int i = 0; i < rows.length; i++) { // Start from 1 to skip header
          Map<String, dynamic> data = {
            'mailId': rows[i][0], // Replace with actual field names
            'name': rows[i][1],
            'password': rows[i][2],
            'phoneNo': rows[i][3],
            'role': rows[i][4],
            'uid': rows[i][5],
          };
          Data.add(data);
        }
      } else {
        setState(() {
          selectedFileName = null; // Reset if no file is selected
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Selected file is not a CSV file."),
        ));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("No file selected."),
      ));
    }
  }

  Future<void> requestStoragePermission() async {
    if (await Permission.storage.request().isDenied) {
      await Permission.storage.request();
    }
    // For Android 11+ (Scoped Storage)
    if (await Permission.manageExternalStorage.isDenied) {
      await Permission.manageExternalStorage.request();
    }
  }

  Future<void> saveCsvFile(String csvData, String fileName) async {
    List<Directory>? directories = await getExternalStorageDirectories(type: StorageDirectory.downloads);
    if (directories != null && directories.isNotEmpty) {
      String path = "${directories.first.path}/$fileName.csv";
      File file = File(path);
      await file.writeAsString(csvData);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("File saved to Downloads at $path"),
      ));
    } else {
      throw Exception("Downloads directory not found");
    }
  }

  String _downloadReport() {
    List<List<dynamic>> csvData = [
      ['mailId', 'name', 'password', 'phoneNo', 'role', 'uid']
    ];
    String csv = const ListToCsvConverter().convert(csvData);
    return csv;
  }

  Future<void> exportCollectionToCsv() async {
    await requestStoragePermission();
    String csvData = _downloadReport();
    await saveCsvFile(csvData, 'Firestore_UserDetails');
  }

  // Function to show success message
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  // Function to show error message
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Navigate to the previous page
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (context) => SuperAdmin()));
          },
        ),
        title: const Text("Create User"),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Form(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),
              // Row for the CSV template title and button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Download CSV Template",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton(
                    onPressed: exportCollectionToCsv,
                    child: const Text("Download"),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                "Choose the CSV file",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextFormField(
                readOnly: true, // Prevent manual input
                decoration: InputDecoration(
                  labelText: 'Selected file',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.attach_file),
                    onPressed: uploadCsvToFirestore,
                      // Open file picker on click
                  ),
                ),
                controller: TextEditingController(text: selectedFileName), // Set the file name as the tex;

              ),

              const SizedBox(height: 20),

              Center(
                child: ElevatedButton(
                  onPressed: () async {

                    if (Data != null && Data!.isNotEmpty) {
                      for(int i=0;i<Data.length;i++){

                        AuthServices().signupUser(Data[i]['mailId'],Data[i]['password'],context);
                        await FirebaseFirestore.instance.collection('UserDetails').doc(Data[i]['uid']).set(Data[i]);
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('The User has been Created'),
                        ),
                      );

                      // Navigate back to SuperAdmin page
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => SuperAdmin()),
                      );
                    } else {
                      _showErrorSnackBar('Please upload a valid CSV file');
                    }
                  },
                  child: const Text("Create"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}