import 'package:college/Database/Database.dart';
import 'package:college/Incharge/incharge.dart';
import 'package:flutter/material.dart';
import 'package:random_string/random_string.dart';
import 'package:intl/intl.dart'; // For date formatting

class Inchrgechat extends StatefulWidget {
  final String issueTitle;
  final String Tid;
  final currentUid;
  final Status;
  final Aid;
  const Inchrgechat({required this.issueTitle, required this.Tid, required this.currentUid, required this.Status,required this.Aid});
  @override
  State<Inchrgechat> createState() => _InchrgechatState();
}

class _InchrgechatState extends State<Inchrgechat> {
  final TextEditingController _messageController = TextEditingController();
  List<Widget> _chatMessages = [];
  String? currentUid;
  String? Tid;
  List<String> Iid = [];
  String? Aid;
  String? Did;
  String? Cid;
  String? Status;
  @override
  void initState() {
    super.initState();
    currentUid=widget.currentUid;
    Tid = widget.Tid;
    Aid =widget.Aid;
    Status = widget.Status;
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
          Did = currentUserToken[0]['Did'];
        } else {
          Did = null;
        }
      });
    } catch (e) {
      setState(() {
        Did = null;
      });
    }
  }

  Future<void> _fetchDepartments() async {
    try {
      List<Map<String, dynamic>> departments = await DatabaseMethods().getDepartment();
      List<Map<String, dynamic>> currentUserDept = departments.where((dept) => dept['Id'] == Did).toList();
      print(currentUid);
      setState(() {
        if (currentUserDept.isNotEmpty) {
          Iid = currentUserDept[0]['Iid'];
        } else {
          Iid = [];
        }
      });
    } catch (e) {
      setState(() {
        Iid = [];
      });
    }
  }


  Future<void> _changestatus(String Currstatus) async {

    List<Map<String, dynamic>> status = await DatabaseMethods().getStatusList();
    Map<String, dynamic> record = status.firstWhere(
          (item) => item['Pid'] == Tid,
      orElse: () => {},
    );
    String? Pid = record.isNotEmpty ? record['SId'] as String? : null;
    Map<String, dynamic> updateddata = {
      'ClosedOn': DateTime.now(),
      'ClosedBy' :currentUid,
    };
    Map<String, dynamic> statusupdate = {
      'Status': Currstatus  == 'Completed'?'CM':'S',
    };
    try {
      await DatabaseMethods().updateToken(Tid!, updateddata);
      await DatabaseMethods().updateStatus(Pid!, statusupdate);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$Currstatus successfully!')),
      );
      Currstatus  == 'Completed'? Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Incharge(),),) : null;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating Status: $e')),
      );
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
      print("No chat found. Creating a new chat.");
      await _sendMessages;
      return;
    }
    Cid = currentUserToken[0]['cid'];

    List<Map<String, dynamic>> sortedMessages = List<Map<String, dynamic>>.from(
        currentUserToken[0]['messages']);
    sortedMessages.sort((a, b) => a['time'].compareTo(b['time']));

    List<Widget> messagesWidgets = [];

    for (var message in sortedMessages) {
      bool isSender = message['sentBy'] == currentUid;
      bool isAdmin = message['sentBy'] == Aid;
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
                        isAdmin ? 'Admin' : 'User',
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
                      Text(
                        message['message'],
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 5),
                      Align(
                        alignment:
                        isSender ? Alignment.centerRight : Alignment.centerLeft,
                        child: Text(
                          '${DateFormat('yyyy-MM-dd').format(message['time'].toDate())}\n'
                          '${DateFormat('hh:mm a').format(message['time'].toDate())}',
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
          "Tid": Tid ?? "DefaultTid",
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


  void _handleTicketStatus(String Currstatus) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('$Currstatus Ticket'),
          content: Text('Are you sure you want to mark this ticket as $Currstatus?'),
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
                Currstatus == 'complete' ? _changestatus("Completed"):_changestatus("Solved");
                Navigator.pushReplacement(context, MaterialPageRoute(builder:(context)=>Incharge()));
              },
              child: Text("$Currstatus"),
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
                  MaterialPageRoute(builder: (context) => Incharge()));
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
                  onPressed: () => Status == 'Pending' || Status == 'Reraised' ? _handleTicketStatus('solve') : null,
                  child: Text('Solved'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
                    textStyle: TextStyle(fontSize: 16),
                    backgroundColor: Status == 'Pending' || Status == 'Reraised' ? null : Colors.grey,
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Status == 'Pending' || Status == 'Reraised' || Status == 'Solved' ?_handleTicketStatus('complete') : null,
                  child: Text('Completed'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
                    textStyle: TextStyle(fontSize: 16),
                    backgroundColor: Status == 'Pending' || Status == 'Reraised'|| Status == 'Solved' ? null : Colors.grey,
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