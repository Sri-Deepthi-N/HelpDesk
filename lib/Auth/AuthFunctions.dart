import 'package:college/Auth/LoginPage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthServices {


  // Method to handle user sign-in
  static signinUser(String email, String password, BuildContext context) async {
    try {
      // Sign in with email and password
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      // Notify the user about successful login
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('You are Logged in')));
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase errors
      if (e.code == 'user-not-found') {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No user Found with this Email')));
      } else if (e.code == 'wrong-password') {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Password did not match')));
      }
    }
  }

  signupUser(String email, String password, BuildContext context) async {
    try {
      // Sign in with email and password
      await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
          email: email,
          password: password
      );
      // Notify the user about successful login
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('User Created')));
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'weak-password') {
        message = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        message = 'The account already exists for that email.';
      } else {
        message = 'Registration failed. Please try again.';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('An error occurred. Please try again.'),
      ));
    }
  }


  Future <void> sendPasswordReset(String email) async{
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    }
    catch (e){
      print(e.toString());
    }
  }

  static Future<void> logout(BuildContext context) async {
    try {
      // Sign out from Firebase
      await FirebaseAuth.instance.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
            (Route<dynamic> route) => false,  // This ensures the user can't go back
      );
    } catch (e) {
      print('Error during sign out: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging out. Please try again.')),
      );
    }
  }

}
