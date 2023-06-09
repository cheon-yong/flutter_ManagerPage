// ignore_for_file: library_private_types_in_public_api

import 'package:adaptive_scrollbar/adaptive_scrollbar.dart';
import 'package:flutter/material.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer';

import 'loginPage.dart';
import 'main.dart';


class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  _StatisticsPageState createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  String url = "http://ec2-43-200-219-190.ap-northeast-2.compute.amazonaws.com:37235";

  final ScrollController verticalScroll = ScrollController();
  final ScrollController horizontalScroll = ScrollController();
  
  int playCount = 0;
  int eyetrackCount = 0;
  int pollCount = 0;

  String startDate = "";
  String endDate = "";

  final String firstDay = "2000-01-01 00:00:00";

  Future<http.Response?> getScores(String startDate, String endDate) async {
    try {
      http.Response res = await http.get(
        Uri.parse("$url/api/admin/getScores?startDate=$startDate&endDate=$endDate"),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': '*/*',
          'Authorization' : "Bearer ${MyHomePageState.token}"
        }
      );

      return res;
    } catch(error) {
      log(error.toString());
      return null;
    }
  }

  String getDates() {
    String start = startDate.split(' ')[0];
    String end = endDate.split(' ')[0];
    return "기준일 : $start ~ $end";
  }

  @override
  initState() {
    super.initState();
    setCounts(DateTime.now().toString(), DateTime.now().toString());
  }

  setCounts(String start, String end) async {
    start = start.substring(0, start.indexOf(" "));
    end = end.substring(0, end.indexOf(" "));

    String startDate = "$start 00:00:00";
    String endDate = "$end 23:59:59";
    
    var res = await getScores(startDate, endDate);
    var data = jsonDecode(res!.body);
    var success = data['success'];
    
    if (success) {
      playCount = data['playCount'] ?? 0;
      eyetrackCount = data['eyetrackCount'] ?? 0;
      pollCount = data['pollCount'] ?? 0;
      this.startDate = startDate;
      this.endDate = endDate;
      setState(() {});
    } else {
      await Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage()))
      .then((value) {
        MyHomePageState.refreshToken();
        setState(() {});
      });
    }
  }

  List<DateTime?> _rangeDatePickerValueWithDefaultValue = [
    DateTime.now().add(const Duration(days: -1)),
    DateTime.now(),
  ];
  
  String _getValueText(
    CalendarDatePicker2Type datePickerType,
    List<DateTime?> values,
  ) {
    values =
        values.map((e) => e != null ? DateUtils.dateOnly(e) : null).toList();
    var valueText = (values.isNotEmpty ? values[0] : null)
        .toString()
        .replaceAll('00:00:00.000', '');

    if (datePickerType == CalendarDatePicker2Type.multi) {
      valueText = values.isNotEmpty
          ? values
              .map((v) => v.toString().replaceAll('00:00:00.000', ''))
              .join(', ')
          : 'null';
    } else if (datePickerType == CalendarDatePicker2Type.range) {
      if (values.isNotEmpty) {
        final startDate = values[0].toString().replaceAll('00:00:00.000', '');
        final endDate = values.length > 1
            ? values[1].toString().replaceAll('00:00:00.000', '')
            : 'null';
        valueText = '$startDate ~  $endDate';
      } else {
        return 'null';
      }
    }

    return valueText;
  }

  showCalander() { 
    showDialog(context: context, 
    builder: (BuildContext context) {
      return AlertDialog(
        content: Container(
          alignment: Alignment.center, 
          height: 500,
          width: 800,
          margin: const EdgeInsets.all(10.0), 
          child : _buildDefaultRangeDatePickerWithValue(),
        ),
        actions: [
          TextButton(
              onPressed: () async {
                await setCounts(
                  _rangeDatePickerValueWithDefaultValue[0].toString(),
                  _rangeDatePickerValueWithDefaultValue[1].toString(),
                );

                Navigator.of(context).pop();
              },
              child: const Text("조회")
            ),
          TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("닫기")
            )
        ],
      );
    }
    );
  }
  Widget _buildDefaultRangeDatePickerWithValue() {
    final config = CalendarDatePicker2Config(
      calendarType: CalendarDatePicker2Type.range,
      selectedDayHighlightColor: Colors.teal[800],
      weekdayLabelTextStyle: const TextStyle(
        color: Colors.black87,
        fontWeight: FontWeight.bold,
      ),
      controlsTextStyle: const TextStyle(
        color: Colors.black,
        fontSize: 15,
        fontWeight: FontWeight.bold,
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 10),
        CalendarDatePicker2(
          config: config,
          value: _rangeDatePickerValueWithDefaultValue,
          onValueChanged: (dates) =>
              setState(() => _rangeDatePickerValueWithDefaultValue = dates),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _getValueText(
                config.calendarType,
                _rangeDatePickerValueWithDefaultValue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 25),
      ],
    );
  }

  createTable(String header, String content) {
    return 
      Table(
        defaultColumnWidth: const FixedColumnWidth(230.0),
        border: TableBorder.all(color: Colors.white),
        children: [
          TableRow(
            children: [
              Container(
                height: 50,
                color: Colors.black,
                alignment: Alignment.center,
                child: Text(
                  header,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24
                  ),
                ),
              )
            ],
          ),
          TableRow(
            children: [
              Container(
                height: 50,
                color: Colors.black,
                alignment: Alignment.center,
                child: Text(
                  content,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24
                  ),
                ),
              )
            ]
          )
        ],
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
                  "통계 관리",
                  style: TextStyle(
                    fontSize: 24.0,
                    //fontWeight: FontWeight.w400
                  ),
                )
              ),
              Row(
                children: <Widget>[
                  const SizedBox(
                    width: 41,
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black, // Background color
                    ),
                    child: const Text(
                      "오늘"
                    ),
                    onPressed: () => {
                      setCounts(DateTime.now().toString(), DateTime.now().toString())
                    }, 
                  ),
                  const SizedBox(width: 21),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black, // Background color
                    ),
                    child: const Text(
                      "전체"
                    ),
                    onPressed: () => {
                      setCounts(firstDay, DateTime.now().toString())
                    }, 
                  ),
                  const SizedBox(width: 21),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black, // Background color
                    ),
                    child: const Text(
                      "날짜 선택"
                    ),
                    onPressed: showCalander, 
                  ),
                ]
              ),
              const SizedBox(
                height: 50
              ),
              Row(
                children: [
                  const SizedBox(
                    width: 41,
                  ),
                  Text(
                    getDates(),
                    style: TextStyle(
                      fontSize: 32
                    ),
                  )
                ],
              ),
              const SizedBox(
                height: 50
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  const SizedBox(
                    width: 41,
                  ),
                  createTable("발달놀이 수", playCount.toString()),
                  const SizedBox(
                    width: 21,
                  ),
                  createTable("관찰놀이 수", eyetrackCount.toString()),
                  const SizedBox(
                    width: 21,
                  ),
                  createTable("부모체크리스트 수", pollCount.toString()),
                ]
              ),
            ]
          )
        )
      )
    );
  }
}
