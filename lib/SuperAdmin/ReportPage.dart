import 'package:college/Database/Database.dart';
import 'package:college/SuperAdmin/GeneratedReport.dart';
import 'package:college/SuperAdmin/superadmin.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(Superadminreport());
}

class Superadminreport extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Report Generator',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ReportPage(),
    );
  }
}

class ReportPage extends StatefulWidget {
  @override
  _ReportPageState createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  String? _selectedDepartment;
  String? _selectedStatus;
  DateTime? _fromDate;
  DateTime? _toDate;

  List<Map<String, dynamic>> _departments = [];

  @override
  void initState() {
    super.initState();
    _fetchDepartments();
  }

  Future<void> _fetchDepartments() async {
    try {
      List<Map<String, dynamic>> departments = await DatabaseMethods().getDepartment();
      setState(() {
        _departments = departments;
      });
    } catch (e) {
      setState(() {
        _departments = [{'Department': 'Error loading departments', 'Did': null}];
      });
    }
  }

  final List<String> _statuses = ['Pending', 'Solved', 'Closed','Reraised'];

  Future<void> _selectFromDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2021),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _fromDate) {
      if (picked.isAfter(DateTime.now())) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('The selected date cannot be after today.')),
        );
      } else {
        setState(() {
          _fromDate = picked;
        });
      }
    }
  }

  Future<void> _selectToDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2021),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _toDate) {
      if (picked.isAfter(DateTime.now())) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('The selected date cannot be after today.')),
        );
      } else if (_fromDate != null && picked.isBefore(_fromDate!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('The "To" date cannot be before the "From" date.')),
        );
      } else {
        setState(() {
          _toDate = picked;
        });
      }
    }
  }

  void _generateReport() {
    if (_selectedDepartment != null &&
        _selectedStatus != null &&
        _fromDate != null &&
        _toDate != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => Supergenerate(
            _selectedDepartment!,
            _selectedStatus!,
            _fromDate!,
            _toDate!,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all the fields before generating the report.')),
      );
    }
  }

  void _cancel() {
    setState(() {
      _selectedDepartment = null;
      _selectedStatus = null;
      _fromDate = null;
      _toDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Generate Report'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => SuperAdmin()));
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDropdown(
                label: 'Department',
                value: _selectedDepartment,
                items: _departments.map<DropdownMenuItem<String>>((dept) {
                  return DropdownMenuItem<String>(
                    value: dept['Department'],
                    child: Text(dept['Department']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDepartment = value;
                  });
                },
              ),
              SizedBox(height: 20),

              _buildDropdown(
                label: 'Status',
                value: _selectedStatus,
                items: _statuses.map<DropdownMenuItem<String>>((status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedStatus = value;
                  });
                },
              ),
              SizedBox(height: 20),

              _buildDatePicker(
                label: 'From',
                selectedDate: _fromDate,
                onTap: () => _selectFromDate(context),
              ),
              SizedBox(height: 20),

              _buildDatePicker(
                label: 'To',
                selectedDate: _toDate,
                onTap: () => _selectToDate(context),
              ),
              SizedBox(height: 40),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton('Generate', _generateReport),
                  _buildActionButton('Cancel', _cancel),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Container(
          width: double.infinity, // Set width to fill available space
          padding: EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black),
            borderRadius: BorderRadius.circular(5),
          ),
          child: DropdownButton<String>(
            isExpanded: true,
            value: value,
            onChanged: onChanged,
            hint: Text('Select $label'),
            underline: SizedBox(), // Remove the underline
            items: items,
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime? selectedDate,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity, // Set width to fill available space
            padding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              selectedDate == null
                  ? 'Select $label Date'
                  : DateFormat('dd-MM-yyyy').format(selectedDate),
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(label),
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 15, horizontal: 25),
        textStyle: TextStyle(fontSize: 16),
      ),
    );
  }
}
