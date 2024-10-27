import 'package:college/Admin/adminChangePassword.dart';
import 'package:college/Admin/adminChat.dart';
import 'package:college/Admin/departmentList.dart';
import 'package:college/Admin/report.dart';
import 'package:college/Admin/updateIncharge.dart';
import 'package:college/Auth/AuthFunctions.dart';
import 'package:college/Database/Database.dart';
import 'package:college/admin/ticketPAge.dart';
import 'package:college/admin/adminrise.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Adminpage(),
  ));
}

class Adminpage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AdminHomePage();
  }
}

class AdminHomePage extends StatefulWidget {
  @override
  _AdminHomePageState createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  List<String> importantTickets = []; // Track important tickets
  String? currentUsername;
  String? currentUid;
  String? Status;
  String? Aid;
  String? Important;
  List<Map<String, dynamic>> _status = [];
  List<Map<String, dynamic>> _token = [];
  List<Map<String, dynamic>> mergedList = [];

  @override
  void initState(){
    super.initState();
    getOnTheLoad();

  }

  void getOnTheLoad() async {
    await _fetchStatus();
    await _fetchToken();
    _mergeLists();
    await _fetchCurrentUser();
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
    for (var token in _token) {
      if (token['TId'] == null || token['Department'] == null) continue;
      var matchingStatus = _status.firstWhere(
            (status) => status['Pid'] == token['TId'],
        orElse: () => {'Status': 'No Status', 'SolvedOn': 'Not Solved', 'ClosedOn': 'Not Closed'},
      );
      mergedList.add({
        'RaisedOn': token['RaisedOn'] ?? 'Not Raised',
        'Problem': token['Problem'] ?? 'No Problem Description',
        'TId': token['TId'] ?? 'No TId',
        'Department': token['Department'] ?? 'No Department',
        'Status':matchingStatus['Status']=='P' ? 'Pending' : matchingStatus['Status']=='S' ? 'Solved' : matchingStatus['Status']=='C' ? 'Closed': matchingStatus['Status']=='R' ?'Reraised'  : 'No Status',
        'Important':matchingStatus['Important'] ?? false,
        'Ratings': token['Ratings'],
      });
    }
  }

  Future<String?> _getUserName(String? email) async {
    try {
      if (email == null) return null;

      List<Map<String, dynamic>> users = await DatabaseMethods().getUser(); // Fetch users from your database
      for (var user in users) {
        if (user['mailId'] == email) {
          return user['name']; // Return the name if email matches
        }
      }
    } catch (e) {
      print('Error fetching username: $e');
    }
    return null;
  }

  Future<String?> _getUserId(String email) async {
    try {
      List<Map<String, dynamic>> users = await DatabaseMethods().getUser();

      var user = users.firstWhere(
            (user) => user['mailId'] == email,
      );
      var aid = users.firstWhere(
            (user) => user['role'] == "A",
      );
      if (user != null) {
        Aid = aid['uid'].toString(); // Assign Aid
        return user['uid']; // Return the user ID
      }
    }catch (e) {
      print('Error fetching user ID: $e');
    }
    return null;
  }
  // Method to fetch the current logged-in user and their username
  Future<void> _fetchCurrentUser() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String email = user.email ?? '';
        currentUid = await _getUserId(email);
        String? username = await _getUserName(user.email);
        if (mounted) {
          setState(() {
            currentUsername = username; // Update username and rebuild UI
          });
        }
      }
    } catch (e) {
      print('Error fetching current user: $e');
    }
  }

  getontheload() async {
    setState(() {});
    _fetchCurrentUser();
  }


  Widget allToken() {
    _mergeLists(); // Ensure mergedList is populated
    mergedList.sort((a, b) => a["RaisedOn"].compareTo(b["RaisedOn"]));
    if (mergedList.isEmpty) {
      return Center(child: Text('No Issues found'));
    }
    mergedList.sort((a, b) => a["RaisedOn"].compareTo(b["RaisedOn"]));

    return ListView.builder(
      itemCount: mergedList.length,
      itemBuilder: (context, index) {
        var item = mergedList[index];
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          child: Column(  // Use Column to stack elements vertically
            crossAxisAlignment: CrossAxisAlignment.start, // Align items to start
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween, // Adjust alignment as needed
                children: [
                  Icon(
                    item["Important"] == true ? Icons.star : Icons.star_border,
                    color: item["Important"] == true ? Colors.yellow[600] : Colors.black,
                  ),
                  SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      item["Problem"],
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item["Department"],
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Adminchat(
                            issueTitle: item["Problem"].toString(),
                            Tid: item['TId'].toString(),
                            currentUid: currentUid,
                            Status: item['Status'].toString(),
                            Aid: Aid,
                            Imp: item['Important'],
                          ),
                        ),
                      );
                      // Call _mergeLists and wrap in setState to trigger a UI rebuild
                      setState(() {
                        _fetchStatus();
                        _mergeLists();
                        allToken();
                      });
                    },
                    child: Text(
                      item["Status"] ?? "Status not available",
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              if (item["Status"] == 'Closed') // Check if the status is 'Closed'
                Row(
                  children: [
                    StarRating(
                      rating: (item['Ratings'] ?? 0).toDouble(), // Convert rating to double
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );

  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome ${currentUsername ?? 'User'}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => Adminrise()),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            SizedBox(height: 50),
            ListTile(
              leading: Icon(Icons.task),
              title: Text('To Solve'),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => Adminpage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.report),
              title: Text('Report'),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => Report()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.lock),
              title: Text('Change Password'),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => AdminChangePassword()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.confirmation_number),
              title: Text('My Ticket'),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => Ticketpage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.supervised_user_circle),
              title: Text('Update Incharge'),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => UpdateInchargeApp()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.departure_board),
              title: Text('Enable Department'),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => DepartmentListApp()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
              onTap: () {
                AuthServices.logout(context);
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const [
                Text(
                  'Issues',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Department',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Status',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Expanded(child: allToken()),
          ],
        ),
      ),
    );
  }
}

class StarRating extends StatelessWidget {
  final double rating;

  const StarRating({
    Key? key,
    required this.rating,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.yellow,
        );
      }),
    );
  }
}

