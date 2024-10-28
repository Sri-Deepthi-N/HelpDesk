import 'package:college/Database/Database.dart';
import 'package:college/User/userpage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:random_string/random_string.dart';

class Risepage extends StatefulWidget {
  const Risepage({Key? key}) : super(key: key);

  @override
  State<Risepage> createState() => _RisePageState();
}

class _RisePageState extends State<Risepage> {
  final TextEditingController _ticketController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String? _selectedDepartment;
  List<Map<String, dynamic>> _departments = [];
  String? currentUsername;
  String? currentUid;

  @override
  void initState() {
    super.initState();
    _fetchDepartments();
    _fetchCurrentUser();
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

  Future<String?> _getUserName(String? email) async {
    try {
      if (email == null) return null;
      List<Map<String, dynamic>> users = await DatabaseMethods().getUser();
      for (var user in users) {
        if (user['mailId'] == email) {
          return user['name'];
        }
      }
    } catch (e) {
      print('Error fetching user Name: $e');
    }
    return null;
  }

  Future<String?> _getUserid(String? email) async {
    try {
      if (email == null) return null;
      List<Map<String, dynamic>> users = await DatabaseMethods().getUser();
      for (var user in users) {
        if (user['mailId'] == email) {
          return user['uid'];
        }
      }
    } catch (e) {
      print('Error fetching user Id: $e');
    }
    return null;
  }

  Future<void> _fetchCurrentUser() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        currentUid = await _getUserid(user.email);
        currentUsername = await _getUserName(user.email);
      }
    } catch (e) {
      print('Error fetching current user: $e');
    }
  }

  void _raiseTicket() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Ticket Raised!')),
    );
  }

  String? _validateTicket(String value) {
    return (value.split(' ').length > 20) ? 'Ticket must not exceed 20 words.' : null;
  }

  String? _validateDescription(String value) {
    return (value.split(' ').length > 100) ? 'Description must not exceed 100 words.' : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            'Raise a Ticket ',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Userpage()));
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ticket (Max 20 words):',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 5),
            TextField(
              controller: _ticketController,
              maxLines: 2,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                errorText: _validateTicket(_ticketController.text),
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
            SizedBox(height: 20),
            Text(
              'Description (Max 100 words):',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                errorText: _validateDescription(_descriptionController.text),
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
            SizedBox(height: 20),
            Text(
              'Select Department:',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 5),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(5),
              ),
              child: _departments.isNotEmpty
                  ? DropdownButton<String>(
                value: _selectedDepartment,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedDepartment = newValue;
                  });
                },
                items: _departments
                    .where((dept) => dept['Status'] == true)
                    .map<DropdownMenuItem<String>>((Map<String, dynamic> dept) {
                  return DropdownMenuItem<String>(
                    value: dept['Department'],
                    child: Text(dept['Department']),
                  );
                }).toList(),
                hint: Text('Select a department'),
              ) : CircularProgressIndicator(),

            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    if (_validateTicket(_ticketController.text) == null &&
                        _validateDescription(_descriptionController.text) == null &&
                        _selectedDepartment != null) {
                      String? departmentId = _departments.firstWhere(
                              (dept) => dept['Department'] == _selectedDepartment)['Id'];

                      String id = randomAlphaNumeric(10);
                      String id1 = randomAlphaNumeric(10);

                      Map<String, dynamic> tokenInfo = {
                        "TId": id,
                        "Ticket": _ticketController.text,
                        "Description": _descriptionController.text,
                        "Department": _selectedDepartment,
                        "Did": departmentId,
                        "RaisedBy": currentUsername,
                        "RaisedOn": DateTime.now(),
                        "SolvedOn": "Not Solved",
                        "SolvedBy": "Not Solved",
                        "ClosedOn": "Not Closed",
                        "ClosedBy": "Not Closed",
                        "uid": currentUid,
                        "Ratings" : 0,
                      };
                      Map<String, dynamic> statusInfo = {
                        "Pid": id,
                        "SId": id1,
                        "Status": "P",
                        "Important" :false,
                      };
                      await DatabaseMethods().addStatus(statusInfo, id1);
                      await DatabaseMethods().addToken(tokenInfo, id).then((value) {
                        _raiseTicket();
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Userpage()));
                      });
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please fix the errors before submitting.')),
                      );
                    }
                  },
                  child: Text('Raise'),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Userpage()));
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