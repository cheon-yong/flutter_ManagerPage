import 'package:flutter/material.dart';


class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final formKey = new GlobalKey<FormState>()

  String _email;
  String _password;

  void validateAndSave() {
    final form = formKey.currentState;
    if (form!.validate()) {
      form!.save();

    }
  }

  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextFormField(
              decoration: InputDecoration(labelText: "Email"),
              validator: (value) {
                value!.isEmpty ? "Email can`t be empty" : null;
              },
              onSaved: (value) => _email = value!,
            ),
            TextFormField(
              obscureText: true,
              decoration: InputDecoration(labelText: "Password"),
              validator: (value) {
                value!.isEmpty ? "Password can`t be empty" : null;
              },
              onSaved: (value) => _password = value!,
            ),
            ElevatedButton(
              child: Text(
                'Login',
                )
              onPressed: , 
              
              )
            ],
          )
      )
    );
  }
}