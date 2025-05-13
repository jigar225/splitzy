import 'package:expense_splitter/helper/color.dart';
import 'package:expense_splitter/helper/validator.dart';
import 'package:expense_splitter/widgets/customfield.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  TextEditingController email = TextEditingController();
  final formKey = GlobalKey<FormState>();

  reset() async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email.text);
      Get.snackbar(
        "Reset Email Sent",
        "Check your inbox to reset your password.",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  void dispose() {
    email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: Center(
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Text(
                  "Forgot Password",
                  style: GoogleFonts.inter(
                    fontSize: size.width * 0.09,
                    fontWeight: FontWeight.bold,
                    color: dark_blue,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(size.width * 0.03),
                  child: Divider(height: 1, thickness: 2, color: dark_blue),
                ),
                Lottie.asset(
                  "assets/images/Forgot.json",
                  height: size.height * 0.4,
                ),
                Padding(
                  padding: EdgeInsets.all(size.width * 0.03),
                  child: Text(
                    "Enter your registered mail id to get reset password link",
                    style: GoogleFonts.inter(
                      fontSize: size.width * 0.05,
                      fontWeight: FontWeight.bold,
                      color: dark_blue,
                    ),
                  ),
                ),
                Form(
                  key: formKey,
                  child: CustomField(
                    size: size,
                    htext: "Email",
                    preicon: Icons.email_rounded,
                    title: "Email",
                    controller: email,
                    valid: validatemail,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(size.width * 0.03),
                  child: SizedBox(
                    height: size.height * 0.065,
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: dark_blue,
                      ),
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          reset();
                        }
                      },
                      child: Text(
                        "Reset Link",
                        style: GoogleFonts.inter(
                          fontSize: size.width * 0.065,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
