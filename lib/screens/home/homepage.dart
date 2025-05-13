import 'package:expense_splitter/helper/color.dart';
import 'package:expense_splitter/Screens/home/account.dart';
import 'package:expense_splitter/Screens/home/activity.dart';
import 'package:expense_splitter/Screens/home/check_group_screen.dart';
import 'package:flutter/material.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {

  int crntIndex = 0;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: switch (crntIndex) {
        0 => const CheckGroupScreen(),
        1 => const Activity(),
        2 => const Account(),
        _ => const Center(child: Text("Page not Found"),),
      },
      bottomNavigationBar: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
        child: BottomNavigationBar(
          backgroundColor: dark_blue,
          fixedColor: Colors.white,
          selectedIconTheme: IconThemeData(size: 30),
          unselectedIconTheme: IconThemeData(size: 24),
          unselectedItemColor: light_blue,
          type: BottomNavigationBarType.fixed,
          currentIndex: crntIndex,
          onTap: (index) {
            setState(() {
              crntIndex = index;
            });
          },
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.groups_rounded),
              label: "Groups",
            ),
            BottomNavigationBarItem(icon: Icon(Icons.photo), label: "Activity"),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_circle),
              label: "Account",
            ),
          ],
        ),
      ), 
      
    );
  }
}
