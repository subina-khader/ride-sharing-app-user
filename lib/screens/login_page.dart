import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter_intl_phone_field/flutter_intl_phone_field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:trippo_mobile_app/global/global.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:trippo_mobile_app/screens/main_screen.dart';
import 'package:trippo_mobile_app/screens/forget_password_screen.dart';
import 'package:trippo_mobile_app/screens/register_page.dart';
import 'package:trippo_mobile_app/models/user_model.dart';
import 'package:fluttertoast/fluttertoast.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailTextEditingController = TextEditingController();
  final passwordTextEditingController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _passwordVisible = false;

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      await firebaseAuth.signInWithEmailAndPassword(
          email: emailTextEditingController.text.trim(),
          password: passwordTextEditingController.text.trim()
      ).then((auth) async {
        currentUser = auth.user;

        // ✅ NEW: Load user data from Firebase
        if (currentUser != null) {
          DatabaseReference userRef = FirebaseDatabase.instance
              .ref()
              .child("users")
              .child(currentUser!.uid);

          DatabaseEvent event = await userRef.once();

          if (event.snapshot.value != null) {
            userModelCurrentInfo = UserModel.fromSnapshot(event.snapshot);
            print("✅ User data loaded: ${userModelCurrentInfo!.name}");
            print("✅ Phone: ${userModelCurrentInfo!.phone}");

            Fluttertoast.showToast(msg: 'Successfully Logged In');
            Navigator.push(context, MaterialPageRoute(builder: (c) => MainScreen()));
          } else {
            print("❌ User data not found in Firebase");
            Fluttertoast.showToast(msg: 'User data not found. Please register again.');
          }
        }
      }).catchError((errorMessage) {
        Fluttertoast.showToast(msg: "Error occures:\n $errorMessage");
      });
    }
    else {
      Fluttertoast.showToast(msg: "Not all field are valid");
    }
  }

  @override
  Widget build(BuildContext context) {
    bool darkTheme = MediaQuery
        .of(context)
        .platformBrightness == Brightness.dark;
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
                  "Login",
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
                      TextFormField(
                        obscureText: !_passwordVisible,
                        inputFormatters: [LengthLimitingTextInputFormatter(10)],
                        decoration: InputDecoration(
                          hintText: 'Password',
                          fillColor: darkTheme
                              ? Colors.grey[700]
                              : Colors.grey[200],
                          filled: true,
                          suffixIcon: IconButton(
                            icon: _passwordVisible
                                ? Icon(Icons.visibility)
                                : Icon(Icons.visibility_off),

                            onPressed: () {
                              setState(() {
                                _passwordVisible = !_passwordVisible;
                              });
                            },
                          ),
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
                            return "Password can't be empty";
                          }
                          if (text.length <= 2) {
                            return "Enter a valid Password";
                          }
                          if (text.length < 6) {
                            return "Password can't be less than 6";
                          }
                          if (text.length > 9) {
                            return "Password can't be more than 10";
                          }
                          return null;
                        },
                        onChanged: (text) {
                          passwordTextEditingController.text = text;
                        },
                      ),
                      SizedBox(height: 25),
                      ElevatedButton(
                        onPressed: () {
                          _submit();
                        },
                        child: Text(
                          'Login',
                          style: TextStyle(
                            color: darkTheme ? Colors.black : Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        style: ElevatedButton.styleFrom(
                          backgroundColor: darkTheme
                              ? Colors.amber.shade400
                              : Colors.blue,
                          minimumSize: Size(double.infinity, 45),
                        ),
                      ),
                      SizedBox(height: 10),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (c) => ForgetPasswordScreen()));

                        },
                        child: Text(
                          "Forget Password?",
                          style: TextStyle(color: darkTheme
                              ? Colors.amber.shade400
                              : Colors.blue,),
                        ),
                      ),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Doesn\'t have an account?',
                            style: TextStyle(color: Colors.grey),
                          ),
                          SizedBox(width: 5),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (c) => RegisterScreen()));

                            },
                            child: Text(
                              "Register",
                              style: TextStyle(color: darkTheme
                                  ? Colors.amber.shade400
                                  : Colors.blue,),
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