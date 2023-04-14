// ignore_for_file: library_private_types_in_public_api

import 'package:adaptive_scrollbar/adaptive_scrollbar.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer';

import 'main.dart';


class CaptchaPage extends StatefulWidget {
  const CaptchaPage({super.key});

  @override
  _CaptchaPageState createState() => _CaptchaPageState();
}

class _CaptchaPageState extends State<CaptchaPage> {
  
  final formKey = GlobalKey<FormState>();
  final ScrollController verticalScroll = ScrollController();
  final ScrollController horizontalScroll = ScrollController();
  String url = "http://ec2-43-200-219-190.ap-northeast-2.compute.amazonaws.com:37235";

  String code = "";
  String newCode = "";
  
  Future<bool> validate() async {
    if (formKey.currentState!.validate() == false) {
      return false;
    }

    formKey.currentState!.save();

    var res = await setCode(newCode);
    var data = jsonDecode(res!.body);
    var success = data['success'];
    if (success == false) {
      return false;
    }

    code = data['code'];
    setState(() { });
    return true;
  }

  Future<http.Response?> setCode(String code) async {
    try {
      http.Response res = await http.put(
        Uri.parse("$url/api/admin/setCode"),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': '*/*',
          'Authorization' : "Bearer ${MyHomePageState.token}"
        },
        body: {
          "code" : code
        }
      );

      return res;
    } catch(error) {
      log(error.toString());
      return null;
    }
  }

  Future<String> getCode() async {
    try {
      http.Response res = await http.get(
        Uri.parse("$url/api/admin/getCode"),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': '*/*',
          'Authorization' : "Bearer ${MyHomePageState.token}"
        }
      );

      var data = jsonDecode(res.body);
      log(data['code']);
      return data['code'];
    } catch(error) {
      log(error.toString());
      return "";
    }
  }

  @override
  void initState() {
    super.initState();
    getCode()
    .then((value) {
      code = value;
      setState(() {});
    });
  }

  Widget buildText() {
    return Text(
            "현재 코드 : $code",
            style: const TextStyle(
              fontSize: 24.0,
            ),
          );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AdaptiveScrollbar(
        controller: verticalScroll,
        position: ScrollbarPosition.right,
        child: AdaptiveScrollbar(
          //thumbVisibility: true,
          controller: horizontalScroll,
          position: ScrollbarPosition.bottom,
          child: ListView(
            restorationId: 'data_table_list_view',
            children: [
              Container(
                padding: const EdgeInsets.all(8.0),
                child: const Text(
                  "캡챠코드 관리",
                  style: TextStyle(
                    fontSize: 24.0,
                    //fontWeight: FontWeight.w400
                  ),
                )
              ),
              Form(
                key : formKey,
                child: Row(
                  children: <Widget>[
                    const SizedBox(
                      width: 41,
                    ),
                    Flexible(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          //labelText: 'UID',
                          hintText: "변경할 코드를 입력하세요",
                        ),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return "변경할 코드를 입력하세요";
                          }

                          return null;
                        },
                        onSaved: (value) {
                          newCode = value!;
                        },
                        onFieldSubmitted: (value) => validate(),
                      )
                    ),
                    const SizedBox(width: 200),
                    ElevatedButton(
                      child: const Text(
                        "변경"
                      ),
                      onPressed: () => validate(), 
                    ),
                    const SizedBox(width: 40)
                  ]
                ),
              ),
              const SizedBox(
                height: 50
              ),
              Row(
                  children: <Widget>[
                    const SizedBox(
                      width: 41,
                    ),
                    buildText()
                  ]
                ),
            ]
          )
        )
      )
    );
  }
}
