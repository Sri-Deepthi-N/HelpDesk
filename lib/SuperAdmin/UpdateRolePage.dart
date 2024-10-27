import 'package:college/Database/Database.dart';
import 'package:college/SuperAdmin/superadmin.dart';
import 'package:flutter/material.dart';

class UpdateRoleApp extends StatelessWidget {
  const UpdateRoleApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Update Role',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const UpdateRolePage(),
    );
  }
}

class UpdateRolePage extends StatefulWidget {
  const UpdateRolePage({Key? key}) : super(key: key);

  @override
  _UpdateRolePageState createState() => _UpdateRolePageState();
}

class _UpdateRolePageState extends State<UpdateRolePage> {
  List<Map<String, dynamic>> _users = [];
  String? selectedUser;
  String? selectedRole;
  bool isLoading = false; // Loading state

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      List<Map<String, dynamic>> users = await DatabaseMethods().getUser();
      setState(() {
        _users = users;
      });
    } catch (e) {
      print('Error fetching users: $e');
    }
  }

  Future<void> _changeRole() async {
    if (selectedUser != null && selectedRole != null) {
      setState(() {
        isLoading = true; // Start loading
      });
      Map<String, dynamic> updatedRole = {
        'role': selectedRole == 'SuperAdmin' ? 'SA': selectedRole == 'Admin' ? 'A' : selectedRole == 'Incharge' ? 'I' : 'U' ,
      };
      try {
        await DatabaseMethods().updateUser(selectedUser!, updatedRole);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Role updated successfully!')),
        );
        await _fetchUsers();
        selectedRole=null;
        selectedUser=null;
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating role: $e')),
        );
      } finally {
        setState(() {
          isLoading = false; // End loading
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both user and role.')),
      );
    }
  }

  List<String> roles = ['Admin', 'Incharge', 'SuperAdmin', 'User'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Role'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Clear selections before navigating back
            setState(() {
              selectedUser = null;
              selectedRole = null;
            });
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => SuperAdmin()),
            );
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select User:',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 10),
            _users.isNotEmpty
                ? Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black, width: 1.0),
                borderRadius: BorderRadius.circular(5.0),
              ),
              padding: EdgeInsets.symmetric(horizontal: 12.0),
              child: DropdownButton<String>(
                value: selectedUser,
                isExpanded: true,
                underline: SizedBox(),
                hint: const Text('Select a user'),
                items: _users.map<DropdownMenuItem<String>>((Map<String, dynamic> user) {
                  return DropdownMenuItem<String>(
                    value: user['uid'],
                    child: Text(user['uid']),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedUser = newValue;
                  });
                },
              ),
            )
                : const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 20),
            const Text(
              'Select Role:',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black, width: 1.0),
                borderRadius: BorderRadius.circular(5.0),
              ),
              padding: EdgeInsets.symmetric(horizontal: 12.0),
              child: DropdownButton<String>(
                value: selectedRole,
                hint: const Text('Choose Role'),
                isExpanded: true,
                underline: SizedBox(),
                items: roles.map((String role) {
                  return DropdownMenuItem<String>(
                    value: role,
                    child: Text(role),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedRole = newValue;
                  });
                },
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: isLoading ? null : _changeRole, // Disable button while loading
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Update'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      selectedUser = null; // Clear user selection
                      selectedRole = null; // Clear role selection
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
