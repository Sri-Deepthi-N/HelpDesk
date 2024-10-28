import 'package:college/Auth/AuthFunctions.dart';
import 'package:college/Database/Database.dart';
import 'package:college/Incharge/InchargeMyTicket.dart';
import 'package:college/Incharge/inchargeChat.dart';
import 'package:college/Incharge/inchargeRise.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Incharge extends StatefulWidget {
  const Incharge({Key? key}) : super(key: key);

  @override
  State<Incharge> createState() => _InchargeState();
}

class _InchargeState extends State<Incharge> {
  String? currentUsername;
  String? currentUid;
  String? Aid;
  String? Status;
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
    allToken();
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
        'Ticket': token['Ticket'] ?? 'No Ticket Description',
        'Department': token['Department'] ?? 'No Department',
        'TId': token['TId'] ?? 'No TId',
        'Ratings': token['Ratings'],
        'RaisedOn': token['RaisedOn'],
        'Status': matchingStatus['Status']=='P' ? 'Pending' :
                  matchingStatus['Status']=='S' ? 'Solved' :
                  matchingStatus['Status']=='C' ? 'Closed':
                  matchingStatus['Status']=='R' ?'Reraised'  :
                  matchingStatus['Status']=='CM' ?'Completed':'No Status',
      });
    }
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
        Aid = aid['uid'].toString();
        return user['uid'];
      }
    } catch (e) {
      print('Error fetching user ID: $e');
    }
    return null;
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

  Future<void> _fetchCurrentUser() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String email = user.email ?? '';
        currentUid = await _getUserId(email);
        String? username = await _getUserName(user.email);
        if (mounted) {
          setState(() {
            currentUsername = username;
          });
        }
      }
    } catch (e) {
      print('Error fetching current user: $e');
    }
  }
  Widget allToken() {
    _mergeLists();
    if (mergedList.isEmpty) {
      return Center(child: Text('No Ticket found.'));
    }
    mergedList.sort((a, b) => a["RaisedOn"].compareTo(b["RaisedOn"]));
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
                      item["Ticket"],
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
                          builder: (context) => Inchrgechat(
                            issueTitle: item["Ticket"],
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
              if (item["Status"] == 'Closed')
                Row(
                  children: [
                    StarRating(
                      rating: (item['Ratings']).toDouble(),
                    ),
                  ],
                ),
              //print(item['Ratings']),
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
                MaterialPageRoute(builder: (context) => Inchargerise()),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            SizedBox(height: 50),
            ListTile(
              leading: Icon(Icons.task_alt),
              title: Text('To Solve'),
              onTap: () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Incharge()));
              },
            ),
            ListTile(
              leading: Icon(Icons.confirmation_number),
              title: Text('My Ticket'),
              onTap: () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Inchargemyticket()));
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
        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.05), // Dynamic padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const [
                Text(
                  'Ticket',
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
