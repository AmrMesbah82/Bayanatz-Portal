// ═══════════════════════════════════════════════════════════════════════════
// Admin login — checked on the SERVER (BUG-01 / BUG-96 / BUG-97, 7/10/2026).
//
// Before: the browser downloaded admin_accounts/<email> (password hash + salt)
// and compared the hash itself; the "session" was that hash in localStorage
// and a one-time routine created the first admin with a password written in
// the app code. Anyone could read the hashes and the rules could not tell an
// admin from a visitor.
//
// Now:
//   1. [AdminAuth.signIn] calls the Cloud Function `adminLogin` (website_app/
//      functions). It checks the password with the Admin SDK and returns a
//      Firebase custom token with the claim  admin: true.
//   2. The app signs in with FirebaseAuth.signInWithCustomToken. Firebase
//      keeps the session (refresh survives a reload) and every Firestore /
//      Storage request carries request.auth.token.admin, which the rules
//      (firestore.rules / storage.rules) require for every admin collection.
//   3. admin_accounts is not readable from any browser.
//   4. "Forgot Password?" → `adminRequestPasswordReset` e-mails a one-hour
//      link  …/?reset=<token>&email=<email>; opening it shows the
//      "Set a new password" form → `adminResetPassword`.
//
//   admin_accounts/{email in lower case}   (managed by the Cloud Functions /
//   functions/scripts/set_admin_password.js — never by the browser)
//     email, name, role, isActive, passwordSalt, passwordHash, passwordAlgo,
//     failedLogins, lockedUntil, lastLoginAt, resetTokenHash, resetExpiresAt
// ═══════════════════════════════════════════════════════════════════════════

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constant/color.dart';
import 'admin_login_page.dart';

/// The signed-in admin.
class AdminAccount {
  const AdminAccount({
    required this.email,
    required this.name,
    required this.role,
  });

  final String email;
  final String name;
  final String role;
}

/// Why a sign-in was refused.
enum AdminLoginError { invalidCredentials, locked, inactive, network }

class AdminLoginResult {
  const AdminLoginResult.success(this.account) : error = null;
  const AdminLoginResult.failure(this.error) : account = null;

  final AdminAccount? account;
  final AdminLoginError? error;
  bool get ok => account != null;
}

/// Why a password reset was refused.
enum AdminResetError { invalidLink, weakPassword, network }

/// A reset link that was opened (…/?reset=<token>&email=<email>).
class AdminResetLink {
  const AdminResetLink(this.email, this.token);
  final String email;
  final String token;
}

class AdminAuth {
  AdminAuth._();

  /// The current admin, or null when signed out. [AdminAuthGate] listens to it.
  static final ValueNotifier<AdminAccount?> current =
      ValueNotifier<AdminAccount?>(null);

  /// Set when the page was opened from a password-reset e-mail.
  static final ValueNotifier<AdminResetLink?> pendingReset =
      ValueNotifier<AdminResetLink?>(_readResetLink());

  static FirebaseAuth get _auth => FirebaseAuth.instance;
  static FirebaseFunctions get _fn => FirebaseFunctions.instance;

  static AdminResetLink? _readResetLink() {
    final q = Uri.base.queryParameters;
    final token = q['reset'] ?? '';
    final email = q['email'] ?? '';
    if (token.isEmpty || email.isEmpty) return null;
    return AdminResetLink(email.trim().toLowerCase(), token.trim());
  }

  // ── Sign in / out ───────────────────────────────────────────────────────

  static Future<AdminLoginResult> signIn(String email, String password) async {
    final id = email.trim().toLowerCase();
    try {
      final res = await _fn
          .httpsCallable('adminLogin')
          .call({'email': id, 'password': password});
      final data = Map<String, dynamic>.from(res.data as Map);
      final token = data['token'] as String? ?? '';
      if (token.isEmpty) {
        return const AdminLoginResult.failure(AdminLoginError.network);
      }
      await _auth.signInWithCustomToken(token);
      final account = AdminAccount(
        email: id,
        name: data['name'] as String? ?? '',
        role: data['role'] as String? ?? 'admin',
      );
      current.value = account;
      return AdminLoginResult.success(account);
    } on FirebaseFunctionsException catch (e) {
      debugPrint('[admin-login] ${e.code}: ${e.message}');
      return AdminLoginResult.failure(switch (e.code) {
        'unauthenticated' => AdminLoginError.invalidCredentials,
        'resource-exhausted' => AdminLoginError.locked,
        'permission-denied' => AdminLoginError.inactive,
        _ => AdminLoginError.network,
      });
    } catch (e) {
      debugPrint('[admin-login] $e');
      return const AdminLoginResult.failure(AdminLoginError.network);
    }
  }

  /// Re-opens the Firebase session after a page refresh. Only a user whose
  /// token carries the admin claim gets in.
  static Future<void> restoreSession() async {
    try {
      final user = await _auth
          .authStateChanges()
          .first
          .timeout(const Duration(seconds: 8));
      if (user == null) return;
      // Force refresh so a revoked session (password reset) is noticed.
      final token = await user.getIdTokenResult(true);
      final claims = token.claims ?? const <String, dynamic>{};
      if (claims['admin'] != true) {
        await _auth.signOut();
        return;
      }
      current.value = AdminAccount(
        email: (claims['email'] as String? ?? '').toLowerCase(),
        name: '',
        role: claims['role'] as String? ?? 'admin',
      );
    } catch (e) {
      debugPrint('[admin-login] restore failed: $e');
      try {
        await _auth.signOut();
      } catch (_) {}
    }
  }

  static Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (_) {}
    current.value = null;
  }

  // ── Forgot password (BUG-97) ──────────────────────────────────────────────

  /// Always "succeeds" (the server never says whether the e-mail exists);
  /// returns false only when the request could not be sent at all.
  static Future<bool> requestPasswordReset(String email,
      {bool arabic = false}) async {
    try {
      await _fn.httpsCallable('adminRequestPasswordReset').call({
        'email': email.trim().toLowerCase(),
        'locale': arabic ? 'ar' : 'en',
      });
      return true;
    } catch (e) {
      debugPrint('[admin-reset] request failed: $e');
      return false;
    }
  }

  /// Returns null on success.
  static Future<AdminResetError?> resetPassword(
      AdminResetLink link, String newPassword) async {
    try {
      await _fn.httpsCallable('adminResetPassword').call({
        'email': link.email,
        'token': link.token,
        'password': newPassword,
      });
      pendingReset.value = null;
      return null;
    } on FirebaseFunctionsException catch (e) {
      debugPrint('[admin-reset] ${e.code}: ${e.message}');
      if (e.code == 'invalid-argument') return AdminResetError.weakPassword;
      if (e.code == 'permission-denied') return AdminResetError.invalidLink;
      return AdminResetError.network;
    } catch (e) {
      debugPrint('[admin-reset] $e');
      return AdminResetError.network;
    }
  }

  /// Same rule as the server: ≥ 8 characters, letters and digits.
  static bool isStrongPassword(String p) =>
      p.length >= 8 &&
      RegExp(r'[A-Za-z]').hasMatch(p) &&
      RegExp(r'\d').hasMatch(p);
}

/// Shows [AdminLoginPage] until an admin is signed in, then [builder].
/// Call [AdminAuth.restoreSession] before `runApp` so a refresh skips login.
class AdminAuthGate extends StatelessWidget {
  const AdminAuthGate({super.key, required this.builder});

  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AdminAccount?>(
      valueListenable: AdminAuth.current,
      builder: (context, account, _) {
        if (account == null) return const _AuthShell(child: AdminLoginPage());
        // Keyed by email so switching account rebuilds the whole app.
        return KeyedSubtree(key: ValueKey(account.email), child: builder(context));
      },
    );
  }
}

class _AuthShell extends StatelessWidget {
  const _AuthShell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // ScreenUtilInit so shared widgets that use .sp (CircleProgress) work on
    // the login screen too — BayanatzApp's own ScreenUtilInit isn't built yet.
    return ScreenUtilInit(
      designSize: const Size(1366, 768),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, __) => MaterialApp(
      title: 'Bayanatz Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: ColorPick.primary),
        scaffoldBackgroundColor: ColorPick.background,
        textTheme: GoogleFonts.cairoTextTheme(),
        useMaterial3: true,
      ),
      home: child,
      ),
    );
  }
}
