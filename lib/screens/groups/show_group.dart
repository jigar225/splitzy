import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_splitter/helper/color.dart';
import 'package:expense_splitter/Screens/groups/add_group.dart';
import 'package:expense_splitter/Screens/groups/group_detail_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ShowGroup extends StatefulWidget {
  const ShowGroup({super.key});

  @override
  State<ShowGroup> createState() => _ShowGroupState();
}

class _ShowGroupState extends State<ShowGroup> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> groups = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserGroups();
  }

  Future<void> fetchUserGroups() async {
    setState(() => isLoading = true);

    String userId = _auth.currentUser!.uid;
    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(userId).get();

    if (userDoc.exists && userDoc.data() != null) {
      List<dynamic>? fetchedGroupIds =
          (userDoc.data() as Map<String, dynamic>)['groupIds'];
debugPrint('hello---${fetchedGroupIds?.length}');
      if (fetchedGroupIds != null && fetchedGroupIds.isNotEmpty) {
        // Fetch all group details in a single query
        QuerySnapshot groupSnapshot = await _firestore
            .collection('groups')
            .where(FieldPath.documentId, whereIn: fetchedGroupIds)
            .get();

        setState(() {
          groups = groupSnapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
              .toList();
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> refreshGroups() async {
    await fetchUserGroups();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: dark_blue,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: Center(
          child: Text(
            "My Groups",
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              fontSize: size.width * 0.07,
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: refreshGroups,
        child: isLoading
            ? const Center(child: CircularProgressIndicator()) // Only one loader in center
            : ListView.builder(
                itemCount: groups.length,
                itemBuilder: (context, index) {
                  var group = groups[index];
            
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GroupDetailPage(groupId: group['id']),
                        ),
                      );
                    },
                    child: ListTile(
                      leading: Icon(Icons.group,size: size.width*0.08,color: dark_blue,),
                      title: Text(group["name"] ?? "Unnamed Group",style: GoogleFonts.inter(color: dark_blue,fontSize: size.width*0.05,fontWeight: FontWeight.bold),),
                      subtitle: Text(
                        "Created on: ${group['createdAt']?.toDate().toString().split(' ')[0]}",
                        style: GoogleFonts.inter(fontSize: size.width*0.035),
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: light_blue,
        foregroundColor: dark_blue,
        shape: CircleBorder(),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddGroup()),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
