import 'package:college/Database/Database.dart';
import 'package:college/SuperAdmin/superadmin.dart';
import 'package:flutter/material.dart';
import 'package:random_string/random_string.dart';

// Example Department Page
class DepartmentPage extends StatefulWidget {
  @override
  _DepartmentPageState createState() => _DepartmentPageState();
}

class _DepartmentPageState extends State<DepartmentPage> {
  final TextEditingController _departmentController = TextEditingController();
  List<Map<String, dynamic>> _departments = []; // List to store department names and IDs
  List<String> _incharges = []; // Change to List<String> for dropdown
  String? selectedInCharge;
  List<String> selectedInCharges = [];

  @override
  void initState() {
    super.initState();
    _fetchDepartments(); // Fetch departments when the widget is initialized
    _getIncharges(); // Fetch in-charges when the widget is initialized
  }

  // Fetch departments from the database
  Future<void> _fetchDepartments() async {
    try {
      List<Map<String, dynamic>> departments = await DatabaseMethods()
          .getDepartment();
      setState(() {
        _departments = departments;
      });
    } catch (e) {
      setState(() {
        _departments =
        [{'Department': 'Error loading departments', 'Did': null}];
      });
    }
  }

  // Fetch users from the database


  // Fetch In-Charge users
  Future<void> _getIncharges() async {
    try {
      List<Map<String, dynamic>> users = await DatabaseMethods()
          .getUser(); // Fetch all users

      setState(() {
        _incharges = users
            .where((user) =>
        user['role'] == 'I')
            .map((
            user) => user['uid'])
            .cast<String>()
            .toList();
      });
    } catch (e) {
      print('Error fetching in-charges: $e');
    }
  }

  // Check if department already exists using 'any'
  bool _departmentExists(String departmentName) {
    return _departments.any((department) =>
    department['Department'] == departmentName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Department Management'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (context) => SuperAdmin()));
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add Department',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _departmentController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Department Name',
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Update In-Charge',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey,
                  width: 1.0,
                ),
                borderRadius: BorderRadius.circular(5.0),
              ),
              padding: EdgeInsets.symmetric(horizontal: 12.0),
              child: DropdownButton<String>(
                value: null, // Set null to allow multi-selection without default selection
                hint: Text(
                  selectedInCharges.isNotEmpty
                      ? selectedInCharges.join(', ') // Display selected items
                      : 'Select In-Charge',
                ),
                isExpanded: true,
                underline: SizedBox(), // Remove the default underline
                items: _incharges.map((String inCharge) {
                  return DropdownMenuItem<String>(
                    value: inCharge,
                    child: StatefulBuilder(
                      builder: (context, setState) {
                        return CheckboxListTile(
                          title: Text(inCharge),
                          value: selectedInCharges.contains(inCharge),
                          onChanged: (bool? selected) {
                            setState(() {
                              if (selected == true) {
                                selectedInCharges.add(inCharge);
                              } else {
                                selectedInCharges.remove(inCharge);
                              }
                            });
                            // Trigger UI rebuild to update the hint with selected names
                            this.setState(() {});
                          },
                        );
                      },
                    ),
                  );
                }).toList(),
                onChanged: (_) {}, // No action needed here as we're managing the selection in CheckboxListTile
              )
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    String departmentName = _departmentController.text.trim();
                    if (departmentName.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please enter a department name')),
                      );
                      return;
                    }

                    // Ensure selectedInCharges are not empty before adding department
                    if (!_departmentExists(departmentName) && selectedInCharges.isNotEmpty) {
                      String id = randomAlphaNumeric(10);
                      Map<String, dynamic> DeptInfo = {
                        "Id": id,
                        "Department": departmentName,
                        "Status": true,
                        "Iid": selectedInCharges, // Store all selected in-charges
                      };
                      await DatabaseMethods().addDepartment(DeptInfo, id).then((value) {
                        _departmentController.clear();
                        selectedInCharges.clear();
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => SuperAdmin()));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Department added successfully')),
                        );
                        _fetchDepartments();
                      });
                    } else if (selectedInCharges.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please select at least one in-charge')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Department already exists')),
                      );
                    }
                  },
                  child: Text('Add'),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    _departmentController.clear();
                    selectedInCharges.clear(); // Clear selected items on cancel
                  },
                  child: Text('Cancel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}