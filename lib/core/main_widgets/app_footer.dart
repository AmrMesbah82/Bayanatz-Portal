// ******************* FILE INFO *******************
// File Name: app_footer.dart
// UPDATED: Footer background now reads from model.branding.headerFooterColor
// FIXED: _socialIcons / _socialIconsRaw now filter by l.visibility ✅
//        Toggling visibility OFF in admin hides the icon in the footer.
// Description: AppFooter driven by MainPageModel via MainCmsCubit.
// Created by: Amr Mesbah

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:web_app_admin/core/widget/network_image_view.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../features/home/data/models/home_model.dart' show NavButtonModel, HomePageModel;
import '../../features/home/presentation/controller/home_cubit.dart';
import '../../features/home/presentation/controller/home_state.dart';
import '../../features/main/data/models/main_model.dart';
import '../../features/main/presentation/controller/main_cubit.dart';
import '../../features/main/presentation/controller/main_state.dart';
import '../../features/home/presentation/controller/lang_state.dart';
import '../theme/app_wight.dart';
import '../theme/appcolors.dart';
import '../theme/new_theme.dart';



class _BP {
  static const double mobile = 768;
  static const double tablet = 1024;
}

const Color _kFallbackPrimary    = Color(0xFF008037);
const Color _kFallbackFooterBg   = Color(0xFFF5F5F5); // fallback if headerFooterColor is empty

List<FooterColumnModel> _syncedFooterColumns(
    MainPageModel model, List<NavButtonModel> navButtons) {
  final navByRoute = <String, NavButtonModel>{
    for (final btn in navButtons)
      if (btn.route.isNotEmpty) btn.route: btn,
  };
  final List<FooterColumnModel> result = [];
  for (final col in model.footerColumns) {
    final nav = col.route.isNotEmpty ? navByRoute[col.route] : null;
    if (nav != null) {
      if (!nav.status) continue;
      result.add(col.copyWith(title: nav.name));
    } else {
      result.add(col);
    }
  }
  return result;
}

String _bi(BiText b, bool isRtl) {
  final v = isRtl ? b.ar : b.en;
  return v.isNotEmpty ? v : b.en;
}

Color _hexColor(String hex, Color fallback) {
  try {
    final clean = hex.replaceAll('#', '');
    if (clean.length == 6) return Color(int.parse('FF$clean', radix: 16));
  } catch (_) {}
  return fallback;
}

String _staticCopyright(bool isRtl) {
  final year = DateTime.now().year.toString();
  return isRtl
      // BUG-49 / BUG-81: same text as the public site's footer.
      ? '© $year بيانات زي. جميع الحقوق محفوظة.'
      : '© $year Bayanatz. All rights reserved.';
}

class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MainCmsCubit, MainCmsState>(
      builder: (context, state) {
        final MainPageModel model = switch (state) {
          MainCmsLoaded(:final data) => data,
          MainCmsSaved(:final data)  => data,
          _                          => MainPageModel.defaultModel,
        };

        final Color primary    = _hexColor(model.branding.primaryColor,      _kFallbackPrimary);
        // ✅ Footer background from CMS branding
        final Color footerBg   = _hexColor(model.branding.headerFooterColor, _kFallbackFooterBg);

        return BlocBuilder<HomeCmsCubit, HomeCmsState>(
            builder: (context, homeState) {
        final List<NavButtonModel> navButtons = switch (homeState) {
          HomeCmsLoaded(:final data) => data.navButtons,
          HomeCmsSaved(:final data)  => data.navButtons,
          _                          => HomePageModel.defaultModel.navButtons,
        };
        final List<FooterColumnModel> columns =
            _syncedFooterColumns(model, navButtons);

        return BlocBuilder<LanguageCubit, LanguageState>(
          builder: (context, langState) {
            final bool isRtl = langState.isArabic;
            final double screenWidth = MediaQuery.of(context).size.width;

            Widget footer;
            if (screenWidth >= _BP.tablet) {
              footer = _FooterDesktop(
                model: model, columns: columns,
                primary: primary, footerBg: footerBg, isRtl: isRtl,
              );
            } else if (screenWidth >= _BP.mobile) {
              footer = _FooterDesktop(
                model: model, columns: columns,
                primary: primary, footerBg: footerBg, isRtl: isRtl,
              );
            } else {
              footer = _FooterMobile(
                model: model, columns: columns,
                primary: primary, footerBg: footerBg, isRtl: isRtl,
              );
            }

            return Directionality(
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              child: footer,
            );
          },
        );
            });
      },
    );
  }
}

// ─── DESKTOP ──────────────────────────────────────────────────────────────────

class _FooterDesktop extends StatelessWidget {
  final MainPageModel model;
  final List<FooterColumnModel> columns;
  final Color primary;
  final Color footerBg; // ✅ from branding.headerFooterColor
  final bool isRtl;

  const _FooterDesktop({
    required this.model,
    required this.columns,
    required this.primary,
    required this.footerBg,
    required this.isRtl,
  });

  @override
  Widget build(BuildContext context) {
    final double contentW = (248.w * 4) + (8.w * 3);
    final double hPad =
    ((MediaQuery.of(context).size.width - contentW) / 2)
        .clamp(16.0, double.infinity);

    return Container(
      padding: EdgeInsets.all(22.sp),
      decoration: BoxDecoration(
        color: footerBg, // ✅ CMS-driven color
        borderRadius: BorderRadiusDirectional.only(
          topStart: Radius.circular(24.r),
          topEnd:   Radius.circular(24.r),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LogoBox(logoUrl: model.branding.logoUrl, primary: primary, size: 50.sp),
              SizedBox(width: 32.w),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: columns
                      .map((col) => _FooterColumnWidget(
                    column:     col,
                    titleColor: AppColors.text,
                    primary:    primary,
                    isRtl:      isRtl,
                  ))
                      .toList(),
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          Divider(color: primary, thickness: 0.5),
          SizedBox(height: 14.h),
          Row(
            children: [
              const Expanded(flex: 2, child: SizedBox()),
              Expanded(
                flex: 3,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    ..._socialIcons(model.socialLinks, primary),
                    const Spacer(),
                    Text(
                      _staticCopyright(isRtl),
                      style: StyleText.fontSize14Weight400.copyWith(
                        color: AppColors.text,
                        fontWeight: FontWeight.w900,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── TABLET ───────────────────────────────────────────────────────────────────

class _FooterTablet extends StatelessWidget {
  final MainPageModel model;
  final List<FooterColumnModel> columns;
  final Color primary;
  final Color footerBg; // ✅ from branding.headerFooterColor
  final bool isRtl;

  const _FooterTablet({
    required this.model,
    required this.columns,
    required this.primary,
    required this.footerBg,
    required this.isRtl,
  });

  @override
  Widget build(BuildContext context) {
    final int mid  = (columns.length / 2).ceil();
    final row1     = columns.sublist(0, mid);
    final row2     = columns.sublist(mid);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Container(
        padding: EdgeInsets.all(20.sp),
        decoration: BoxDecoration(
          color: footerBg, // ✅ CMS-driven color
          borderRadius: BorderRadiusDirectional.only(
            topStart: Radius.circular(18.r),
            topEnd:   Radius.circular(18.r),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _LogoBox(logoUrl: model.branding.logoUrl, primary: primary, size: 32),
            SizedBox(height: 18.h),
            Wrap(
              spacing: 16.w, runSpacing: 16.h,
              children: row1
                  .map((col) => _FooterColumnWidget(
                column: col, titleColor: AppColors.text,
                primary: primary, isRtl: isRtl,
              ))
                  .toList(),
            ),
            if (row2.isNotEmpty) ...[
              SizedBox(height: 16.h),
              Wrap(
                spacing: 16.w, runSpacing: 16.h,
                children: row2
                    .map((col) => _FooterColumnWidget(
                  column: col, titleColor: AppColors.text,
                  primary: primary, isRtl: isRtl,
                ))
                    .toList(),
              ),
            ],
            SizedBox(height: 20.h),
            Divider(color: primary, thickness: 1),
            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: _socialIcons(model.socialLinks, primary, gap: 8)),
                Flexible(
                  child: Text(
                    _staticCopyright(isRtl),
                    textAlign: TextAlign.end,
                    style: GoogleFonts.cairo(
                      fontSize:   10.sp,
                      fontWeight: FontWeight.w400,
                      color:      AppColors.secondaryText,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── MOBILE ───────────────────────────────────────────────────────────────────

class _FooterMobile extends StatelessWidget {
  final MainPageModel model;
  final List<FooterColumnModel> columns;
  final Color primary;
  final Color footerBg; // ✅ from branding.headerFooterColor
  final bool isRtl;

  const _FooterMobile({
    required this.model,
    required this.columns,
    required this.primary,
    required this.footerBg,
    required this.isRtl,
  });

  @override
  Widget build(BuildContext context) {
    final String? firstLabel =
    (columns.isNotEmpty && columns.first.labels.isNotEmpty)
        ? _bi(columns.first.labels.first.label, isRtl)
        : null;
    final String? firstRoute =
    (columns.isNotEmpty &&
        columns.first.labels.isNotEmpty &&
        columns.first.labels.first.route.isNotEmpty)
        ? columns.first.labels.first.route
        : null;

    return Container(
      color: footerBg, // ✅ CMS-driven color
      padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              Expanded(child: Divider(color: primary.withValues(alpha: 0.5), thickness: 1)),
              SizedBox(width: 10.w),
              ..._socialIconsRaw(model.socialLinks, primary),
              SizedBox(width: 10.w),
              Expanded(child: Divider(color: primary.withValues(alpha: 0.5), thickness: 1)),
            ],
          ),
          SizedBox(height: 12.h),
          if (firstLabel != null)
            _FooterLink(label: firstLabel, route: firstRoute, primary: primary),
          SizedBox(height: 6.h),
          Text(
            _staticCopyright(isRtl),
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize:   10.sp,
              fontWeight: FontWeight.w400,
              color:      AppColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Footer Column ────────────────────────────────────────────────────────────

class _FooterColumnWidget extends StatefulWidget {
  final FooterColumnModel column;
  final Color titleColor;
  final Color primary;
  final bool isRtl;

  const _FooterColumnWidget({
    required this.column,
    required this.titleColor,
    required this.primary,
    required this.isRtl,
  });

  @override
  State<_FooterColumnWidget> createState() => _FooterColumnWidgetState();
}

class _FooterColumnWidgetState extends State<_FooterColumnWidget> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final String title = _bi(widget.column.title, widget.isRtl);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit:  (_) => setState(() => _hovered = false),
          cursor: widget.column.route.isNotEmpty
              ? SystemMouseCursors.click
              : MouseCursor.defer,
          child: GestureDetector(
            onTap: widget.column.route.isNotEmpty
                ? () => _navigateTo(context, widget.column.route)
                : null,
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 180),
              style: GoogleFonts.cairo(
                fontSize:   13.sp,
                fontWeight: _hovered ? FontWeight.w900 : AppFontWeights.semiBold,
                color: _hovered ? widget.primary : widget.titleColor,
              ),
              child: Text(title),
            ),
          ),
        ),
        SizedBox(height: 6.h),
        ...widget.column.labels.map((lbl) => _FooterLink(
          label:   _bi(lbl.label, widget.isRtl),
          route:   lbl.route.isNotEmpty ? lbl.route : widget.column.route,
          primary: widget.primary,
        )),
      ],
    );
  }
}

// ─── Footer Link ──────────────────────────────────────────────────────────────

class _FooterLink extends StatefulWidget {
  final String  label;
  final String? route;
  final Color   primary;

  const _FooterLink({
    required this.label,
    required this.primary,
    this.route,
  });

  @override
  State<_FooterLink> createState() => _FooterLinkState();
}

class _FooterLinkState extends State<_FooterLink> {
  bool _hovered = false;

  void _handleTap(BuildContext context) {
    final route = widget.route;
    if (route == null || route.isEmpty) return;
    final uri = Uri.tryParse(route);
    if (uri == null) { context.go(route); return; }
    final String path        = uri.path;
    final String queryString = uri.query;
    final currentPath        = GoRouterState.of(context).uri.path;
    if (queryString.isNotEmpty) {
      context.push('$path?$queryString');
    } else {
      if (currentPath == path) { context.push(path); } else { context.go(path); }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      cursor: widget.route != null ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(
        onTap: () => _handleTap(context),
        child: Text(
          widget.label,
          style: GoogleFonts.cairo(
            fontSize:        12.sp,
            fontWeight:      AppFontWeights.regular,
            height:          2.0,
            color:           _hovered ? widget.primary : AppColors.secondaryBlack,
            decoration:      _hovered ? TextDecoration.underline : null,
            decorationColor: widget.primary,
          ),
        ),
      ),
    );
  }
}

// ─── Logo box ─────────────────────────────────────────────────────────────────

class _LogoBox extends StatelessWidget {
  final String logoUrl;
  final Color  primary;
  final double size;

  const _LogoBox({
    required this.logoUrl,
    required this.primary,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width:  size.w,
      height: size.h,
      child: logoUrl.isNotEmpty
          ? NetworkImageView(
        url:     logoUrl,
        width:   size.w,
        height:  size.h,
        fit:     BoxFit.contain,
      )
          : Image.asset('assets/images/logo.jpg', fit: BoxFit.contain),
    );
  }
}

// ─── Social icon helpers ──────────────────────────────────────────────────────

/// ✅ filters by l.visibility — hidden icons won't appear in footer
List<Widget> _socialIcons(
    List<SocialLinkModel> links,
    Color borderColor, {
      double gap = 10,
    }) {
  return links
      .where((l) => l.visibility && (l.iconUrl.isNotEmpty || l.url.isNotEmpty))
      .map((l) => Padding(
    padding: EdgeInsetsDirectional.only(end: gap.w),
    child: _SocialIconWidget(link: l, borderColor: borderColor, size: 32),
  ))
      .toList();
}

/// ✅ same visibility filter for mobile
List<Widget> _socialIconsRaw(List<SocialLinkModel> links, Color borderColor) {
  return links
      .where((l) => l.visibility && (l.iconUrl.isNotEmpty || l.url.isNotEmpty))
      .expand((l) => [
    _SocialIconWidget(link: l, borderColor: borderColor, size: 32, raw: true),
    SizedBox(width: 8.w),
  ])
      .toList();
}

class _SocialIconWidget extends StatelessWidget {
  final SocialLinkModel link;
  final Color           borderColor;
  final double          size;
  final bool            raw;

  const _SocialIconWidget({
    required this.link,
    required this.borderColor,
    required this.size,
    this.raw = false,
  });

  double get _ic => raw ? size * 0.47 : (size * 0.47).w;

  @override
  Widget build(BuildContext context) {
    final Widget iconWidget = link.iconUrl.isNotEmpty
        ? NetworkImageView(
      url:    link.iconUrl,
      width:  20.w,
      height: 20.w,
      fit:    BoxFit.contain,
    )
        : Icon(Icons.link, size: _ic, color: borderColor);

    final box = Container(
      width:  40.w,
      height: 40.w,
      decoration: BoxDecoration(
        border:       Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(raw ? 8 : 8.r),
      ),
      child: Center(child: iconWidget),
    );

    return link.url.isNotEmpty
        ? GestureDetector(
      onTap: () async {
        String rawUrl = link.url.trim();
        if (!rawUrl.startsWith('http://') && !rawUrl.startsWith('https://')) {
          rawUrl = 'https://$rawUrl';
        }

        final uri = Uri.tryParse(rawUrl);
        if (uri == null || !uri.hasAuthority) return; // ✅ guard empty/invalid URLs

        final canLaunch = await canLaunchUrl(uri);
        if (!canLaunch) return;

        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication, // ✅ works reliably on web
          webOnlyWindowName: '_blank',
        );
      },
      child: MouseRegion(cursor: SystemMouseCursors.click, child: box),
    )
        : box;
  }
}

void _navigateTo(BuildContext context, String route) {
  final uri = Uri.tryParse(route);
  if (uri == null) { context.go(route); return; }
  if (uri.query.isNotEmpty) {
    context.push('${uri.path}?${uri.query}');
  } else {
    context.go(uri.path);
  }
}