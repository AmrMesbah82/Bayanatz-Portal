part of '../../pages/careers_main_page.dart';

class _InternTableView extends StatelessWidget {
  final List<InternModel> interns;
  final InternCubit       cubit;
  const _InternTableView({required this.interns, required this.cubit});

  Map<int, TableColumnWidth> get _columnWidths => {
    0: const FlexColumnWidth(1.1),
    1: const FlexColumnWidth(1.4),
    2: const FlexColumnWidth(1.1),
    3: const FlexColumnWidth(1.1),
    4: const FlexColumnWidth(2.0),
  };

  static const _headers = [
    'Joined Date', 'Interns Name',
    'Position', 'Degrees', 'What Have I Learned',
  ];

  TextStyle get _headerStyle => StyleText.fontSize13Weight600.copyWith(
      color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12.sp);

  TextStyle get _cellStyle => StyleText.fontSize12Weight400.copyWith(
      color: AppColors.text, fontSize: 12.sp, height: 1.4);

  Widget _headerCell(String text) => Container(
    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
    child: Text(text, style: _headerStyle, maxLines: 2, overflow: TextOverflow.ellipsis),
  );

  Widget _textCell(String text, {int maxLines = 2}) => Container(
    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
    child: Text(text.isEmpty ? '-' : text,
        maxLines: maxLines, overflow: TextOverflow.ellipsis, style: _cellStyle),
  );

  Widget _nameCell(InternModel intern) => Container(
    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
    child: Row(children: [
      Container(
        width: 30.w, height: 30.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: ColorPick.primary, width: 1.5),
          color: const Color(0xFFE0E0E0),
          image: intern.photoUrl.isNotEmpty
              ? DecorationImage(image: NetworkImage(intern.photoUrl), fit: BoxFit.cover)
              : null,
        ),
        child: intern.photoUrl.isEmpty
            ? Center(child: Icon(Icons.person, color: Colors.grey, size: 15.sp))
            : null,
      ),
      SizedBox(width: 8.w),
      Flexible(
        child: Text(
          intern.fullName.isEmpty ? '-' : intern.fullName,
          maxLines: 2, overflow: TextOverflow.ellipsis,
          style: _cellStyle.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    ]),
  );

  void _confirmDelete(BuildContext context, InternModel intern) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        title: Text('Delete Intern',
            style: StyleText.fontSize16Weight600.copyWith(color: Colors.black87)),
        content: Text('Are you sure you want to delete ${intern.fullName}?',
            style: StyleText.fontSize14Weight400.copyWith(color: Colors.black54)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: StyleText.fontSize13Weight500.copyWith(color: AppColors.secondaryText)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              cubit.delete(intern.id);
            },
            child: Text('Delete',
                style: StyleText.fontSize13Weight600.copyWith(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color rowOdd  = Color(0xFFF1F2ED);
    const Color rowEven = Colors.white;
    const Color divider = Color(0xFFE0E0E0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(4.r),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: ColorPick.primary,
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(4.r), topRight: Radius.circular(4.r)),
            ),
            child: Table(
              columnWidths: _columnWidths,
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                TableRow(children: _headers.map((h) => _headerCell(h)).toList()),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: divider, width: 0.5),
              borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(4.r), bottomRight: Radius.circular(4.r)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(4.r), bottomRight: Radius.circular(4.r)),
              child: Table(
                columnWidths: _columnWidths,
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                border: TableBorder(
                    horizontalInside: BorderSide(color: divider, width: 0.8)),
                children: List.generate(interns.length, (index) {
                  final intern   = interns[index];
                  final rowColor = index.isOdd ? rowOdd : rowEven;

                  void onRowTap() => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                        value: cubit, child: AddInternPage(existing: intern)),
                  ));

                  Widget tap(Widget child) => InkWell(
                    onTap: onRowTap,
                    hoverColor: ColorPick.primary.withValues(alpha: 0.06),
                    mouseCursor: SystemMouseCursors.click,
                    child: child,
                  );

                  return TableRow(
                    decoration: BoxDecoration(color: rowColor),
                    children: [
                      tap(_textCell(intern.joinDateLabel, maxLines: 1)),
                      tap(_nameCell(intern)),
                      tap(_textCell(intern.position)),
                      tap(_textCell(intern.degrees)),
                      tap(_textCell(intern.whatHaveILearned, maxLines: 3)),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// INTERN CARD  (unchanged)
// ═══════════════════════════════════════════════════════════════════════════════
