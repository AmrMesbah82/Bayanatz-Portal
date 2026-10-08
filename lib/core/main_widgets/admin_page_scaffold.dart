// ******************* FILE INFO *******************
// File Name: admin_page_scaffold.dart
// Purpose: The standard shell for EVERY admin CMS page.
//
//          The two top bars — AppAdminNavbar and AdminSubNavBar — are pinned:
//          they stay put while only the page content scrolls underneath. Pages
//          used to put both bars inside their own SingleChildScrollView, so
//          they scrolled away with the content and you lost the navigation as
//          soon as you moved down a long form.
//
//          Structure:
//            Scaffold
//              Column
//                AppAdminNavbar        ← pinned
//                AdminSubNavBar        ← pinned (optional)
//                Expanded
//                  SingleChildScrollView   ← only this scrolls
//                    Center → SizedBox(contentWidth) → child
//
// Usage — replaces the whole Scaffold + SingleChildScrollView + navbar Column
// that each page used to repeat:
//
//   return AdminPageScaffold(
//     activeLabel:    'Web Page',
//     homePage:       CareersMainPageDashboard(),
//     webPage:        MainMainPage(),
//     jobListingPage: JobListingMainPage(),
//     subNavIndex:    1,                 // omit for pages with no sub-navbar
//     child: Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [ ...page content... ],
//     ),
//   );
//
// Created by: Amr Mesbah

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constant/color.dart';
import '../../features/home/presentation/controller/home_cubit.dart';
import 'admin_sub_navbar.dart';
import 'app_admin_navbar.dart';

class AdminPageScaffold extends StatelessWidget {
  const AdminPageScaffold({
    super.key,
    required this.child,
    this.activeLabel = 'Web Page',
    this.homePage,
    this.webPage,
    this.jobListingPage,
    this.showOnlyWebPage = false,
    this.subNavIndex,
    this.homeCubit,
    this.backgroundColor,
    this.contentWidth,
    this.showTopNavbar = true,
    this.overlay,
  });

  /// The scrolling page content. Usually a Column with
  /// `crossAxisAlignment: CrossAxisAlignment.start`.
  final Widget child;

  // ── Top navbar ───────────────────────────────────────────────────────────
  final String  activeLabel;
  final Widget? homePage;
  final Widget? webPage;
  final Widget? jobListingPage;
  final bool    showOnlyWebPage;

  /// Set false for the few screens that show no admin navbar at all.
  final bool showTopNavbar;

  // ── Sub navbar ───────────────────────────────────────────────────────────
  /// 0 = Main · 1 = Home · 2 = Services · 3 = About Us · 4 = Contact Us ·
  /// 5 = Careers. Leave null on pages that have no sub-navbar (job listings,
  /// applications, inquiries, departments).
  final int? subNavIndex;

  /// Passed through to AdminSubNavBar where a page needs to hand it the cubit
  /// it already has in scope.
  final HomeCmsCubit? homeCubit;

  // ── Layout ───────────────────────────────────────────────────────────────
  final Color? backgroundColor;

  /// Width of the centred content column. Defaults to the app-wide 1000.w.
  final double? contentWidth;

  /// Painted on top of everything — e.g. the dimmed saving spinner some pages
  /// show. Kept here so pages don't have to re-introduce their own Stack.
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    final Widget page = Scaffold(
      backgroundColor: backgroundColor ?? ColorPick.background,
      body: Column(
        children: [
          // ── Pinned bars ────────────────────────────────────────────────
          if (showTopNavbar)
            AppAdminNavbar(
              activeLabel:     activeLabel,
              homePage:        homePage       ?? const SizedBox.shrink(),
              webPage:         webPage        ?? const SizedBox.shrink(),
              jobListingPage:  jobListingPage ?? const SizedBox.shrink(),
              showOnlyWebPage: showOnlyWebPage,
            ),

          if (subNavIndex != null) ...[
            SizedBox(height: 20.h),
            // AdminSubNavBar is a fixed 1000.w and does not centre itself.
            Center(
              child: AdminSubNavBar(
                activeIndex: subNavIndex!,
                homeCubit:   homeCubit,
              ),
            ),
          ],

          // ── The only scrolling region ──────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              child: Center(
                child: SizedBox(
                  width: contentWidth ?? 1000.w,
                  child: child,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (overlay == null) return page;
    return Stack(children: [page, overlay!]);
  }
}
