// ******************* FILE INFO *******************
// File Name: csv_export_dialog.dart
// Purpose: One export dialog for the Applications and Inquiries pages
//          (BUG-32). It always downloads a CSV — header-only when there is
//          nothing to export — and validates the file name INSIDE the dialog.
//
//          The old Inquiries dialog reported problems with a SnackBar, which
//          is drawn behind the modal barrier, so nothing seemed to happen and
//          the dialog just stayed open. Applications' Export did nothing at all.

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:web_app_admin/core/widget/auto_close_dialog.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constant/color.dart';
import '../theme/appcolors.dart';

/// Triggers a browser download of [rows] as a UTF-8 CSV (with BOM so Excel
/// opens Arabic text correctly).
void downloadCsv(List<List<String>> rows, String fileName) {
  String esc(String v) {
    final needsQuotes =
        v.contains(',') || v.contains('"') || v.contains('\n') || v.contains('\r');
    final s = v.replaceAll('"', '""');
    return needsQuotes ? '"$s"' : s;
  }

  final buffer = StringBuffer('﻿');
  for (final r in rows) {
    buffer.writeln(r.map(esc).join(','));
  }
  final bytes = utf8.encode(buffer.toString());
  final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..style.display = 'none';
  // Some browsers ignore click() on an anchor that is not in the document.
  html.document.body?.children.add(anchor);
  anchor.click();
  anchor.remove();
  // Revoking immediately can cancel the download in some browsers.
  Future.delayed(const Duration(seconds: 2), () => html.Url.revokeObjectUrl(url));
}

/// Returns an error message for an invalid file name, or null.
String? validateExportFileName(String name) {
  final n = name.trim();
  if (n.isEmpty) return 'Please enter a file name.';
  if (n.length > 80) return 'File name is too long (max 80 characters).';
  if (RegExp(r'[\\/:*?"<>|]').hasMatch(n)) {
    return 'File name can\'t contain \\ / : * ? " < > |';
  }
  return null;
}

/// Shows the export dialog; on Download builds the CSV from [header] + [rows].
Future<void> showCsvExportDialog(
  BuildContext context, {
  required String defaultFileName,
  required List<String> header,
  required List<List<String>> rows,
  String itemLabel = 'rows',
}) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) => _CsvExportDialog(
      defaultFileName: defaultFileName,
      header: header,
      rows: rows,
      itemLabel: itemLabel,
    ),
  );
}

class _CsvExportDialog extends StatefulWidget {
  const _CsvExportDialog({
    required this.defaultFileName,
    required this.header,
    required this.rows,
    required this.itemLabel,
  });

  final String defaultFileName;
  final List<String> header;
  final List<List<String>> rows;
  final String itemLabel;

  @override
  State<_CsvExportDialog> createState() => _CsvExportDialogState();
}

class _CsvExportDialogState extends State<_CsvExportDialog> {
  late final TextEditingController _name =
      TextEditingController(text: widget.defaultFileName);
  String? _error;
  bool _done = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _download() {
    final err = validateExportFileName(_name.text);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    final raw = _name.text.trim();
    final fileName = raw.toLowerCase().endsWith('.csv') ? raw : '$raw.csv';
    try {
      downloadCsv([widget.header, ...widget.rows], fileName);
      setState(() => _done = true);
      // Success message closes the dialog by itself after 3 s.
      Future.delayed(kAutoCloseDialogDuration, () {
        if (!mounted) return;
        final route = ModalRoute.of(context);
        if (route != null && route.isCurrent) Navigator.of(context).pop();
      });
    } catch (e) {
      setState(() => _error = 'Export failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.rows.length;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      child: Container(
        width: 400.w,
        padding: EdgeInsets.all(20.sp),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 30.sp,
                  height: 30.sp,
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle, color: ColorPick.primary),
                  child: Icon(Icons.file_download_outlined,
                      size: 16.sp, color: Colors.white),
                ),
                SizedBox(width: 8.sp),
                Expanded(
                  child: Text('Export',
                      style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text)),
                ),
                IconButton(
                  tooltip: 'Close',
                  icon: Icon(Icons.close, size: 18.sp, color: AppColors.text),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            SizedBox(height: 12.sp),
            if (_done) ...[
              Row(children: [
                Icon(Icons.check_circle, color: const Color(0xFF008037), size: 20.sp),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    count == 0
                        ? 'Downloaded (header only — there are no ${widget.itemLabel} to export yet).'
                        : 'Downloaded $count ${widget.itemLabel}.',
                    style: TextStyle(fontSize: 13.sp, color: AppColors.text),
                  ),
                ),
              ]),
              SizedBox(height: 8.sp),
            ] else ...[
              Text('File Name',
                  style: TextStyle(fontSize: 12.sp, color: AppColors.text)),
              SizedBox(height: 6.sp),
              TextField(
                controller: _name,
                autofocus: true,
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                onSubmitted: (_) => _download(),
                style: TextStyle(fontSize: 13.sp),
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: const Color(0xFFF1F2ED),
                  hintText: 'Enter file name',
                  suffixText: '.csv',
                  errorText: _error,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6.r),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              SizedBox(height: 6.sp),
              Text(
                count == 0
                    ? 'Nothing to export yet — the file will contain the column headers only.'
                    // BUG-280: "1 application will be exported." (was "1 applications").
                    : '$count ${count == 1 && widget.itemLabel.endsWith('s') ? widget.itemLabel.substring(0, widget.itemLabel.length - 1) : widget.itemLabel} will be exported.',
                style: TextStyle(fontSize: 11.sp, color: AppColors.secondaryText),
              ),
              SizedBox(height: 20.sp),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 38.h,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.grey.shade300,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r)),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('Cancel', // BUG-157: closes the dialog — it discards nothing
                            style: TextStyle(fontSize: 14.sp, color: AppColors.text)),
                      ),
                    ),
                  ),
                  SizedBox(width: 15.sp),
                  Expanded(
                    child: SizedBox(
                      height: 38.h,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorPick.primary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r)),
                        ),
                        onPressed: _download,
                        child: Text('Download',
                            style: TextStyle(fontSize: 14.sp, color: Colors.white)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
