// ignore_for_file: library_private_types_in_public_api, sort_child_properties_last

import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'main.dart';

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  _UserPageState createState() => _UserPageState();
}

const url = "http://localhost:8080";

class _UserPageState extends State<UserPage> with RestorationMixin {
  String token = "";
  String uid = "";
  final formKey = GlobalKey<FormState>();
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

  final RestorableInt _rowIndex = RestorableInt(0);
  final RestorableInt _rowsPerPage =
      RestorableInt(PaginatedDataTable.defaultRowsPerPage);
  final RestorableBool _sortAscending = RestorableBool(true);
  final RestorableIntN _sortColumnIndex = RestorableIntN(null);

  _ReportDataSource? _reportDataSource;
  @override
  void initState() {
    token = MyHomePageState.token;
    super.initState();
  }

  @override
  String? get restorationId => "userPage";

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
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
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reportDataSource ??= _ReportDataSource(context);
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

  @override
  void dispose() {
    _rowsPerPage.dispose();
    _sortColumnIndex.dispose();
    _sortAscending.dispose();
    _reportDataSource!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Scrollbar(
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
                  Flexible(
                    child: TextFormField(
                      decoration: const InputDecoration(labelText: 'UID'),
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
                  ElevatedButton(
                    child: const Text(
                      "확인"
                    ),
                    onPressed: () => validate(), 
                  )
                ]
              ),
            ),
            Row(
              children : [
                Text("id : ${_reportDataSource!._account.id}"),
                Text("uid : ${_reportDataSource!._account.uid}"),
                Text("타입 : ${_reportDataSource!._account.type}"),
                Text("성별 : ${_reportDataSource!._account.gender}"),
                Text("uid : ${_reportDataSource!._account.age}"),
              ]
            ),

            PaginatedDataTable(
              rowsPerPage: _rowsPerPage.value,
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
              columnSpacing: 10.0,
              columns: [
                DataColumn(
                  label: Container(
                    child: const Text(
                      "번호",
                      textAlign: TextAlign.center,
                    ),
                    width: 30,
                  ),
                  numeric: true,
                  onSort: (columnIndex, ascending) =>
                      _sort<num>((d) => d.id, columnIndex, ascending),
                ),
                DataColumn(
                  label: Container(
                    child: const Text(
                      "생성 시간",
                      textAlign: TextAlign.center,
                    ),
                    width: 200,
                  ),
                  numeric: true,
                  onSort: (columnIndex, ascending) =>
                      _sort<String>((d) => d.completedAt, columnIndex, ascending),
                ),
                DataColumn(
                  label: Container(
                    child: const Text("점수"),
                    width: 200,
                  ),
                  numeric: true,
                  //onSort: (columnIndex, ascending) =>_sort<String>((d) => d.email, columnIndex, ascending),
                ),
                DataColumn(
                  label: Container(
                    child: const Text(
                      "완료 시간"
                    ),
                    width: 200,
                  ),
                  numeric: true,
                  onSort: (columnIndex, ascending) =>
                      _sort<String>((d) => d.completedAt, columnIndex, ascending),
                ),
                DataColumn(
                  label: Container(
                    child: const Text(
                      "수정",
                      textAlign: TextAlign.left,
                    ),
                    width: 30,
                    alignment: Alignment.centerLeft,
                  ),
                  numeric: true,
                ),
              ],
              source: _reportDataSource!,
            ),
          ],
        )
      ),
    );
  }
}

class _Account {
  _Account(this.id, this.uid, this.type, this.gender, this.age, this.createdAt);

  final int id;
  final String uid;
  final String type;
  final String gender;
  final int age;
  final String createdAt;
}

class _Report {
  _Report(this.id, this.createdAt, this.scores, this.completedAt);

  final int id;
  final String createdAt;
  final Object scores;
  final String completedAt;
}

class _ReportDataSource extends DataTableSource {
  
  _ReportDataSource(this.context) {
    _reports = []; 
    _account = _Account(0, "", "", "", 0, "");
  }

  final BuildContext context;
  late List<_Report> _reports;
  late _Account _account;
  

  Future<bool> getReports(String uid) async {
    try {
      var res = await http.get(
      Uri.parse(
        '$url/api/admin/getReports?uid=$uid'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': '*/*'
        },
        
      );

      var data = jsonDecode(res.body);
      var success = data['success'];
      log(data.toString());
      if (success) {
        var account = data['account'];
        log(account.toString());
        _account = _Account(
          account['id'], 
          account['uid'],
          account['type'],
          account['gender'] == null ? "Null" : account['gender'],
          account['age'] == null ? 0 : account['age'],
          account['createdAt'] == null ? "" : account['createdAt']
        );

        // final reports = data['reports'];
        // _reports.clear();
        // for (int i = 0; i < reports.length; i++) {
        //   final report = reports[i];
        //   log(report.toString());
        //   _reports.add(
        //     //_Report(report['id'], report['name'], report['email'], report['role'], report['createdAt'])
        //   );
        // }

        
      } else {
        _reports = [];
      }

      notifyListeners();
      return true;
    } catch (error) {
      log(error.toString());
      return false;
    }
  }

  int _selectedCount = 0;
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

  @override
  DataRow? getRow(int index) {
    assert(index >= 0);
    if (index >= _reports.length) return null;
    final report = _reports[index];
    return DataRow.byIndex(
      index: index,
      cells: [
        DataCell(Text('${report.id}')),
        DataCell(Text(report.createdAt)),
        DataCell(Text(report.scores.toString())),
        DataCell(Text(report.completedAt)),
        DataCell(Text(report.createdAt)),
        DataCell(
          ElevatedButton(
            child: const Text("수정"),
            style: const ButtonStyle(
              backgroundColor: MaterialStatePropertyAll<Color>(Colors.blue),
              alignment: Alignment.center
            ),
            onPressed: () {},
          ),
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
}
