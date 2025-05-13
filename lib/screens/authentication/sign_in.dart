import 'package:expense_splitter/helper/color.dart';
import 'package:expense_splitter/helper/validator.dart';
import 'package:expense_splitter/widgets/customfield.dart';
import 'package:expense_splitter/Screens/authentication/forgot_password.dart';
import 'package:expense_splitter/Screens/authentication/sign_up.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

class SignIn extends StatefulWidget {
  const SignIn({super.key});

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();
  final formkey = GlobalKey<FormState>();
  bool isLoading = false;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  signIn() async {
    setState(() {
      isLoading = true;
    });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text.trim(),
      );
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
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return isLoading
        ? Center(child: CircularProgressIndicator())
        : Scaffold(
          body: Center(
            child: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Text(
                      "Login",
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
                      "assets/images/Login.json",
                      height: size.height * 0.35,
                    ),
                    SizedBox(height: size.height * 0.02),
                    Form(
                      key: formkey,
                      child: Column(
                        children: [
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
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ForgotPassword(),
                                ),
                              );
                            },
                            child: Text(
                              "Forgot Password?",
                              style: GoogleFonts.inter(
                                fontSize: size.width * 0.04,
                                fontWeight: FontWeight.bold,
                                color: dark_blue,
                              ),
                            ),
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
                        height: size.height * 0.065,
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: dark_blue,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            debugPrint("Sign In button tap");
                            if (formkey.currentState!.validate()) {
                              signIn();
                            }
                          },
                          child: Text(
                            "LOGIN",
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: size.width * 0.065,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: "Don't have an Account? ",
                            style: GoogleFonts.inter(
                              color: dark_blue,
                              fontSize: size.width * 0.04,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: "SIGN UP",
                            recognizer:
                                TapGestureRecognizer()
                                  ..onTap = () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => SignUp(),
                                      ),
                                    );
                                  },
                            style: GoogleFonts.inter(
                              fontSize: size.width * 0.05,
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
