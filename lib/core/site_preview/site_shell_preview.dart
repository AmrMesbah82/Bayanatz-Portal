// ******************* FILE INFO *******************
// File Name: site_shell_preview.dart
// Description: Admin-only device preview of the site shell (navbar + footer)
//              drawn with the admin's own AppNavbar / AppFooter copies.
//
// Created by: Amr Mesbah

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'site_preview_frame.dart';

// ── Admin-only copies of the site navbar / footer (no website_app link) ─────
import '../main_widgets/app_navbar.dart' as site_nav;
import '../main_widgets/app_footer.dart' as site_footer;

// ── Admin ────────────────────────────────────────────────────────────────────
import '../../features/home/data/models/home_model.dart';
import '../../features/home/presentation/controller/home_cubit.dart';
import '../../features/main/data/models/main_model.dart';
import '../widget/network_image_view.dart';
import '../../features/main/presentation/controller/main_cubit.dart';
import '../../features/main/presentation/controller/main_state.dart';

/// A single device viewport showing the site shell as visitors will see it.
///
/// Give it the viewport you want to simulate — the site picks its desktop /
/// tablet / mobile layout off MediaQuery width, exactly as it does in a real
/// browser:
///   Desktop 1366×768 · Tablet 1024×768 · Mobile 375×812
class SiteShellPreview extends StatelessWidget {
  const SiteShellPreview({
    super.key,
    required this.fakeWidth,
    required this.fakeHeight,
    required this.isRtl,
    this.model,
  });

  final double fakeWidth;
  final double fakeHeight;
  final bool   isRtl;

  /// The draft to render. Omit it and the live [MainCmsCubit] draft is used,
  /// so the preview tracks unsaved edits automatically.
  final MainPageModel? model;

  @override
  Widget build(BuildContext context) {
    final MainPageModel data = model ?? _draftMainModel(context);

    // BUG-15: this used a nested ScreenUtilInit, which re-configured the
    // global ScreenUtil and blew up the whole admin layout ("Mobile" preview
    // = giant zoom until reload). PreviewViewport simulates the device
    // without touching ScreenUtil.
    return PreviewViewport(
      width:  fakeWidth,
      height: fakeHeight,
      child: Directionality(
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: AbsorbPointer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Real site navbar — CMS colors, CMS nav items, CMS logo.
              site_nav.AppNavbar(
                currentRoute: '/',
                onItemTap: (_) {},
              ),

              // Page body. The Main document is the site SHELL (branding,
              // navbar, footer) — it owns no page content (BUG-23: the body
              // now says so instead of being an unexplained grey block).
              Expanded(
                child: ColoredBox(
                  color: _hexToColor(
                    data.branding.backgroundColor,
                    const Color(0xFFF5F5F5),
                  ),
                  // BUG-23: the body now shows the Home page content (title,
                  // short description and the visible section cards) so the
                  // preview is no longer an empty grey page.
                  child: _HomeBodyPreview(isRtl: isRtl, primaryHex: data.branding.primaryColor),
                ),
              ),

              // Real site footer — CMS columns, social links, colors.
              const site_footer.AppFooter(),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Draft accessor ────────────────────────────────────────────────────────────
/// The Main model currently being edited, whatever state the cubit is in.
/// Falls back to the cubit's in-memory model so the preview never goes blank
/// mid-save or after a transient error.
MainPageModel _draftMainModel(BuildContext context) {
  final MainCmsCubit cubit = context.watch<MainCmsCubit>();
  final MainCmsState state = cubit.state;

  if (state is MainCmsLoaded)     return state.data;
  if (state is MainCmsSaving)     return state.data;
  if (state is MainCmsSaved)      return state.data;
  if (state is MainCmsDraftSaved) return state.data;
  if (state is MainCmsError && state.lastData != null) return state.lastData!;
  return cubit.current;
}

// ── Hex helper ────────────────────────────────────────────────────────────────
Color _hexToColor(String hex, Color fallback) {
  final clean = hex.replaceAll('#', '');
  if (clean.length == 6) {
    final value = int.tryParse('FF$clean', radix: 16);
    if (value != null) return Color(value);
  }
  return fallback;
}

// ── BUG-23: Home content inside the Main preview ─────────────────────────────
class _HomeBodyPreview extends StatelessWidget {
  const _HomeBodyPreview({required this.isRtl, required this.primaryHex});

  final bool isRtl;
  final String primaryHex;

  @override
  Widget build(BuildContext context) {
    final home = context.watch<HomeCmsCubit>().current;
    final primary = _hexToColor(primaryHex, const Color(0xFF008037));
    String t(BiText b) => isRtl && b.ar.trim().isNotEmpty ? b.ar : b.en;
    final sections = home.sections.where((s) => s.visibility).toList();

    if (t(home.title).trim().isEmpty && sections.isEmpty) {
      return Center(
        child: Text(
          isRtl ? 'لا يوجد محتوى للصفحة الرئيسية بعد' : 'No Home page content yet',
          style: const TextStyle(fontSize: 16, color: Color(0xFF8A8A8A)),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            t(home.title),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 40, fontWeight: FontWeight.w800, color: primary),
          ),
          const SizedBox(height: 8),
          Text(
            t(home.shortDescription),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, color: Color(0xFF444444)),
          ),
          const SizedBox(height: 28),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: [
              for (final s in sections)
                Container(
                  width: 240,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          height: 130,
                          width: double.infinity,
                          child: s.imageUrl.isEmpty
                              ? const ColoredBox(color: Color(0xFFEDEDED))
                              : NetworkImageView(url: s.imageUrl, fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _hexToColor(s.textBoxColor, primary),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          t(s.description),
                          maxLines: 5,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, color: Colors.white, height: 1.4),
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
