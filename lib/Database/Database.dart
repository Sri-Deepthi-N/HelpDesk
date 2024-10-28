import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseMethods {
  // Chat Collection
  //add Chat
  Future<void> addChats(Map<String, dynamic> chatInfo, String id) async {
    await FirebaseFirestore.instance
        .collection("Chats")
        .doc(id)
        .set(chatInfo);
  }
  Future<void> addMessages( String chatid,String Msgid,Map<String, dynamic> chatInfo) async {
    await FirebaseFirestore.instance
        .collection("Chats")
        .doc(chatid)
        .collection("Chat")
        .doc(Msgid)
        .set(chatInfo);
    print("Data added to subcollection successfully!");
  }
  // Get Chat
  Future<List<Map<String, dynamic>>> getChats() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection("Chats")
        .get();

    List<Future<Map<String, dynamic>>> chatFutures = snapshot.docs.map((doc) async {
      QuerySnapshot messagesSnapshot = await doc.reference.collection("Chat").get();
      List<Map<String, dynamic>> messages = messagesSnapshot.docs.map((messageDoc) {
        return {
          'message': messageDoc['Message'].toString(),
          'time': messageDoc['Time'],
          'sentBy': messageDoc['sentBy'].toString(),
        };
      }).toList();

      return {
        'adminId': doc['AdminId'].toString(),
        'chatDate': doc['ChatDate'],
        'inchargeId': List<String>.from(doc['InchargeId'] ?? []),
        'tid': doc['Tid'].toString(),
        'cid':doc['Cid'].toString(),
        'chatBy': doc['ChatBy'].toString(),
        'messages': messages,
      };
    }).toList();

    List<Map<String, dynamic>> chats = await Future.wait(chatFutures);
    return chats;
  }
  //Update Chat
  Future<void> updateChats(String id, Map<String, dynamic> chatsInfo) async {
    await FirebaseFirestore.instance
        .collection("Chats")
        .doc(id)
        .update(chatsInfo);
  }

  // Department Collection
  //Add Department
  Future<void> addDepartment(Map<String, dynamic> deptInfo, String id) async {
    await FirebaseFirestore.instance
        .collection("Department")
        .doc(id)
        .set(deptInfo);
  }
  //Get Department
  Future<List<Map<String, dynamic>>> getDepartment() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection("Department")
        .get();
    List<Map<String, dynamic>> departments = snapshot.docs.map((doc) {
      return {
        'Department': doc['Department'].toString(),
        'Id': doc['Id'].toString(),
        'Status': doc['Status'],
        'Iid': List<String>.from(doc['Iid'] ?? []),
      };
    }).toList();
    return departments;
  }

  //Update Department
  Future<void> updateDepartment(String id, Map<String, dynamic> deptInfo) async {
    await FirebaseFirestore.instance
        .collection("Department")
        .doc(id)
        .update(deptInfo);
  }


  // Status Collection
  //Add Status
  Future<void> addStatus(Map<String, dynamic> statusInfo, String id) async {
    await FirebaseFirestore.instance
        .collection("Status")
        .doc(id)
        .set(statusInfo);
  }
  //Get Status
  Future<List<Map<String, dynamic>>> getStatusList() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection("Status")
          .get();
      List<Map<String, dynamic>> status = snapshot.docs.map((doc) {
        return {
          'Pid': doc['Pid'] ?? '',
          'SId': doc['SId'] ?? '',
          'Status': doc['Status'] ?? '',
          'Important': doc['Important'] as bool,
        };
      }).toList();
      return status;
    } catch (e) {
      print("Error fetching users: $e");
      return []; // Return an empty list on error
    }
  }
  //Update Status
  Future<void> updateStatus(String id, Map<String, dynamic> statusInfo) async {
    await FirebaseFirestore.instance
        .collection("Status")
        .doc(id)
        .update(statusInfo);
  }


  // Token Collection
  //Add Token
  Future<void> addToken(Map<String, dynamic> tokenInfo, String id) async {
    await FirebaseFirestore.instance
        .collection("Token")
        .doc(id)
        .set(tokenInfo);
  }
  //Get Token
  Future<List<Map<String, dynamic>>> getTokenList() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection("Token")
        .get();

    List<Map<String, dynamic>> Token = snapshot.docs.map((doc) {
      return {
        "TId": doc['TId'] ?? '',
        "Ticket":doc['Ticket'] ?? '',
        "Description": doc['Description'] ?? '',
        "Department": doc['Department'] ?? '',
        "Did": doc['Did'] ?? '',
        "RaisedBy": doc['RaisedBy'] ?? '',
        "RaisedOn": doc['RaisedOn'] ?? '',
        "SolvedOn" : doc['SolvedOn'] ?? '',
        "SolvedBy":doc['SolvedBy'] ?? '',
        "ClosedOn" : doc['ClosedOn'] ?? '',
        "ClosedBy":doc['ClosedBy'] ?? '',
        "uid": doc['uid'] ?? '',
        "Ratings": doc['Ratings'] ?? '',
      };
    }).toList();
    return Token;
  }

//Update Token
  Future<void> updateToken(String id, Map<String, dynamic> tokenInfo) async {
    await FirebaseFirestore.instance
        .collection("Token")
        .doc(id)
        .update(tokenInfo);
  }


  // User Collection
  //Get User
  Future<List<Map<String, dynamic>>> getUser() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection("UserDetails")
          .get();
      // Process the snapshot into a list of maps
      List<Map<String, dynamic>> users = snapshot.docs.map((doc) {
        return {
          'mailId': doc['mailId'] ?? '',
          'name': doc['name'] ?? '',
          'password': doc['password'] ?? '',
          'phoneNo': doc['phoneNo'] ?? '',
          'role': doc['role'] ?? '',
          'uid': doc['uid'] ?? '',
        };
      }).toList();
      return users;
    } catch (e) {
      print("Error fetching users: $e");
      return []; // Return an empty list on error
    }
  }
//Update User
  Future<void> updateUser(String id, Map<String, dynamic> userInfo) async {
    try {
      await FirebaseFirestore.instance
          .collection("UserDetails")
          .doc(id)
          .update(userInfo);
      print("User details updated successfully.");
    } catch (e) {
      print("Error updating user details: $e");
    }
  }
  //Delete User
  Future<void> deleteUser(String? id) async {
    if (id == null) {
      print("Error: Document ID is null");
      return;
    }
    try {
      print("Attempting to delete user with ID: $id");
      await FirebaseFirestore.instance
          .collection("UserDetails")
          .doc(id)
          .delete();
      print("User deleted successfully.");
    } catch (e) {
      print("Error deleting user: $e");
    }
  }

}
