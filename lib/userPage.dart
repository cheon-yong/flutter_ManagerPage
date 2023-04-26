// ignore_for_file: library_private_types_in_public_api, sort_child_properties_last, avoid_print, prefer_typing_uninitialized_variables

import 'dart:convert';
import 'dart:developer';
import 'dart:html';
import 'dart:js_interop';
import 'dart:ui';
import 'package:adaptive_scrollbar/adaptive_scrollbar.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:url_launcher_web/url_launcher_web.dart';
import 'package:path_provider/path_provider.dart';
import 'loginPage.dart';
import 'main.dart';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart'; 

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  UserPageState createState() => UserPageState();
}

//const url = "http://localhost:37235";
String url = "http://ec2-43-200-219-190.ap-northeast-2.compute.amazonaws.com:37235";

var comments;
var problems;

class _RestorableReportSelections extends RestorableProperty<Set<int>> {
  Set<int> _reportSelections = {};

  bool isSelected(int id) => _reportSelections.contains(id);

  void setReportSelections(List<_Report> reports) {
    final updatedSet = <int>{};
    for (var i = 0; i < reports.length; i += 1) {
      var dessert = reports[i];
      if (dessert.selected) {
        updatedSet.add(i);
      }
    }
    _reportSelections = updatedSet;
    notifyListeners();
  }
  
  @override
  Set<int> createDefaultValue() => _reportSelections;
  
  @override
  Set<int> fromPrimitives(Object? data) {
    final selectedItemIndices = data as List<dynamic>;
    _reportSelections = {
      ...selectedItemIndices.map<int>((dynamic id) => id as int),
    };
    return _reportSelections;
  }
  
  @override
  void initWithValue(Set<int> value) {
    _reportSelections = value;
  }
  
  @override
  Object? toPrimitives() => _reportSelections.toList();

}

class UserPageState extends State<UserPage> with RestorationMixin {
  String? token = "";
  String uid = "";
  final formKey = GlobalKey<FormState>();
  final ScrollController verticalScroll = ScrollController();
  final ScrollController horizontalScroll = ScrollController();

  Future<bool> validate() async {
    if (formKey.currentState!.validate() == false) {
      return false;
    }

    formKey.currentState!.save();
    var success = await _reportDataSource!.getReports(uid);
    if (success) {
      setState(() {});
    }
    return true;
  }

  final _RestorableReportSelections _reportSelections = _RestorableReportSelections();
  final RestorableInt _rowIndex = RestorableInt(0);
  final RestorableInt _rowsPerPage =
      RestorableInt(PaginatedDataTable.defaultRowsPerPage);
  final RestorableBool _sortAscending = RestorableBool(true);
  final RestorableIntN _sortColumnIndex = RestorableIntN(null);
  final _availableRowPerPage = [10, 15, 30];
  _ReportDataSource? _reportDataSource;

  @override
  void initState() {
    token = MyHomePageState.token;
    rootBundle.loadString('assets/config/Comments.json')
      .then((value) {
        comments = json.decode(value);
      });

    rootBundle.loadString('assets/config/Problems.json')
      .then((value) {
        problems = json.decode(value)['problems'];
        log(problems.toString());
      });

    super.initState();
  }

  @override
  String? get restorationId => "userPage";

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_reportSelections, 'selected_row_indices');
    registerForRestoration(_rowIndex, 'current_row_index');
    registerForRestoration(_rowsPerPage, 'rows_per_page');
    registerForRestoration(_sortAscending, 'sort_ascending');
    registerForRestoration(_sortColumnIndex, 'sort_column_index');

    _reportDataSource ??= _ReportDataSource(context);
    switch (_sortColumnIndex.value) {
      case 0:
        _reportDataSource!._sort<num>((d) => d.id, _sortAscending.value);
        break;
      case 1:
        _reportDataSource!._sort<String>((d) => d.createdAt, _sortAscending.value);
        break;
      case 2:
        // Score
        //_reportDataSource!._sort<String>((d) => d.role, _sortAscending.value);
        break;
      case 3:
        _reportDataSource!._sort<String>((d) => d.completedAt, _sortAscending.value);
        break;
    }
    _reportDataSource!.updateSelectedReports(_reportSelections);
    _reportDataSource!.addListener(_updateSelectedReportRowListener);
  }

  
  void _updateSelectedReportRowListener() {
    _reportSelections.setReportSelections(_reportDataSource!._reports);
  }

  void _sort<T>(
    Comparable<T> Function(_Report d) getField,
    int columnIndex,
    bool ascending,
  ) {
    _reportDataSource!._sort<T>(getField, ascending);
    setState(() {
      _sortColumnIndex.value = columnIndex;
      _sortAscending.value = ascending;
    });
  }

  void exportExcel() async {
    //var account = _reportDataSource!._account;
    var selectedReport = _reportDataSource!.getSelectedReport();

    // Create Excel file
    var excel = Excel.createExcel();
    excel['Sheet1'].isRTL = false;

    var sheet = excel['Sheet1'];
    sheet.insertRowIterables(["번호", "UID", "아동나이", "아동성별", "생성 시간", "발달지원구간 점수", "발달지원구간 문구", "자폐위험도 점수", "자폐위험도 문구", "선별구간 점수", "선별구간 문구", "완료 시간"], 0);

    for (int i = 0; i < selectedReport.length; i++) {
      var report = selectedReport[i];
      var dataList = [report.id.toString(), report.uid, report.age.toString(), report.gender.toString(), report.createdAt, report.mainScore.toString(), report.mainComment['section'], report.eyeScore.toString(), report.eyeComment['section'], report.pollScore.toString(), report.pollComment['section'], report.completedAt];
      sheet.insertRowIterables(dataList, i + 1);
    }

    excel.save(fileName : "excel.xlsx");

  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reportDataSource ??= _ReportDataSource(context);
    _reportDataSource!.addListener(_updateSelectedReportRowListener);
  }


  @override
  void dispose() {
    _rowsPerPage.dispose();
    _sortColumnIndex.dispose();
    _sortAscending.dispose();
    _reportDataSource!.removeListener(_updateSelectedReportRowListener);
    _reportDataSource!.dispose();
    super.dispose();
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
                  "유저 관리",
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
                          hintText: "UID를 입력하세요",
                        ),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return "UID을 입력하세요";
                          }

                          return null;
                        },
                        onSaved: (value) {
                          uid = value!;
                        },
                        onFieldSubmitted: (value) => validate(),
                      )
                    ),
                    const SizedBox(width: 200),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black, // Background color
                      ),
                      child: const Text(
                        "확인"
                      ),
                      onPressed: () => validate(), 
                    ),
                    const SizedBox(width: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black, // Background color
                      ),
                      child: const Text(
                        "선택 다운"
                      ),
                      onPressed: () => exportExcel(), 
                    ),
                    const SizedBox(width: 39)
                  ]
                ),
              ),
              PaginatedDataTable(
                showCheckboxColumn: true,
                rowsPerPage: _rowsPerPage.value,
                availableRowsPerPage: _availableRowPerPage,
                onRowsPerPageChanged: (value) {
                  setState(() {
                    _rowsPerPage.value = value!;
                  });
                },
                initialFirstRowIndex: _rowIndex.value,
                onPageChanged: (rowIndex) {
                  setState(() {
                    _rowIndex.value = rowIndex;
                  });
                },
                sortColumnIndex: _sortColumnIndex.value,
                sortAscending: _sortAscending.value,
                onSelectAll: _reportDataSource!._selectAll,
                columnSpacing: 90.0,
                columns: [
                  DataColumn(
                    label: const Expanded(
                      child: Text(
                        "ㅤ번호",
                        textAlign: TextAlign.center,
                      ),
                    ),
                    //numeric: true,
                    onSort: (columnIndex, ascending) =>
                        _sort<num>((d) => d.id, columnIndex, ascending),
                  ),
                  DataColumn(
                    label: const Expanded(
                      child: 
                        Text(
                        "ㅤ생성 시간",
                        textAlign: TextAlign.center,
                      ),
                    ),
                    onSort: (columnIndex, ascending) =>
                        _sort<String>((d) => d.completedAt, columnIndex, ascending),
                  ),
                  const DataColumn(
                    label: Expanded(
                      child: Text(
                        "발달지원구간 점수",
                        textAlign: TextAlign.center,
                      ),
                    ),
                    //onSort: (columnIndex, ascending) =>_sort<String>((d) => d.email, columnIndex, ascending),
                  ),
                  const DataColumn(
                    label: Expanded(
                      child: Text(
                        "발달지원구간 문구",
                        textAlign: TextAlign.center,
                      )
                    ),
                    //onSort: (columnIndex, ascending) =>_sort<String>((d) => d.email, columnIndex, ascending),
                  ),
                  const DataColumn(
                    label: Expanded(
                      child: Text(
                        "자폐위험도 점수",
                        textAlign: TextAlign.center
                      ),
                    ),
                    numeric: true,
                    //onSort: (columnIndex, ascending) =>_sort<String>((d) => d.email, columnIndex, ascending),
                  ),
                  const DataColumn(
                    label: Expanded(
                      child: Text(
                        "자폐위험도 문구",
                        textAlign: TextAlign.center
                      ),
                    ),
                    //onSort: (columnIndex, ascending) =>_sort<String>((d) => d.email, columnIndex, ascending),
                  ),
                  const DataColumn(
                    label: Expanded(
                      child: Text(
                        "선별구간 점수",
                        textAlign: TextAlign.center
                      )
                    ),
                    numeric: true,
                    //onSort: (columnIndex, ascending) =>_sort<String>((d) => d.email, columnIndex, ascending),
                  ),
                  const DataColumn(
                    label: Expanded(
                      child: Text(
                        "선별구간 문구",
                        textAlign: TextAlign.center
                      )
                    ),
                    //onSort: (columnIndex, ascending) =>_sort<String>((d) => d.email, columnIndex, ascending),
                  ),
                  DataColumn(
                    label: const Expanded(
                      child: Text(
                        "ㅤ완료 시간",
                        textAlign: TextAlign.center,
                      )
                    ),
                    onSort: (columnIndex, ascending) =>
                        _sort<String>((d) => d.completedAt, columnIndex, ascending),
                  ),
                  const DataColumn(
                    label: Expanded(
                      child: Text(
                        "상세",
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const DataColumn(
                    label: Expanded(
                      child: Text(
                        "로그 상세",
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
                source: _reportDataSource!,
              ),
            ],
          ),
        )
      ),
    );
  }
}

class _Account {
  _Account(this.id, this.uid, this.type, this.gender, this.age, this.createdAt, this.father_age, this.mother_age);

  final int id;
  final String uid;
  final String type;
  final String gender;
  final int age;
  final String createdAt;
  final int father_age;
  final int mother_age;
}

class _Report {
  _Report(
    this.id,
    this.account_id,
    this.uid,
    this.type,
    this.age,
    this.gender,
    this.father_age,
    this.mother_age,
    this.createdAt, 
    this.completedAt, 
    this.mainScore, 
    this.mainComment, 
    this.eyeScore, 
    this.eyeComment, 
    this.pollScore, 
    this.pollComment
  );

  final int id;
  final int account_id;
  final String uid;
  final String type;
  final int age;
  final String gender;
  final int father_age;
  final int mother_age;
  final String createdAt;
  final String completedAt;
  final int mainScore;
  final dynamic mainComment;
  final int eyeScore;
  final dynamic eyeComment;
  final int pollScore;
  final dynamic pollComment;
  bool selected = false;
}

class _ReportDataSource extends DataTableSource {
  
  _ReportDataSource(this.context) {
    _reports = []; 
    _account = _Account(0, "", "", "", 0, "", 0, 0);
    getReports("");
  }

  final BuildContext context;
  late List<_Report> _reports;
  late _Account _account;

  dynamic getMainComment(int score) {
    var main = comments['main'];

    if (score <= 25) {
      return main[0];
    } else if (score <= 50) {
      return main[1];
    } else if (score <= 75) {
      return main[2];
    } else {
      return main[3];
    }
  }
  
  dynamic getEyeComment(int score) {
    var eye = comments['eye'];

    if (score <= 30) {
      return eye[0];
    } else if (score <= 60) {
      return eye[1];
    } else {
      return eye[2];
    }
  }

  dynamic getPollComment(int score) {
    var poll = comments['poll'];
    if (score <= 57) {
      return poll[0];
    } else if (score <= 83) {
      return poll[1];
    } else if (score <= 108) {
      return poll[2];
    } else if (score <= 134) {
      return poll[3];
    } else {
      return poll[4];
    }
  }

  Future<bool> getReports(String uid) async {
    try {
      var res = await http.get(
      Uri.parse(
        '$url/api/admin/getReports?uid=$uid'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': '*/*',
          'Authorization' : "Bearer ${MyHomePageState.token}"
        },
      );

      var data = jsonDecode(res.body);
      var success = data['success'];


      if (success) {
        var account = data['account'];
        if (account != null) {
          _account = _Account(
            account['id'] ?? 0, 
            account['uid'] ?? "",
            account['type'] ?? "",
            account['gender'] ?? "Null",
            account['age'] ?? 0,
            account['createdAt'] ?? "",
            account['father_age'] ?? 0,
            account['mother_age'] ?? 0
          );
        } else {
          _account = _Account(
            0, 
            "",
            "",
            "",
            0,
            "",
            0,
            0
          );
        }
        

        final reports = data['reports'];
        _reports.clear();
        for (int i = 0; i < reports.length; i++) {
          final report = reports[i];
          int mainScore = report['main_score'];
          int eyeScore = report['eye_score'];
          int pollScore = report['poll_score'];

          var mainComment = getMainComment(mainScore);
          var eyeComment = getEyeComment(eyeScore);
          var pollComment = getPollComment(pollScore);
          var createdAt = simpleDate(report['createdAt'] as String);
          var completedAt = simpleDate(report['completedAt'] ?? "");

          _reports.add(
            _Report(
              report['id'],
              report['account_id'] ?? 0,
              report['uid'] ?? "",
              report['type'] ?? "",
              report['age'] ?? 0,
              report['gender'] ?? 0,
              report['father_age'] ?? 0,
              report['mother_age'] ?? 0,
              createdAt,
              completedAt,
              mainScore,
              mainComment,
              eyeScore,
              eyeComment,
              pollScore,
              pollComment
            )
          );
        }
        
      } else {
        await Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage()))
        .then((value) {
          MyHomePageState.refreshToken();
          getReports(uid);
        });

        return false;
      }

      notifyListeners();
      return true;
    } catch (error) {
      log(error.toString());
      return false;
    }
  }

  int _selectedCount = 0;
  void updateSelectedReports(_RestorableReportSelections selectedRows) {
    _selectedCount = 0;
    for (var i = 0; i < _reports.length; i += 1) {
      var report = _reports[i];
      if (selectedRows.isSelected(i)) {
        report.selected = true;
        _selectedCount += 1;
      } else {
        report.selected = false;
      }
    }
    notifyListeners();
  }

  String simpleDate(String date) {
    if (date.isNull || date.isEmpty) {
      return "";
    }

    var newDate = date.replaceAll("T", " ");
    var dotIndex = newDate.indexOf(".");
    newDate = newDate.replaceRange(dotIndex, date.length, " ").trimRight();

    return newDate;
  }

  List<_Report> getSelectedReport() {
    List<_Report> selectedReport = [];

    for (var i = 0; i < _reports.length; i += 1) {
      var report = _reports[i];
      if (report.selected) {
        selectedReport.add(report);
      }
    }

    return selectedReport;
  }

  void _sort<T>(Comparable<T> Function(_Report d) getField, bool ascending) {
    _reports.sort((a, b) {
      final aValue = getField(a);
      final bValue = getField(b);
      return ascending
          ? Comparable.compare(aValue, bValue)
          : Comparable.compare(bValue, aValue);
    });

    notifyListeners();
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

  Column element(String title, String content, {double spacing = 10.0}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold
          ),
        ),
        const SizedBox(height : 10.0),
        Text(content),
        SizedBox(height : spacing),
      ]  
    );
  }

  Table createLeftTable(List<List<String>> datas, double headerWidth, double contentWidth) {
    List<TableRow> rows = [];
    for (int i = 0; i < datas.length; i++) {
      rows.add(
        TableRow(
          children: [
            Container(
              padding: EdgeInsets.all(5.0),
              color: Colors.black,
              alignment: Alignment.centerLeft,
              child: Text(
                datas[i][0],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15.0,
                  color: Colors.white
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Container(
              padding: EdgeInsets.all(5.0),
              alignment: Alignment.centerLeft,
              child: Text(
                datas[i][1],
                textAlign: TextAlign.center,
              ),
            )
          ],
        )
      );
    }
    return Table(
            columnWidths: <int, TableColumnWidth>{
              0 : FixedColumnWidth(headerWidth),
              1 : FixedColumnWidth(contentWidth)
            },
            border: TableBorder.all(color: Colors.black),
            children: rows,
          );
  }
  Table createRightTable(List<List<String>> datas, List<double> widths) {
    List<TableRow> rows = [];
    for (int i = 0; i < datas.length; i++) {
      rows.add(
        TableRow(
          children: [
            TableCell(
              verticalAlignment: TableCellVerticalAlignment.fill,
              child: Container(
                padding: EdgeInsets.all(5.0),
                alignment: Alignment.topLeft,
                decoration: const BoxDecoration(
                  color: Colors.black,
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white,
                      width: 1
                    )
                  )
                ),
                child: Text(
                  datas[i][0],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15.0,
                    color: Colors.white
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            ),
            Container(
              padding: EdgeInsets.all(5.0),
              alignment: Alignment.centerLeft,
              child: Text(
                datas[i][1],
                textAlign: TextAlign.center,
              ),
            ),
            TableCell(
              verticalAlignment: TableCellVerticalAlignment.fill,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.black,
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white,
                      width: 1
                    )
                  )
                ),
                padding: EdgeInsets.all(5.0),
                alignment: Alignment.topLeft,
                child: Text(
                  datas[i][2],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15.0,
                    color: Colors.white
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.all(5.0),
              alignment: Alignment.centerLeft,
              child: Text(
                datas[i][3],
                textAlign: TextAlign.left,
              ),
            )
          ],
        )
      );
    }
    return Table(
            columnWidths: <int, TableColumnWidth>{
              0 : FixedColumnWidth(widths[0]),
              1 : FixedColumnWidth(widths[1]),
              2 : FixedColumnWidth(widths[2]),
              3 : FixedColumnWidth(widths[3])
            },
            border: TableBorder.all(color: Colors.black),
            children: rows,
          );
  }
  
  detailDialog(_Report report, _Account account) {
    showDialog(
      context: context, 
      builder: (BuildContext context) {
        return AlertDialog(
          title: Container(
            alignment: Alignment.topLeft,
            child: const Text(
              "유저 상세"
            ),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.black,
                )
              )
            ),
          ),
          contentPadding: const EdgeInsets.all(25.0),
          content: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                alignment: Alignment.center, 
                height: 800,
                margin: const EdgeInsets.all(10.0), 
                child : Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        createLeftTable(
                          [
                            ["계정번호", '${report.account_id}'],
                            ["레포트 번호", '${report.id}'],
                            ["로그인 & UID", "${report.type}, ${report.uid}"],
                            ["아동 나이", '${report.age}'],
                            ["아동 성별", report.gender],
                            ["아버지 연령대", '${report.father_age}'],
                            ["어머니 연령대", '${report.mother_age}']
                          ], 100, 250),
                      ],
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Container(
                      decoration: const BoxDecoration(
                        border: Border(
                          right: BorderSide(
                            color: Colors.black
                          )
                        )
                      ),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        createRightTable([
                          ["리포트 선별 시점", report.createdAt, "리포트 완료 시점", report.completedAt],
                          ["발달 놀이 - 발달 지원 구간 점수", "${report.mainScore}", "발달 놀이 - 발달 지원 구간 텍스트", report.mainComment['section']],
                          ["발달 놀이 - 지원 내용 점수", "${report.mainScore}", "발달 놀이 - 지원 내용 텍스트", report.mainComment['detail']],
                          ["관찰 놀이 - 자폐위험도 점수", '${report.eyeScore}', "관찰 놀이 - 자폐위험도 선별 텍스트", report.eyeComment['section']],
                          ["관찰 놀이 - 필요조치 점수", '${report.eyeScore}', "관찰 놀이 - 필요조치 선별 텍스트", report.eyeComment['detail']],
                          ["부모체크리스트 - 선별구간 점수", '${report.pollScore}', "부모체크리스트 - 선별구간 텍스트", report.pollComment['section']],
                          ["부모체크리스트 - 자폐위험도 점수", '${report.pollScore}', "부모체크리스트 - 자폐위험도 텍스트", report.pollComment['risky']],
                          ["부모체크리스트 - 필요조치 점수", '${report.pollScore}', "부모체크리스트 - 필요조치 텍스트", report.pollComment['detail']]
                        ], [250, 200, 250, 800]),
                      ],
                    ),
                  ],
                ),
              ),
            )
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("닫기")
            )
          ],
        );
      },
    );
  }

  downloadLog(int report_id) async {
    var res = await http.get(
      Uri.parse(
        '$url/api/admin/getLogs?report_id=$report_id'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': '*/*',
          'Authorization' : "Bearer ${MyHomePageState.token}"
        },
    );

    var data = jsonDecode(res.body);
    var success = data['success'];
    if (success) {
      exportLogExcel(data);
    } else {
      await Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage()))
      .then((value) {
        MyHomePageState.refreshToken();
      });
    }
  }

  exportLogExcel(dynamic data) async {
    String uid = data['uid'].toString();
    String report_id = data['report_id'].toString();
    var details = data['details'];
    
    List<dynamic> scores = details.where((detail) => detail['question_id'] == 0).toList();
    List<dynamic> eyetrack = details.where((detail) => detail['question_id'] != 0).toList();
    List<dynamic> polls = scores.where((detail) => detail['part_id'] > 30).toList();

    // Create Excel file
    var excel = Excel.createExcel();

    // Write Totel Log
    {
      String scoreSheetName = "종합";
      excel.rename("Sheet1", scoreSheetName);
      var totalSheet = excel[scoreSheetName];
      totalSheet.insertRowIterables(["완료시간", "게임종류", "세트명", "게임명", "총점", "Right Side", "Wrong Side", "Unknown Side", "Scaled Score"], 0);
      int line = 1;
      for (int i = 0; i < scores.length; i++) { 
        var log = scores[i];
        List<String> detail = log['detail'].split('/');
        detail[2] = (int.parse(detail[2]) % 10).toString();
        if (detail[1].contains("MainGame")) {
          detail.insert(detail.length - 1, "");
          totalSheet.insertRowIterables(detail, line);
          line++;
        }
        else if (detail[1].contains('Eyetrack')) {
          List<String> eyescores = detail.last.split(" | ");
          detail.removeAt(detail.length - 1);
          for (int j = 0; j < eyescores.length; j++) {
            if (eyescores[j].isEmpty) {
              break;
            }

            var sides = eyescores[j].split(",");
            var temp = [...detail];
            temp.insert(temp.length - 1, (j+1).toString());
            for (int k = 0; k < sides.length; k++) {
              temp.add(sides[k].split("-").last);
            }
            totalSheet.insertRowIterables(temp, line);
            line++;
          }
        } else {
          detail.insert(detail.length - 2, "");
          detail.removeAt(detail.length - 1);
          totalSheet.insertRowIterables(detail, line);
          line++;
        }
      }
    }

    // Write Poll Log
    {
      
      String pollSheetName = "부모체크리스트";
      var pollSheet = excel[pollSheetName];
      var columns = ["세트수", "문제번호", "문제내용", "정답으로 선택한 번호"];

      pollSheet.insertRowIterables(columns, 0);
      int line = 1;
      for (int i = 0; i < polls.length; i++) {
        var log = polls[i];
        int part = log['part_id'] % 10;
        List<String> details = log['detail'].split("/").last.split(',');
        for (int j = 0; j < details.length; j++) {
          if (details[j] == " ") {
            break;
          }
          pollSheet.insertRowIterables([part.toString(), (j+1).toString(), problems[i][j], details[j]], line);
          line++;
        }
      }
    }
    
    // Write Eyetrack Log
    {
      for (int i = 0; i < eyetrack.length; i++) {
        var log = eyetrack[i];
        int partId = log['part_id'] % 10;
        int questionId = log['question_id'];
        
        List<String> detail = log['detail'].split('\n');
        String sheetName = "시선추적 ${partId}_$questionId";
        var sheet = excel[sheetName];
        sheet.insertRowIterables(["시간", "성공여부", "시선범위", "시선도약", "좌표"], 0);
        for (int j = 0; j < detail.length; j++) {
          var dataList = detail[j].split(' / ');
          sheet.insertRowIterables(dataList, j + 1);
        }
      }
    }
    

    excel.save(fileName : "${uid}_$report_id.xlsx");

  }

  @override
  DataRow? getRow(int index) {
    assert(index >= 0);
    //if (index >= _reports.length) return null;
    log("index : $index");
    final report = _reports[index];
    return DataRow.byIndex(
      index: index,
      selected: report.selected,
      onSelectChanged: (value) {
        if (report.selected != value) {
          _selectedCount += value! ? 1 : -1;
          assert(_selectedCount >= 0);
          report.selected = value;
          notifyListeners();
        }
      },
      cells: [
        DataCell(
          Center(
            child : Text(
              '${report.id}',
              textAlign: TextAlign.center,
            ),
            //alignment: Alignment.center,
          )
        ),
        DataCell(
          Center(
            child : Text(
              report.createdAt,
              textAlign: TextAlign.center,
            ),
            //alignment: Alignment.center,
          )
        ),
        DataCell(
          Center(
            child : Text(
              '${report.mainScore}',
              textAlign: TextAlign.center,
            )
          )
        ),
        DataCell(
          Center(
            child : Text(
              report.mainComment['section'],
              textAlign: TextAlign.center,
            )
          )
        ),
        DataCell(
          Center(
            child : Text(
              '${report.eyeScore}',
              textAlign: TextAlign.center,
            )
          )
        ),
        DataCell(
          Center(
            child : Text(
              report.eyeComment['section'],
              textAlign: TextAlign.center,
            )
          )
        ),
        DataCell(
          Center(
            child : Text(
              '${report.pollScore}',
              textAlign: TextAlign.center,
            )
          )
        ),
        DataCell(
          Center(
            child : Text(
              report.pollComment['section'],
              textAlign: TextAlign.center,
            )
          )
        ),
        DataCell(
          Center(
            child : Text(
              report.completedAt,
              textAlign: TextAlign.center,
            )
          )
        ),
        DataCell(
          Center(
            child : ElevatedButton(
              child: const Text("상세"),
              style: const ButtonStyle(
                backgroundColor: MaterialStatePropertyAll<Color>(Colors.blue),
                alignment: Alignment.center
              ),
              onPressed: () => detailDialog(report, _account),
            )
          )
        ),
        DataCell(
          Center(
            child : ElevatedButton(
              child: const Text("로그 상세"),
              style: const ButtonStyle(
                backgroundColor: MaterialStatePropertyAll<Color>(Colors.blue),
                alignment: Alignment.center
              ),
              onPressed: () => downloadLog(report.id),
            )
          )
        )
      ],
    );
  }

  @override
  int get rowCount => _reports.length;

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => _selectedCount;
  
  void _selectAll(bool? checked) {
    for (final report in _reports) {
      report.selected = checked ?? false;
    }
    _selectedCount = checked! ? _reports.length : 0;
    notifyListeners();
  }
}
