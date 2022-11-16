import 'package:ardrive_ui_library/ardrive_ui_library.dart';
import 'package:ardrive_ui_library/src/components/data_table/data_table_page_indicators/numbered_page_indicator.dart';
import 'package:flutter/material.dart';

class ArDriveDataTable extends StatefulWidget {
  ArDriveDataTable({
    Key? key,
    required this.columns,
    required this.showCheckboxColumn,
    this.sortColumnIndex,
    this.sortAscending = true,
    this.dataRowHeight = kMinInteractiveDimension,
    this.headingRowHeight = 56.0,
    this.horizontalMargin = 24.0,
    this.columnSpacing = 56.0,
    this.showFirstLastButtons = false,
    this.initialFirstRowIndex = 0,
    this.onPageChanged,
    this.rowsPerPage = defaultRowsPerPage,
    this.availableRowsPerPage = const <int>[
      defaultRowsPerPage,
      defaultRowsPerPage * 2,
      defaultRowsPerPage * 5,
      defaultRowsPerPage * 10
    ],
    this.onRowsPerPageChanged,
    this.arrowHeadColor,
    required this.source,
    this.checkboxHorizontalMargin,
    this.tableKey,
    this.rowsPerPageText,
    this.rowCountText,
  })  : assert(columns.isNotEmpty),
        assert(sortColumnIndex == null ||
            (sortColumnIndex >= 0 && sortColumnIndex < columns.length)),
        assert(rowsPerPage > 0),
        assert(() {
          if (onRowsPerPageChanged != null) {
            assert(availableRowsPerPage.contains(rowsPerPage));
          }
          return true;
        }()),
        super(key: key);

  /// The configuration and labels for the columns in the table.
  final List<DataColumn> columns;

  /// The current primary sort key's column.
  ///
  /// See [DataTable.sortColumnIndex].
  final int? sortColumnIndex;

  final Key? tableKey;

  /// Whether the column mentioned in [sortColumnIndex], if any, is sorted
  /// in ascending order.
  ///
  /// See [DataTable.sortAscending].
  final bool sortAscending;
  final bool showCheckboxColumn;

  /// The height of each row (excluding the row that contains column headings).
  ///
  /// This value is optional and defaults to kMinInteractiveDimension if not
  /// specified.
  final double dataRowHeight;

  /// The height of the heading row.
  ///
  /// This value is optional and defaults to 56.0 if not specified.
  final double headingRowHeight;

  /// The horizontal margin between the edges of the table and the content
  /// in the first and last cells of each row.
  ///
  /// When a checkbox is displayed, it is also the margin between the checkbox
  /// the content in the first data column.
  ///
  /// This value defaults to 24.0 to adhere to the Material Design specifications.
  ///
  /// If [checkboxHorizontalMargin] is null, then [horizontalMargin] is also the
  /// margin between the edge of the table and the checkbox, as well as the
  /// margin between the checkbox and the content in the first data column.
  final double horizontalMargin;

  /// The horizontal margin between the contents of each data column.
  ///
  /// This value defaults to 56.0 to adhere to the Material Design specifications.
  final double columnSpacing;

  /// Flag to display the pagination buttons to go to the first and last pages.
  final bool showFirstLastButtons;

  /// The index of the first row to display when the widget is first created.
  final int? initialFirstRowIndex;

  /// Invoked when the user switches to another page.
  ///
  /// The value is the index of the first row on the currently displayed page.
  final ValueChanged<int>? onPageChanged;

  /// The number of rows to show on each page.
  ///
  /// See also:
  ///
  ///  * [onRowsPerPageChanged]
  ///  * [defaultRowsPerPage]
  final int rowsPerPage;

  /// The default value for [rowsPerPage].
  ///
  /// Useful when initializing the field that will hold the current
  /// [rowsPerPage], when implemented [onRowsPerPageChanged].
  static const int defaultRowsPerPage = 10;

  /// The options to offer for the rowsPerPage.
  ///
  /// The current [rowsPerPage] must be a value in this list.
  ///
  /// The values in this list should be sorted in ascending order.
  final List<int> availableRowsPerPage;

  /// Invoked when the user selects a different number of rows per page.
  ///
  /// If this is null, then the value given by [rowsPerPage] will be used
  /// and no option will be provided to change the value.
  final ValueChanged<int?>? onRowsPerPageChanged;

  /// The data source which provides data to show in each row. Must be non-null.
  ///
  /// This object should generally have a lifetime longer than the
  /// [ArDriveDataTable] widget itself; it should be reused each time the
  /// [ArDriveDataTable] constructor is called.
  final DataTableSource source;

  /// Horizontal margin around the checkbox, if it is displayed.
  ///
  /// If null, then [horizontalMargin] is used as the margin between the edge
  /// of the table and the checkbox, as well as the margin between the checkbox
  /// and the content in the first data column. This value defaults to 24.0.
  final double? checkboxHorizontalMargin;

  /// Defines the color of the arrow heads in the footer.
  final Color? arrowHeadColor;

  //Localizations and Tooltip Text
  final String? rowsPerPageText;

  final String Function(int, int, int)? rowCountText;

  @override
  ArDriveDataTableState createState() => ArDriveDataTableState();
}

/// Holds the state of a [ArDriveDataTable].
///
/// The table can be programmatically paged using the [pageTo] method.
class ArDriveDataTableState extends State<ArDriveDataTable> {
  late int _firstRowIndex;
  late int _rowCount;
  late bool _rowCountApproximate;
  final Map<int, DataRow?> _rows = <int, DataRow?>{};
  final ScrollController scrollController = ScrollController();
  @override
  void initState() {
    super.initState();
    _firstRowIndex = PageStorage.of(context)?.readState(context) as int? ??
        widget.initialFirstRowIndex ??
        0;
    widget.source.addListener(_handleDataSourceChanged);
    _handleDataSourceChanged();
  }

  @override
  void didUpdateWidget(ArDriveDataTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source) {
      oldWidget.source.removeListener(_handleDataSourceChanged);
      widget.source.addListener(_handleDataSourceChanged);
      _handleDataSourceChanged();
    }
  }

  @override
  void dispose() {
    widget.source.removeListener(_handleDataSourceChanged);
    super.dispose();
  }

  void _handleDataSourceChanged() {
    setState(() {
      _rowCount = widget.source.rowCount;
      _rowCountApproximate = widget.source.isRowCountApproximate;
      _rows.clear();
    });
  }

  /// Ensures that the given row is visible.
  void pageTo(int rowIndex) {
    final oldFirstRowIndex = _firstRowIndex;
    setState(() {
      final rowsPerPage = widget.rowsPerPage;
      _firstRowIndex = (rowIndex ~/ rowsPerPage) * rowsPerPage;
    });
    if ((widget.onPageChanged != null) &&
        (oldFirstRowIndex != _firstRowIndex)) {
      widget.onPageChanged!(_firstRowIndex);
    }
    _resetScroll();
  }

  DataRow _getProgressIndicatorRowFor(int index) {
    var haveProgressIndicator = false;
    final cells = widget.columns.map<DataCell>((DataColumn column) {
      if (!column.numeric) {
        haveProgressIndicator = true;
        return const DataCell(CircularProgressIndicator());
      }
      return DataCell.empty;
    }).toList();
    if (!haveProgressIndicator) {
      haveProgressIndicator = true;
      cells[0] = const DataCell(CircularProgressIndicator());
    }
    return DataRow.byIndex(
      index: index,
      cells: cells,
    );
  }

  List<DataRow> _getRows(int firstRowIndex, int rowsPerPage) {
    final result = <DataRow>[];
    final nextPageFirstRowIndex = firstRowIndex + rowsPerPage;
    var haveProgressIndicator = false;
    for (var index = firstRowIndex; index < nextPageFirstRowIndex; index += 1) {
      DataRow? row;
      if (index < _rowCount || _rowCountApproximate) {
        row = _rows.putIfAbsent(index, () => widget.source.getRow(index));
        if (row == null && !haveProgressIndicator) {
          row ??= _getProgressIndicatorRowFor(index);
          haveProgressIndicator = true;
        }
      }
      if (row != null) {
        result.add(row);
      }
    }
    return result;
  }

  void _resetScroll() {
    scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 10),
      curve: Curves.easeIn,
    );
  }

  void _handleFirst() {
    pageTo(0);
  }

  pageButtonStyle() {
    return TextButton.styleFrom(
      padding: EdgeInsets.zero,
      minimumSize: const Size(10, 10),
      textStyle: TextStyle(
        color: ArDriveTheme.of(context).themeData.colors.themeFgDefault,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final footerTextStyle = Theme.of(context).textTheme.caption!.copyWith(
          color: ArDriveTheme.of(context).themeData.colors.themeFgDefault,
        );

    final footerWidgets = <Widget>[];
    if (widget.onRowsPerPageChanged != null) {
      final List<Widget> availableRowsPerPage = widget.availableRowsPerPage
          .where(
              (int value) => value <= _rowCount || value == widget.rowsPerPage)
          .map<DropdownMenuItem<int>>((int value) {
        return DropdownMenuItem<int>(
          value: value,
          child: Text('$value'),
        );
      }).toList();
      footerWidgets.addAll(<Widget>[
        Container(
          width: 14.0,
        ),
        Text(
          widget.rowsPerPageText ?? 'Rows Per Page',
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 56.0),
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                style: footerTextStyle,
                items: availableRowsPerPage.cast<DropdownMenuItem<int>>(),
                value: widget.rowsPerPage,
                onChanged: (rowsPerPage) {
                  widget.onRowsPerPageChanged?.call(rowsPerPage);
                  _handleFirst();
                },
              ),
            ),
          ),
        ),
      ]);
    }
    footerWidgets.addAll(<Widget>[
      Container(width: 32.0),
      Text(widget.rowCountText?.call(
            _firstRowIndex + 1,
            _firstRowIndex + widget.rowsPerPage,
            _rowCount,
          ) ??
          '${_firstRowIndex + 1} - ${_firstRowIndex + widget.rowsPerPage} of $_rowCount'),
      NumberedPageIndicator(
        isRowCountApproximate: _rowCountApproximate,
        rowCount: _rowCount,
        firstRowIndex: _firstRowIndex,
        pageTo: pageTo,
        rowsPerPage: widget.rowsPerPage,
        showFirstAndLastButtons: widget.showFirstLastButtons,
      ),
    ]);

    return Scrollbar(
      controller: scrollController,
      child: SingleChildScrollView(
        controller: scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: double.infinity),
              child: DataTable(
                key: widget.tableKey,
                columns: widget.columns,
                showCheckboxColumn: false,
                sortColumnIndex: widget.sortColumnIndex,
                sortAscending: widget.sortAscending,
                dataRowHeight: widget.dataRowHeight,
                headingRowHeight: widget.headingRowHeight,
                horizontalMargin: widget.horizontalMargin,
                checkboxHorizontalMargin: widget.checkboxHorizontalMargin,
                columnSpacing: widget.columnSpacing,
                showBottomBorder: true,
                rows: _getRows(_firstRowIndex, widget.rowsPerPage),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color:
                      ArDriveTheme.of(context).themeData.colors.themeBgSurface,
                ),
              ),
            ),
            DefaultTextStyle(
              style: footerTextStyle,
              child: IconTheme.merge(
                data: const IconThemeData(
                  opacity: 0.54,
                ),
                child: SizedBox(
                  height: 56.0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: footerWidgets,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
