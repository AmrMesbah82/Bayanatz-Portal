// ******************* FILE INFO *******************
// File Name: job_listing_export_dialog.dart
// Created by: Amr Mesbah
// Purpose: Export Applicant Details table to PDF — Flutter Web compatible
// FIXED: Uses dart:html AnchorElement for web download (no printing package)
// FIXED: Loads Google Font (Roboto) for Unicode support in pdf package

import 'dart:convert';
import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;



import '../../features/job/data/models/application_model.dart';
import '../../features/job/data/models/job_listing_model.dart';
import '../custom/2-custom_textfield.dart';
import '../theme/new_theme.dart';
import 'package:web_app_admin/core/custom/circle_progress.dart';

// ── Colors ───────────────────────────────────────────────────────────────────
class _C {
  static const Color primary = Color(0xFF008037);
}

// ═════════════════════════════════════════════════════════════════════════════
//  PUBLIC API — call from Export button in _ApplicantDetailsTab
// ═════════════════════════════════════════════════════════════════════════════
//
//  Usage:
//    showJobListingExportDialog(
//      context,
//      job: widget.job,
//      applications: _filtered,
//    );

Future<void> showJobListingExportDialog(
    BuildContext context, {
      required JobPostModel job,
      required List<ApplicationModel> applications,
    }) {
  return showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    builder: (_) => _JobListingExportDialog(
      job: job,
      applications: applications,
    ),
  );
}

// ═════════════════════════════════════════════════════════════════════════════
//  DIALOG
// ═════════════════════════════════════════════════════════════════════════════

class _JobListingExportDialog extends StatefulWidget {
  final JobPostModel job;
  final List<ApplicationModel> applications;

  const _JobListingExportDialog({
    required this.job,
    required this.applications,
  });

  @override
  State<_JobListingExportDialog> createState() =>
      _JobListingExportDialogState();
}

class _JobListingExportDialogState extends State<_JobListingExportDialog> {
  final TextEditingController _fileNameController = TextEditingController();
  bool _isExporting = false;

  @override
  void dispose() {
    _fileNameController.dispose();
    super.dispose();
  }

  // ── Load font that supports Unicode ───────────────────────────────────────
  Future<pw.Font> _loadFont() async {
    try {
      // Try loading Roboto from assets (most Flutter projects include it)
      final fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
      return pw.Font.ttf(fontData);
    } catch (_) {
      // Fallback: use Helvetica (works for English-only content)
      return pw.Font.helvetica();
    }
  }

  Future<pw.Font> _loadFontBold() async {
    try {
      final fontData = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
      return pw.Font.ttf(fontData);
    } catch (_) {
      return pw.Font.helveticaBold();
    }
  }

  // ── Generate PDF bytes ────────────────────────────────────────────────────
  Future<Uint8List> _generatePdf() async {
    final pdf = pw.Document();

    final font = await _loadFont();
    final fontBold = await _loadFontBold();

    final baseStyle = pw.TextStyle(font: font, fontSize: 7);
    final headerStyle = pw.TextStyle(
      font: fontBold,
      fontSize: 7,
      color: PdfColors.white,
    );
    final titleStyle = pw.TextStyle(
      font: fontBold,
      fontSize: 18,
    );
    final subtitleStyle = pw.TextStyle(
      font: font,
      fontSize: 11,
      color: PdfColors.grey700,
    );
    final smallStyle = pw.TextStyle(
      font: font,
      fontSize: 10,
      color: PdfColors.grey600,
    );
    final footerStyle = pw.TextStyle(
      font: font,
      fontSize: 8,
      color: PdfColors.grey500,
    );

    // ── Table headers ──
    final headers = [
      'No',
      'First Name',
      'Last Name',
      'Email',
      'Code',
      'Phone',
      'Year Of Graduation',
      'Stage',
      'Status',
      'Score',
      'Tags',
      'Location',
    ];

    // ── Table data rows ──
    final dataRows = <List<String>>[];
    for (int i = 0; i < widget.applications.length; i++) {
      final a = widget.applications[i];
      final avgScore = (a.technicalSkills +
          a.communicationSkills +
          a.experienceBackground +
          a.cultureFit +
          a.leadershipPotential);
      final scoreText =
      avgScore > 0 ? (avgScore / 5).toStringAsFixed(1) : '-';

      dataRows.add([
        '${i + 1}',
        a.firstName.isNotEmpty ? a.firstName : '-',
        a.lastName.isNotEmpty ? a.lastName : '-',
        a.email.isNotEmpty ? a.email : '-',
        a.countryCode.isNotEmpty ? a.countryCode : '-',
        a.phone.isNotEmpty ? a.phone : '-',
        a.yearOfGraduation.isNotEmpty ? a.yearOfGraduation : '-',
        a.status.stage.isNotEmpty ? a.status.stage : '-',
        a.status.label.isNotEmpty ? a.status.label : '-',
        scoreText,
        a.tag.isNotEmpty ? a.tag : '-',
        a.jobLocation.isNotEmpty ? a.jobLocation : '-',
      ]);
    }

    // ── Chunk rows into pages ──
    const int rowsPerPage = 25;
    final totalPages = (dataRows.length / rowsPerPage).ceil().clamp(1, 9999);

    for (int pageIndex = 0; pageIndex < totalPages; pageIndex++) {
      final startRow = pageIndex * rowsPerPage;
      final endRow = (startRow + rowsPerPage).clamp(0, dataRows.length);
      final pageRows = dataRows.sublist(startRow, endRow);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(24),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // ── Title header ──
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Applicant Details', style: titleStyle),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Job: ${widget.job.title.en.isNotEmpty ? widget.job.title.en : "Untitled"}',
                          style: subtitleStyle,
                        ),
                        pw.Text(
                          'Department: ${widget.job.department.isNotEmpty ? widget.job.department : "-"}',
                          style: smallStyle,
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'Total Applicants: ${widget.applications.length}',
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 11,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Page ${pageIndex + 1} of $totalPages',
                          style: footerStyle,
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 12),

                // ── Table ──
                pw.Expanded(
                  child: pw.Table(
                    border: pw.TableBorder.all(
                      color: PdfColors.grey300,
                      width: 0.5,
                    ),
                    columnWidths: {
                      0: const pw.FixedColumnWidth(28),   // No
                      1: const pw.FlexColumnWidth(1.2),   // First Name
                      2: const pw.FlexColumnWidth(1.2),   // Last Name
                      3: const pw.FlexColumnWidth(2),     // Email
                      4: const pw.FixedColumnWidth(36),   // Code
                      5: const pw.FlexColumnWidth(1.2),   // Phone
                      6: const pw.FlexColumnWidth(1),     // Year Of Grad
                      7: const pw.FlexColumnWidth(0.9),   // Stage
                      8: const pw.FlexColumnWidth(1),     // Status
                      9: const pw.FixedColumnWidth(36),   // Score
                      10: const pw.FlexColumnWidth(0.7),  // Tags
                      11: const pw.FlexColumnWidth(1.2),  // Location
                    },
                    children: [
                      // ── Header row ──
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(
                          color: PdfColor.fromInt(0xFF008037),
                        ),
                        children: headers.map((h) {
                          return pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 6,
                            ),
                            child: pw.Text(h, style: headerStyle, maxLines: 1),
                          );
                        }).toList(),
                      ),

                      // ── Data rows ──
                      ...pageRows.asMap().entries.map((entry) {
                        final rowIndex = entry.key;
                        final row = entry.value;
                        return pw.TableRow(
                          decoration: pw.BoxDecoration(
                            color: rowIndex % 2 == 0
                                ? PdfColors.white
                                : const PdfColor.fromInt(0xFFF9F9F9),
                          ),
                          children: row.map((cell) {
                            return pw.Padding(
                              padding: const pw.EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 5,
                              ),
                              child: pw.Text(cell, style: baseStyle, maxLines: 1),
                            );
                          }).toList(),
                        );
                      }),
                    ],
                  ),
                ),

                // ── Footer ──
                pw.SizedBox(height: 8),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Generated on: ${_formatDate(DateTime.now())}',
                      style: footerStyle,
                    ),
                    pw.Text(
                      'Bayanatz Job Listing System',
                      style: footerStyle,
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );
    }

    return pdf.save();
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  // ── Download PDF via browser (Flutter Web) ────────────────────────────────
  void _downloadPdfWeb(Uint8List bytes, String fileName) {
    final base64 = base64Encode(bytes);
    final anchor = html.AnchorElement(
      href: 'data:application/pdf;base64,$base64',
    )
      ..setAttribute('download', fileName)
      ..style.display = 'none';

    html.document.body?.children.add(anchor);
    anchor.click();
    anchor.remove();
  }

  // ── Export action ─────────────────────────────────────────────────────────
  Future<void> _exportPdf() async {
    if (_isExporting) return;

    final fileName = _fileNameController.text.trim();
    if (fileName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a file name'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (widget.applications.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No applicants to export'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isExporting = true);

    try {

      final pdfBytes = await _generatePdf();

      final finalName = fileName.toLowerCase().endsWith('.pdf')
          ? fileName
          : '$fileName.pdf';


      // ── Download via browser ──
      _downloadPdfWeb(pdfBytes, finalName);


      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: IntrinsicHeight(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.r),
          ),
          constraints: BoxConstraints(
            maxWidth: 411.sp,
            minWidth: 350.sp,
          ),
          child: Padding(
            padding: EdgeInsets.all(20.sp),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──
                Row(
                  children: [
                    Container(
                      width: 30.sp,
                      height: 30.sp,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: _C.primary,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.picture_as_pdf_rounded,
                          size: 16.sp,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.sp),
                    Text(
                      'Export PDF',
                      style: StyleText.fontSize16Weight500.copyWith(
                        color: const Color(0xFF333333),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6.sp),
                Text(
                  '${widget.applications.length} applicant(s) will be exported',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: const Color(0xFFAAAAAA),
                  ),
                ),
                SizedBox(height: 20.sp),

                // ── File name input ──
                Text(
                  'File Name',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF333333),
                  ),
                ),
                SizedBox(height: 6.sp),
                CustomTextField(
                  controller: _fileNameController,
                  height: 40,
                  valueStyle: TextStyle(fontSize: 13.sp),
                  fillColor: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(6.r),
                  hint: 'Enter file name',
                  hintStyle: TextStyle(
                    fontSize: 13.sp,
                    color: const Color(0xFFAAAAAA),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 10.h,
                  ),
                  suffixIcon: Text(
                    '.pdf',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: const Color(0xFF999999),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                SizedBox(height: 20.sp),

                // ── Action buttons ──
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 42.sp,
                        child: TextButton(
                          onPressed: _isExporting
                              ? null
                              : () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFFEEEEEE),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                          child: Text(
                            'Cancel', // BUG-157: closes the dialog
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: _isExporting
                                  ? Colors.grey
                                  : const Color(0xFF333333),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.sp),
                    Expanded(
                      child: SizedBox(
                        height: 42.sp,
                        child: ElevatedButton(
                          onPressed: _isExporting ? null : _exportPdf,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isExporting
                                ? Colors.grey
                                : _C.primary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                          child: _isExporting
                              ? SizedBox(
                            width: 18.sp,
                            height: 18.sp,
                            child: const CircleProgress(),
                          )
                              : Text(
                            'Download',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}