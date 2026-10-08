part of '../../pages/about_us_edit.dart';

extension _AboutEditImageHelpers on _AboutEditPageMasterState {
  // ── URL loaders (XHR — CORS-safe for Firebase Storage) ──────────────────

  Future<Uint8List> _cachedLoad(String url, {bool isSvg = false}) {
    return _urlBytesCache.putIfAbsent(
      url,
      () => isSvg ? _loadSvg(url) : _loadImageBytes(url),
    );
  }

  Future<Uint8List> _loadImageBytes(String url) async {
    try {
      final response = await html.HttpRequest.request(
        url,
        method: 'GET',
        responseType: 'arraybuffer',
      );
      if (response.status == 200 && response.response != null) {
        return (response.response as ByteBuffer).asUint8List();
      }
      throw Exception('HTTP ${response.status}');
    } catch (e) {
      throw Exception('Failed to load image: $e');
    }
  }

  Future<Uint8List> _loadSvg(String url) async {
    try {
      final response = await html.HttpRequest.request(
        url,
        method: 'GET',
        responseType: 'arraybuffer',
        mimeType: 'image/svg+xml',
      );
      if (response.status == 200 && response.response != null) {
        return (response.response as ByteBuffer).asUint8List();
      }
      throw Exception('HTTP ${response.status}');
    } catch (e) {
      throw Exception('Failed to load SVG: $e');
    }
  }

  // ── Image upload circle ───────────────────────────────────────────────────

  Widget _imageUploadCircle({
    required String label,
    required Uint8List? bytes,
    required String url,
    required VoidCallback onTap,
    bool isSvg = false,
    bool showError = false,
  }) {
    // Delegates to the single shared image-upload circle (core/custom).
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        imageUploadCircle(label: label, bytes: bytes, url: url, onTap: onTap),
        if (showError)
          Padding(
            padding: EdgeInsets.only(top: 4.h),
            child: Text(
              'This field is required',
              style: StyleText.fontSize10Weight400.copyWith(color: Colors.red),
            ),
          ),
      ],
    );
  }

  bool _isSvgMemory(Uint8List b, bool hintSvg) {
    if (hintSvg) return true;
    if (b.length < 5) return false;
    final header =
        String.fromCharCodes(b.sublist(0, b.length.clamp(0, 100))).trimLeft();
    return header.startsWith('<svg') || header.startsWith('<?xml');
  }

  // ── Shared form helpers ──────────────────────────────────────────────────

  Widget _bilingualRow({
    required TextEditingController enCtrl,
    required TextEditingController arCtrl,
    required String enHint,
    required String arHint,
    int maxLength = 150,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: CustomValidatedTextFieldMaster(
            hint: enHint,
            controller: enCtrl,
            fillColor: Colors.white,
            height: 42,
            maxLines: 1,
            maxLength: maxLength,
            submitted: _submitted,
            isRequired: true,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.start,
            primaryColor: ColorPick.primary,
            onChanged: (_) => setState(() {}),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: CustomValidatedTextFieldMaster(
            hint: arHint,
            controller: arCtrl,
            height: 42,
            fillColor: Colors.white,
            maxLines: 1,
            maxLength: maxLength,
            submitted: _submitted,
            isRequired: true,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            primaryColor: ColorPick.primary,
            onChanged: (_) => setState(() {}),
          ),
        ),
      ],
    );
  }

  Widget _fieldLabel(String text) => Text(text,
      style: StyleText.fontSize14Weight400.copyWith(color: AppColors.text));

  Widget _fieldLabelAr(String text) => Align(
        alignment: Alignment.centerRight,
        child: Text(text,
            style: StyleText.fontSize14Weight400
                .copyWith(color: AppColors.text)),
      );

  Widget _btn({
    required String label,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 48.h,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4.r),
        ),
        child: Center(
          child: Text(
            label,
            style: StyleText.fontSize15Weight600.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
