import 'package:college/Admin/adminChat.dart';
import 'package:college/Database/Database.dart';
import 'package:college/admin/adminpage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Ticketpage extends StatefulWidget {
  const Ticketpage({Key? key}) : super(key: key);

  @override
  State<Ticketpage> createState() => _TicketpageState();
}

class _TicketpageState extends State<Ticketpage> {
  String? currentUsername;
  String? currentUid;
  String? Status;
  String? Aid;
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
      if (token['uid'] != currentUid) continue;

      if (token['TId'] == null || token['Department'] == null) continue;
      var matchingStatus = _status.firstWhere(
            (status) => status['Pid'] == token['TId'],
        orElse: () => {'Status': 'No Status', 'SolvedOn': 'Not Solved', 'ClosedOn': 'Not Closed'},
      );
      mergedList.add({
        'RaisedOn':token ['RaisedOn'] ?? 'Not Raised' ,
        'Important':token ['Important'] ?? false ,
        'Ticket': token['Ticket'] ?? 'No Ticket Description',
        'Department': token['Department'] ?? 'No Department',
        'Status': matchingStatus['Status']=='P' ? 'Pending' :
                  matchingStatus['Status']=='S' ? 'Solved' :
                  matchingStatus['Status']=='C' ? 'Closed':
                  matchingStatus['Status']=='R' ?'Reraised'  :
                  matchingStatus['Status']=='CM' ?'Completed'  :'No Status',
        'TId': token['TId'],
      });
    }
  }

  Future<void> _fetchCurrentUser() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String email = user.email ?? '';
        currentUid = await _getUserId(email);

        if (user.email != null) {
          String? username = await _getUserName(user.email!);
          if (mounted) {
            setState(() {
              currentUsername = username;
            });
          }
        }
      }
    } catch (e) {
      print('Error fetching current user: $e');
    }
  }


  Future<String?> _getUserName(String email) async {
    try {
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
          child: Row(
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
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Adminchat(
                        issueTitle: item["Ticket"].toString(),
                        Tid: item['TId'].toString(),
                        currentUid: currentUid,
                        Status: item['Status'].toString(),
                        Aid: Aid,
                        Imp: item['Important'],
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Ticket'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => Adminpage()),
            );
          },
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
