import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_splitter/helper/color.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Account extends StatefulWidget {
  const Account({Key? key}) : super(key: key);

  @override
  _AccountState createState() => _AccountState();
}

class _AccountState extends State<Account> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> _fetchUserData() async {
    // Get current user uid
    String uid = _auth.currentUser!.uid;
    DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return doc.data() as Map<String, dynamic>;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "My Profile",
          style: GoogleFonts.inter(
            fontSize: size.width * 0.07,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),  
        ),
        backgroundColor: dark_blue,
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _fetchUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("No user data found."));
          }
          final data = snapshot.data!;
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // CircleAvatar: If you have a profile image URL, replace with NetworkImage.
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: dark_blue,
                    child: data.containsKey('firstName') &&
                            (data['firstName'] as String).isNotEmpty
                        ? Text(
                            (data['firstName'] as String)[0].toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 40,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            "Hello",
                            style: GoogleFonts.inter(
                              fontSize: 40,
                              color: Colors.white,
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),
                  // Username (display name)
                  Text(
                    data['userName'] ?? "No Username",
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Details as ListTiles
                  ListTile(
                    leading: Icon(Icons.person, color: dark_blue),
                    title: Text(
                      "First Name",
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      data['firstName'] ?? "N/A",
                      style: GoogleFonts.inter(),
                    ),
                  ),
                  ListTile(
                    leading: Icon(Icons.person, color: dark_blue),
                    title: Text(
                      "Last Name",
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      data['lastName'] ?? "N/A",
                      style: GoogleFonts.inter(),
                    ),
                  ),
                  ListTile(
                    leading: Icon(Icons.email, color: dark_blue),
                    title: Text(
                      "Email",
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      data['email'] ?? "N/A",
                      style: GoogleFonts.inter(),
                    ),
                  ),
                  ListTile(
                    leading: Icon(Icons.payment, color: dark_blue),
                    title: Text(
                      "UPI ID",
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      data['upi'] ?? "N/A",
                      style: GoogleFonts.inter(),
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  SizedBox(
                    width: size.width*0.9,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: dark_blue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 14)
                      ),
                      onPressed: ()async{
                      await _auth.signOut();
                    }, child: Text("Log out")),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
