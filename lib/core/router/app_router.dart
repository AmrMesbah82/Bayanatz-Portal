import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';


import '../../features/about_us/presentation/controller/about_us_cubit.dart';
import '../../features/about_us/presentation/ui/pages/about_us_company_edit.dart';
import '../../features/about_us/presentation/ui/pages/about_us_company_main.dart';
import '../../features/about_us/presentation/ui/pages/about_us_main.dart';
import '../../features/careers/presentation/controller/careers_cubit.dart';
import '../../features/careers/presentation/ui/pages/careers_edit.dart';
import '../../features/careers/presentation/ui/pages/careers_main.dart';
import '../../features/careers/presentation/ui/pages/careers_main_page.dart';
import '../../features/careers/presentation/ui/pages/careers_preview.dart';
import '../../features/contact_us/presentation/ui/pages/contact_us_edit.dart';
import '../../features/contact_us/presentation/ui/pages/contact_us_preview.dart';
import '../../features/contact_us/presentation/ui/pages/contact_us_main.dart';
import '../../features/home/presentation/controller/home_cubit.dart';
import '../../features/home/presentation/ui/pages/home_main.dart';
import '../../features/home/presentation/ui/pages/home_edit.dart';
import '../../features/job/data/repository/application_repo_impl.dart';
import '../../features/job/data/repository/job_listing_repo_impl.dart';
import '../../features/main/presentation/ui/pages/main_edit.dart';
import '../../features/main/presentation/ui/pages/main_main.dart';
import '../../features/main/presentation/ui/pages/main_preview.dart';
import '../../features/job/presentation/ui/pages/job_listing_main.dart';
import '../../features/job/presentation/ui/pages/job_listing_edit.dart';
import '../../features/job/presentation/ui/pages/job_listing_detail.dart' show JobListingDetailPage;
import '../../features/departments/presentation/ui/pages/department_main.dart';
import '../../features/job/presentation/ui/pages/application_main.dart';
import '../../features/inquire/presentation/ui/pages/inquiry_main.dart';
import '../../features/services/presentation/ui/pages/services_main/services_main.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// SLIDE + ANGLE + FADE PAGE TRANSITION
// ═══════════════════════════════════════════════════════════════════════════════

enum SlideDirection { fromRight, fromLeft, fromBottom }

CustomTransitionPage<T> animatedPage<T>({
  required LocalKey key,
  required Widget child,
  SlideDirection slideDirection = SlideDirection.fromRight,
  Duration duration = const Duration(milliseconds: 650),
  Curve curve = Curves.easeOutCubic,
}) {
  return CustomTransitionPage<T>(
    key: key,
    child: child,
    transitionDuration: duration,
    reverseTransitionDuration: const Duration(milliseconds: 400),
    transitionsBuilder: (context, animation, secondaryAnimation, pageChild) {
      final Offset beginOffset = switch (slideDirection) {
        SlideDirection.fromRight => const Offset(0.12, 0.0),
        SlideDirection.fromLeft => const Offset(-0.12, 0.0),
        SlideDirection.fromBottom => const Offset(0.0, 0.08),
      };

      final slideAnim = Tween<Offset>(
        begin: beginOffset,
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: curve));

      final fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: animation,
          curve: const Interval(0.0, 0.55, curve: Curves.easeIn),
        ),
      );

      final skewSign = slideDirection == SlideDirection.fromLeft ? 1.0 : -1.0;
      final skewAnim = Tween<double>(
        begin: skewSign * 0.05,
        end: 0.0,
      ).animate(CurvedAnimation(parent: animation, curve: curve));

      final scaleAnim = Tween<double>(
        begin: 0.97,
        end: 1.0,
      ).animate(CurvedAnimation(parent: animation, curve: curve));

      final exitFade = Tween<double>(begin: 1.0, end: 0.92).animate(
        CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeIn),
      );

      return FadeTransition(
        opacity: exitFade,
        child: FadeTransition(
          opacity: fadeAnim,
          child: SlideTransition(
            position: slideAnim,
            child: AnimatedBuilder(
              animation: animation,
              builder: (_, child) => Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0008)
                  ..rotateY(skewAnim.value)
                  ..scale(scaleAnim.value),
                alignment: Alignment.center,
                child: child,
              ),
              child: pageChild,
            ),
          ),
        ),
      );
    },
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// ROUTER
// ═══════════════════════════════════════════════════════════════════════════════

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      // ── Public pages ───────────────────────────────────────────────────────
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const CareersMainPageDashboard(),
      ),

      // ── Top-level admin sections (BUG-05) ──────────────────────────────────
      // Each section has its own URL so F5 keeps you on the same page, the
      // browser Back button goes to the previous section, and sections can be
      // bookmarked / shared.
      GoRoute(
        path: '/jobs',
        name: 'jobs',
        builder: (context, state) => const JobListingMainPage(),
      ),
      // BUG-119: "Our Departments" and "Create New Job Post" had no URL, so
      // the browser Back button jumped to Home. Real routes now.
      GoRoute(
        path: '/jobs/new',
        name: 'job-new',
        pageBuilder: (context, state) => animatedPage(
          key: state.pageKey,
          child: const JobListingEditPage(),
          slideDirection: SlideDirection.fromBottom,
        ),
      ),
      GoRoute(
        path: '/jobs/departments',
        name: 'departments',
        pageBuilder: (context, state) => animatedPage(
          key: state.pageKey,
          child: const DepartmentMainPage(),
          slideDirection: SlideDirection.fromBottom,
        ),
      ),
      // BUG-259: Job Post Details had no URL (address stayed /jobs). Declared
      // AFTER /jobs/new and /jobs/departments so those still match first.
      GoRoute(
        path: '/jobs/:jobId',
        name: 'job-detail',
        pageBuilder: (context, state) => animatedPage(
          key: state.pageKey,
          child: JobListingDetailPage(jobId: state.pathParameters['jobId']!),
          slideDirection: SlideDirection.fromBottom,
        ),
      ),
      GoRoute(
        path: '/applications',
        name: 'applications',
        builder: (context, state) => const ApplicationMainPage(),
      ),
      GoRoute(
        path: '/inquiries',
        name: 'inquiries',
        builder: (context, state) => const InquiryMainPage(),
      ),
      GoRoute(
        path: '/admin/services',
        name: 'services-cms',
        builder: (context, state) => const ServicesMainPageMaster(),
      ),

      // ── About Us CMS ───────────────────────────────────────────────────────
      // GoRoute(
      //   path: '/admin/about-edit',
      //   name: 'about-edit',
      //   pageBuilder: (context, state) => animatedPage(
      //     key: state.pageKey,
      //     child: const AboutEditPage(),
      //     slideDirection: SlideDirection.fromBottom,
      //   ),
      // ),

      // ── Home CMS (HomeMainPageMaster) ──────────────────────────────────────────
      GoRoute(
        path: '/admin/home-page',
        name: 'home-page',
        pageBuilder: (context, state) => animatedPage(
          key: state.pageKey,
          child: BlocProvider.value(
            value: context
                .read<HomeCmsCubit>(), // ✅ reuse global cubit from main.dart
            child: const HomeMainPageMaster(),
          ),
          slideDirection: SlideDirection.fromBottom,
        ),
      ),

      // BUG-276: the Home editor has its own URL like Main / Contact /
      // Careers, so refresh / Back / bookmarks open the right state.
      GoRoute(
        path: '/admin/home-page/edit',
        name: 'home-page-edit',
        pageBuilder: (context, state) => animatedPage(
          key: state.pageKey,
          child: BlocProvider.value(
            value: context.read<HomeCmsCubit>(),
            child: const HomeEditPageMaster(),
          ),
          slideDirection: SlideDirection.fromBottom,
        ),
      ),

      // ── About Company (opened from Job Listing) ───────────────────────────
      // Real routes, so the URL changes and the browser Back button works.
      GoRoute(
        path: '/admin/about-company',
        name: 'about-company',
        pageBuilder: (context, state) => animatedPage(
          key: state.pageKey,
          child: const AboutCompanyMainPage(),
          slideDirection: SlideDirection.fromBottom,
        ),
      ),

      GoRoute(
        path: '/admin/about-company/edit',
        name: 'about-company-edit',
        pageBuilder: (context, state) => animatedPage(
          key: state.pageKey,
          child: const AboutCompanyEditPage(),
          slideDirection: SlideDirection.fromBottom,
        ),
      ),

      GoRoute(
        path: '/admin/about-cms',
        name: 'about-cms',
        pageBuilder: (context, state) => animatedPage(
          key: state.pageKey,
          child: BlocProvider(
            create: (_) => AboutCubit()..load(),
            child: const AboutMainPageMasterDashboard(),
          ),
          slideDirection: SlideDirection.fromBottom,
        ),
      ),

      // ── Dashboard (Main / Edit / Preview) ─────────────────────────────────
      GoRoute(
        path: '/admin/dashboard',
        name: 'home_main',
        pageBuilder: (context, state) => animatedPage(
          key: state.pageKey,
          child: const MainMainPage(),
          slideDirection: SlideDirection.fromBottom,
        ),
      ),

      GoRoute(
        path: '/admin/dashboard/edit',
        name: 'home_edit',
        pageBuilder: (context, state) => animatedPage(
          key: state.pageKey,
          child: const MainEditPage(),
          slideDirection: SlideDirection.fromBottom,
        ),
      ),

      // Despite the name, this route is the MAIN preview, and it is the one
      // the "Preview Screen" button on the Main page opens. That entry is
      // read-only — you are looking at what is already live, not reviewing
      // unsaved edits — so Publish is hidden here. The edit flow pushes
      // MainPreviewPage directly (see main_edit) and keeps its Publish button.
      GoRoute(
        path: '/admin/dashboard/preview',
        name: 'home_preview',
        pageBuilder: (context, state) => animatedPage(
          key: state.pageKey,
          child: const MainPreviewPage(showPublish: false),
          slideDirection: SlideDirection.fromBottom,
        ),
      ),

      // ── Contact Submissions ────────────────────────────────────────────────

      // ── Contact Us CMS ─────────────────────────────────────────────────────
      GoRoute(
        path: '/admin/contact-cms',
        name: 'contact-cms',
        pageBuilder: (context, state) => animatedPage(
          key: state.pageKey,
          child: const ContactUsMainPage(),
          slideDirection: SlideDirection.fromBottom,
        ),
      ),

      GoRoute(
        path: '/admin/contact-cms/edit',
        name: 'contact-cms-edit',
        pageBuilder: (context, state) => animatedPage(
          key: state.pageKey,
          child: const ContactUsCmsEditPage(),
          slideDirection: SlideDirection.fromBottom,
        ),
      ),

      GoRoute(
        path: '/admin/contact-cms/preview',
        name: 'contact-cms-preview',
        pageBuilder: (context, state) => animatedPage(
          key: state.pageKey,
          child: const ContactUsCmsPreviewPage(),
          slideDirection: SlideDirection.fromBottom,
        ),
      ),

      // ── Careers CMS ────────────────────────────────────────────────────────

      // ✅ AFTER
      GoRoute(
        path: '/admin/careers-cms',
        name: 'careers-cms',
        pageBuilder: (context, state) => animatedPage(
          key: state.pageKey,
          child: BlocProvider(
            create: (_) => CareersCmsCubit(
              jobRepo: JobListingRepoImp(),
              appRepo:
                  ApplicationRepoImp(), // your application repo implementation
            )..load(),
            child: const CareersMainPageMaster(),
          ),
          slideDirection: SlideDirection.fromBottom,
        ),
      ),

      // Reuses the app-wide CareersCmsCubit (created in main.dart) instead of
      // building a fresh one and re-fetching: the data is already loaded, so the
      // edit page opens directly with no blank loading screen in between.
      GoRoute(
        path: '/admin/careers-cms/edit',
        name: 'careers-cms-edit',
        pageBuilder: (context, state) => animatedPage(
          key: state.pageKey,
          child: BlocProvider<CareersCmsCubit>.value(
            value: context.read<CareersCmsCubit>(),
            child: const CareersEditPage(),
          ),
          slideDirection: SlideDirection.fromBottom,
        ),
      ),

      GoRoute(
        path: '/admin/careers-cms/preview',
        name: 'careers-cms-preview',
        pageBuilder: (context, state) => animatedPage(
          key: state.pageKey,
          child: BlocProvider(
            create: (_) => CareersCmsCubit(
              jobRepo: JobListingRepoImp(),
              appRepo:
                  ApplicationRepoImp(), // your application repo implementation
            )..load(),
            child: const CareersPreviewPage(),
          ),
          slideDirection: SlideDirection.fromBottom,
        ),
      ),
    ],
  );
}
