import 'package:college/Admin/adminPage.dart';
import 'package:college/Database/Database.dart';
import 'package:flutter/material.dart';

class DepartmentListApp extends StatelessWidget {
  const DepartmentListApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Department List',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const DepartmentListPage(),
    );
  }
}

class DepartmentListPage extends StatefulWidget {
  const DepartmentListPage({Key? key}) : super(key: key);

  @override
  _DepartmentListPageState createState() => _DepartmentListPageState();
}

class _DepartmentListPageState extends State<DepartmentListPage> {
  List<Map<String, dynamic>> departments = [];

  @override
  void initState() {
    super.initState();
    _fetchDepartments();
  }

  Future<void> _fetchDepartments() async {
    try {
      List<Map<String, dynamic>> fetchedDepartments = await DatabaseMethods().getDepartment();
      setState(() {
        departments = fetchedDepartments;
      });
    } catch (e) {
      setState(() {
        departments = [{'Department': 'Error loading departments', 'Did': null, 'Status': false}];
      });
    }
  }

  void _toggleDepartment(int index, bool value) {
    if (!value) {
      // If disabling, show confirmation dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Confirm Disable'),
            content: const Text(
                'If you disable this department, all related processes will be terminated. Do you want to proceed?'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  setState(() {
                    departments[index]['Status'] = value;
                  });
                  await DatabaseMethods().updateDepartment(
                    departments[index]['Did'],
                    {'Status': value},
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${departments[index]['Department']} department disabled.'),
                    ),
                  );
                },
                child: const Text('Confirm'),
              ),
            ],
          );
        },
      );
    } else {
      setState(() {
        departments[index]['Status'] = value;
      });
      DatabaseMethods().updateDepartment(
        departments[index]['Did'],
        {'Status': value},
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${departments[index]['Department']} department enabled.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Departments'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(context, MaterialPageRoute(builder:(context)=>Adminpage()));
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: departments.length,
          itemBuilder: (context, index) {
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              child: ListTile(
                title: Text(departments[index]['Department']),
                subtitle: Text(
                  departments[index]['Status'] ? 'Enabled' : 'Disabled',
                  style: TextStyle(
                    color: departments[index]['Status']
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
                trailing: Switch(
                  value: departments[index]['Status'],
                  onChanged: (bool value) {
                    _toggleDepartment(index, value);
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
