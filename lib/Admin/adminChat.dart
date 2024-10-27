import 'package:college/Database/Database.dart';
import 'package:college/admin/adminpage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:random_string/random_string.dart';

class Adminchat extends StatefulWidget {
  final String issueTitle;
  final String Tid; // Add Tid as a final variable to ChatPage
  final currentUid;
  final Status;
  final Aid;
  final bool Imp;
  Adminchat({required this.issueTitle, required this.Tid, required this.currentUid, required this.Status,required this.Aid,required this.Imp});

  @override
  _AdminchatState createState() => _AdminchatState();
}

class _AdminchatState extends State<Adminchat> {
  final TextEditingController _messageController = TextEditingController();
  List<Widget> _chatMessages = []; // To hold chat message widgets
  String? currentUid;
  String? Tid;
  List<String> Iid = [];
  String? Aid;
  String? Did; // Declare Did to store Department ID
  String? Cid;
  String? Status;
  bool? Imp;
  @override
  void initState() {
    super.initState();
    currentUid=widget.currentUid;
    Tid = widget.Tid;
    Aid =widget.Aid;
    Status = widget.Status;
    Imp =widget.Imp;
    _fetchDepartments();
    _fetchToken();
    _displayMessages();
  }

  Future<void> _fetchToken() async {
    try {
      List<Map<String, dynamic>> tokens = await DatabaseMethods().getTokenList();
      List<Map<String, dynamic>> currentUserToken = tokens.where((token) => token['TId'] == Tid).toList();

      setState(() {
        if (currentUserToken.isNotEmpty) {
          Did = currentUserToken[0]['Did']; // Extract Did from the first token
        } else {
          Did = null; // Reset Did if no token is found
        }
      });
    } catch (e) {
      setState(() {
        Did = null; // Reset Did on error
      });
    }
  }

  Future<void> _changestatus() async {
    List<Map<String, dynamic>> status = await DatabaseMethods().getStatusList();
    Map<String, dynamic> record = status.firstWhere(
          (item) => item['Pid'] == Tid,
      orElse: () => {}, // Default to an empty map if Tid is not found
    );
    String? Pid = record.isNotEmpty ? record['SId'] as String? : null;
    Map<String, dynamic> statusupdate = {
      'Status': "R",
    };
    try {
      await DatabaseMethods().updateStatus(Pid!, statusupdate);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reraised successfully!')),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating password: $e')),
      );
    }

  }

  Future<void> _MarkasImportant() async {
    List<Map<String, dynamic>> status = await DatabaseMethods().getStatusList();
    Map<String, dynamic> record = status.firstWhere(
          (item) => item['Pid'] == Tid,
      orElse: () => {}, // Default to an empty map if Tid is not found
    );
    String? Pid = record.isNotEmpty ? record['SId'] as String? : null;
    Map<String, dynamic> statusupdate = {
      'Important': Imp! ? false : true,
    };
    try {
      await DatabaseMethods().updateStatus(Pid!, statusupdate);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Imp! ? 'Mark not as Important': 'Mark as Important')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating password: $e')),
      );
    } finally {

      setState(() {});
    }
  }

  Future<void> _fetchDepartments() async {
    try {
      List<Map<String, dynamic>> departments = await DatabaseMethods().getDepartment();
      List<Map<String, dynamic>> currentUserDept = departments.where((dept) => dept['Id'] == Did).toList();
      setState(() {
        if (currentUserDept.isNotEmpty) {
          Iid = currentUserDept[0]['Iid']; // Extract Iid from the found department
        } else {
          Iid = []; // Reset Iid if no matching department is found
        }
      });
    } catch (e) {
      setState(() {
        Iid = [];
      });
    }
  }

  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }


  void _displayMessages() async {
    List<Map<String, dynamic>> chats = await DatabaseMethods().getChats();
    List<Map<String, dynamic>> currentUserToken =
    chats.where((token) => token['tid'] == Tid).toList();

    if (currentUserToken.isEmpty) {
      print("No chat found for the given Tid. Creating a new chat.");
      await _sendMessages;
      return;
    }
    Cid = currentUserToken[0]['cid'];

    // Sort messages by 'time' field
    List<Map<String, dynamic>> sortedMessages = List<Map<String, dynamic>>.from(
        currentUserToken[0]['messages']);
    sortedMessages.sort((a, b) => a['time'].compareTo(b['time']));

    List<Widget> messagesWidgets = [];

    for (var message in sortedMessages) {
      bool isSender = message['sentBy'] == currentUid;
      bool isSuperAdmin = Iid.contains(message['sentBy']);

      messagesWidgets.add(
        Align(
          alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isSender ? Colors.lightBlue[200] : Colors.grey[300],
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
                bottomLeft: isSender ? Radius.circular(8) : Radius.circular(0),
                bottomRight: isSender ? Radius.circular(0) : Radius.circular(8),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isSender) ...[
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.person,
                          color: Colors.pinkAccent,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        isSuperAdmin ? 'Incharge' : 'User',
                        style: TextStyle(color: Colors.black),
                      ),
                    ],
                  ),
                  SizedBox(width: 8),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 10),
                      Text(
                        message['message'],
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 5),
                      Align(
                        alignment:
                        isSender ? Alignment.centerRight : Alignment.centerLeft,
                        child: Text(
                          '${DateFormat('yyyy-MM-dd').format(message['time'].toDate())}\n${DateFormat('hh:mm a').format(message['time'].toDate())
                          }',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSender) ...[
                  SizedBox(width: 8),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person, color: Colors.green),
                      ),
                      SizedBox(height: 5),
                      Text('My Message', style: TextStyle(color: Colors.black)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    setState(() {
      _chatMessages = messagesWidgets;
    });
  }


  void _sendMessages() async {
    List<Map<String, dynamic>> chats = await DatabaseMethods().getChats();
    List<Map<String, dynamic>> currentUserToken = chats.where((token) => token['tid'] == Tid).toList();
    String chatId = randomAlphaNumeric(10);
    if(_messageController != null){
      if (currentUserToken == null || currentUserToken.isEmpty) {
        Map<String, dynamic> chatInfo = {
          "AdminId": Aid,
          "Cid": chatId,
          "ChatDate": DateTime.now(),
          "InchargeId": Iid,
          "Tid": Tid ?? "DefaultTid", // Use Tid from the widget
          "ChatBy": currentUid,
        };
        await DatabaseMethods().addChats(chatInfo, chatId);
        String msgId = randomAlphaNumeric(10);
        Map<String, dynamic> MessageInfo = {
          "Message": _messageController.text,
          "Time": DateTime.now(),
          "sentBy": currentUid,
        };
        await DatabaseMethods().addMessages(chatId, msgId, MessageInfo);
        print("Added");
        _messageController.clear();
      } else {
        String msgId = randomAlphaNumeric(10);
        Map<String, dynamic> MessageInfo = {
          "Message": _messageController.text,
          "Time": DateTime.now(),
          "sentBy": currentUid,
        };
        print("Updated");
        _messageController.clear();
        await DatabaseMethods().addMessages(Cid!, msgId, MessageInfo);
      }
    }
    else{
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Enter message to send')),
      );
    }
    _displayMessages();
  }

  void _handleTicketStatus(String status) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Reraise Ticket'),
          content: Text('Are you sure you want to mark this ticket as $status?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                status == 'Reraise' ?{
                  _changestatus(),
                  Navigator.pushReplacement(context, MaterialPageRoute(builder:(context)=>Adminpage())),
                }  :_MarkasImportant();
              },
              child: Text("$status"),
            ),
          ],
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.issueTitle),
        actions: [
          IconButton(
            icon: Icon(Icons.close),
            onPressed: () {
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) => Adminpage()));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scrollController,
              children: _chatMessages,

            ),
          ),

          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _scrollToBottom, // Call the method here
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                      ),
                      enabled: Status == 'Pending' || Status == 'Reraised', // Enable only if status is 'Pending'
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: Status == 'Pending' || Status == 'Reraised' ? _sendMessages : null,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => _handleTicketStatus(Imp! ? 'Mark not as Important': 'Mark as Important'),
                  child: Text(Imp! ? 'Mark not as Important': 'Mark as Important'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
                    textStyle: TextStyle(fontSize: 16),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _handleTicketStatus('Reraise'),
                  child: Text('Reraise'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
                    textStyle: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}