part of '../../pages/main_edit.dart';

class _ColorPickerField extends StatefulWidget {
  final TextEditingController controller;
  final String? label;
  final String hintText;
  final VoidCallback? onColorChanged;

  const _ColorPickerField({
    required this.controller,
    this.label,
    this.hintText = '#008037',
    this.onColorChanged,
  });

  @override
  State<_ColorPickerField> createState() => _ColorPickerFieldState();
}

class _ColorPickerFieldState extends State<_ColorPickerField> {
  OverlayEntry? _overlay;
  final LayerLink _layerLink = LayerLink();

  Color get _currentColor {
    try {
      final hex = widget.controller.text.replaceAll('#', '');
      if (hex.length == 6) return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {}
    return ColorPick.primary;
  }

  static String _colorToHex(Color c) =>
      '#${c.red.toRadixString(16).padLeft(2, '0')}'
          '${c.green.toRadixString(16).padLeft(2, '0')}'
          '${c.blue.toRadixString(16).padLeft(2, '0')}'.toUpperCase();

  void _openPicker() {
    _closePicker();
    _overlay = OverlayEntry(
      builder: (_) => _ColorWheelOverlay(
        layerLink:    _layerLink,
        initialColor: _currentColor,
        onApply: (color) {
          widget.controller.text = _colorToHex(color);
          widget.controller.notifyListeners();
          _closePicker();
          if (mounted) setState(() {});
          widget.onColorChanged?.call();
        },
        onClose: _closePicker,
      ),
    );
    Overlay.of(context).insert(_overlay!);
  }

  void _closePicker() { _overlay?.remove(); _overlay = null; }

  @override
  void dispose() { _closePicker(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(widget.label!,
              style: StyleText.fontSize14Weight500.copyWith(color: AppColors.text)),
          SizedBox(height: 5.h),
        ],
        CompositedTransformTarget(
          link: _layerLink,
          child: CustomTextField(
            controller: widget.controller,
            hint: widget.hintText,
            fillColor: AppColors.card,
            height: 36,
            // BUG-275: hex only, and say so when the value is not #RRGGBB.
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[#0-9A-Fa-f]')),
              LengthLimitingTextInputFormatter(7),
            ],
            errorText: widget.controller.text.trim().isEmpty ||
                    _isHexColor(widget.controller.text)
                ? null
                : 'Use a hex colour like #008037',
            onChanged: (_) { setState(() {}); widget.onColorChanged?.call(); },
            onTap: _openPicker,
            prefixIcon: Container(
              width: 16.w, height: 16.h,
              decoration: BoxDecoration(
                color: _currentColor,
                shape: BoxShape.circle,
                border: Border.all(color: ColorPick.white),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Color Wheel Overlay ───────────────────────────────────────────────────────
