import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:web_app_admin/features/about_us/presentation/controller/about_us_company_cubit.dart';
import 'package:web_app_admin/features/about_us/presentation/controller/about_us_cubit.dart';

import 'core/auth/admin_auth.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

import 'package:web_app_admin/features/about_us/data/repository/about_us_company_repo_impl.dart';
import 'features/careers/presentation/controller/careers_cubit.dart';
import 'features/careers/presentation/controller/careers_section_cubit.dart';
import 'features/contact_us/presentation/controller/contact_us_location_cubit.dart';
import 'features/contact_us/presentation/controller/contact_us_cubit.dart';
import 'features/departments/data/repository/department_repo_impl.dart';
import 'features/departments/presentation/controller/department_cubit.dart';
import 'features/home/data/repository/home_repository_impl.dart';
import 'features/home/presentation/controller/home_cubit.dart';
import 'features/main/data/repository/main_repository_impl.dart';
import 'features/main/presentation/controller/main_cubit.dart';
import 'features/home/presentation/controller/lang_state.dart';
import 'features/inquire/data/repository/inquiry_repo_impl.dart';
import 'features/inquire/presentation/controller/inquiry_cubit.dart';
import 'features/inquire/presentation/ui/pages/inquiry_main.dart';
import 'features/job/data/repository/application_repo_impl.dart';
import 'features/job/data/repository/job_listing_repo_impl.dart';
import 'features/job/presentation/controller/application_cubit.dart';
import 'features/job/presentation/controller/job_listing_cubit.dart';
import 'features/services/data/repository/blog_repo_impl.dart';
import 'features/services/data/repository/services_repo_impl.dart';
import 'features/services/presentation/controller/blog_cubit.dart';
import 'features/services/presentation/controller/services_cubit.dart';
import 'firebase_options.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  usePathUrlStrategy(); // ← removes the # from URLs
  // BUG-05: make context.push()/pushNamed() update the address bar too, so
  // sub-pages opened with push (About Company, etc.) survive a reload.
  GoRouter.optionURLReflectsImperativeAPIs = true;
  AppTheme.setCurrentThemeColors();
  // BUG-96: the "[one-time setup]" that created admin@bayanatz.com with a
  // password written in the app code is gone (use
  // website_app/functions/scripts/set_admin_password.js instead).
  // Login is checked on the server (adminLogin Cloud Function) and the
  // Firebase Auth session survives a page refresh.
  await AdminAuth.restoreSession();
  // BayanatzApp — with all its cubits — is only built after sign-in.
  runApp(AdminAuthGate(builder: (_) => const BayanatzApp()));
}

Size _getDesignSize({
  required double screenWidth,
  required double screenHeight,
}) {
  final isLandscape = screenWidth > screenHeight;

  // ignore: avoid_print

  // ==================== DESKTOP PLATFORMS ====================
  if (!kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux)) {
    // ignore: avoid_print

    if (screenWidth >= 1920) {
      const size = Size(1920, 1080);
      // ignore: avoid_print
      return size;
    }
    if (screenWidth >= 1366) {
      const size = Size(1366, 768);
      // ignore: avoid_print
      return size;
    }
    if (screenWidth >= 768) {
      final size = isLandscape ? const Size(1024, 768) : const Size(768, 1024);
      // ignore: avoid_print
      return size;
    }
    const size = Size(375, 812);
    // ignore: avoid_print
    return size;
  }

  // ==================== DESKTOP WEB (≥ 1100) — BUG-282 ====================
  // The design size used to jump with the window (1024 → 1366 → 1920), so a
  // WIDER screen got a NARROWER, smaller page: content 1221 px at 1280,
  // 1054 px at 1440, 1000 px at 1920. On desktop web the design size now IS
  // the window, i.e. scale 1: the same component sizes at every desktop
  // width, a 1000 px content column centred, and the margins grow with the
  // screen.
  if (screenWidth >= 1100) {
    return Size(screenWidth, screenHeight < 600 ? 600 : screenHeight);
  }

  // ==================== LARGE DESKTOP / TV (≥ 1920) ====================
  if (screenWidth >= 1920) {
    const size = Size(1920, 1080);
    // ignore: avoid_print
    return size;
  }

  // ==================== LAPTOP (1366 – 1919) ====================
  if (screenWidth >= 1366) {
    const size = Size(1366, 768);
    // ignore: avoid_print
    return size;
  }

  // ==================== TABLET (768 – 1365) ====================
  if (screenWidth >= 768) {
    final size = isLandscape ? const Size(1024, 768) : const Size(768, 1024);
    // ignore: avoid_print
    return size;
  }

  // ==================== MOBILE (< 768) ====================
  final size = isLandscape ? const Size(812, 375) : const Size(375, 812);
  // ignore: avoid_print
  return size;
}

class BayanatzApp extends StatelessWidget {
  const BayanatzApp({super.key});

  @override
  Widget build(BuildContext context) {
    final screen = View.of(context).physicalSize / View.of(context).devicePixelRatio;
    final designSize = _getDesignSize(
      screenWidth: screen.width,
      screenHeight: screen.height,
    );

    return ScreenUtilInit(
      designSize: designSize,
      minTextAdapt: true,
      splitScreenMode: true,
      ensureScreenSize: true,
      useInheritedMediaQuery: true,
      builder: (ctx, _) {
        return MultiBlocProvider(
          providers: [
            // ← Add LanguageCubit FIRST so it's available to all widgets
            BlocProvider<LanguageCubit>(
              create: (_) => LanguageCubit(),
            ),
            BlocProvider<HomeCmsCubit>(
              create: (_) => HomeCmsCubit(
                repository: HomeRepositoryImpl(),
              )..load(),
            ),
            // Main page CMS — its OWN model + repository + Firestore
            // collection ('mainPage'): branding/theme, logo, footer, social.
            BlocProvider<MainCmsCubit>(
              create: (_) => MainCmsCubit(
                repository: MainRepositoryImpl(),
              )..load(),
            ),
            BlocProvider<ServiceCmsCubit>(
              create: (_) => ServiceCmsCubit(
                repo: ServiceRepositoryImpl(),
              )..load(),
            ),
            BlocProvider<BlogCubit>(
              create: (_) => BlogCubit(BlogRepositoryImpl())..load(),  // ✅ With repository
            ),
            BlocProvider<AboutCubit>(
              create: (_) => AboutCubit()..load(),
            ),
            BlocProvider<ContactCubit>(
              create: (_) => ContactCubit(),
            ),
            BlocProvider<ContactUsCmsCubit>(
              create: (_) => ContactUsCmsCubit()..load(),
            ),
            BlocProvider<CareersCmsCubit>(
              create: (_) => CareersCmsCubit(
                jobRepo: JobListingRepoImp(),
                appRepo: ApplicationRepoImp(), // your application repo implementation
              )..loadRealData(), // ← was ..load()
            ),

            BlocProvider(
              create: (_) => InquiryCubit(repo: InquiryRepoImp()),
              child: InquiryMainPage(),
            ),

            BlocProvider<JobListingCubit>(
              create: (_) => JobListingCubit(repo: JobListingRepoImp())..loadJobs(),
            ),

            BlocProvider<AboutCompanyCubit>(
              create: (_) => AboutCompanyCubit(
                repo: AboutCompanyRepoImp(),
              )..loadAboutCompany(),
            ),

            BlocProvider<DepartmentCubit>(
              create: (_) => DepartmentCubit(
                repo: DepartmentRepoImp(),
              )..loadDepartments(),
            ),
            BlocProvider<ApplicationCubit>(
              create: (_) => ApplicationCubit(
                repo: ApplicationRepoImp(),
              ),
            ),
            BlocProvider<InquiryCubit>(
              create: (_) => InquiryCubit(repo: InquiryRepoImp()),
            ),


            BlocProvider<CareersSectionCubit>(
              create: (_) => CareersSectionCubit(
                sectionKey: 'whyJoinOurTeam', // default section
              )..load(),
            ),

          ],
          child: BlocBuilder<LanguageCubit, LanguageState>(
            builder: (context, langState) {
              return MaterialApp.router(
                title: 'Bayanatz',
                debugShowCheckedModeBanner: false,
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: AppTheme.isDark ? ThemeMode.dark : ThemeMode.light,
                routerConfig: AppRouter.router,
                locale: langState.locale,
                supportedLocales: const [
                  Locale('en'), // English
                  Locale('ar'), // Arabic
                ],
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
              );
            },
          ),
        );
      },
    );
  }
}