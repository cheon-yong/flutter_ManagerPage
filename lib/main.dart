// ignore_for_file: prefer_const_literals_to_create_immutables

import 'package:easy_sidemenu/easy_sidemenu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:iboamanager/StatisticsPage.dart';
import 'package:iboamanager/UserPage.dart';
import 'package:iboamanager/loginPage.dart';
import 'dart:developer';
import 'adminPage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Iboa Manager',
      theme: ThemeData(
        fontFamily: 'NotoSansKR',
        brightness: Brightness.light,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        primaryColor: Colors.blueGrey,
        primarySwatch: Colors.blueGrey,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const MyHomePage(title: 'Iboa Manager'),
      //home : const LoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;
  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  PageController page = PageController();
  SideMenuController sideMenu = SideMenuController();

  static final storage = FlutterSecureStorage();
  static String token = "";

  @override
  void initState() {
    sideMenu.addListener((p0) {
      page.jumpToPage(p0);
    });
    getToken();
    //log("token : " + token);
    super.initState();
  }

  void getToken() {
    storage.read(key: "token")
    .then((value) {
      token = value.toString();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
      ),
      body: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SideMenu(
            controller: sideMenu,
            style: SideMenuStyle(
              // showTooltip: false,
              displayMode: SideMenuDisplayMode.auto,
              hoverColor: Colors.blue[100],
              selectedColor: Colors.lightBlue,
              selectedTitleTextStyle: const TextStyle(color: Colors.white),
              selectedIconColor: Colors.white,
              decoration: const BoxDecoration(
                //borderRadius: BorderRadius.all(Radius.circular(10)),
                border: Border(
                  right: BorderSide(
                    color: Colors.black,
                    width: 1.0,
                    style: BorderStyle.solid
                  )
                )
              ),
              //backgroundColor: Colors.blueGrey[700]
              backgroundColor: Colors.white
            ),
            title: Column(
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxHeight: 150,
                    maxWidth: 150,
                  ),
                  child: Image.asset(
                    'assets/images/eyesonicon.png',
                  ),
                ),
                const Divider(
                  indent: 8.0,
                  endIndent: 8.0,
                ),
              ],
            ),
            footer: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'EYESON',
                style: TextStyle(fontSize: 15),
              ),
            ),
            items: [
              // SideMenuItem(
              //   priority: 0,
              //   title: "dashboard",
              //   onTap: (page, _) {
              //     sideMenu.changePage(page);
              //   },
              //   icon: const Icon(Icons.home),
              //   badgeContent: const Text(
              //     '3',
              //     style: TextStyle(color: Colors.white),
              //   ),
              //   tooltipContent: "This is a tooltip for Dashboard item",
              // ),
              SideMenuItem(
                priority: 0,
                title: '어드민 관리',
                onTap: (page, _) {
                  sideMenu.changePage(page);
                },
                icon: const Icon(Icons.supervisor_account),
              ),
              SideMenuItem(
                priority: 1,
                title: '유저 관리',
                onTap: (page, _) {
                  sideMenu.changePage(page);
                },
                icon: const Icon(Icons.file_copy_rounded),
                // trailing: Container(
                //     decoration: const BoxDecoration(
                //         color: Colors.amber,
                //         borderRadius: BorderRadius.all(Radius.circular(6))),
                //     child: Padding(
                //       padding: const EdgeInsets.symmetric(
                //           horizontal: 6.0, vertical: 3),
                //       child: Text(
                //         'New',
                //         style: TextStyle(fontSize: 11, color: Colors.grey[800]),
                //       ),
                //     )),
              ),
              SideMenuItem(
                priority: 2,
                title: '통계 관리',
                onTap: (page, _) {
                  sideMenu.changePage(page);
                },
                icon: const Icon(Icons.download),
              ),
            ],
          ),
          Expanded(
            child: PageView(
              controller: page,
              children: [
                const AdminPage(),
                const UserPage(),
                const StatisticsPage(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}