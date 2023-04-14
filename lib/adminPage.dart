// ignore_for_file: library_private_types_in_public_api, avoid_unnecessary_containers, sort_child_properties_last, non_constant_identifier_names, use_build_context_synchronously

import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:iboamanager/main.dart';

//const url = "http://localhost:37235";
String url = "http://ec2-43-200-219-190.ap-northeast-2.compute.amazonaws.com:37235";


class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> with RestorationMixin {
  String? token = "";

  final RestorableInt _rowIndex = RestorableInt(0);
  final RestorableInt _rowsPerPage =
      RestorableInt(PaginatedDataTable.defaultRowsPerPage);
  final RestorableBool _sortAscending = RestorableBool(true);
  final RestorableIntN _sortColumnIndex = RestorableIntN(null);

  _AdminDataSource? _adminDataSource;
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

    _adminDataSource ??= _AdminDataSource(context);
    switch (_sortColumnIndex.value) {
      case 0:
        _adminDataSource!._sort<num>((d) => d.id, _sortAscending.value);
        break;
      case 1:
        _adminDataSource!._sort<String>((d) => d.name, _sortAscending.value);
        break;
      case 2:
        _adminDataSource!._sort<String>((d) => d.role, _sortAscending.value);
        break;
      case 3:
        _adminDataSource!
            ._sort<String>((d) => d.createdAt, _sortAscending.value);
        break;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _adminDataSource ??= _AdminDataSource(context);
  }

  void _sort<T>(
    Comparable<T> Function(_Admin d) getField,
    int columnIndex,
    bool ascending,
  ) {
    _adminDataSource!._sort<T>(getField, ascending);
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
    _adminDataSource!.dispose();
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
              child: Row(
                children: [ const Text(
                    "어드민 관리",
                    style: TextStyle(
                      fontSize: 24.0,
                    //fontWeight: FontWeight.w400
                    ),
                  ),
                  Row(
                    children: [
                      ElevatedButton(
                        child: const Text("추가하기"),
                        style: const ButtonStyle(
                          backgroundColor: MaterialStatePropertyAll<Color>(Colors.blue),
                          alignment: Alignment.center
                        ),
                        onPressed: () =>_adminDataSource?.createDialog(),
                      ),
                      const SizedBox(
                        width: 121,
                      )
                    ],
                  )
                ],
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
              ),
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
              columnSpacing: 90,
              columns: [
                DataColumn(
                  label: const Expanded(
                    child: Text(
                      "ㅤ번호",
                      textAlign: TextAlign.center,
                    ),
                    //color: Colors.blue,
                  ),
                  onSort: (columnIndex, ascending) =>
                      _sort<num>((d) => d.id, columnIndex, ascending),
                ),
                DataColumn(
                  label: const Expanded(
                    child: Text(
                        "ㅤ이름",
                        textAlign: TextAlign.center,
                      )
                  ),
                  onSort: (columnIndex, ascending) => _sort<String>((d) => d.name, columnIndex, ascending),
                ),
                DataColumn(
                  label: const Expanded(
                    child: Text(
                    "ㅤ이메일",
                    textAlign: TextAlign.center
                    ),
                  ),
                  onSort: (columnIndex, ascending) =>
                      _sort<String>((d) => d.email, columnIndex, ascending),
                ),
                DataColumn(
                  label: const Expanded(
                    child: Text(
                    "ㅤ권한",
                    textAlign: TextAlign.center
                    ),
                  ),
                  onSort: (columnIndex, ascending) =>
                      _sort<String>((d) => d.role, columnIndex, ascending),
                ),
                DataColumn(
                  label: const Expanded(
                    child: Text(
                      "ㅤ생성일",
                      textAlign: TextAlign.center,
                    ),
                  ),
                  onSort: (columnIndex, ascending) => _sort<String>(
                      (d) => d.createdAt, columnIndex, ascending),
                ),
                DataColumn(
                  label: const Expanded(
                    child: Text(
                      "ㅤ수정",
                      textAlign: TextAlign.center,
                    )
                  ),
                  onSort: (columnIndex, ascending) =>
                      _sort<String>((d) => d.role, columnIndex, ascending),
                ),
              ],
              source: _adminDataSource!,
            ),
          ],
        )
      ),
    );
  }
}

class _Admin {
  _Admin(this.id, this.name, this.email, this.role, this.createdAt);

  final int id;
  final String name;
  final String email;
  String role;
  final String createdAt;

  _Admin Copy() {
    return _Admin(id, name, email, role, createdAt);
  }
}

class _AdminDataSource extends DataTableSource {
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

  _AdminDataSource(this.context) {
    _admins = []; 
    getAdmins();
  }

  final BuildContext context;
  late List<_Admin> _admins;

  void getAdmins() async {
    try {
      var res = await http.get(
      Uri.parse(
        '$url/api/admin/getAdmins'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': '*/*',
          'Authorization' : "Bearer ${MyHomePageState.token}"
        },
      );

      var data = jsonDecode(res.body);
      var success = data['success'];
      if (success) {
        final admins = data['admins'];
        _admins.clear();
        for (int i = 0; i < admins.length; i++) {
          final admin = admins[i];
          String createdAt = admin['createdAt'].toString().replaceFirst("T", " ").replaceAll(".000Z", "");
          _admins.add(
            _Admin(admin['id'], admin['name'], admin['email'], admin['role'], createdAt)
          );
        }
      } else {
        _admins = [];
      }

      notifyListeners();
    } catch (error) {
      log(error.toString());
    }
  }

  int _selectedCount = 0;
  void _sort<T>(Comparable<T> Function(_Admin d) getField, bool ascending) {
    _admins.sort((a, b) {
      final aValue = getField(a);
      final bValue = getField(b);
      return ascending
          ? Comparable.compare(aValue, bValue)
          : Comparable.compare(bValue, aValue);
    });

    notifyListeners();
  }
  createAdmin(String email, String password, String name, String role) async {
    try {
      http.Response res = await http.post(
        Uri.parse("$url/api/admin/createAdmin"),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': '*/*',
          'Authorization' : "Bearer ${MyHomePageState.token}"
        },
        body: {
          'email': email,
          'password': password,
          'name' : name,
          'role' : role
        }
      );

      return res;

    } catch(error) {
      log(error.toString());
    }
  }

  deleteAdmin(_Admin account) async {
    try {
      http.Response res = await http.delete(
        Uri.parse("$url/api/admin/deleteAdmin"),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': '*/*',
          'Authorization' : "Bearer ${MyHomePageState.token}"
        },
        body: {
          'id': "${account.id}"
        }
      );

      return res;

    } catch(error) {
      log(error.toString());
    }
  }

  modifyAdmin(_Admin account) async {
    try {
      http.Response res = await http.put(
        Uri.parse("$url/api/admin/modifyAdmin"),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': '*/*',
          'Authorization' : "Bearer ${MyHomePageState.token}"
        },
        body: {
          'id': "${account.id}",
          'role': account.role
        }
      );

      return res;
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

  Future<bool> validate() async {
    if (formKey.currentState!.validate() == false) {
      return false;
    }

    formKey.currentState!.save();

    return true;
  }

  createDialog() {
    String email = "";
    String password = "";
    String name = "";
    String role = "normal";

    showDialog(
      context: context, 
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("관리자 계정 생성"),
          content: Form(
            key: formKey,
            child: Container(
              alignment: Alignment.center, 
              height: 300,
              margin: const EdgeInsets.all(10.0), 
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  TextFormField(
                    decoration: const InputDecoration(labelText: '이메일'),
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
                    decoration: const InputDecoration(labelText: '비밀번호'),
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
                  TextFormField(
                    decoration: const InputDecoration(labelText: '이름'),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return "이름을 입력하세요";
                      }

                      return null;
                    },
                    onSaved: (value) {
                      name = value!;
                    },
                  ),
                  DropdownButtonFormField(
                    decoration: const InputDecoration(labelText: "권한"),
                    items: _valueList,
                    onChanged: ((value) {
                      role = value.toString();
                    }),

                    validator: (value) {
                      if (value!.isEmpty) {
                        return "권한을 선택하세요";
                      }
                      
                      return null;
                    },
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
                var valid = await validate();
                log("vaid : " + valid.toString());
                if (!valid) {
                  return;
                }

                var res = await createAdmin(email, password, name, role);
                var data = jsonDecode(res.body);
                var result = data['success'];

                Navigator.of(context).pop();
                if (result) {
                  ScaffoldMessenger.of(context).showSnackBar(makeSnackBar("추가 성공"));
                  getAdmins();
                } else {
                  if (res.statusCode == 403) {
                    ScaffoldMessenger.of(context).showSnackBar(makeSnackBar("Master가 아닙니다"));
                  } else if (res.statusCode == 404) {
                    ScaffoldMessenger.of(context).showSnackBar(makeSnackBar("계정을 찾을 수 없습니다."));
                  } else if (res.statusCode == 409) {
                    ScaffoldMessenger.of(context).showSnackBar(makeSnackBar("존재하는 이메일입니다."));
                  }
                }
              },
              child: const Text("추가")
            ),
          ],
        );
      },
    );
  }

  modifyDialog(_Admin account) {
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
                var res = await deleteAdmin(tempAccount);
                var data = jsonDecode(res.body);
                var result = data['success'];
                Navigator.of(context).pop();
                if (result) {
                  ScaffoldMessenger.of(context).showSnackBar(makeSnackBar("삭제 성공"));
                  getAdmins();
                } else {
                  if (res.statusCode == 403) {
                    ScaffoldMessenger.of(context).showSnackBar(makeSnackBar("Master가 아닙니다"));
                  } else if (res.statusCode == 404) {
                    ScaffoldMessenger.of(context).showSnackBar(makeSnackBar("계정을 찾을 수 없습니다."));
                  } else if (res.statusCode == 409) {
                    ScaffoldMessenger.of(context).showSnackBar(makeSnackBar("삭제에 실패했습니다."));
                  }
                }
              },
              child: const Text("삭제")
            ),
            TextButton(
              onPressed: () async {
                var res = await modifyAdmin(tempAccount);
                var data = jsonDecode(res.body);
                var result = data['success'];
                Navigator.of(context).pop();
                if (result) {
                  ScaffoldMessenger.of(context).showSnackBar(makeSnackBar("수정 성공"));
                  getAdmins();
                } else {
                  if (res.statusCode == 403) {
                    ScaffoldMessenger.of(context).showSnackBar(makeSnackBar("Master가 아닙니다"));
                  } else if (res.statusCode == 404) {
                    ScaffoldMessenger.of(context).showSnackBar(makeSnackBar("계정을 찾을 수 없습니다."));
                  } else if (res.statusCode == 409) {
                    ScaffoldMessenger.of(context).showSnackBar(makeSnackBar("수정에 실패했습니다"));
                  }
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
    if (index >= _admins.length) return null;
    final admin = _admins[index];
    return DataRow.byIndex(
      index: index,
      cells: [
        DataCell(
          Center(
            child : Text(
                '${admin.id}',
                textAlign: TextAlign.center,
            ),
          ),
        ),
        DataCell(
          Center(
            child: 
              Text(
                admin.name,
                textAlign: TextAlign.center,
              )
            ,
          )
        ),
        DataCell(
          Center(
            child: Text(
              admin.email,
              textAlign: TextAlign.center,
            ),
          )
        ),
        DataCell(
          Center(
            child: Text(
              admin.role,
              textAlign: TextAlign.center,
            ),
          )
        ),
        DataCell(
          Center(
            child: Text(
              admin.createdAt,
              textAlign: TextAlign.center,
            ),
          )
        ),
        DataCell(
          Center(
            child: ElevatedButton(
              child: const Text("수정"),
              style: const ButtonStyle(
                backgroundColor: MaterialStatePropertyAll<Color>(Colors.blue),
                alignment: Alignment.center
              ),
              onPressed: () => modifyDialog(admin),
            ),
          )
        )
      ],
    );
  }

  @override
  int get rowCount => _admins.length;

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => _selectedCount;
}
