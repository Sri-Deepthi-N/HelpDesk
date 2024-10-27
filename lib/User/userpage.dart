import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:college/Auth/AuthFunctions.dart';
import 'package:college/Database/Database.dart';
import 'package:college/User/chatapp.dart';
import 'package:college/User/risepage.dart';
import 'package:college/User/userChangePassword.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Userpage extends StatefulWidget {
  const Userpage({Key? key}) : super(key: key);

  @override
  State<Userpage> createState() => _UserpageState();
}

class _UserpageState extends State<Userpage> {
  Stream<QuerySnapshot>? tokenStream;
  String? currentUsername;
  String? currentUid;
  String? Aid;

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
    await _fetchCurrentUser();
    _mergeLists();
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
      if (token['uid'] != currentUid) continue;

      if (token['TId'] == null || token['Department'] == null) continue;

      var matchingStatus = _status.firstWhere(
            (status) => status['Pid'] == token['TId'],
        orElse: () => {'Status': 'No Status', 'SolvedOn': 'Not Solved', 'ClosedOn': 'Not Closed'},
      );

      mergedList.add({
        'RaisedOn': token['RaisedOn'] ?? 'Not Raised',
        'Problem': token['Problem'] ?? 'No Problem Description',
        'Department': token['Department'] ?? 'No Department',
        'Status': matchingStatus['Status'] == 'P' ? 'Pending'
            : matchingStatus['Status'] == 'S' ? 'Solved'
            : matchingStatus['Status'] == 'C' ? 'Closed'
            : matchingStatus['Status'] == 'R' ? 'Reraised'
            : 'No Status',
        'TId': token['TId'],
        'Ratings': token['Ratings'], // Initialize rating
      });
    }
  }

  Future<void> _fetchCurrentUser() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String email = user.email ?? '';
        currentUid = await _getUserId(email);
        currentUsername = await _getUserName(email);

        if (currentUid != null) {
          setState(() {
            tokenStream = FirebaseFirestore.instance
                .collection('Token')
                .where('uid', isEqualTo: currentUid)
                .snapshots();
          });
        }
      }
    } catch (e) {
      print('Error fetching current user: $e');
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
      print('Error fetching username: $e');
    }
    return null;
  }

  Future<String?> _getUserId(String email) async {
    try {
      List<Map<String, dynamic>> users = await DatabaseMethods().getUser();
      var user = users.firstWhere((user) => user['mailId'] == email);
      var aid = users.firstWhere((user) => user['role'] == "A");

      if (user != null) {
        Aid = aid['uid'].toString();
        return user['uid'];
      }
    } catch (e) {
      print('Error fetching user ID: $e');
    }
    return null;
  }

  Widget allToken() {
    // Sort the list by the "RaisedOn" field in descending order
    mergedList.sort((a, b) => a["RaisedOn"].compareTo(b["RaisedOn"]));

    if (mergedList.isEmpty) {
      return Center(child: Text('No problems found for this user.'));
    }

    return ListView.builder(
      itemCount: mergedList.length,
      itemBuilder: (context, index) {
        var item = mergedList[index];
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
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
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatPage(
                            issueTitle: item["Problem"],
                            Tid: item['TId'],
                            currentUid: currentUid,
                            Status: item['Status'],
                            Aid: Aid,
                          ),
                        ),
                      );
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
    final size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome ${currentUsername ?? 'User'}'),
      ),
      body: Padding(
        padding: EdgeInsets.all(size.width * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Userchangepassword(),
                      ),
                    );
                  },
                  child: const Text(
                    'Change Password',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 18,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    AuthServices.logout(context);
                  },
                  child: const Text(
                    'Logout',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
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
            Align(
              alignment: Alignment.centerRight,
              child: _buildAddButton(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Risepage()),
        );
      },
      style: ElevatedButton.styleFrom(
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(10),
        backgroundColor: Colors.blue,
      ),
      child: const Icon(Icons.add, size: 24, color: Colors.white),
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
