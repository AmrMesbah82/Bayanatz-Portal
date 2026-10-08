// ******************* FILE INFO *******************
// File Name: department_image_field.dart
// Purpose: BUG-86 — "Image" field of Department Information (flowchart
//          1:9391 / 1:9418 / 1:9428). Create and Edit had only the EN/AR name;
//          the card always showed the default logo and Firestore kept an
//          unused empty Icon_Url.
//
// Picking an image uploads it straight away to Storage
// (departments/<time>_<file>) and reports the download URL; the page stores
// it as the department's iconUrl when it saves.

import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/constant/color.dart';
import '../../../../../core/custom/image_upload_circle.dart';

class DepartmentImageField extends StatefulWidget {
  const DepartmentImageField({
    super.key,
    required this.url,
    required this.onChanged,
    this.enabled = true,
  });

  /// Current image URL ('' = none).
  final String url;
  final ValueChanged<String> onChanged;
  final bool enabled;

  @override
  State<DepartmentImageField> createState() => _DepartmentImageFieldState();
}

class _DepartmentImageFieldState extends State<DepartmentImageField> {
  Uint8List? _bytes;
  bool _uploading = false;
  String? _error;

  static const _types = {
    'png': 'image/png',
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'webp': 'image/webp',
    'svg': 'image/svg+xml',
  };

  Future<void> _pick() async {
    if (!widget.enabled || _uploading) return;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: _types.keys.toList(),
      withData: true,
    );
    final file = (result == null || result.files.isEmpty) ? null : result.files.first;
    if (file == null || file.bytes == null) return;
    final ext = file.name.split('.').last.toLowerCase();
    final mime = _types[ext];
    if (mime == null) {
      setState(() => _error = 'Please choose a PNG, JPG, WebP or SVG image.');
      return;
    }
    if (file.bytes!.lengthInBytes > 5 * 1024 * 1024) {
      setState(() => _error = 'The image must be smaller than 5 MB.');
      return;
    }
    setState(() {
      _bytes = file.bytes;
      _uploading = true;
      _error = null;
    });
    try {
      final safe = file.name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
      final ref = FirebaseStorage.instance
          .ref('departments/${DateTime.now().millisecondsSinceEpoch}_$safe');
      await ref.putData(file.bytes!, SettableMetadata(contentType: mime));
      final url = await ref.getDownloadURL();
      if (!mounted) return;
      setState(() => _uploading = false);
      widget.onChanged(url);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _uploading = false;
        _bytes = null;
        _error = 'Upload failed. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Figma (Create New Department, node 7126:60610): only the round image
    // picker with the camera badge — no label, hint or extra buttons.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            imageUploadCircleBare(
              bytes: _bytes,
              url: widget.url,
              onTap: _pick,
            ),
            if (_uploading)
              SizedBox(
                width: 24.sp,
                height: 24.sp,
                child: const CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        if (_error != null) ...[
          SizedBox(height: 4.h),
          Text(_error!,
              style: TextStyle(fontSize: 11.sp, color: ColorPick.red)),
        ],
      ],
    );
  }
}
