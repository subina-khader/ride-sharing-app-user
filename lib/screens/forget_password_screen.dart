import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/services.dart';
import 'package:email_validator/email_validator.dart';
import 'package:trippo_mobile_app/global/global.dart';
import 'package:trippo_mobile_app/screens/login_page.dart';
import 'package:trippo_mobile_app/screens/main_screen.dart';

class ForgetPasswordScreen extends StatefulWidget {
  const ForgetPasswordScreen({super.key});

  @override
  State<ForgetPasswordScreen> createState() => _ForgetPasswordScreenState();
}

class _ForgetPasswordScreenState extends State<ForgetPasswordScreen> {
  final emailTextEditingController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Future<void> _submit() async {
    firebaseAuth
        .sendPasswordResetEmail(email: emailTextEditingController.text.trim())
        .then((value) {
          Fluttertoast.showToast(
            msg:
                "We have sent an email to recover the password. Please check your email.",
          );
        })
        .onError((error, stackTrace) {
          Fluttertoast.showToast(msg: "Error occurred:\n${error.toString()}");
          print("Error occurred:\n${error.toString()}");
        });
  }

  @override
  Widget build(BuildContext context) {
    bool darkTheme =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(10.0),
          child: ListView(
            children: [
              Image.asset(
                darkTheme
                    ? 'assets/images/darktheme.png'
                    : 'assets/images/lighttheme.png',
              ),
              SizedBox(height: 10),
              Center(
                child: Text(
                  "Forgot Password Screen",
                  style: TextStyle(
                    color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8.0, 10, 8),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextFormField(
                        inputFormatters: [LengthLimitingTextInputFormatter(50)],
                        decoration: InputDecoration(
                          hintText: 'Email',
                          fillColor: darkTheme
                              ? Colors.grey[700]
                              : Colors.grey[200],
                          filled: true,
                          prefixIcon: Icon(Icons.people),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                              width: 0,
                              style: BorderStyle.none,
                            ),
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: (text) {
                          if (text == null || text.isEmpty) {
                            return "Email can't be empty";
                          }
                          if (text.length <= 2 ||
                              !(text.contains('@')) ||
                              !(text.contains('.'))) {
                            return "Enter a valid email";
                          }
                          if (text.length > 99) {
                            return "Email can't be more than 100";
                          }
                          if (EmailValidator.validate(text) == true)
                            return null;
                        },
                        onChanged: (text) {
                          setState(() {
                            emailTextEditingController.text = text;
                          });
                        },
                      ),
                      SizedBox(height: 20),

                      ElevatedButton(
                        onPressed: () {
                          _submit();
                        },
                        child: Text(
                          'Send Reset Password Link',
                          style: TextStyle(
                            color: darkTheme ? Colors.blue : Colors.white,
                            fontSize: 18,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: darkTheme
                              ? Colors.white
                              : Colors.blue,
                          minimumSize: Size(double.infinity, 45),
                        ),
                      ),
                      SizedBox(height: 10),
                      GestureDetector(
                        onTap: () {},
                        child: Text(
                          "Forget Password?",
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account?',
                            style: TextStyle(color: Colors.grey),
                          ),
                          SizedBox(width: 5),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(context,MaterialPageRoute(builder: (c) => LoginPage()));
                            },
                            child: Text(
                              "Login",
                              style: TextStyle(color: Colors.blue),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
