// ═══════════════════════════════════════════════════════════════════════════
// Admin sign-in screen — same layout as Knowticed Plus's SignInScreen
// (knowticed_plus/lib/features/onboarding/o3_authentication/presentation/ui/
//  pages/sign_in_screen.dart):
//
//   • landscape (desktop / wide browser) → split panel: hero image on the
//     left (1 / 2.6 of the width, white 19 % veil), title + tagline + form on
//     the right, logo top-left, language toggle top-right, copyright and
//     version pinned at the bottom.
//   • portrait (phone / narrow browser)  → hero image (45 % of the height)
//     with the logo on it, then title, tagline, form, copyright + version.
//
// Fields: 8 px radius, white fill, no border, primary-tinted SVG prefix icon,
// eye toggle on the password. Sign In button: primary, 300 × 38.
//
// This screen lives OUTSIDE BayanatzApp (no ScreenUtil / LanguageCubit yet),
// so sizes are plain logical pixels and the EN/AR strings are local.
// Sign-in is checked on the server by the `adminLogin` Cloud Function, which
// returns a Firebase custom token (see admin_auth.dart — BUG-96).
// BUG-97: "Forgot Password?" opens a real reset flow (e-mail link → new
// password form).
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../constant/color.dart';
import '../theme/appcolors.dart';
import '../widget/auto_close_dialog.dart';
import '../custom/circle_progress.dart';
import 'admin_auth.dart';

const String _kHeroImage = 'assets/images/login/login_photo.jpeg';
// Transparent copy of assets/images/logo.jpg (white background removed).
const String _kLogo = 'assets/images/login/logo.png';
const String _kMailIcon = 'assets/images/login/mail.svg';
const String _kPasswordIcon = 'assets/images/login/password.svg';
const String _kAppVersion = '1.0.0';

// Theme colours: text = AppColors.text, hints = AppColors.secondaryText.
Color get _kText => AppColors.text;
Color get _kSecondaryText => AppColors.secondaryText;

// ── Local strings (EN / AR) ────────────────────────────────────────────────
class _S {
  const _S(this.ar);
  final bool ar;

  // BUG-280: one Arabic brand name (About Company says "بيانات زي") and a
  // masculine adjective for "الأفق" ("الرقمي", was "الرقمية").
  String get title => ar ? 'لوحة تحكم بيانات زي' : 'Bayanatz Admin';
  String get tagline => ar
      ? 'انطلق في الأفق الرقمي بكل سهولة'
      : 'Navigate the Digital Frontier with Ease';
  String get enterEmail => ar ? 'أدخل بريدك الإلكتروني' : 'Enter Your Email';
  String get enterPassword => ar ? 'أدخل كلمة المرور' : 'Enter Your Password';
  String get forgotPassword => ar ? 'هل نسيت كلمة المرور؟' : 'Forgot Password?';
  String get signIn => ar ? 'تسجيل الدخول' : 'Sign In';
  String get toggle => ar ? 'English' : 'العربية';
  String get version => ar ? 'الإصدار:' : 'Version:';
  String copyright(int y) => ar
      ? 'حقوق النشر© $y Bayanatz. كل الحقوق محفوظة'
      : 'Copyright© $y Bayanatz. ALL RIGHTS RESERVED';

  String get missingTitle => ar ? 'بيانات ناقصة' : 'Missing Information';
  String get missingBody => ar
      ? 'من فضلك أدخل البريد الإلكتروني وكلمة المرور لتسجيل الدخول.'
      : 'Please enter both email and password to sign in.';
  String get errorTitle => ar ? 'تعذر تسجيل الدخول' : 'Sign In Failed';
  // One message for unknown e-mail and wrong password (no account probing).
  String get invalidCredentials => ar
      ? 'البريد الإلكتروني أو كلمة المرور غير صحيحة.'
      : 'Incorrect email or password.';
  String get locked => ar
      ? 'تم إيقاف الحساب مؤقتاً بعد محاولات خاطئة متكررة. حاول بعد 15 دقيقة.'
      : 'Too many failed attempts. Please try again in 15 minutes.';
  String get inactive => ar
      ? 'هذا الحساب غير مفعل. تواصل مع مسؤول النظام.'
      : 'This account is deactivated. Contact the system administrator.';
  String get network => ar
      ? 'تعذر الاتصال. تحقق من الإنترنت وحاول مرة أخرى.'
      : 'Could not connect. Check your internet and try again.';
  String get forgotTitle => ar ? 'نسيت كلمة المرور' : 'Forgot Password';
  String get forgotIntro => ar
      ? 'أدخل بريدك الإلكتروني وسنرسل لك رابطاً لإعادة تعيين كلمة المرور.'
      : "Enter your email and we'll send you a link to reset your password.";
  String get sendLink => ar ? 'إرسال الرابط' : 'Send Reset Link';
  String get backToSignIn => ar ? 'العودة لتسجيل الدخول' : 'Back to Sign In';
  String get linkSentTitle => ar ? 'تحقق من بريدك' : 'Check Your Email';
  String get linkSentBody => ar
      ? 'إذا كان هذا البريد لحساب مسؤول، فستصلك رسالة بها رابط صالح لمدة ساعة.'
      : 'If this email belongs to an admin account, a reset link (valid for 1 hour) is on its way.';
  String get invalidEmail =>
      ar ? 'يرجى إدخال بريد إلكتروني صحيح.' : 'Please enter a valid email.';
  String get resetTitle => ar ? 'تعيين كلمة مرور جديدة' : 'Set a New Password';
  String resetFor(String email) =>
      ar ? 'للحساب: $email' : 'For: $email';
  String get newPassword => ar ? 'كلمة المرور الجديدة' : 'New Password';
  String get confirmPassword => ar ? 'تأكيد كلمة المرور' : 'Confirm Password';
  String get savePassword => ar ? 'حفظ كلمة المرور' : 'Save Password';
  String get weakPassword => ar
      ? 'كلمة المرور يجب أن تكون 8 أحرف على الأقل وتحتوي على حروف وأرقام.'
      : 'Use at least 8 characters with letters and numbers.';
  String get mismatch =>
      ar ? 'كلمتا المرور غير متطابقتين.' : "The passwords don't match.";
  String get invalidLink => ar
      ? 'رابط إعادة التعيين غير صالح أو منتهي. اطلب رابطاً جديداً.'
      : 'This reset link is invalid or has expired. Please request a new one.';
  String get resetDoneTitle => ar ? 'تم التحديث' : 'Password Updated';
  String get resetDoneBody => ar
      ? 'تم حفظ كلمة المرور الجديدة. سجّل الدخول الآن.'
      : 'Your new password is saved. You can sign in now.';
}

enum _Mode { signIn, forgot, reset }

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _busy = false;
  bool _obscure = true;

  /// BUG-285: empty-field errors are shown under the fields (like every
  /// admin form) instead of in a "Missing Information" pop-up.
  String? _emailError;
  String? _passwordError;
  String get _requiredMsg =>
      _arabic ? 'هذا الحقل مطلوب.' : 'This field is required.';
  bool _arabic = false;
  late _Mode _mode =
      AdminAuth.pendingReset.value != null ? _Mode.reset : _Mode.signIn;

  _S get s => _S(_arabic);

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  // ── Actions ──────────────────────────────────────────────────────────────

  Future<void> _onSignInPressed() async {
    if (_busy) return;
    final email = _email.text.trim().toLowerCase();
    final password = _password.text;

    // BUG-285: inline, per field — no modal.
    setState(() {
      _emailError = email.isEmpty ? _requiredMsg : null;
      _passwordError = password.isEmpty ? _requiredMsg : null;
    });
    if (email.isEmpty || password.isEmpty) return;

    setState(() => _busy = true);
    final result = await AdminAuth.signIn(email, password);
    if (!mounted) return;
    setState(() => _busy = false);

    if (result.ok) return; // AdminAuthGate swaps to the dashboard.
    _showMessage(
      s.errorTitle,
      switch (result.error!) {
        AdminLoginError.invalidCredentials => s.invalidCredentials,
        AdminLoginError.locked => s.locked,
        AdminLoginError.inactive => s.inactive,
        AdminLoginError.network => s.network,
      },
      isError: true,
    );
  }

  // BUG-97: "Forgot Password?" did nothing.
  void _onForgotPasswordPressed() => setState(() => _mode = _Mode.forgot);

  Future<void> _onSendResetLink() async {
    if (_busy) return;
    final email = _email.text.trim().toLowerCase();
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$').hasMatch(email)) {
      _showMessage(s.missingTitle, s.invalidEmail, isError: true);
      return;
    }
    setState(() => _busy = true);
    final ok = await AdminAuth.requestPasswordReset(email, arabic: _arabic);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (ok) _mode = _Mode.signIn;
    });
    ok
        ? _showMessage(s.linkSentTitle, s.linkSentBody, isError: false)
        : _showMessage(s.errorTitle, s.network, isError: true);
  }

  Future<void> _onSaveNewPassword() async {
    final link = AdminAuth.pendingReset.value;
    if (_busy || link == null) return;
    final p1 = _newPassword.text;
    if (!AdminAuth.isStrongPassword(p1)) {
      _showMessage(s.errorTitle, s.weakPassword, isError: true);
      return;
    }
    if (p1 != _confirmPassword.text) {
      _showMessage(s.errorTitle, s.mismatch, isError: true);
      return;
    }
    setState(() => _busy = true);
    final err = await AdminAuth.resetPassword(link, p1);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (err == null) {
        _email.text = link.email;
        _mode = _Mode.signIn;
      }
    });
    if (err == null) {
      _showMessage(s.resetDoneTitle, s.resetDoneBody, isError: false);
    } else {
      _showMessage(
        s.errorTitle,
        switch (err) {
          AdminResetError.invalidLink => s.invalidLink,
          AdminResetError.weakPassword => s.weakPassword,
          AdminResetError.network => s.network,
        },
        isError: true,
      );
    }
  }

  Widget _linkText(String text, VoidCallback onTap) => MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Text(text, style: TextStyle(fontSize: 14, color: _kText)),
        ),
      );

  Widget _primaryButton(String label, VoidCallback onPressed) => SizedBox(
        width: 300,
        height: 44,
        child: ElevatedButton(
          onPressed: _busy ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: ColorPick.primary,
            disabledBackgroundColor: ColorPick.primary,
            disabledForegroundColor: Colors.white,
            foregroundColor: Colors.white,
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(label,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      );

  Widget _forgotForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        Text(s.forgotTitle,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700, color: _kText)),
        const SizedBox(height: 6),
        Text(s.forgotIntro, style: TextStyle(fontSize: 14, color: _kSecondaryText)),
        const SizedBox(height: 14),
        _field(
          controller: _email,
          hint: s.enterEmail,
          icon: _kMailIcon,
          keyboardType: TextInputType.emailAddress,
          autofill: AutofillHints.email,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _onSendResetLink(),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _linkText(s.backToSignIn, () => setState(() => _mode = _Mode.signIn)),
          ],
        ),
        const SizedBox(height: 40),
        Center(child: _primaryButton(s.sendLink, _onSendResetLink)),
      ],
    );
  }

  Widget _resetForm() {
    final link = AdminAuth.pendingReset.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        Text(s.resetTitle,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700, color: _kText)),
        if (link != null) ...[
          const SizedBox(height: 6),
          Text(s.resetFor(link.email),
              style: TextStyle(fontSize: 14, color: _kSecondaryText)),
        ],
        const SizedBox(height: 14),
        _field(
          controller: _newPassword,
          hint: s.newPassword,
          icon: _kPasswordIcon,
          obscure: true,
          autofill: AutofillHints.newPassword,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 14),
        _field(
          controller: _confirmPassword,
          hint: s.confirmPassword,
          icon: _kPasswordIcon,
          obscure: true,
          autofill: AutofillHints.newPassword,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _onSaveNewPassword(),
        ),
        const SizedBox(height: 6),
        Text(s.weakPassword, style: TextStyle(fontSize: 12, color: _kSecondaryText)),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _linkText(s.backToSignIn, () {
              AdminAuth.pendingReset.value = null;
              setState(() => _mode = _Mode.signIn);
            }),
          ],
        ),
        const SizedBox(height: 40),
        Center(child: _primaryButton(s.savePassword, _onSaveNewPassword)),
      ],
    );
  }

  /// The form for the current mode (sign in / forgot / reset).
  Widget _activeForm() => switch (_mode) {
        _Mode.signIn => _signInForm(),
        _Mode.forgot => _forgotForm(),
        _Mode.reset => _resetForm(),
      };

  void _showMessage(String title, String body, {required bool isError}) {
    showDialog<void>(
      context: context,
      // Closes itself after 3 s (AutoCloseDialog) — no OK button.
      builder: (ctx) => AutoCloseDialog(child: Directionality(
        textDirection: _arabic ? TextDirection.rtl : TextDirection.ltr,
        child: Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isError ? Icons.error_outline_rounded : Icons.info_outline_rounded,
                    size: 56,
                    color: ColorPick.primary,
                  ),
                  const SizedBox(height: 14),
                  Text(title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700, color: _kText)),
                  const SizedBox(height: 8),
                  Text(body,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: _kSecondaryText)),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      )),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isPortrait = size.width < size.height || size.width < 760;

    return Directionality(
      textDirection: _arabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: ColorPick.background,
        body: Stack(
          children: [
            isPortrait ? _portraitLayout(size) : _landscapeLayout(size),
            // While signing in: the app's own CircleProgress in the centre of
            // the page, over a light veil that blocks taps on the form.
            if (_busy)
              Positioned.fill(
                child: AbsorbPointer(
                  child: Container(
                    color: Colors.black.withOpacity(0.15),
                    child: const CircleProgress(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Shared pieces ────────────────────────────────────────────────────────

  Widget _signInForm() {
    return Column(
      children: [
        const SizedBox(height: 14),
        _field(
          controller: _email,
          hint: s.enterEmail,
          icon: _kMailIcon,
          keyboardType: TextInputType.emailAddress,
          autofill: AutofillHints.email,
          textInputAction: TextInputAction.next,
          errorText: _emailError, // BUG-285
          onChanged: (_) {
            if (_emailError != null) setState(() => _emailError = null);
          },
        ),
        const SizedBox(height: 14),
        _field(
          controller: _password,
          hint: s.enterPassword,
          icon: _kPasswordIcon,
          obscure: true,
          autofill: AutofillHints.password,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _onSignInPressed(),
          errorText: _passwordError, // BUG-285
          onChanged: (_) {
            if (_passwordError != null) setState(() => _passwordError = null);
          },
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: _onForgotPasswordPressed,
                child: Text(s.forgotPassword,
                    style: TextStyle(fontSize: 14, color: _kText)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 40),
        // BUG-284: on a phone / narrow window the button spans the same
        // width as the fields (it was a centred 300 px button that did not
        // line up with them).
        SizedBox(
          width: MediaQuery.of(context).size.width < 700 ? double.infinity : 300,
          height: 44,
          child: ElevatedButton(
            onPressed: _busy ? null : _onSignInPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorPick.primary,
              disabledBackgroundColor: ColorPick.primary,
              disabledForegroundColor: Colors.white,
              foregroundColor: Colors.white,
              elevation: 0,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(s.signIn,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required String icon,
    TextInputType? keyboardType,
    bool obscure = false,
    String? autofill,
    TextInputAction? textInputAction,
    ValueChanged<String>? onSubmitted,
    String? errorText,
    ValueChanged<String>? onChanged,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    );
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure && _obscure,
      // Same vertically-centred star mask as Knowticed Plus.
      obscuringCharacter: '∗',
      autofillHints: autofill == null ? null : [autofill],
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      onChanged: onChanged,
      enabled: !_busy,
      style: TextStyle(fontSize: 14, color: _kText),
      cursorColor: ColorPick.primary,
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        // AppColors.card (white in light, dark grey in dark) — same as
        // Knowticed Plus, so AppColors.text stays readable in both themes.
        fillColor: AppColors.card,
        // No grey tint when the mouse hovers over the field (web / desktop).
        hoverColor: Colors.transparent,
        hintText: hint,
        hintStyle: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w500, color: _kSecondaryText),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: border,
        enabledBorder: border,
        disabledBorder: border,
        focusedBorder: border.copyWith(
            borderSide: const BorderSide(color: ColorPick.primary, width: 1)),
        // BUG-285: same error state as the admin forms (red border + text).
        errorText: errorText,
        errorStyle: const TextStyle(fontSize: 12, color: ColorPick.red),
        errorBorder: border.copyWith(
            borderSide: const BorderSide(color: ColorPick.red, width: 1.5)),
        focusedErrorBorder: border.copyWith(
            borderSide: const BorderSide(color: ColorPick.red, width: 1.5)),
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: SvgPicture.asset(
            icon,
            width: 18,
            height: 18,
            colorFilter:
                const ColorFilter.mode(ColorPick.primary, BlendMode.srcIn),
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 42, minHeight: 18),
        suffixIcon: obscure
            ? IconButton(
                splashRadius: 18,
                icon: Icon(
                  _obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                  color: _kSecondaryText,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              )
            : null,
      ),
    );
  }

  Widget _logo(double size) => Image.asset(
        _kLogo,
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => Icon(Icons.admin_panel_settings_outlined,
            size: size, color: ColorPick.primary),
      );

  Widget _headings({required bool isPortrait}) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.title,
              style: TextStyle(
                  fontSize: 28, fontWeight: FontWeight.w700, color: _kText)),
          SizedBox(height: isPortrait ? 8 : 10),
          Text(s.tagline,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w500, color: _kText)),
        ],
      );

  Widget _copyright() => Text(
        s.copyright(DateTime.now().year),
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13, color: _kText),
      );

  Widget _versionLabel() => Text(
        '${s.version} $_kAppVersion',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13, color: _kText),
      );

  /// BUG-283: on a phone the link sits on the dark photo — white text on a
  /// dark pill there (dark grey on the photo was 1.38 : 1 contrast).
  Widget _languageToggle({bool onPhoto = false}) => MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => setState(() {
            _arabic = !_arabic;
            // Re-word any shown error in the new language.
            if (_emailError != null) _emailError = _requiredMsg;
            if (_passwordError != null) _passwordError = _requiredMsg;
          }),
          child: onPhoto
              ? Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(s.toggle,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                )
              : Text(s.toggle,
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600, color: _kText)),
        ),
      );

  // ── Portrait — phone / narrow window ─────────────────────────────────────

  Widget _portraitLayout(Size size) {
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: size.height),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Image.asset(
                  _kHeroImage,
                  width: double.infinity,
                  height: size.height * 0.40,
                  fit: BoxFit.cover,
                ),
                PositionedDirectional(
                  top: 32,
                  start: 16,
                  child: _logo(48),
                ),
                PositionedDirectional(
                  top: 40,
                  end: 16,
                  child: _languageToggle(onPhoto: true), // BUG-283
                ),
              ],
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _headings(isPortrait: true),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _activeForm(),
            ),
            const SizedBox(height: 48),
            Center(
              child: Column(
                children: [
                  _copyright(),
                  const SizedBox(height: 8),
                  _versionLabel(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Landscape — desktop / wide window ────────────────────────────────────

  Widget _landscapeLayout(Size size) {
    return Row(
      children: [
        // Hero panel with the same white 19 % veil as Knowticed Plus.
        SizedBox(
          width: size.width / 2,
          height: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(_kHeroImage, fit: BoxFit.cover),
              Container(color: Colors.white.withOpacity(0.19)),
              PositionedDirectional(
                top: size.height * 0.07,
                start: 32,
                child: _logo(size.height * 0.09),
              ),
            ],
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: size.height * 0.07),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _headings(isPortrait: false),
                        _activeForm(),
                      ],
                    ),
                  ),
                ),
              ),
              PositionedDirectional(
                top: size.height * 0.07,
                end: 48,
                child: _languageToggle(),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 24,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _copyright(),
                    const SizedBox(height: 8),
                    _versionLabel(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
