import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:web_app_admin/core/constant/color.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../features/main/presentation/controller/main_cubit.dart';
import '../../features/main/presentation/controller/main_state.dart';
import '../../features/inquire/presentation/ui/pages/inquiry_main.dart';
import '../../features/job/presentation/ui/pages/application_main.dart';
import '../auth/admin_auth.dart';
import '../theme/app_wight.dart';
import '../theme/appcolors.dart';
// StyleText resolves the admin-selected English/Arabic font at runtime,
// so navbar labels follow the CMS font choice instead of a hardcoded Cairo.
import '../theme/new_theme.dart';

class _BP {
  static const double mobile = 600;
  static const double tablet = 1024;
}

Color _navbarBgFromState(MainCmsState state) {
  final String hex = switch (state) {
    MainCmsLoaded(:final data) => data.branding.headerFooterColor,
    MainCmsSaved(:final data)  => data.branding.headerFooterColor,
    _                          => '',
  };
  return _hexColor(hex, AppColors.white);
}

Color _hexColor(String hex, Color fallback) {
  try {
    final clean = hex.replaceAll('#', '');
    if (clean.length == 6) return Color(int.parse('FF$clean', radix: 16));
  } catch (_) {}
  return fallback;
}

// BUG-05: every top-level section now has its own URL. The navbar used to
// swap the body with Navigator.pushReplacement(MaterialPageRoute), so the
// address bar never changed, F5 always landed on Home and the browser Back
// button left the app. Navigating with go_router paths fixes all three.
class AdminRoutes {
  static const String home         = '/';
  static const String jobListing   = '/jobs';
  static const String applications = '/applications';
  static const String inquiries    = '/inquiries';
  static const String webPage      = '/admin/dashboard';
}

void _goTo(BuildContext context, String location) {
  // BUG-101: detail pages (Job Post Details, Applicant details …) are pushed
  // on top of their section with Navigator.push. go('/jobs') while already
  // on /jobs changed nothing, so "Job Listing" in the menu did nothing.
  // Close every page that was pushed on top first, then go.
  final router = GoRouter.of(context);
  Navigator.of(context, rootNavigator: true)
      .popUntil((route) => route.settings is Page);
  router.go(location);
}

class _AdminNavItem {
  final String  label;
  final String  route;
  final Widget? page;
  const _AdminNavItem({required this.label, required this.route, this.page});
}

class AppAdminNavbar extends StatelessWidget {
  final String  activeLabel;
  final Widget  homePage;
  final Widget  webPage;
  final Widget  jobListingPage;
  final bool    showOnlyWebPage;

  const AppAdminNavbar({
    super.key,
    required this.activeLabel,
    required this.homePage,
    required this.webPage,
    required this.jobListingPage,
    this.showOnlyWebPage = false,
  });

  List<_AdminNavItem> get _navItems => [
    _AdminNavItem(label: 'Home',         route: AdminRoutes.home,         page: homePage),
    _AdminNavItem(label: 'Job Listing',  route: AdminRoutes.jobListing,   page: jobListingPage),
    _AdminNavItem(label: 'Applications', route: AdminRoutes.applications, page: const ApplicationMainPage()),
    // BUG-40: "Inquires" is a verb — the section is "Inquiries".
    _AdminNavItem(label: 'Inquiries',    route: AdminRoutes.inquiries,    page: const InquiryMainPage()),
  ];

  // BUG-23 / BUG-40: some pages passed 'web page' (lower case) or the old
  // 'Inquires' spelling, so nothing was highlighted. Normalise here.
  String get _normalisedActive {
    final l = activeLabel.trim().toLowerCase();
    if (l == 'web page')                      return 'Web Page';
    if (l == 'inquires' || l == 'inquiries')  return 'Inquiries';
    if (l == 'job listing')                   return 'Job Listing';
    if (l == 'applications')                  return 'Applications';
    if (l == 'home')                          return 'Home';
    return activeLabel;
  }

  @override
  Widget build(BuildContext context) {
    final String activeLabel = _normalisedActive;
    return BlocBuilder<MainCmsCubit, MainCmsState>(
      builder: (context, cmsState) {
        // BUG-50: the admin navbar always uses the ADMIN theme colour. It used
        // to take the public site's CMS primary colour (green), which leaked
        // into the tablet/mobile selected state.
        final Color  primary  = ColorPick.primary;
        final Color  navbarBg = _navbarBgFromState(cmsState);
        final double w        = MediaQuery.of(context).size.width;

        if (w >= _BP.tablet) {
          return _AdminNavbarDesktop(
            activeLabel:     activeLabel,
            navItems:        _navItems,
            primary:         primary,
            navbarBg:        navbarBg,
            webPage:         webPage,
            showOnlyWebPage: showOnlyWebPage,
          );
        }
        if (w >= _BP.mobile) {
          return _AdminNavbarTablet(
            activeLabel:     activeLabel,
            navItems:        _navItems,
            primary:         primary,
            navbarBg:        navbarBg,
            webPage:         webPage,
            showOnlyWebPage: showOnlyWebPage,
          );
        }
        return _AdminNavbarMobile(
          activeLabel:     activeLabel,
          navItems:        _navItems,
          primary:         primary,
          navbarBg:        navbarBg,
          webPage:         webPage,
          showOnlyWebPage: showOnlyWebPage,
        );
      },
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  DESKTOP
// ═════════════════════════════════════════════════════════════════════════════

class _AdminNavbarDesktop extends StatelessWidget {
  final String               activeLabel;
  final List<_AdminNavItem>  navItems;
  final Color                primary;
  final Color                navbarBg;
  final Widget               webPage;
  final bool                 showOnlyWebPage;

  const _AdminNavbarDesktop({
    required this.activeLabel,
    required this.navItems,
    required this.primary,
    required this.navbarBg,
    required this.webPage,
    required this.showOnlyWebPage,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width:   1000.w,
        margin:  EdgeInsets.symmetric(vertical: 16.h),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color:        ColorPick.white,
          borderRadius: BorderRadius.circular(4.r),
        ),
        child: Row(
          children: [
            _AdminLogo(
              onTap: () => _goTo(context, AdminRoutes.home),
            ),
            SizedBox(width: 250.w),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!showOnlyWebPage)
                  ...navItems.map((item) => _AdminNavLink(
                    label:       item.label,
                    route:       item.route,
                    activeLabel: activeLabel,
                    primary:     ColorPick.white,
                  )),
                // BUG-150: no extra 12.w — "Web Page" sat 54 px from
                // "Inquiries" while the other items are ~44 px apart.
                _WebPageButton(
                  primary:  ColorPick.primary,
                  isActive: activeLabel == 'Web Page',
                  onTap:    () => _goTo(context, AdminRoutes.webPage),
                ),
              ],
            ),
            const Spacer(),
            const _SignOutButton(), // BUG-01
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  TABLET
// ═════════════════════════════════════════════════════════════════════════════

class _AdminNavbarTablet extends StatelessWidget {
  final String               activeLabel;
  final List<_AdminNavItem>  navItems;
  final Color                primary;
  final Color                navbarBg;
  final Widget               webPage;
  final bool                 showOnlyWebPage;

  const _AdminNavbarTablet({
    required this.activeLabel,
    required this.navItems,
    required this.primary,
    required this.navbarBg,
    required this.webPage,
    required this.showOnlyWebPage,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        decoration: BoxDecoration(
          color:        navbarBg,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          children: [
            _AdminLogo(
              onTap: () => _goTo(context, AdminRoutes.home),
            ),
            SizedBox(width: 16.w),
            // BUG-150: at 820 px "Web Page" was pushed to the far right (324 px
            // gap) next to Sign out. It now follows the other menu items.
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (!showOnlyWebPage)
                      ...navItems.map((item) => _AdminNavLink(
                        label:       item.label,
                        route:       item.route,
                        activeLabel: activeLabel,
                        primary:     primary,
                        compact:     true,
                      )),
                    _WebPageButton(
                      primary:  primary,
                      compact:  true,
                      isActive: activeLabel == 'Web Page',
                      onTap:    () => _goTo(context, AdminRoutes.webPage),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 12.w),
            const _SignOutButton(compact: true), // BUG-01
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  MOBILE
// ═════════════════════════════════════════════════════════════════════════════

class _AdminNavbarMobile extends StatelessWidget {
  final String               activeLabel;
  final List<_AdminNavItem>  navItems;
  final Color                primary;
  final Color                navbarBg;
  final Widget               webPage;
  final bool                 showOnlyWebPage;

  const _AdminNavbarMobile({
    required this.activeLabel,
    required this.navItems,
    required this.primary,
    required this.navbarBg,
    required this.webPage,
    required this.showOnlyWebPage,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color:        navbarBg,
          borderRadius: BorderRadius.circular(6.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _AdminLogo(
              onTap: () => _goTo(context, AdminRoutes.home),
            ),
            if (!showOnlyWebPage)
              GestureDetector(
                onTap: () => _openDrawer(context),
                child: Container(
                  width:  36.w,
                  height: 36.w,
                  decoration: BoxDecoration(
                    color:        primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(Icons.menu_rounded, color: primary, size: 20.sp),
                ),
              )
            else
              _WebPageButton(
                primary:  primary,
                compact:  true,
                isActive: activeLabel == 'Web Page',
                onTap:    () => _goTo(context, AdminRoutes.webPage),
              ),
          ],
        ),
      ),
    );
  }

  void _openDrawer(BuildContext context) {
    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        opaque:             false,
        barrierDismissible: true,
        barrierColor:       Colors.transparent,
        pageBuilder: (ctx, anim, _) => _AdminMobileDrawer(
          activeLabel: activeLabel,
          navItems:    navItems,
          primary:     primary,
          navbarBg:    navbarBg,
          webPage:     webPage,
        ),
        transitionsBuilder: (ctx, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  MOBILE DRAWER
// ═════════════════════════════════════════════════════════════════════════════

class _AdminMobileDrawer extends StatelessWidget {
  final String               activeLabel;
  final List<_AdminNavItem>  navItems;
  final Color                primary;
  final Color                navbarBg;
  final Widget               webPage;

  const _AdminMobileDrawer({
    required this.activeLabel,
    required this.navItems,
    required this.primary,
    required this.navbarBg,
    required this.webPage,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F5),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: navbarBg,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _AdminLogo(
                    rawSize: true,
                    onTap: () {
                      final router = GoRouter.of(context);
                      Navigator.of(context).pop();
                      router.go(AdminRoutes.home);
                    },
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width:  36.w,
                      height: 36.w,
                      decoration: BoxDecoration(
                        color:        primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(Icons.close_rounded, color: primary, size: 20.sp),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                children: [
                  ...navItems.map((item) {
                    final bool isActive  = activeLabel == item.label;
                    return GestureDetector(
                      onTap: () {
                        final router = GoRouter.of(context);
                        Navigator.of(context).pop();
                        router.go(item.route);
                      },
                      child: Opacity(
                        opacity: 1.0,
                        child: Container(
                          width:   double.infinity,
                          margin:  EdgeInsets.only(bottom: 6.h),
                          padding: EdgeInsets.symmetric(
                              vertical: 12.h, horizontal: 16.w),
                          decoration: BoxDecoration(
                            color: isActive ? primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Text(
                            item.label,
                            style: StyleText.fontSize14Weight400.copyWith(
                              fontSize:   14.sp,
                              fontWeight: isActive
                                  ? AppFontWeights.semiBold
                                  : AppFontWeights.regular,
                              color: isActive ? Colors.white : AppColors.text,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  SizedBox(height: 12.h),
                  GestureDetector(
                    onTap: () {
                      final router = GoRouter.of(context);
                      Navigator.of(context).pop();
                      router.go(AdminRoutes.webPage);
                    },
                    child: Container(
                      width:   double.infinity,
                      padding: EdgeInsets.symmetric(
                          vertical: 13.h, horizontal: 16.w),
                      decoration: BoxDecoration(
                        color: activeLabel == 'Web Page'
                            ? primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10.r),
                        border: activeLabel == 'Web Page'
                            ? null
                            : Border.all(color: primary),
                      ),
                      child: Text(
                        'Web Page',
                        textAlign: TextAlign.center,
                        style: StyleText.fontSize14Weight600.copyWith(
                          fontSize:   14.sp,
                          fontWeight: AppFontWeights.semiBold,
                          color: activeLabel == 'Web Page'
                              ? Colors.white
                              : primary,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  // BUG-01: sign out
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      AdminAuth.signOut();
                    },
                    icon:  Icon(Icons.logout_rounded, color: primary, size: 18.sp),
                    label: Text('Sign out',
                        style: StyleText.fontSize14Weight500.copyWith(color: primary)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  LOGO
// ═════════════════════════════════════════════════════════════════════════════

class _AdminLogo extends StatelessWidget {
  final bool         rawSize;
  final VoidCallback onTap;

  const _AdminLogo({this.rawSize = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final double sz = rawSize ? 40.w : 40.w;

    // 29/9/2026 — the admin navbar always shows the new transparent logo
    // (same as the login screen), not the website's CMS logo.
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Image.asset(
          'assets/images/login/logo.png',
          width: sz,
          height: sz,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  NAV LINK
// ═════════════════════════════════════════════════════════════════════════════

class _AdminNavLink extends StatefulWidget {
  final String  label;
  final String  route;
  final String  activeLabel;
  final Color   primary;
  final bool    compact;

  const _AdminNavLink({
    required this.label,
    required this.route,
    required this.activeLabel,
    required this.primary,
    this.compact = false,
  });

  @override
  State<_AdminNavLink> createState() => _AdminNavLinkState();
}

class _AdminNavLinkState extends State<_AdminNavLink> {
  bool _hovered = false;

  bool get _isActive  => widget.activeLabel == widget.label;
  bool get _isEnabled => true;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _goTo(context, widget.route),
      child: Opacity(
        opacity: _isEnabled ? 1.0 : 0.45,
        child: Container(
          margin: EdgeInsets.symmetric(
              horizontal: widget.compact ? 2.w : 4.w),
          padding: EdgeInsets.symmetric(
            horizontal: widget.compact ? 8.w  : 16.w,
            vertical:   widget.compact ? 6.h  : 5.h,
          ),
          decoration: BoxDecoration(
            color: _isActive
                ? ColorPick.primary
                : (_hovered
                ? widget.primary.withValues(alpha: 0.08)
                : Colors.transparent),
            borderRadius: BorderRadius.circular(4.r),
          ),
          child: Text(
            widget.label,
            // Same style as AdminSubNavBar items
            style: StyleText.fontSize14Weight500.copyWith(
              fontSize: widget.compact ? 11.sp : null,
              color: _isActive
                  ? Colors.white
                  : (_hovered ? widget.primary : const Color(0xFF333333)),
            ),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  WEB PAGE BUTTON
// ═════════════════════════════════════════════════════════════════════════════

class _WebPageButton extends StatefulWidget {
  final Color        primary;
  final bool         compact;
  final bool         isActive;
  final VoidCallback onTap;

  const _WebPageButton({
    required this.primary,
    required this.onTap,
    this.compact  = false,
    this.isActive = false,
  });

  @override
  State<_WebPageButton> createState() => _WebPageButtonState();
}

class _WebPageButtonState extends State<_WebPageButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(
          horizontal: widget.compact ? 14.w : 16.w,
          vertical:   widget.compact ? 7.h  : 5.h,
        ),
        decoration: BoxDecoration(
          color: widget.isActive
              ? widget.primary
              : (_hovered
              ? widget.primary.withValues(alpha: 0.08)
              : Colors.transparent),
          borderRadius: BorderRadius.circular(4.r),
        ),
        child: Text(
          'Web Page',
          // Same style as AdminSubNavBar items
          style: StyleText.fontSize14Weight500.copyWith(
            fontSize: widget.compact ? 11.sp : null,
            color: widget.isActive
                ? Colors.white
                : (_hovered ? widget.primary : const Color(0xFF333333)),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  SIGN OUT (BUG-01)
// ═════════════════════════════════════════════════════════════════════════════

class _SignOutButton extends StatelessWidget {
  final bool compact;
  const _SignOutButton({this.compact = false});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip:   'Sign out',
      onPressed: AdminAuth.signOut,
      icon: Icon(
        Icons.logout_rounded,
        size:  compact ? 18.sp : 20.sp,
        color: const Color(0xFF333333),
      ),
    );
  }
}
