// ignore_for_file: file_names, constant_identifier_names

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:core';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:iboamanager/main.dart';



class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _pref = SharedPreferences.getInstance();
  final formKey = GlobalKey<FormState>();

  String email = "";
  String password = "";
  String url = "http://ec2-43-200-219-190.ap-northeast-2.compute.amazonaws.com:37235";
  //String url = "http://localhost:37235";

  @override
  void initState() {
    super.initState();
    
    checkToken();
  }

  void checkToken() async {
    var prefs = await _pref;

    var token = prefs.getString("token");
    if (token == null) {
      return;
    }
    var res = await autoLogin(token);
    var data = jsonDecode(res.body);
    if (data['success']) {
      Navigator.pop(context);
    }
  }

  void validateAndSave() async {
    if (formKey.currentState!.validate() == false) {
      ScaffoldMessenger.of(context).showSnackBar(makeSnackBar("아이디 또는 비밀번호가 올바르지 않습니다"));
      return;
    }
    
    formKey.currentState!.save();
    var res = await getToken(email, password);
    var data = jsonDecode(res.body);
    var success = data['success'];    
    if (success) {
      final SharedPreferences prefs = await _pref;
      await prefs.setString("token", data['token']);
      Navigator.pop(context, success);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(makeSnackBar("아이디 또는 비밀번호가 올바르지 않습니다"));
    }
  }

  SnackBar makeSnackBar(String comment) {
    return SnackBar(
        content: Text(
          comment,
          style: const TextStyle(fontFamily: "NotoSansKR"),
        ),
        duration: const Duration(seconds: 3),
    );
  }

  Future<http.Response> getToken(String email, String password) async {
    http.Response response = await http.post(
      Uri.parse("$url/api/admin/login"),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': '*/*',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Credentials': 'true'
      },
      body: {
        'email': email,
        'password': password
      },
    );

    log(response.toString());

    return response;
  }

  Future<http.Response> autoLogin(String token) async {
    http.Response response = await http.post(
      Uri.parse("$url/api/admin/autoLogin"),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': '*/*',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Credentials': 'true',
        'Authorization' : "Bearer $token"
      }
    );

    return response;
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
          color: const Color.fromRGBO(0, 0, 0, 1),
        )),
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextFormField(
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return "이메일을 입력하세요";
                  }
                  final RegExp emailRegExp =
                      RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+');

                  if (!emailRegExp.hasMatch(value)) {
                    return "이메일 형식이 아닙니다";
                  }

                  return null;
                },
                onSaved: (value) {
                  email = value!;
                },
              ),
              TextFormField(
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return "비밀번호를 입력하세요"; 
                  }

                  return null;
                },
                onSaved: (value) {
                  password = value!;
                },
              ),
              ElevatedButton(
                onPressed: validateAndSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black, // Background color
                ),
                child: const Text(
                  'Login',
                  style: TextStyle(fontSize: 20.0),
                ),
              ),
            ],
          ),
        ),
      ),
    ));
  }
}
