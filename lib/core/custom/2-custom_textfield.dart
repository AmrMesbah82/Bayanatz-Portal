// ******************* FILE INFO *******************
// File Name: 2-custom_textfield.dart
// Description: The single shared text field widget. EVERY text field in
//              the app must use this widget — no raw TextField /
//              TextFormField anywhere.
//              App-wide rules baked in:
//              • NO character counter is ever shown (showCharCount ignored).
//              • NO language restriction — every field accepts Arabic AND
//                English freely (restrictByDirection ignored).
//              • Cursor + text-selection (copy) highlight always use
//                ColorPick.primary — never the theme/platform yellow.
// Created by: Amr Mesbah

/// Module: core › custom

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constant/color.dart';
import '../main_widgets/form_dirty_scope.dart';
import '../main_widgets/validation_scope.dart';
import '../theme/appcolors.dart';
import '../theme/new_theme.dart';

/// Custom text field widget — mirrors CustomDropdown API exactly.
///
/// Border rule: NO border by default; red border only when [errorText] is set.
/// Sentinel returned by the built-in "required" check. It marks the field as
/// in-error (red border) while rendering no message — see _resolvedError.
const String _kRequiredNoMessage = '\u0000required';

class CustomTextField extends StatefulWidget {
  // ── Controller / Focus ───────────────────────────────────────────────────

  /// Text editing controller. If null an internal one is created.
  final TextEditingController? controller;

  /// Focus node. If null an internal one is created.
  final FocusNode? focusNode;

  // ── Content ──────────────────────────────────────────────────────────────

  /// Initial value (only used when [controller] is null).
  final String? initialValue;

  /// Placeholder text.
  final String? hint;

  /// Label displayed above the field.
  final String? label;

  /// Error message — also triggers the red border.
  final String? errorText;

  /// Helper text displayed below the field.
  final String? helperText;

  // ── Icons ────────────────────────────────────────────────────────────────

  /// Widget shown at the start of the field.
  final Widget? prefixIcon;

  /// Widget shown at the end of the field (overrides the password-toggle eye).
  final Widget? suffixIcon;

  // ── Behaviour ────────────────────────────────────────────────────────────

  /// Whether the field is interactive.
  final bool enabled;

  /// Whether the field is read-only (tappable but not editable).
  final bool readOnly;

  /// Adds a red " *" to the label.
  final bool required;

  /// Hides text (password mode). Shows an eye-toggle unless [suffixIcon] is
  /// provided.
  final bool obscureText;

  /// Maximum number of lines. 1 = single-line (default). null = unlimited.
  final int? maxLines;

  /// Minimum number of lines for multiline fields.
  final int? minLines;

  /// Hard character limit (enforced silently — no counter is shown).
  final int? maxLength;

  /// Keyboard type.
  final TextInputType? keyboardType;

  /// Input formatters (e.g. digits-only).
  final List<TextInputFormatter>? inputFormatters;

  /// Text alignment inside the field.
  final TextAlign textAlign;

  /// Text direction (useful for RTL/LTR mixed content).
  final TextDirection? textDirection;

  /// Action button on the keyboard.
  final TextInputAction? textInputAction;

  /// Auto-capitalisation strategy.
  final TextCapitalization textCapitalization;

  /// Whether to enable autocorrect.
  final bool autocorrect;

  /// Whether to show text-suggestions.
  final bool enableSuggestions;

  // ── Callbacks ────────────────────────────────────────────────────────────

  /// Called on every keystroke.
  final ValueChanged<String>? onChanged;

  /// Called when the user submits (presses the keyboard action button).
  final ValueChanged<String>? onSubmitted;

  /// Called when the field gains or loses focus.
  final ValueChanged<bool>? onFocusChanged;

  /// Called when the field is tapped (useful when [readOnly] is true).
  final VoidCallback? onTap;

  // ── Appearance ───────────────────────────────────────────────────────────

  /// Background fill color.
  final Color? fillColor;

  /// BUG-294: a read-only VIEW (detail pages) — not editable, but drawn
  /// like a normal field (solid white, normal text colour) instead of the
  /// dimmed "disabled" look.
  final bool readOnlyView;

  /// Border radius — defaults to 4.r internally.
  final BorderRadius? borderRadius;

  /// Padding inside the field container.
  final EdgeInsetsGeometry? contentPadding;

  // ── Text styles ──────────────────────────────────────────────────────────

  final TextStyle? valueStyle;
  final TextStyle? hintStyle;
  final TextStyle? labelStyle;
  final TextStyle? errorStyle;
  final TextStyle? helperStyle;
  final TextStyle? counterStyle;

  // ── Sizing (optional fixed box) ────────────────────────────────────────────

  /// Fixed width (interpreted in .w). Null → expands to parent.
  final double? width;

  /// Fixed height (interpreted in .h). Null → sizes to content.
  final double? height;

  // ── Built-in validation (opt-in) ───────────────────────────────────────────

  /// When true, an empty field shows a "required" error (use after a submit
  /// attempt). Only takes effect together with the other validation flags.
  final bool submitted;

  /// Restricts input to digits and validates the value is numeric.
  final bool onlyDigits;

  /// DEPRECATED / IGNORED — kept only for call-site compatibility.
  /// Every field accepts Arabic and English; no language restriction is
  /// ever applied.
  final bool restrictByDirection;

  /// Auto-capitalises the first letter of each word (LTR, non-digit only).
  final bool autoCapitalize;

  /// DEPRECATED / IGNORED — kept only for call-site compatibility.
  /// No character counter is ever shown anywhere in the app.
  final bool showCharCount;

  const CustomTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.initialValue,
    this.hint,
    this.label,
    this.errorText,
    this.helperText,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
    this.readOnly = false,
    this.required = false,
    this.obscureText = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.keyboardType,
    this.inputFormatters,
    this.textAlign = TextAlign.start,
    this.textDirection,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.onChanged,
    this.onSubmitted,
    this.onFocusChanged,
    this.onTap,
    this.fillColor,
    this.readOnlyView = false,
    this.borderRadius,
    this.contentPadding,
    this.valueStyle,
    this.hintStyle,
    this.labelStyle,
    this.errorStyle,
    this.helperStyle,
    this.counterStyle,
    this.width,
    this.height,
    this.submitted = false,
    this.onlyDigits = false,
    this.restrictByDirection = false,
    this.autoCapitalize = false,
    this.showCharCount = false,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late FocusNode _focusNode;
  late TextEditingController _controller;
  bool _ownsController = false;
  bool _ownsFocusNode = false;
  bool _obscured = true; // tracks password visibility toggle

  @override
  void initState() {
    super.initState();

    // Controller
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = TextEditingController(text: widget.initialValue);
      _ownsController = true;
    }

    // Focus node
    if (widget.focusNode != null) {
      _focusNode = widget.focusNode!;
    } else {
      _focusNode = FocusNode();
      _ownsFocusNode = true;
    }

    _focusNode.addListener(_onFocusChange);

    if (_needsTextListener) {
      _controller.addListener(_onTextChange);
    }
  }

  void _onFocusChange() {
    setState(() {}); // rebuild so suffix eye-icon tint can update if needed
    widget.onFocusChanged?.call(_focusNode.hasFocus);
  }

  void _onTextChange() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void didUpdateWidget(covariant CustomTextField oldWidget) {
    super.didUpdateWidget(oldWidget);

    // ── Controller swapped by the parent ────────────────────────────────────
    // Some pages dispose their controllers and create NEW ones when
    // re-seeding from a freshly loaded model. We must follow the new
    // instance — keeping the cached (now disposed) one crashes with
    // "A TextEditingController was used after being disposed".
    if (widget.controller != oldWidget.controller) {
      if (_needsTextListener) {
        try {
          _controller.removeListener(_onTextChange);
        } catch (_) {
          // old controller may already be disposed by the parent
        }
      }
      if (_ownsController) _controller.dispose();
      _ownsController = false;
      if (widget.controller != null) {
        _controller = widget.controller!;
      } else {
        _controller = TextEditingController(text: widget.initialValue);
        _ownsController = true;
      }
      if (_needsTextListener) _controller.addListener(_onTextChange);
    }

    // ── Focus node swapped by the parent ────────────────────────────────────
    if (widget.focusNode != oldWidget.focusNode) {
      try {
        _focusNode.removeListener(_onFocusChange);
      } catch (_) {}
      if (_ownsFocusNode) _focusNode.dispose();
      _ownsFocusNode = false;
      if (widget.focusNode != null) {
        _focusNode = widget.focusNode!;
      } else {
        _focusNode = FocusNode();
        _ownsFocusNode = true;
      }
      _focusNode.addListener(_onFocusChange);
    }
  }

  @override
  void dispose() {
    // The external controller/focus node may have been disposed by its owner
    // before this widget unmounts (e.g. page re-seed + navigation) — guard.
    try {
      _focusNode.removeListener(_onFocusChange);
    } catch (_) {}
    if (_ownsFocusNode) _focusNode.dispose();
    if (_needsTextListener) {
      try {
        _controller.removeListener(_onTextChange);
      } catch (_) {}
    }
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  /// QA-Oct11 #25: Cairo's tall ascent sat the text LOW in a fixed-height
  /// field; an even 1.4 line box puts the glyphs on the box's middle.
  TextStyle _centred(TextStyle s) => _fillsHeight
      ? s.copyWith(height: 1.4, leadingDistribution: TextLeadingDistribution.even)
      : s;

  /// One-line field with a fixed height → fills that height (see TextField).
  bool get _fillsHeight =>
      widget.height != null && !_isMultiline && !widget.obscureText;

  bool get _isMultiline =>
      (widget.maxLines ?? 1) != 1 || widget.minLines != null;

  // ── Opt-in helpers ─────────────────────────────────────────────────────────

  /// Effective character limit: explicit [maxLength] only. The counter is
  /// NEVER shown (app-wide rule) so [showCharCount] adds no implicit limit.
  int? get _effectiveMaxLength => widget.maxLength;

  /// True when a blocked Publish asked the page to show what's missing.
  /// Reading it in build() subscribes, so the border appears immediately.
  bool get _revealMissing =>
      widget.required && ValidationScope.revealed(context);

  /// Treat a revealed page exactly like a submit attempt.
  bool get _submitted => widget.submitted || _revealMissing;

  bool get _hasValidation => _submitted || widget.onlyDigits;

  // A required field has to repaint as soon as it is filled in, so the red
  // border clears while the user types — not only on the next Publish tap.
  bool get _needsTextListener => widget.submitted || widget.onlyDigits || widget.required;

  /// Resolves the error to display: explicit [errorText] wins, otherwise the
  /// built-in validation (only active when a validation flag is set).
  ///
  /// NOTE: There is deliberately NO language validation here — every field
  /// accepts Arabic and English text freely.
  String? get _resolvedError {
    final explicit = widget.errorText;
    if (explicit != null && explicit.isNotEmpty) return explicit;
    if (!_hasValidation) return null;

    final text = _controller.text;
    final isEmpty = text.trim().isEmpty;
    final isRtl = widget.textDirection == TextDirection.rtl;

    if (_submitted && isEmpty) {
      // Border only, no message. The red outline already says "this one" —
      // a line of text under every empty field just adds noise and shifts the
      // layout. _EMPTY_REQUIRED is a sentinel: it turns the border red without
      // rendering anything beneath the field.
      return _kRequiredNoMessage;
    }
    if (widget.onlyDigits &&
        text.isNotEmpty &&
        !RegExp(r'^\d+$').hasMatch(text)) {
      return 'Only numbers are allowed.';
    }
    return null;
  }

  /// Builds input formatters from the opt-in flags, then appends any caller
  /// supplied [inputFormatters].
  ///
  /// NOTE: No Arabic-only / English-only formatters — both languages are
  /// always allowed.
  List<TextInputFormatter>? get _resolvedFormatters {
    final list = <TextInputFormatter>[];
    if (widget.autoCapitalize &&
        widget.textDirection != TextDirection.rtl &&
        !widget.onlyDigits) {
      list.add(_CapitalizeTextFormatter());
    }
    if (widget.onlyDigits) {
      list.add(FilteringTextInputFormatter.digitsOnly);
    }
    if (widget.inputFormatters != null) list.addAll(widget.inputFormatters!);
    return list.isEmpty ? null : list;
  }

  // Effective obscure: only applies when the prop is true AND not multiline
  bool get _effectiveObscure =>
      widget.obscureText && !_isMultiline && _obscured;

  @override
  Widget build(BuildContext context) {
    final resolvedError = _resolvedError;
    final hasError = resolvedError != null && resolvedError.isNotEmpty;
    // BUG-27 / BUG-46: an empty required field now also says WHY it is red
    // ("This field is required.") — a border alone looked like a broken
    // button, especially when the field was far above Publish/Save.
    final showMessage = hasError;
    // BUG-291: an Arabic field says it in Arabic (it showed the English
    // text with the full stop flipped to the front: ".This field is required").
    final bool isRtlField = widget.textDirection == TextDirection.rtl ||
        Directionality.of(context) == TextDirection.rtl;
    final String? messageText = resolvedError == _kRequiredNoMessage
        ? (isRtlField ? 'هذا الحقل مطلوب.' : 'This field is required.')
        : (isRtlField && resolvedError == 'Only numbers are allowed.'
            ? 'يُسمح بالأرقام فقط.'
            : resolvedError);
    final radius = widget.borderRadius ?? BorderRadius.circular(4.r);
    final isDisabled = !widget.enabled && !widget.readOnlyView; // BUG-294

    // ── Suffix icon resolution ─────────────────────────────────────────────
    // Priority: explicit suffixIcon > password-toggle eye > nothing
    Widget? resolvedSuffix = widget.suffixIcon;
    if (resolvedSuffix == null && widget.obscureText && !_isMultiline) {
      resolvedSuffix = GestureDetector(
        onTap: () => setState(() => _obscured = !_obscured),
        child: Icon(
          _obscured
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          size: 20.sp,
          color: hasError
              ? AppColors.red
              : isDisabled
              ? AppColors.text.withOpacity(0.3)
              : AppColors.text.withOpacity(0.5),
        ),
      );
    }

    // ── Content padding ────────────────────────────────────────────────────
    final effectivePadding = widget.contentPadding ??
        EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Label ──────────────────────────────────────────────────────────
        if (widget.label != null) ...[
          RichText(
            text: TextSpan(
              text: widget.label,
              style: widget.labelStyle ??
                  StyleText.label.copyWith(
                    color: hasError
                        ? AppColors.red
                        : isDisabled
                        ? AppColors.text.withOpacity(0.4)
                        : AppColors.text,
                  ),
              children: widget.required
                  ? [
                TextSpan(
                  text: '',
                  style: StyleText.label
                      .copyWith(color: AppColors.red),
                ),
              ]
                  : [],
            ),
          ),
          SizedBox(height: 6.h),
        ],

        // ── Field ──────────────────────────────────────────────────────────
        SizedBox(
          width: widget.width?.w,
          height: widget.height?.h,
          child: Theme(
            // ── Cursor / selection color rule ───────────────────────────────
            // Flutter derives the blinking cursor color, the text-selection
            // (copy) highlight, and the drag handles from
            // TextSelectionThemeData — NOT from TextField params alone on
            // every platform. Force all three to ColorPick.primary here so
            // they never fall back to the theme primary (yellow).
            data: Theme.of(context).copyWith(
              textSelectionTheme: TextSelectionThemeData(
                cursorColor: ColorPick.primary,
                selectionColor: ColorPick.primary.withOpacity(0.3),
                selectionHandleColor: ColorPick.primary,
              ),
            ),
            // ── No scrollbar rule ───────────────────────────────────────────
            // A multi-line field (Short Description, Description, any textarea)
            // gets a grey track down its right edge on web because Flutter's
            // desktop ScrollBehavior draws one for every scrollable, including
            // the one inside a TextField. It overlaps the text and looks like a
            // rendering fault next to the flat, borderless field. Hidden here
            // once, so it is gone from every textarea in the app.
            child: ScrollConfiguration(
              behavior: const _NoFieldScrollbar(),
              child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              enabled: widget.enabled,
              readOnly: widget.readOnly,
              obscureText: _effectiveObscure,
              // Fixed-height one-line field: EXPANDS to the full height,
              // the same technique as the dropdown trigger (InputDecorator
              // expands) — so field and dropdown are identical boxes.
              maxLines: _fillsHeight ? null : (widget.obscureText ? 1 : widget.maxLines),
              minLines: _fillsHeight ? null : widget.minLines,
              expands: _fillsHeight,
              maxLength: _effectiveMaxLength,
              cursorColor: ColorPick.primary,
              keyboardType: _isMultiline
                  ? TextInputType.multiline
                  : (widget.keyboardType ??
                  (widget.onlyDigits ? TextInputType.number : null)),
              inputFormatters: _fillsHeight
                  ? [...?_resolvedFormatters, FilteringTextInputFormatter.deny(RegExp(r'[\n\r]'))]
                  : _resolvedFormatters,
              textAlign: widget.textAlign,
              textDirection: widget.textDirection,
              textInputAction: widget.textInputAction ??
                  (_fillsHeight ? TextInputAction.done : null),
              textCapitalization: widget.textCapitalization,
              autocorrect: widget.autocorrect,
              enableSuggestions: widget.enableSuggestions,
              onChanged: (v) {
                // Seeding a form sets controller.text directly, which never
                // reaches here — so this only fires on a real human edit.
                FormDirtyScope.markDirty(context);
                widget.onChanged?.call(v);
              },
              onSubmitted: widget.onSubmitted,
              onTap: widget.onTap,
              style: _centred(widget.valueStyle ??
                  StyleText.value.copyWith(
                    color: isDisabled
                        ? AppColors.text.withOpacity(0.4)
                        : AppColors.text,
                  )),
              // NEVER show the built-in counter (app-wide rule)
              buildCounter: _effectiveMaxLength != null
                  ? (_,
                  {required currentLength,
                    required isFocused,
                    maxLength}) =>
              const SizedBox.shrink()
                  : null,
              // A one-line field with a fixed height fills that WHOLE height
              // (text centred), exactly like the dropdowns next to it — before,
              // only the text line was painted and the box looked shorter.
              textAlignVertical:
                  _fillsHeight ? TextAlignVertical.center : null,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: effectivePadding,
                filled: true,
                // No hover overlay tint on desktop/web
                hoverColor: Colors.transparent,
                fillColor: isDisabled
                    ? (widget.fillColor ?? AppColors.card).withOpacity(0.5)
                    : widget.fillColor ?? AppColors.card,

                // ── No border rule ────────────────────────────────────────────
                // Default / focused / disabled → no border at all.
                // Error → red border.
                border: hasError
                    ? OutlineInputBorder(
                  borderRadius: radius,
                  borderSide:
                  BorderSide(color: AppColors.red, width: 1.5.w),
                )
                    : OutlineInputBorder(
                  borderRadius: radius,
                  borderSide: BorderSide.none,
                ),
                enabledBorder: hasError
                    ? OutlineInputBorder(
                  borderRadius: radius,
                  borderSide:
                  BorderSide(color: AppColors.red, width: 1.5.w),
                )
                    : OutlineInputBorder(
                  borderRadius: radius,
                  borderSide: BorderSide.none,
                ),
                focusedBorder: hasError
                    ? OutlineInputBorder(
                  borderRadius: radius,
                  borderSide:
                  BorderSide(color: AppColors.red, width: 1.5.w),
                )
                    : OutlineInputBorder(
                  borderRadius: radius,
                  borderSide: BorderSide.none,
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: radius,
                  borderSide: BorderSide.none,
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: radius,
                  borderSide: BorderSide(color: AppColors.red, width: 1.5.w),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: radius,
                  borderSide: BorderSide(color: AppColors.red, width: 1.5.w),
                ),
                // ─────────────────────────────────────────────────────────────

                hintText: widget.hint,
                hintStyle: _centred(widget.hintStyle ?? StyleText.hint),

                prefixIcon: widget.prefixIcon != null
                    ? Padding(
                  padding: EdgeInsets.only(left: 12.w, right: 8.w),
                  child: widget.prefixIcon,
                )
                    : null,
                prefixIconConstraints: const BoxConstraints(),

                suffixIcon: resolvedSuffix != null
                    ? Padding(
                  padding: EdgeInsets.only(left: 8.w, right: 12.w),
                  child: resolvedSuffix,
                )
                    : null,
                suffixIconConstraints: const BoxConstraints(),

                // Suppress built-in error / helper — we render our own
                errorText: null,
                helperText: null,
                counterText: '',
              ),
            ),
            ),
          ),
        ),

        // ── Error / Helper row (NO counter — app-wide rule) ────────────────
        // The built-in "required" check reports through a sentinel so the
        // border turns red WITHOUT a message underneath. Only a message the
        // caller actually supplied is rendered.
        if (showMessage || widget.helperText != null) ...[
          SizedBox(height: 4.h),
          showMessage
              ? Text(
            messageText!,
            textDirection:
                isRtlField ? TextDirection.rtl : TextDirection.ltr, // BUG-291
            style: widget.errorStyle ??
                StyleText.subTitle.copyWith(color: AppColors.red),
          )
              : Text(
            widget.helperText!,
            style: widget.helperStyle ??
                StyleText.subTitle.copyWith(
                  color: AppColors.text.withOpacity(0.5),
                ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private input formatters (self-contained — no external dependencies)
// ─────────────────────────────────────────────────────────────────────────────

/// Capitalises the first letter of every word.
class _CapitalizeTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    if (newValue.text.isEmpty) return newValue;

    final capitalizedText = newValue.text.split(' ').map((word) {
      if (word.isEmpty) return word;
      if (word.length == 1) return word.toUpperCase();
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');

    return TextEditingValue(
      text: capitalizedText,
      selection: TextSelection.collapsed(offset: capitalizedText.length),
    );
  }
}

/// Scroll behaviour that draws no scrollbar.
///
/// Wrapped around the TextField above so multi-line fields don't get the
/// desktop scrollbar track painted over their right edge. It only affects the
/// scrollable inside the field — page scrollbars elsewhere are untouched.
class _NoFieldScrollbar extends MaterialScrollBehavior {
  const _NoFieldScrollbar();

  @override
  Widget buildScrollbar(
      BuildContext context, Widget child, ScrollableDetails details) => child;
}
