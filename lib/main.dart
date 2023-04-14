// ignore_for_file: prefer_const_literals_to_create_immutables

import 'dart:ui';

import 'package:easy_sidemenu/easy_sidemenu.dart';
import 'package:flutter/material.dart';
import 'package:iboamanager/captchaPage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:iboamanager/StatisticsPage.dart';
import 'package:iboamanager/UserPage.dart';
import 'package:iboamanager/loginPage.dart';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'adminPage.dart';


class MyCustomScrollBehavior extends MaterialScrollBehavior {
  // Override behavior methods and getters like dragDevices
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scrollBehavior: MyCustomScrollBehavior(),
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

  final _pref = SharedPreferences.getInstance();
  static String? token = "";

  @override
  void initState() {
    sideMenu.addListener((p0) {
      page.jumpToPage(p0);
    });
    getToken();
    super.initState();
  }

  void getToken() async {
    final SharedPreferences prefs = await _pref;

    token = prefs.getString("token");
    if (token == null) {
      logout();
    }
  }

  void logout() async {
    final SharedPreferences prefs = await _pref;

    prefs.clear();
    Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage()));
  }

  Widget sideMenuWidget() {
    return 
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
      footer: Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: logout, 
              child: const Text(
                "로그아웃",
                style: TextStyle(
                  fontSize: 30
                ),
              )
            ),
            const SizedBox(
              height: 10,
            ),
            const Text(
              'EYESON',
              style: TextStyle(
                fontSize: 15
              ),
            )
          ],
        )
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
          icon: const Icon(Icons.auto_graph_outlined),
        ),
        SideMenuItem(
          priority: 3,
          title: '캡챠 관리',
          onTap: (page, _) {
            sideMenu.changePage(page);
          },
          icon: const Icon(Icons.password_outlined),
        ),
      ],
    );
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
          sideMenuWidget(),
          Expanded(
            child: PageView(
              physics: const NeverScrollableScrollPhysics(),
              controller: page,
              children: [
                const AdminPage(),
                const UserPage(),
                const StatisticsPage(),
                const CaptchaPage(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}