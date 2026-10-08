part of '../../pages/careers_edit.dart';

extension _CareersEditWidgets on _CareersEditPageState {
  Widget _arField({
    required String label,
    required String hint,
    required TextEditingController ctrl,
    double height = 36,
    int maxLines = 1,
    bool isRequired = true,
  }) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: CustomTextField(
        label: label, hint: hint, controller: ctrl,
        labelStyle: StyleText.fontSize13Weight600.copyWith(color: Colors.black87),
        maxLines: maxLines, maxLength: 100000,
        height: maxLines > 1 ? null : height,
        fillColor: Colors.white,
        textDirection: TextDirection.rtl, textAlign: TextAlign.right,
        required: isRequired, submitted: _submitted,
      ),
    );
  }

  Widget _enField({
    required String label,
    required String hint,
    required TextEditingController ctrl,
    double height = 36,
    int maxLines = 1,
    bool isRequired = true,
  }) {
    return CustomTextField(
      label: label, hint: hint, controller: ctrl,
      labelStyle: StyleText.fontSize13Weight600.copyWith(color: Colors.black87),
      maxLines: maxLines, maxLength: 100000,
      height: maxLines > 1 ? null : height,
      fillColor: Colors.white,
      textDirection: TextDirection.ltr, textAlign: TextAlign.left,
      required: isRequired, submitted: _submitted,
    );
  }

  Widget _iconUploadWidget({required String statId, required String label}) {
    final newBytes = _statIcons[statId];
    final savedUrl = _statIconUrls[statId] ?? '';

    Future<void> pickIcon() async {
      final bytes = await _pickSvgFile();
      if (bytes != null) setState(() { _statIcons[statId] = bytes; _hasChanges = true; });
    }

    // Delegates to the single shared image-upload circle (core/custom).
    return imageUploadCircle(
      label: label,
      bytes: newBytes,
      url: savedUrl,
      onTap: pickIcon,
    );
  }

  Widget _actionButtons() {
    // Shared action buttons — style lives in core/main_widgets/edit_action_buttons.dart
    return Column(
      children: [
        EditActionButtons(
          onPreview:      _preview,
          onPublish:      _handlePublish,
          onDiscard:      _discard,
          publishEnabled: _isPublishEnabled,
          publishDisabledTooltip: _publishTooltip,
          // BUG-62: this page has its own exact change check (_hasChanges,
          // which now includes statistics); the shared text-only dirty flag
          // must not veto it.
          requireChanges: false,
        ),
        if (_submitted && !_isFormValid)
          Padding(
            padding: EdgeInsets.only(top: 12.h),
            child: Text('Please fix validation errors above before publishing',
                style: StyleText.fontSize12Weight500.copyWith(color: Colors.red)),
          ),
      ],
    );
  }

  Widget _accordion({required String key, required String title, required List<Widget> children}) {
    final isOpen = _open[key] ?? true;
    return CustomAccordion(
      title:    title,
      isOpen:   isOpen,
      onToggle: () => setState(() => _open[key] = !isOpen),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _btn({required String label, required Color color, VoidCallback? onTap}) {
    final bool disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity, height: 44.h,
        decoration: BoxDecoration(
          color: disabled ? color.withValues(alpha: 0.45) : color,
          borderRadius: BorderRadius.circular(6.r),
        ),
        alignment: Alignment.center,
        child: Text(label, style: StyleText.fontSize14Weight600.copyWith(color: Colors.white)),
      ),
    );
  }

  String _ord(int n) {
    if (n == 1) return '1st';
    if (n == 2) return '2nd';
    if (n == 3) return '3rd';
    return '${n}th';
  }
}
