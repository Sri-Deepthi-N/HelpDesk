import 'package:college/Admin/adminPage.dart';
import 'package:college/Database/Database.dart';
import 'package:flutter/material.dart';

class UpdateInchargeApp extends StatelessWidget {
  const UpdateInchargeApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Update Incharge',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const UpdateInchargePage(),
    );
  }
}

class UpdateInchargePage extends StatefulWidget {
  const UpdateInchargePage({Key? key}) : super(key: key);

  @override
  _UpdateInchargePageState createState() => _UpdateInchargePageState();
}

class _UpdateInchargePageState extends State<UpdateInchargePage> {
  List<Map<String, dynamic>> _departments = [];
  List<String> selectedInCharges = [];
  List<String> _incharges = [];
  String? _selectedDepartment; // This holds the ID of the selected department

  @override
  void initState() {
    super.initState();
    _fetchDepartments(); // Fetch departments when the widget is initialized
    _getIncharges();
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

  Future<void> _getIncharges() async {
    try {
      List<Map<String, dynamic>> users = await DatabaseMethods().getUser(); // Fetch all users
      setState(() {
        _incharges = users
            .where((user) => user['role'] == 'I')
            .map((user) => user['uid'])
            .cast<String>()
            .toList();
      });
    } catch (e) {
      print('Error fetching in-charges: $e');
    }
  }

  Future<String?> _getId(String dept) async {
    try {
      List<Map<String, dynamic>> departments = await DatabaseMethods().getDepartment(); // Fetch all departments
      // Find the ID of the selected department
      String? id = departments.firstWhere(
              (department) => department['Department'] == dept, // Match by department name
          orElse: () => {'Did': null} // Return a default value if not found
      )['Did']; // Return the department ID
      return id; // Return the ID
    } catch (e) {
      print('Error fetching department ID: $e');
      return null; // Return null on error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Incharge'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Adminpage())); // Go back to the previous screen
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Department:',
              style: TextStyle(fontSize: 18),
            ),
            _departments.isNotEmpty
                ? Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey,
                  width: 1.0,
                ),
                borderRadius: BorderRadius.circular(5.0),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: DropdownButton<String>(
                value: _selectedDepartment,
                hint: const Text('Select a department'),
                isExpanded: true,
                underline: SizedBox(),
                items: _departments.map<DropdownMenuItem<String>>((Map<String, dynamic> dept) {
                  return DropdownMenuItem<String>(
                    value: dept['Department'], // Use department name for display
                    child: Text(dept['Department']),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedDepartment = newValue; // Store selected department name
                    _getId(newValue!); // Fetch the ID of the selected department
                  });
                },
              ),
            )
                : const CircularProgressIndicator(),
            const SizedBox(height: 20),
            const Text(
              'Select Incharge:',
              style: TextStyle(fontSize: 18),
            ),
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.black,
                  width: 1.0,
                ),
                borderRadius: BorderRadius.circular(5.0),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
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
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    if (_selectedDepartment != null && selectedInCharges  != null) {
                      // Prepare department info to update
                      Map<String, dynamic> deptInfo = {
                        'Iid': selectedInCharges, // Set the new in-charge
                      };

                      // Get the department ID
                      String? deptId = await _getId(_selectedDepartment!);
                      if (deptId != null) {
                        // Perform the update operation here
                        try {
                          await DatabaseMethods().updateDepartment(deptId, deptInfo); // Pass department ID
                          // Show success message
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Incharge updated successfully!')),
                          );
                          // Navigate back to the admin page
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Adminpage()));
                        } catch (e) {
                          // Handle any errors during the update
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error updating incharge: $e')),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Error fetching department ID.'),
                          ),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select both department and incharge.'),
                        ),
                      );
                    }
                  },
                  child: const Text('Update'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedDepartment = null; // Clear department selection
                      selectedInCharges = []; // Clear incharge selection
                    });
                  },
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
