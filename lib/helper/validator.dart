import 'package:cloud_firestore/cloud_firestore.dart';

String? validatemail(String? value) {
  if (value!.isEmpty) {
    return 'Email is required';
  }
  final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
  if (!emailRegex.hasMatch(value)) {
    return 'Please enter a valid email address';
  }
  return null;
}

String? validatepassword(String? value) {
  if (value!.isEmpty) {
    return 'Password is required';
  }
  if (value.length < 8) {
    return 'Password must be at least 8 characters';
  }
  return null;
}

String? validatefirstname(String? value) {
  if (value!.isEmpty) {
    return 'First Name is required';
  }
  return null;
}

String? validatelastname(String? value) {
  if (value!.isEmpty) {
    return 'Last Name is required';
  }
  return null;
}

String? validateUsernameField(String? value) {
  if (value!.isEmpty) {
    return 'User Name is required';
  }
  return null;
}

Future<String?> validateUsername(String? value) async {

  var querySnapshot = await FirebaseFirestore.instance
      .collection('users')
      .where('userName', isEqualTo: value)
      .get();

  if (querySnapshot.docs.isNotEmpty) {
    return 'Username already taken. Please choose another one';
  }

  return null;
}

String? validateGroup(String? value) {
  if (value!.isEmpty) {
    return 'Group Name is required';
  }
  return null;
}

String? isValidUPI(String? value) {
  if(value!.isEmpty){
    return "UPI must be filled";
  }
  final RegExp upiRegex = RegExp(r'^[a-zA-Z0-9.\-_]{2,256}@[a-zA-Z]{2,64}$');
  if(!upiRegex.hasMatch(value)){
    return 'Enter valid UPI id';
  }
  return null;
}