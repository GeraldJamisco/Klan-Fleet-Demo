import 'package:material_ui/material_ui.dart';

import '../theme/console_theme.dart';

class TableCol {
  const TableCol(this.title, this.width);

  final String title;

  /// Minimum width. Columns grow proportionally when there is spare room.
  final double width;
}

/// A table that scrolls sideways on narrow screens and stretches on wide ones.
class ConsoleTable extends StatelessWidget {
  const ConsoleTable({
    super.key,
    required this.columns,
    required this.rows,
    this.rowHeight = 56,
  });

  final List<TableCol> columns;
  final List<List<Widget>> rows;
  final double rowHeight;

  @override
  Widget build(BuildContext context) {
    final c = context.cc;
    return LayoutBuilder(
      builder: (context, constraints) {
        final natural = columns.fold<double>(0, (sum, col) => sum + col.width);
        final available = constraints.maxWidth;
        final scale = available.isFinite && available > natural ? available / natural : 1.0;

        Widget rowOf(List<Widget> cells, {required bool header}) {
          return Container(
            height: header ? 40 : rowHeight,
            decoration: BoxDecoration(
              color: header ? c.surface2 : null,
              border: Border(top: BorderSide(color: c.line)),
            ),
            child: Row(
              children: [
                for (var i = 0; i < columns.length; i++)
                  SizedBox(
                    width: columns[i].width * scale,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: Align(alignment: Alignment.centerLeft, child: cells[i]),
                    ),
                  ),
              ],
            ),
          );
        }

        final headerCells = <Widget>[
          for (final col in columns)
            Text(
              col.title.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: c.muted,
              ),
            ),
        ];

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: natural * scale,
            child: Column(
              children: [
                rowOf(headerCells, header: true),
                for (final cells in rows) rowOf(cells, header: false),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Plain table text in the console's style.
class CellText extends StatelessWidget {
  const CellText(this.text, {super.key, this.bold = false, this.muted = false});

  final String text;
  final bool bold;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final c = context.cc;
    return Text(
      text,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 12,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
        color: muted ? c.muted : c.text,
      ),
    );
  }
}
