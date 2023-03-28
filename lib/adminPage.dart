// ignore_for_file: library_private_types_in_public_api, avoid_unnecessary_containers, sort_child_properties_last

import 'package:flutter/material.dart';
import 'package:iboamanager/main.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> with RestorationMixin {
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
              columns: [
                DataColumn(
                  label: const Text("번호"),
                  onSort: (columnIndex, ascending) =>
                      _sort<num>((d) => d.id, columnIndex, ascending),
                ),
                DataColumn(
                  label: const Text("이름"),
                  numeric: true,
                  onSort: (columnIndex, ascending) =>
                      _sort<String>((d) => d.name, columnIndex, ascending),
                ),
                DataColumn(
                  label: const Text("이메일"),
                  numeric: true,
                  onSort: (columnIndex, ascending) =>
                      _sort<String>((d) => d.email, columnIndex, ascending),
                ),
                DataColumn(
                  label: const Text("권한"),
                  numeric: true,
                  onSort: (columnIndex, ascending) =>
                      _sort<String>((d) => d.role, columnIndex, ascending),
                ),
                DataColumn(
                  label: const Text("생성일"),
                  numeric: true,
                  onSort: (columnIndex, ascending) => _sort<String>(
                      (d) => d.createdAt, columnIndex, ascending),
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
  final String role;
  final String createdAt;
}

class _AccountDataSource extends DataTableSource {
  _AccountDataSource(this.context) {
    _accounts = <_Account>[
      _Account(1, "이름1", "이메일1", "마스타1", "오늘"),
      _Account(2, "이름2", "이메일2", "마네쟈2", "내일"),
      _Account(3, "이름3", "이메일3", "마네쟈3", "모레"),
      _Account(4, "이름4", "이메일4", "마네쟈4", "글피"),
      _Account(5, "이름5", "이메일5", "마네쟈5", "다음주"),
    ];
  }

  final BuildContext context;
  late List<_Account> _accounts;
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
