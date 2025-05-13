import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_splitter/helper/color.dart';
import 'package:expense_splitter/helper/validator.dart';
import 'package:expense_splitter/widgets/customfield.dart';
import 'package:expense_splitter/Screens/authentication/sign_in.dart';
import 'package:expense_splitter/Screens/authentication/wrapper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();
  TextEditingController firstName = TextEditingController();
  TextEditingController lastName = TextEditingController();
  TextEditingController userName = TextEditingController();
  TextEditingController upi = TextEditingController();
  final formkey = GlobalKey<FormState>();

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    firstName.dispose();
    lastName.dispose();
    userName.dispose();
    upi.dispose();
    super.dispose();
  }

  signUp() async {
    try {
      String? usernameError = await validateUsername(userName.text.trim());
      if (usernameError != null) {
        Get.snackbar(
          "Error",
          usernameError,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: email.text.trim(),
            password: password.text.trim(),
          );
      await FirebaseFirestore.instance
          .collection("users")
          .doc(userCredential.user!.uid)
          .set({
            "firstName": firstName.text.trim(),
            "lastName": lastName.text.trim(),
            "userName": userName.text.trim(),
            "email": email.text.trim(),
            "upi": upi.text.trim(),
          });
      Get.offAll(Wrapper());
    } on FirebaseAuthException catch (e) {
      Get.snackbar(
        "error message",
        e.code,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        borderRadius: 10,
        margin: EdgeInsets.all(5),
        duration: Duration(seconds: 5),
        icon: Icon(Icons.error, color: Colors.white),
        isDismissible: true,
        forwardAnimationCurve: Curves.easeOutBack,
      );
    } catch (e) {
      Get.snackbar("error message", e.toString());
    }
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
                  "Sign Up",
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
                  "assets/images/signup.json",
                  height: size.height * 0.4,
                ),
                SizedBox(height: size.height * 0.02),
                Form(
                  key: formkey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: size.width * 0.5,
                            child: CustomField(
                              size: size,
                              htext: "First Name",
                              preicon: Icons.person,
                              title: "First Name",
                              controller: firstName,
                              valid: validatefirstname,
                            ),
                          ),
                          SizedBox(
                            width: size.width * 0.5,
                            child: CustomField(
                              size: size,
                              htext: "Last Name",
                              preicon: Icons.person,
                              title: "Last Name",
                              controller: lastName,
                              valid: validatelastname,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          SizedBox(
                            width: size.width * 0.5,
                            child: CustomField(
                              size: size,
                              htext: "User Name",
                              preicon: Icons.person,
                              title: "User Name",
                              controller: userName,
                              valid: validateUsernameField,
                            ),
                          ),
                          SizedBox(
                            width: size.width * 0.5,
                            child: CustomField(
                              size: size,
                              htext: "UPI",
                              preicon: Icons.credit_card,
                              title: "UPI ID",
                              controller: upi,
                              valid: isValidUPI,
                            ),
                          ),
                        ],
                      ),
                      CustomField(
                        size: size,
                        htext: "Email",
                        preicon: Icons.email_rounded,
                        title: "Email",
                        controller: email,
                        valid: validatemail,
                      ),
                      CustomField(
                        size: size,
                        htext: "Password",
                        preicon: Icons.lock_outline_rounded,
                        title: "Password",
                        controller: password,
                        valid: validatepassword,
                        sufIcon: Icons.remove_red_eye,
                        sufIcon2: Icons.visibility_off,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: size.width * 0.03,
                    vertical: size.height * 0.02,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: size.height * 0.065,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: dark_blue,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        if (formkey.currentState!.validate()) {
                          signUp();
                        }
                      },
                      child: Text(
                        "SIGN UP",
                        style: GoogleFonts.inter(
                          fontSize: size.width * 0.065,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: "Already have an Account? ",
                        style: GoogleFonts.inter(
                          color: dark_blue,
                          fontSize: size.width * 0.04,
                        ),
                      ),
                      TextSpan(
                        text: "SIGN IN",
                        recognizer:
                            TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SignIn(),
                                  ),
                                );
                              },
                        style: GoogleFonts.inter(
                          fontSize: size.width * 0.045,
                          fontWeight: FontWeight.bold,
                          color: dark_blue,
                        ),
                      ),
                    ],
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
