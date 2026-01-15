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
import 'package:fluttertoast/fluttertoast.dart';

import 'login_page.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameTextEditingController = TextEditingController();
  final emailTextEditingController = TextEditingController();
  final addressTextEditingController = TextEditingController();
  final passwordTextEditingController = TextEditingController();
  final confirmTextEditingController = TextEditingController();
  final phoneTextEditingController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _passwordVisible = false;

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      await firebaseAuth.createUserWithEmailAndPassword(
          email: emailTextEditingController.text.trim(),
          password: passwordTextEditingController.text.trim()
      ).then((auth) async {
        currentUser = auth.user;
        if (currentUser != null) {
          Map userMap = {
            "id": currentUser!.uid,
            "name": nameTextEditingController.text.trim(),
            "email": emailTextEditingController.text.trim(),
            "address": addressTextEditingController.text.trim(),
            "phone": phoneTextEditingController.text.trim(),

          };
          DatabaseReference userRef = FirebaseDatabase.instance.ref().child(
              "users");
          userRef.child(currentUser!.uid).set(userMap);
        }
        await Fluttertoast.showToast(msg: "Successfully Logged In");
        Navigator.push(
            context, MaterialPageRoute(builder: (c) => MainScreen()));
      }).catchError((errorMessage){
        Fluttertoast.showToast(msg: 'Error occures:\n $errorMessage');
        return "Enter valid credentials";

      });
      }
    else
      {
        Fluttertoast.showToast(msg: "Not all field are valid");
      }
  }

  @override
  Widget build(BuildContext context) {
    bool darkTheme =
        MediaQuery
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
                  "Register",
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
                          hintText: 'Name',
                          hintStyle: TextStyle(
                            color: darkTheme ? Colors.white : Colors.black,
                          ),
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
                            return "Name Field can't be empty";
                          }
                          if (text.length <= 2) {
                            return "Enter a valid name";
                          }
                          if (text.length > 49) {
                            return "Name can't be more than 50";
                          }
                          return null;
                        },
                        onChanged: (text) {
                          setState(() {
                            nameTextEditingController.text = text;
                          });
                        },
                      ),
                      SizedBox(height: 10),
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
                      SizedBox(height: 10),
                      IntlPhoneField(
                        decoration: InputDecoration(
                          hintText: 'Mobile Number',
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
                        showDropdownIcon: true,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: (text) {
                          if (text == null || text.number.isEmpty) {
                            return "Mobile number can't be empty";
                          }
                          if (text.number.length <= 2) {
                            return "Enter a valid Mobile number";
                          }
                          return null;
                        },
                        onChanged: (text) {
                          setState(() {
                            phoneTextEditingController.text =
                                text.completeNumber;
                          });
                        },
                      ),
                      SizedBox(height: 10),
                      TextFormField(
                        inputFormatters: [LengthLimitingTextInputFormatter(50)],
                        decoration: InputDecoration(
                          hintText: 'Address',
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
                            return "Address can't be empty";
                          }
                          if (text.length <= 2) {
                            return "Enter a valid Address";
                          }
                          if (text.length > 99) {
                            return "Address can't be more than 100";
                          }
                          return null;
                        },
                        onChanged: (text) {
                          setState(() {
                            addressTextEditingController.text = text;
                          });
                        },
                      ),
                      SizedBox(height: 10),
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
                          if (text.length <6) {
                            return "Password can't be less than 656";
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
                      SizedBox(height: 10),
                      TextFormField(
                        obscureText: !_passwordVisible,
                        inputFormatters: [LengthLimitingTextInputFormatter(10)],
                        decoration: InputDecoration(
                          hintText: 'Confirm Password',
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
                          if (text != passwordTextEditingController.text) {
                            return "Password doesn't match";
                          }
                          if (text == null || text.isEmpty) {
                            return "Password can't be empty";
                          }
                          if (text.length <= 2) {
                            return "Enter a valid Password";
                          }
                          if (text.length > 9) {
                            return "Password can't be more than 10";
                          }
                          return null;
                        },
                        onChanged: (text) {
                          confirmTextEditingController.text = text;
                        },
                      ),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          _submit();
                        },
                        child: Text(
                          'Register',
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
                          Navigator.push(context,MaterialPageRoute(builder: (c) => ForgetPasswordScreen()));

                        },
                        child: Text(
                          "Forget Password?",
                          style: TextStyle(color:darkTheme
                              ? Colors.amber.shade400
                              : Colors.blue,),
                        ),
                      ),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Have an account?',
                            style: TextStyle(color: Colors.grey),
                          ),
                          SizedBox(width: 5),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(context,MaterialPageRoute(builder: (c) => LoginPage()));

                            },
                            child: Text(
                              "Sign In",
                              style: TextStyle(color:darkTheme
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
