import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:college/Database/Database.dart';
import 'package:college/SuperAdmin/ReportPage.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class Supergenerate extends StatelessWidget {
  final String selectedDepartment;
  final String selectedStatus;
  final DateTime fromDate;
  final DateTime toDate;

  Supergenerate(this.selectedDepartment, this.selectedStatus, this.fromDate, this.toDate);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Report',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: TicketTablePage(
        selectedDepartment: selectedDepartment,
        selectedStatus: selectedStatus,
        fromDate: fromDate,
        toDate: toDate,
      ),
    );
  }
}

class TicketTablePage extends StatefulWidget {
  final String selectedDepartment;
  final String selectedStatus;
  final DateTime fromDate;
  final DateTime toDate;
  TicketTablePage({
    required this.selectedDepartment,
    required this.selectedStatus,
    required this.fromDate,
    required this.toDate,
  });

  @override
  _TicketTablePageState createState() => _TicketTablePageState();
}

class _TicketTablePageState extends State<TicketTablePage> {

  List<Map<String, dynamic>> _status = [];
  List<Map<String, dynamic>> _token = [];
  List<Map<String, dynamic>> mergedList = [];
  @override
  void initState() {
    super.initState();
    getOnTheLoad();
  }

  void getOnTheLoad() async {
    await _fetchStatus();
    await _fetchToken();
    _mergeLists();
    setState(() {});
  }

  Future<void> _fetchToken() async {
    try {
      List<Map<String, dynamic>> token = await DatabaseMethods().getTokenList();
      setState(() {
        _token = token;
      });
    } catch (e) {
      setState(() {
        _token = [{'Token': 'Error loading Tokens', 'Did': null}];
      });
    }
  }

  Future<void> _fetchStatus() async {
    try {
      List<Map<String, dynamic>> status = await DatabaseMethods().getStatusList();
      setState(() {
        _status = status;
      });
    } catch (e) {
      setState(() {
        _status = [{'Status': 'Error loading status', 'Did': null}];
      });
    }
  }

  void _mergeLists() {
    mergedList.clear();

    DateTime fromDate;
    DateTime toDate;

    if (widget.fromDate is DateTime && widget.toDate is DateTime) {
      fromDate = widget.fromDate;
      toDate = widget.toDate.add(Duration(days: 1));
    } else {
      print("fromDate and toDate must be DateTime objects.");
      return;
    }
    for (var token in _token) {
      if (token['TId'] == null || token['Department'] == null) continue;
      var matchingStatus = _status.firstWhere(
            (status) => status['Pid'] == token['TId'],
        orElse: () => {'Status': 'No Status', 'SolvedOn': 'Not Solved', 'ClosedOn': 'Not Closed'},
      );
      if (token['RaisedOn'] != null && token['RaisedOn'] is Timestamp) {
        DateTime raisedOn = (token['RaisedOn'] as Timestamp).toDate();
        DateTime? solvedOn;
        DateTime? closedOn;
        String? sts = widget.selectedStatus=='Pending' ? 'P' :
        widget.selectedStatus=='Solved' ? 'S' :
        widget.selectedStatus=='Closed' ? 'C':
        widget.selectedStatus=='Completed' ? 'CM':'R';
        if (token['SolvedOn'] != null && token['SolvedOn'] is Timestamp) {
          solvedOn = (token['SolvedOn'] as Timestamp).toDate();
        }
        if (token['ClosedOn'] != null && token['ClosedOn'] is Timestamp) {
          closedOn = (token['ClosedOn'] as Timestamp).toDate();
        }
        if (token['Department'] == widget.selectedDepartment &&
            matchingStatus['Status'] == sts &&
            raisedOn.isAfter(fromDate.subtract(Duration(days: 1))) &&
            raisedOn.isBefore(toDate)) {
          mergedList.add({
            'TId': token['TId'] ?? 'N/A',
            'Ticket': token['Ticket'] ?? 'No Ticket Description',
            'RaisedOn': DateFormat('dd-MM-yyyy').format(raisedOn),
            'Status': matchingStatus['Status']=='P' ? 'Pending' :
                      matchingStatus['Status']=='S' ? 'Solved' :
                      matchingStatus['Status']=='C' ? 'Closed':
                      matchingStatus['Status']=='R' ?'Reraised'  :
                      matchingStatus['Status']=='CM' ? 'Completed' :'No Status',
            'SolvedOn': solvedOn != null ? DateFormat('dd-MM-yyyy').format(solvedOn) : 'Not Solved',
            'ClosedOn': closedOn != null ? DateFormat('dd-MM-yyyy').format(closedOn) : 'Not Closed',
          });
        }
      }
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
      ['Sl.no', 'Ticket', 'Status', 'Raised On', 'Solved On', 'Closed On'],
      ...mergedList.asMap().entries.map((entry) => [
        entry.key + 1,
        entry.value['Ticket'] ?? 'No Ticket Description',
        entry.value['Status'] ?? 'No Status',
        entry.value['RaisedOn'] ?? 'Not Raised',
        entry.value['SolvedOn'] ?? 'Not Solved',
        entry.value['ClosedOn'] ?? 'Not Closed',
      ]),
    ];

    String csv = const ListToCsvConverter().convert(csvData);
    return csv;
  }

  Future<void> exportCollectionToCsv() async {
    await requestStoragePermission();
    String csvData = _downloadReport();
    await saveCsvFile(csvData, 'Firestore_Collection');
  }


  @override
  Widget build(BuildContext context) {
    ScrollController verticalController = ScrollController();
    ScrollController horizontalController = ScrollController();

    return Scaffold(
      appBar: AppBar(
        title: Text('Report'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Superadminreport()));
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Scrollbar(
                thumbVisibility: true,
                controller: verticalController,
                child: SingleChildScrollView(
                  controller: verticalController,
                  scrollDirection: Axis.vertical,
                  child: Scrollbar(
                    thumbVisibility: true,
                    controller: horizontalController,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      controller: horizontalController,
                      child: Container(
                        color: Colors.grey[100],
                        child: DataTable(
                          columnSpacing: 8.0,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                          ),
                          headingRowColor: MaterialStateProperty.all(Colors.grey[800]),
                          dataRowColor: MaterialStateProperty.resolveWith((Set<MaterialState> states) {
                            if (states.contains(MaterialState.selected)) {
                              return Colors.grey[200];
                            }
                            return Colors.grey[300];
                          }),
                          columns: [
                            DataColumn(
                              label: Container(
                                width: 50,
                                child: Text(
                                  'Sl.no',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Container(
                                width: 200,
                                child: Text(
                                  'Ticket',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Container(
                                width: 80,
                                child: Text(
                                  'Status',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Container(
                                width: 80,
                                child: Text(
                                  'Raised On',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Container(
                                width: 80,
                                child: Text(
                                  'Solved On',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Container(
                                width: 80,
                                child: Text(
                                  'Closed On',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          rows: mergedList.map((ticket) {
                            int index = mergedList.indexOf(ticket);
                            Color rowColor = (index % 2 == 0) ? Colors.grey[300] ?? Colors.grey : Colors.grey[200] ?? Colors.grey;
                            return DataRow(
                              color: MaterialStateProperty.all(rowColor),
                              cells: [
                                DataCell(Text((index + 1).toString())),
                                DataCell(Text(ticket['Ticket'] ?? 'N/A')),
                                DataCell(Text(ticket['Status'] ?? 'N/A')),
                                DataCell(Text(ticket['RaisedOn'] ?? 'N/A')),
                                DataCell(Text(ticket['SolvedOn'] ?? 'N/A')),
                                DataCell(Text(ticket['ClosedOn'] ?? 'N/A')),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: exportCollectionToCsv,
            icon: Icon(Icons.download),
            label: Text('Download Report'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
            ),
          ),
        ],
      )
    );
  }
}
