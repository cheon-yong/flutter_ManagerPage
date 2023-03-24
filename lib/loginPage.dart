// ignore_for_file: file_names, constant_identifier_names

import 'dart:convert';

import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final formKey = GlobalKey<FormState>();

  String email = "";
  String password = "";

  void validateAndSave() {
    if (formKey.currentState!.validate() == false) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
          "로그인 실패",
          style: TextStyle(fontFamily: "NotoSansKR"),
        ),
        duration: Duration(seconds: 3),
      ));
      return;
    }

    formKey.currentState!.save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
      child: Container(
        width: 500,
        height: 500,
        decoration: BoxDecoration(
            border: Border.all(
          width: 1,
          color: Color.fromRGBO(0, 0, 0, 1),
        )),
        padding: EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextFormField(
                decoration: InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return "이메일을 입력하세요";
                  }
                  final RegExp emailRegExp =
                      RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+');

                  if (!emailRegExp.hasMatch(email)) {
                    return "이메일 형식이 아닙니다";
                  }

                  return null;
                },
              ),
              TextFormField(
                obscureText: true,
                decoration: InputDecoration(labelText: 'Password'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return "비밀번호를 입력하세요";
                  }

                  return null;
                },
              ),
              ElevatedButton(
                child: Text(
                  'Login',
                  style: TextStyle(fontSize: 20.0),
                ),
                onPressed: validateAndSave,
              ),
            ],
          ),
        ),
      ),
    ));
  }
}
