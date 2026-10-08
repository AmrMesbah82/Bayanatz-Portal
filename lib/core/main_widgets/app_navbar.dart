// ******************* FILE INFO *******************
// File Name: app_navbar.dart
// UPDATED: Navbar background now reads from model.branding.headerFooterColor ✅
//          Nav items are driven by HomeCmsCubit (navButtons from CMS model).
//          Items with status=false are filtered out and never rendered.
//          Labels come from the model's BiText (en/ar) instead of hardcoded
//          localisation strings, so CMS name edits are reflected immediately.
//          onItemTap callback preserved for admin/dashboard override.
//          ✅ Logo: nothing is shown until the real URL arrives from Firebase.
//             No static asset placeholder flicker.
//
//          Design sizes (ScreenUtil):
//          Desktop (≥1366) → 1366×768, Tablet (768–1365) → 1024×768,
//          Mobile  (<768)  → 375×812
//          Primary color driven by HomeCmsCubit → HomePageModel.branding.primaryColor
//          Navbar background driven by HomeCmsCubit → HomePageModel.branding.headerFooterColor

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:web_app_admin/core/widget/network_image_view.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../features/home/data/models/home_model.dart';
import '../../features/home/presentation/controller/home_cubit.dart';
import '../../features/home/presentation/controller/home_state.dart';
import '../../features/main/presentation/controller/main_cubit.dart';
import '../../features/main/presentation/controller/main_state.dart';
import '../../features/home/presentation/controller/lang_state.dart';
import '../theme/app_theme.dart';
import '../theme/app_wight.dart';
import '../theme/appcolors.dart';

class _WebColors {
  static const Color primary        = Colors.transparent;
  static const Color cardLightGreen = Color(0xFFE8F5EE);
  static const Color drawerBg       = Color(0xFFF5F9F5);
}

class _BP {
  static const double mobile = 600;
  static const double tablet = 1024;
}

// ── SVG asset map — keyed by route ────────────────────────────────────────────
const Map<String, String> _kSvgMap = {
  '/':         'assets/drawer/home_drawer.svg',
  '/services': 'assets/drawer/services_drawer.svg',
  '/about':    'assets/drawer/about_us_drawer.svg',
  '/contact':  'assets/drawer/contact_us_drawer.svg',
  '/careers':  'assets/drawer/career_drawer.svg',
  '/jobs':     'assets/drawer/career_drawer.svg',
};

// ── Extract primary color from CMS state ─────────────────────────────────────
Color _primaryFromState(MainCmsState state) {
  final String hex = switch (state) {
    MainCmsLoaded(:final data) => data.branding.primaryColor,
    MainCmsSaved(:final data)  => data.branding.primaryColor,
    _                          => '',
  };
  return _hexColor(hex, _WebColors.primary);
}

// ✅ Extract navbar background color from CMS state (headerFooterColor)
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

Color _lightTint(Color primary) => primary.withValues(alpha: 0.12);

// ── CMS-driven nav items, filtered by status ──────────────────────────────────
List<({String label, String route, String svgAsset})> _getVisibleNavItems(
    BuildContext context, String languageCode, HomeCmsState cmsState) {
  // Drive the navbar from the admin-configured nav buttons so name, order
  // and visibility (status) edits show up in the preview exactly like on
  // the live website. Kept in sync with website_app.
  // Nav labels are stored in mainPage/main (edited on the Main page) —
  // prefer them; fall back to the HOME doc, then to defaults.
  List<NavButtonModel> navButtons = const <NavButtonModel>[];
  try {
    navButtons = switch (context.read<MainCmsCubit>().state) {
      MainCmsLoaded(:final data) => data.navButtons,
      MainCmsSaved(:final data)  => data.navButtons,
      _                          => const <NavButtonModel>[],
    };
  } catch (_) {}
  if (navButtons.isEmpty) {
    navButtons = switch (cmsState) {
      HomeCmsLoaded(:final data) => data.navButtons,
      HomeCmsSaved(:final data)  => data.navButtons,
      _                          => const <NavButtonModel>[],
    };
  }
  if (navButtons.isEmpty) {
    navButtons = HomePageModel.defaultModel.navButtons;
  }

  // Defensive: dedupe by route (keep the FIRST occurrence = admin order).
  final seenRoutes = <String>{};
  navButtons = navButtons
      .where((b) => b.route.isNotEmpty && seenRoutes.add(b.route))
      .toList();

  final bool isAr = languageCode == 'ar';

  return navButtons
      .where((btn) => btn.status)
      .where((btn) => btn.route.isNotEmpty)
      .map((btn) => (
  label: isAr
      ? (btn.name.ar.isNotEmpty ? btn.name.ar : btn.name.en)
      : (btn.name.en.isNotEmpty ? btn.name.en : btn.name.ar),
  route:    btn.route,
  svgAsset: _kSvgMap[btn.route] ?? 'assets/drawer/home_drawer.svg',
  ))
      .toList();
}

// ─────────────────────────────────────────────────────────────────────────────
// AppNavbar — entry point
// ─────────────────────────────────────────────────────────────────────────────

class AppNavbar extends StatelessWidget {
  final String currentRoute;

  /// Optional callback invoked when a nav item is tapped.
  /// Receives the route string of the tapped item (e.g. '/careers').
  /// When null the navbar falls back to `context.go(route)`.
  final void Function(String route)? onItemTap;

  const AppNavbar({
    super.key,
    required this.currentRoute,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MainCmsCubit, MainCmsState>(
      builder: (context, mainState) {
        final Color primary  = _primaryFromState(mainState);
        final Color navbarBg = _navbarBgFromState(mainState);
        return BlocBuilder<HomeCmsCubit, HomeCmsState>(
          builder: (context, cmsState) {
        final double w       = MediaQuery.of(context).size.width;

        if (w >= _BP.tablet)
          return _NavbarDesktop(
            currentRoute: currentRoute,
            primary:      primary,
            navbarBg:     navbarBg,
            cmsState:     cmsState,
            onItemTap:    onItemTap,
          );
        if (w >= _BP.mobile)
          return _NavbarTablet(
            currentRoute: currentRoute,
            primary:      primary,
            navbarBg:     navbarBg,
            cmsState:     cmsState,
            onItemTap:    onItemTap,
          );
        return _NavbarMobile(
          currentRoute: currentRoute,
          primary:      primary,
          navbarBg:     navbarBg,
          cmsState:     cmsState,
          onItemTap:    onItemTap,
        );
          },
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// DESKTOP  (≥ 1024px) — design size 1366×768
// ═══════════════════════════════════════════════════════════════════════════════

class _NavbarDesktop extends StatelessWidget {
  final String                       currentRoute;
  final Color                        primary;
  final Color                        navbarBg;
  final HomeCmsState                 cmsState;
  final void Function(String route)? onItemTap;

  const _NavbarDesktop({
    required this.currentRoute,
    required this.primary,
    required this.navbarBg,
    required this.cmsState,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageCubit, LanguageState>(
      builder: (context, langState) {
        final navItems = _getVisibleNavItems(context, langState.locale.languageCode, cmsState);
        final isRtl    = langState.isArabic;

        return Directionality(
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
            decoration: BoxDecoration(
              color:        navbarBg,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const _BayanatzLogo(),
                Row(
                  children: navItems
                      .map((e) => _NavItem(
                    key:          ValueKey('${e.route}_${langState.locale.languageCode}'),
                    label:        e.label,
                    route:        e.route,
                    currentRoute: currentRoute,
                    primary:      primary,
                    onItemTap:    onItemTap,
                  ))
                      .toList(),
                ),
                _LanguageToggle(primary: primary),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TABLET  (600 – 1023px) — design size 1024×768
// ═══════════════════════════════════════════════════════════════════════════════

class _NavbarTablet extends StatelessWidget {
  final String                       currentRoute;
  final Color                        primary;
  final Color                        navbarBg;
  final HomeCmsState                 cmsState;
  final void Function(String route)? onItemTap;

  const _NavbarTablet({
    required this.currentRoute,
    required this.primary,
    required this.navbarBg,
    required this.cmsState,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageCubit, LanguageState>(
      builder: (context, langState) {
        final navItems = _getVisibleNavItems(context, langState.locale.languageCode, cmsState);
        final isRtl    = langState.isArabic;

        return Directionality(
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              decoration: BoxDecoration(
                color:        navbarBg,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const _BayanatzLogo(),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: navItems
                          .map((e) => _NavItem(
                        key:          ValueKey('${e.route}_${langState.locale.languageCode}'),
                        label:        e.label,
                        route:        e.route,
                        currentRoute: currentRoute,
                        primary:      primary,
                        compact:      true,
                        onItemTap:    onItemTap,
                      ))
                          .toList(),
                    ),
                  ),
                  _LanguageToggle(primary: primary),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MOBILE  (< 600px) — design size 375×812
// ═══════════════════════════════════════════════════════════════════════════════

class _NavbarMobile extends StatelessWidget {
  final String                       currentRoute;
  final Color                        primary;
  final Color                        navbarBg;
  final HomeCmsState                 cmsState;
  final void Function(String route)? onItemTap;

  const _NavbarMobile({
    required this.currentRoute,
    required this.primary,
    required this.navbarBg,
    required this.cmsState,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageCubit, LanguageState>(
      builder: (context, langState) {
        final isRtl = langState.isArabic;

        return Directionality(
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Container(
              decoration: BoxDecoration(
                color:        navbarBg,
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 0.w, vertical: 8.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const _BayanatzLogo(rawSize: true),
                    GestureDetector(
                      onTap: () => _openDrawer(context),
                      child: Container(
                        width:  36.w,
                        height: 36.w,
                        decoration:
                        BoxDecoration(borderRadius: BorderRadius.circular(8.r)),
                        child: Icon(Icons.menu_rounded,
                            color: AppColors.textButton, size: 20.sp),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _openDrawer(BuildContext context) {
    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        opaque:             false,
        barrierDismissible: true,
        barrierColor:       Colors.transparent,
        pageBuilder: (ctx, anim, _) => _FullScreenDrawer(
          currentRoute: currentRoute,
          primary:      primary,
          navbarBg:     navbarBg,
          cmsState:     cmsState,
          onItemTap:    onItemTap,
        ),
        transitionsBuilder: (ctx, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }
}

// ─── Full-Screen Drawer (mobile) ──────────────────────────────────────────────

class _FullScreenDrawer extends StatelessWidget {
  final String                       currentRoute;
  final Color                        primary;
  final Color                        navbarBg;
  final HomeCmsState                 cmsState;
  final void Function(String route)? onItemTap;

  const _FullScreenDrawer({
    required this.currentRoute,
    required this.primary,
    required this.navbarBg,
    required this.cmsState,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageCubit, LanguageState>(
      builder: (context, langState) {
        final navItems    = _getVisibleNavItems(context, langState.locale.languageCode, cmsState);
        final isRtl       = langState.isArabic;
        final Color lightTint = _lightTint(primary);

        return Directionality(
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: _WebColors.drawerBg,
            body: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    color: navbarBg,
                    padding: EdgeInsets.symmetric(
                        horizontal: 16.w, vertical: 10.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const _BayanatzLogo(rawSize: true),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width:  36.w,
                            height: 36.w,
                            decoration: BoxDecoration(
                              color:        lightTint,
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Icon(Icons.menu_rounded,
                                color: primary, size: 20.sp),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 10.h),

                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [_LanguageToggle(primary: primary)],
                    ),
                  ),

                  SizedBox(height: 10.h),

                  Expanded(
                    child: ListView(
                      key:     ValueKey(langState.locale.languageCode),
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      children: navItems.map((e) {
                        final bool isActive = currentRoute == e.route;
                        return GestureDetector(
                          onTap: () {
                            Navigator.of(context).pop();
                            if (onItemTap != null) {
                              onItemTap!(e.route);
                            } else {
                              context.go(e.route);
                            }
                          },
                          child: Container(
                            key: ValueKey(
                                '${e.route}_${langState.locale.languageCode}'),
                            width:   double.infinity,
                            margin:  EdgeInsets.only(bottom: 6.h),
                            padding: EdgeInsets.symmetric(
                                vertical: 12.h, horizontal: 16.w),
                            decoration: BoxDecoration(
                              color: isActive ? primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Row(
                              children: [
                                SvgPicture.asset(
                                  e.svgAsset,
                                  width:  20.w,
                                  height: 20.w,
                                  colorFilter: ColorFilter.mode(
                                    isActive ? Colors.white : AppColors.textButton,
                                    BlendMode.srcIn,
                                  ),
                                ),
                                SizedBox(width: 14.w),
                                Text(
                                  e.label,
                                  textDirection: isRtl
                                      ? TextDirection.rtl
                                      : TextDirection.ltr,
                                  style: GoogleFonts.cairo(
                                    fontSize:   14.sp,
                                    fontWeight: isActive
                                        ? AppFontWeights.semiBold
                                        : AppFontWeights.regular,
                                    color: isActive ? Colors.white : AppColors.text,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

// ✅ _BayanatzLogo: shows nothing (transparent SizedBox) while logoUrl is empty.
//    Once Firebase returns the URL, it renders the SVG.
//    No static asset placeholder is ever shown.
class _BayanatzLogo extends StatelessWidget {
  final bool rawSize;
  const _BayanatzLogo({this.rawSize = false});

  @override
  Widget build(BuildContext context) {
    final double sz = rawSize ? 40.w : 36.w;

    return BlocBuilder<MainCmsCubit, MainCmsState>(
      builder: (context, state) {
        final String logoUrl = switch (state) {
          MainCmsLoaded(:final data) => data.branding.logoUrl,
          MainCmsSaved(:final data)  => data.branding.logoUrl,
          _                          => '',
        };

        // ✅ Nothing shown until we have a real URL — no static flicker.
        if (logoUrl.isEmpty) {
          return SizedBox(width: sz, height: sz);
        }

        return GestureDetector(
          onTap: () => context.go('/'),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              // ✅ Network logo rendered via HTML <img> (HtmlElementView).
              child: NetworkImageView(
                url:    logoUrl,
                width:  sz,
                height: sz,
                fit:    BoxFit.fill,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Nav Item ─────────────────────────────────────────────────────────────────

class _NavItem extends StatefulWidget {
  final String                       label;
  final String                       route;
  final String                       currentRoute;
  final Color                        primary;
  final bool                         compact;
  final void Function(String route)? onItemTap;

  const _NavItem({
    super.key,
    required this.label,
    required this.route,
    required this.currentRoute,
    required this.primary,
    this.compact   = false,
    this.onItemTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hovered = false;
  bool get _isActive => widget.currentRoute == widget.route;

  @override
  Widget build(BuildContext context) {
    final Color hoverBg = _lightTint(widget.primary);

    return BlocBuilder<LanguageCubit, LanguageState>(
      builder: (context, langState) {
        return MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit:  (_) => setState(() => _hovered = false),
          cursor:  SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              if (widget.onItemTap != null) {
                widget.onItemTap!(widget.route);
              } else {
                context.go(widget.route);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.symmetric(
                  horizontal: widget.compact ? 2.w : 3.w),
              padding: EdgeInsets.symmetric(
                horizontal: widget.compact ? 8.w  : 12.w,
                vertical:   widget.compact ? 6.h  : 7.h,
              ),
              decoration: BoxDecoration(
                color: _isActive
                    ? widget.primary
                    : (_hovered ? hoverBg : hoverBg.withValues(alpha: 0)),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                widget.label,
                textDirection: langState.isArabic
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                style: GoogleFonts.cairo(
                  fontSize:   widget.compact ? 11.sp : 13.sp,
                  fontWeight: _isActive
                      ? AppFontWeights.medium
                      : AppFontWeights.regular,
                  color: _isActive
                      ? Colors.white
                      : (_hovered ? widget.primary : AppColors.text),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Language Toggle ──────────────────────────────────────────────────────────

class _LanguageToggle extends StatelessWidget {
  final Color primary;
  const _LanguageToggle({required this.primary});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageCubit, LanguageState>(
      builder: (context, state) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6.r),
            color:        AppColors.secondaryText.withValues(alpha: .1),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize:      MainAxisSize.max,
              children: [
                _LangBtn(
                  label:   'AR',
                  active:  state.isArabic,
                  primary: primary,
                  onTap:   () =>
                      context.read<LanguageCubit>().setLanguage('ar'),
                ),
                _LangBtn(
                  label:   'EN',
                  active:  state.isEnglish,
                  primary: primary,
                  onTap:   () =>
                      context.read<LanguageCubit>().setLanguage('en'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LangBtn extends StatelessWidget {
  final String       label;
  final bool         active;
  final Color        primary;
  final VoidCallback onTap;

  const _LangBtn({
    required this.label,
    required this.active,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
          decoration: BoxDecoration(
            color:        active ? primary : Colors.transparent,
            borderRadius: BorderRadius.circular(5.r),
          ),
          child: Text(
            label,
            style: GoogleFonts.cairo(
              fontSize:   11.sp,
              fontWeight: AppFontWeights.semiBold,
              color:      active ? Colors.white : AppColors.secondaryBlack,
            ),
          ),
        ),
      ),
    );
  }
}