// ignore_for_file: library_private_types_in_public_api, avoid_unnecessary_containers, sort_child_properties_last, non_constant_identifier_names

import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:iboamanager/main.dart';

const url = "http://localhost:8080";

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  AdminPageState createState() => AdminPageState();
}

class AdminPageState extends State<AdminPage> with RestorationMixin {
  String token = "";

  final RestorableInt _rowIndex = RestorableInt(0);
  final RestorableInt _rowsPerPage =
      RestorableInt(PaginatedDataTable.defaultRowsPerPage);
  final RestorableBool _sortAscending = RestorableBool(true);
  final RestorableIntN _sortColumnIndex = RestorableIntN(null);

  _AccountDataSource? _accountDataSource;
  @override
  void initState() {
    token = MyHomePageState.token;
    super.initState();
  }

  @override
  String? get restorationId => "adminPage";

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_rowIndex, 'current_row_index');
    registerForRestoration(_rowsPerPage, 'rows_per_page');
    registerForRestoration(_sortAscending, 'sort_ascending');
    registerForRestoration(_sortColumnIndex, 'sort_column_index');

    _accountDataSource ??= _AccountDataSource(context);
    switch (_sortColumnIndex.value) {
      case 0:
        _accountDataSource!._sort<num>((d) => d.id, _sortAscending.value);
        break;
      case 1:
        _accountDataSource!._sort<String>((d) => d.name, _sortAscending.value);
        break;
      case 2:
        _accountDataSource!._sort<String>((d) => d.role, _sortAscending.value);
        break;
      case 3:
        _accountDataSource!
            ._sort<String>((d) => d.createdAt, _sortAscending.value);
        break;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _accountDataSource ??= _AccountDataSource(context);
  }

  void _sort<T>(
    Comparable<T> Function(_Account d) getField,
    int columnIndex,
    bool ascending,
  ) {
    _accountDataSource!._sort<T>(getField, ascending);
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
    _accountDataSource!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Scrollbar(
        child: ListView(
          restorationId: 'data_table_list_view',
          children: [
            PaginatedDataTable(
              header: const Text("어드민 관리"),
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
                      "이름",
                      textAlign: TextAlign.center,
                    ),
                    width: 30,
                  ),
                  numeric: true,
                  onSort: (columnIndex, ascending) =>
                      _sort<String>((d) => d.name, columnIndex, ascending),
                ),
                DataColumn(
                  label: Container(
                    child: const Text("이메일"),
                    width: 40,
                  ),
                  numeric: true,
                  onSort: (columnIndex, ascending) =>
                      _sort<String>((d) => d.email, columnIndex, ascending),
                ),
                DataColumn(
                  label: Container(
                    child: const Text("권한"),
                    width: 30,
                  ),
                  numeric: true,
                  onSort: (columnIndex, ascending) =>
                      _sort<String>((d) => d.role, columnIndex, ascending),
                ),
                DataColumn(
                  label: Container(
                    child: const Text(
                      "생성일",
                      textAlign: TextAlign.center,
                    ),
                    width: 1000,
                  ),
                  numeric: true,
                  onSort: (columnIndex, ascending) => _sort<String>(
                      (d) => d.createdAt, columnIndex, ascending),
                ),
                DataColumn(
                  label: Container(
                    child: const Text(
                      "수정",
                      textAlign: TextAlign.center,
                    ),
                    width: 30,
                    alignment: Alignment.center,
                  ),
                  numeric: true,
                  onSort: (columnIndex, ascending) =>
                      _sort<String>((d) => d.role, columnIndex, ascending),
                ),
              ],
              source: _accountDataSource!,
            ),
          ],
        )
      ),
    );
  }
}

class _Account {
  _Account(this.id, this.name, this.email, this.role, this.createdAt);

  final int id;
  final String name;
  final String email;
  String role;
  final String createdAt;

  _Account Copy() {
    return _Account(id, name, email, role, createdAt);
  }
}

class _AccountDataSource extends DataTableSource {
  final formKey = GlobalKey<FormState>();
  final List<DropdownMenuItem<String>> _valueList = [
    const DropdownMenuItem(
      child: Text("master"), 
      value: 'master',
    ), 
    const DropdownMenuItem(
      child: Text("normal"), 
      value: 'normal',
    ), 
  ];

  _AccountDataSource(this.context) {
    _accounts = []; 
    getAccounts();
  }

  final BuildContext context;
  late List<_Account> _accounts;

  void getAccounts() async {
    try {
      log("getAdmins");
      var res = await http.get(
      Uri.parse(
        '$url/api/admin/getAdmins'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': '*/*'
        },
      );

      var data = jsonDecode(res.body);
      var success = data['success'];
      if (success) {
        final admins = data['admins'];
        _accounts.clear();
        for (int i = 0; i < admins.length; i++) {
          final admin = admins[i];
          log(admin.toString());
          _accounts.add(
            _Account(admin['id'], admin['name'], admin['email'], admin['role'], admin['createdAt'])
          );
        }
      } else {
        _accounts = [];
      }

      notifyListeners();
    } catch (error) {
      log(error.toString());
    }
  }

  int _selectedCount = 0;
  void _sort<T>(Comparable<T> Function(_Account d) getField, bool ascending) {
    _accounts.sort((a, b) {
      final aValue = getField(a);
      final bValue = getField(b);
      return ascending
          ? Comparable.compare(aValue, bValue)
          : Comparable.compare(bValue, aValue);
    });

    notifyListeners();
  }

  deleteAdmin(_Account account) async {
    try {
      log("id : ${account.id}, role : ${account.role}");
      http.Response res = await http.delete(
        Uri.parse("$url/api/admin/deleteAdmin"),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': '*/*'
        },
        body: {
          'id': "${account.id}"
        }
      );

      var data = jsonDecode(res.body);
      return data['success'];

    } catch(error) {
      log(error.toString());
    }
  }

  modifyAdmin(_Account account) async {
    try {
      log("id : ${account.id}, role : ${account.role}");
      http.Response res = await http.put(
        Uri.parse("$url/api/admin/modifyAdmin"),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': '*/*'
        },
        body: {
          'id': "${account.id}",
          'role': account.role
        }
      );

      var data = jsonDecode(res.body);
      return data['success'];

    } catch(error) {
      log(error.toString());
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

  modifyDialog(_Account account) {
    var tempAccount = account.Copy();

    showDialog(
      context: context, 
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("권한 변경 또는 삭제"),
          content: Form(
            key: formKey,
            child: Container(
              alignment: Alignment.center, 
              height: 300,
              margin: EdgeInsets.all(10.0), 
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text("id : ${tempAccount.id}"),
                  Text("이메일 : ${tempAccount.email}"),
                  Text("이름 : ${tempAccount.name}"),
                  DropdownButtonFormField(
                    items: _valueList,
                    onChanged: ((value) {
                      tempAccount.role = value.toString();
                    }),
                  )
                ],
              ),
            )
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("취소")
            ),
            TextButton(
              onPressed: () async {
                var result = await deleteAdmin(tempAccount);
                if (result) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(makeSnackBar("삭제 성공"));
                  getAccounts();
                } else {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(makeSnackBar("삭제 실패"));
                }
              },
              child: const Text("삭제")
            ),
            TextButton(
              onPressed: () async {
                var result = await modifyAdmin(tempAccount);
                if (result) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(makeSnackBar("변경 성공"));
                  getAccounts();
                } else {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(makeSnackBar("변경 실패"));
                }
              },
              child: const Text("수정")
            ), 
          ],
        );
      },
    );
  }

  @override
  DataRow? getRow(int index) {
    assert(index >= 0);
    if (index >= _accounts.length) return null;
    final account = _accounts[index];
    return DataRow.byIndex(
      index: index,
      cells: [
        DataCell(Text('${account.id}')),
        DataCell(Text(account.name)),
        DataCell(Text(account.email)),
        DataCell(Text(account.role)),
        DataCell(Text(account.createdAt)),
        DataCell(
          ElevatedButton(
            child: const Text("수정"),
            style: const ButtonStyle(
              backgroundColor: MaterialStatePropertyAll<Color>(Colors.blue),
              alignment: Alignment.center
            ),
            onPressed: () => modifyDialog(account),
          ),
        )
      ],
    );
  }

  @override
  int get rowCount => _accounts.length;

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => _selectedCount;
}
