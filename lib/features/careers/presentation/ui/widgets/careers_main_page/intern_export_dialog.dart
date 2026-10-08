part of '../../pages/careers_main_page.dart';

class _InternExportDialog extends StatefulWidget {
  final List<InternModel> interns;
  const _InternExportDialog({required this.interns});

  @override
  State<_InternExportDialog> createState() => _InternExportDialogState();
}

class _InternExportDialogState extends State<_InternExportDialog> {
  final _nameCtrl = TextEditingController();
  bool  _saving   = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  String _escapeCsv(String v) {
    if (v.isEmpty) return '';
    if (v.contains(',') || v.contains('"') || v.contains('\n')) {
      return '"${v.replaceAll('"', '""')}"';
    }
    return v;
  }

  Future<void> _export() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Please enter a file name.'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      ));
      return;
    }

    setState(() => _saving = true);

    final buf = StringBuffer();
    buf.writeln('No,Full Name,Position,Degrees,Joined Date,What Have I Learned,Tags');

    for (int i = 0; i < widget.interns.length; i++) {
      final n = widget.interns[i];
      buf.writeln([
        '${i + 1}',
        _escapeCsv(n.fullName),
        _escapeCsv(n.position),
        _escapeCsv(n.degrees),
        _escapeCsv(n.joinDateLabel),
        _escapeCsv(n.whatHaveILearned),
        // _escapeCsv(n.tags.join('; ')),
      ].join(','));
    }

    final fileName = name.toLowerCase().endsWith('.csv') ? name : '$name.csv';
    final blob = html.Blob([buf.toString()], 'text/csv');
    final url  = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click();
    html.Url.revokeObjectUrl(url);

    setState(() => _saving = false);
    if (mounted) Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Exported "$fileName" successfully!',
          style: StyleText.fontSize14Weight400.copyWith(color: Colors.white)),
      backgroundColor: ColorPick.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Container(
        width: 360.w,
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(12.r)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 32.w, height: 32.h,
                decoration: BoxDecoration(color: ColorPick.primary, shape: BoxShape.circle),
                child: Center(
                  child: CustomSvg(
                    assetPath: 'assets/images/export.svg',
                    width: 16.w, height: 16.h,
                    fit: BoxFit.scaleDown, color: Colors.white,
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Text('Export Interns',
                  style: StyleText.fontSize16Weight600.copyWith(color: AppColors.text)),
            ]),
            SizedBox(height: 20.h),
            Text('File Name',
                style: StyleText.fontSize12Weight500.copyWith(color: AppColors.text)),
            SizedBox(height: 6.h),
            CustomTextField(
              controller: _nameCtrl,
              onChanged: (_) => setState(() {}),
              height: 36,
              fillColor: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(6.r),
              hint: 'e.g. interns_2025',
              hintStyle: StyleText.fontSize12Weight400.copyWith(color: AppColors.secondaryText),
              contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              valueStyle: StyleText.fontSize12Weight400.copyWith(color: AppColors.text),
            ),
            SizedBox(height: 24.h),
            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: _saving ? null : () => Navigator.pop(context),
                  child: Container(
                    height: 44.h,
                    decoration: BoxDecoration(
                      color: _saving ? Colors.grey.shade300 : const Color(0xFFE0E0E0),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Center(
                      child: Text('Discard',
                          style: StyleText.fontSize14Weight600.copyWith(
                              color: _saving ? Colors.grey : ColorPick.discard)),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: GestureDetector(
                  onTap: _saving ? null : _export,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 44.h,
                    decoration: BoxDecoration(
                      color: _saving
                          ? ColorPick.primary.withValues(alpha: 0.5)
                          : _nameCtrl.text.trim().isEmpty
                          ? ColorPick.primary.withValues(alpha: 0.4)
                          : ColorPick.primary,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Center(
                      child: _saving
                          ? SizedBox(
                        width: 18.w, height: 18.h,
                        child: const CircleProgress(),
                      )
                          : Text('Download',
                          style: StyleText.fontSize14Weight600.copyWith(color: Colors.white)),
                    ),
                  ),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
