import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:college/Auth/AuthFunctions.dart';
import 'package:college/SuperAdmin/superadmin.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class Createuser extends StatefulWidget {
  const Createuser({Key? key}) : super(key: key);

  @override
  State<Createuser> createState() => _CreateuserState();
}

class _CreateuserState extends State<Createuser> {
  List<Map<String, dynamic>> Data= [];
  String? selectedFileName;

  Future<void> uploadCsvToFirestore() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        selectedFileName = result.files.first.name;
      });
      File file = File(result.files.single.path!);
      if (file.path.endsWith('.csv')) {
        String csvData = await file.readAsString();
        List<List<dynamic>> rows = const CsvToListConverter().convert(csvData);

        for (int i = 0; i < rows.length; i++) {
          Map<String, dynamic> data = {
            'mailId': rows[i][0],
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
          selectedFileName = null;
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

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

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
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Selected file',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.attach_file),
                    onPressed: uploadCsvToFirestore,
                  ),
                ),
                controller: TextEditingController(text: selectedFileName),

              ),

              const SizedBox(height: 20),

              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    if (Data != null && Data!.isNotEmpty) {
                      for(int i=0;i<Data.length;i++){

                        await AuthServices().signupUser(Data[i]['mailId'],Data[i]['password'],context);
                        await FirebaseFirestore.instance.collection('UserDetails').doc(Data[i]['uid']).set(Data[i]);
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('The User has been Created'),
                        ),
                      );

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