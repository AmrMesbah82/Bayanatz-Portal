// ******************* FILE INFO *******************
// File Name: about_us_main.dart
// Screen 1 — About Us CMS: Main view page
// Sub-tabs: About Us | Our Strategy | Terms of Service
// FIXED: Dynamic last-updated date (from model.lastUpdatedAt)
// FIXED: Tab bar restyled to match ServicesMainPageMaster pattern
// UPDATED: Added Navigation Label accordion section to About Us tab

// ignore_for_file: avoid_web_libraries_in_flutter

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:web_app_admin/core/custom/circle_progress.dart';
import 'package:web_app_admin/core/widget/format.dart';
import 'package:web_app_admin/core/widget/network_image_view.dart';

import 'package:web_app_admin/core/widget/navigator.dart';
import 'package:web_app_admin/features/about_us/presentation/ui/pages/terms_page/terms_main.dart';
import 'package:web_app_admin/features/about_us/presentation/ui/pages/terms_page/terms_preview.dart';

import '../../../../../core/constant/color.dart';
import '../../../../../core/custom_svg.dart';
import '../../../../../core/main_widgets/admin_sticky_body.dart';
import '../../../../../core/main_widgets/admin_sub_navbar.dart';
import '../../../../../core/main_widgets/cms_sub_tabs.dart'; // BUG-155
import '../../../../../core/main_widgets/app_admin_navbar.dart';
import '../../../../../core/theme/appcolors.dart';
import '../../../../../core/theme/new_theme.dart';
import '../../../../main/presentation/ui/pages/main_main.dart';
import '../../../data/models/about_us_model.dart';
import '../../controller/about_us_cubit.dart';
import '../../controller/about_us_state.dart';
import 'about_us_edit.dart';
import 'about_us_preview.dart';
import 'strategy_page/strategy_main.dart';
import 'strategy_page/strategy_preview.dart';
import '../../../../../core/custom/3-custom_accordion.dart';

part '../widgets/about_us_main/about_main_helpers.dart';


// class _C {
//   static const Color primary   = Color(0xFF008037);
//   static const Color sectionBg = Color(0xFFF5F5F5);
//   static const Color cardBg    = Color(0xFFFFFFFF);
//   static const Color labelText = Color(0xFF333333);
//   static const Color hintText  = Color(0xFFAAAAAA);
//   static const Color back      = Color(0xFFF1F2ED);
// }

// ─────────────────────────────────────────────────────────────────────────────
class AboutMainPageMasterDashboard extends StatefulWidget {
  const AboutMainPageMasterDashboard({super.key});

  @override
  State<AboutMainPageMasterDashboard> createState() =>
      _AboutMainPageMasterDashboardState();
}

class _AboutMainPageMasterDashboardState
    extends State<AboutMainPageMasterDashboard> {

  int _subNavIndex = 3;
  final List<String> _subNavLabels = [
    'Main', 'Home', 'Services', 'About Us', 'Contact Us', 'Careers'
  ];

  int _tabIndex = 0;
  final List<String> _tabLabels = [
    'About Us',
    'Our Strategy',
    'Terms and Conditions', // BUG-143: same name as the public site
  ];

  final Map<String, bool> _open = {
    'headings':        true,
    'navigationLabel': true,
    'vision':          true,
    'mission':         true,
    'values':          true,
  };

  // ── URL → bytes cache (avoids re-fetching on every rebuild) ──

  // ── Lifted cubits so Preview button can access them from any tab ──
  late final StrategyCubit _strategyCubit;
  late final TermsCubit    _termsCubit;

  @override
  void initState() {
    super.initState();
    _strategyCubit = StrategyCubit();
    _termsCubit    = TermsCubit();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AboutCubit>().load();
    });
  }

  @override
  void dispose() {
    _strategyCubit.close();
    _termsCubit.close();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Network images — rendered through the shared NetworkImageView
  // (core/widget/network_image_view.dart): browser <img> element, handles
  // remote SVG + raster URLs identically. No manual XHR loading needed.
  // ══════════════════════════════════════════════════════════════════════════

  Widget _networkImage({
    required String url,
    bool isSvg = false,
    BoxFit fit = BoxFit.cover,
    double iconSize = 24,
  }) {
    if (url.isEmpty) {
      return Icon(
        isSvg ? Icons.description_outlined : Icons.image_outlined,
        color: Colors.grey[500], size: iconSize.sp,
      );
    }
    return NetworkImageView(url: url, fit: fit);
  }

  // ── Preview button handler — respects active tab ──────────────────────────
  //
  // Every tab opens its preview READ-ONLY (showSave: false): this button shows
  // what is already live, so there is nothing here to publish. Save belongs to
  // the edit screens, which open the same previews with unsaved work in hand.
  void _onPreviewTap(AboutPageModel aboutModel) {
    switch (_tabIndex) {
      case 0:
        final cubit = context.read<AboutCubit>();
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: cubit,
            child: AboutPreviewPageLast(
              model: aboutModel,
              imageUploads: const {},
              showSave: false,
            ),
          ),
        ));

      case 1:
        final strategyState = _strategyCubit.state;
        final OurStrategyModel? sm = switch (strategyState) {
          StrategyLoaded s => s.data,
          StrategySaved  s => s.data,
          _                => null,
        };
        if (sm == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Strategy data not loaded yet.')),
          );
          return;
        }
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: _strategyCubit,
            child: StrategyPreviewPage(
              model: sm,
              imageUploads: const {},
              showSave: false,
            ),
          ),
        ));

      case 2:
        final termsState = _termsCubit.state;
        final TermsOfServiceModel? tm = switch (termsState) {
          TermsLoaded s => s.data,
          TermsSaved  s => s.data,
          _             => null,
        };
        if (tm == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Terms data not loaded yet.')),
          );
          return;
        }
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: _termsCubit,
            child: TermsPreviewPage(
              model: tm,
              imageUploads: const {},
              showSave: false,
            ),
          ),
        ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AboutCubit, AboutState>(
      builder: (context, state) {
        if (state is AboutLoading || state is AboutInitial) {
          return const Scaffold(
            backgroundColor: ColorPick.white,
            body: Center(child: CircleProgress()),
          );
        }

        final AboutPageModel? model = switch (state) {
          AboutLoaded s => s.data,
          AboutSaved  s => s.data,
          _             => null,
        };

        if (model == null) {
          return const Scaffold(
            backgroundColor: ColorPick.white,
            body: Center(child: Text('No data found')),
          );
        }

        return Scaffold(
          backgroundColor: ColorPick.background,
          body: AdminStickyBody(
  children: [
                  AppAdminNavbar(
                    activeLabel: 'Web Page',
                    homePage: MainMainPage(),
                    webPage: MainMainPage(),
                    jobListingPage: MainMainPage(),
                  ),
                  SizedBox(height: 20.h),
                  AdminSubNavBar(activeIndex: 3),
                  SizedBox(width: 1000.w, child: _body(model)),
                ],
),
        );
      },
    );
  }

  // ── Page body ──────────────────────────────────────────────────────────────
  Widget _body(AboutPageModel model) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Title + Preview Screen ───────────────────────────────────────────
        Row(children: [
          Text('About Us',
              style: StyleText.fontSize45Weight600.copyWith(
                  color: ColorPick.primary, fontWeight: FontWeight.w700)),
          const Spacer(),
          GestureDetector(
            onTap: () => _onPreviewTap(model),
            child: Container(
              width: 130.w, height: 36.h,
              decoration: BoxDecoration(
                  color: ColorPick.primary,
                  borderRadius: BorderRadius.circular(6.r)),
              child: Center(
                child: Text('Preview Screen',
                    style: StyleText.fontSize14Weight500
                        .copyWith(color: Colors.white)),
              ),
            ),
          ),
        ]),
        SizedBox(height: 14.h),

        // ── Tab bar ─────────────────────────────────────────────────────────
        _buildTabBar(),
        SizedBox(height: 12.h),

        // ── Tab content ──────────────────────────────────────────────────────
        if (_tabIndex == 0) _aboutUsTab(model),
        if (_tabIndex == 1)
          BlocProvider.value(
            value: _strategyCubit,
            child: const StrategyMainView(),
          ),
        if (_tabIndex == 2)
          BlocProvider.value(
            value: _termsCubit,
            child: const TermsMainView(),
          ),

        SizedBox(height: 40.h),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 0 — About Us
  // ══════════════════════════════════════════════════════════════════════════
  Widget _aboutUsTab(AboutPageModel model) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Last updated row ─────────────────────────────────────────────
        _lastUpdatedRow(
          lastUpdated: model.lastUpdatedAt,
          onEdit: () => navigateTo(context, AboutEditPageMaster()),
        ),
        SizedBox(height: 16.h),

        // ① Headings
        _accordion(
          key: 'headings',
          title: 'Headings',
          children: [
            SizedBox(height: 16.h),
            Row(children: [
              Expanded(child: _readField('Title',
                  model.title.en.isEmpty ? 'Text Here' : model.title.en)),
              SizedBox(width: 16.w),
              Expanded(child: _readFieldRtl('العنوان', model.title.ar)),
            ]),
          ],
        ),
        SizedBox(height: 12.h),

        // ② Navigation Label
        _accordion(
          key: 'navigationLabel',
          title: 'Navigation Label',
          children: [
            _navigationLabelReadView(model.navigationLabel),
          ],
        ),
        SizedBox(height: 12.h),

        // ③ Vision
        _accordion(
          key: 'vision',
          title: 'Vision',
          children: [
            _sectionReadView(
              iconUrl:   model.vision.iconUrl,
              svgUrl:    model.vision.svgUrl,
              subDescEn: model.vision.subDescription.en,
              subDescAr: model.vision.subDescription.ar,
              descEn:    model.vision.description.en,
              descAr:    model.vision.description.ar,
            ),
          ],
        ),
        SizedBox(height: 12.h),

        // ④ Mission
        _accordion(
          key: 'mission',
          title: 'Mission',
          children: [
            _sectionReadView(
              iconUrl:   model.mission.iconUrl,
              svgUrl:    model.mission.svgUrl,
              subDescEn: model.mission.subDescription.en,
              subDescAr: model.mission.subDescription.ar,
              descEn:    model.mission.description.en,
              descAr:    model.mission.description.ar,
            ),
          ],
        ),
        SizedBox(height: 12.h),

        // ⑤ Values
        _accordion(
          key: 'values',
          title: 'Values',
          children: [
            if (model.values.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.h),
                  child: Text('No values yet.',
                      style: StyleText.fontSize13Weight400
                          .copyWith(color: AppColors.secondaryText)),
                ),
              )
            else
              Column(
                children: [
                  SizedBox(height: 15.h),
                  _valuesGrid(model.values),
                ],
              ),
          ],
        ),
      ],
    );
  }

  // ── Navigation Label read view ─────────────────────────────────────────────
  Widget _navigationLabelReadView(AboutNavigationLabel navLabel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 16.h),
        // Icon preview
        Row(
          children: [
            _iconPreviewCircle(label: 'Icon', url: navLabel.iconUrl),
          ],
        ),
        SizedBox(height: 16.h),
        // Bilingual title
        Row(children: [
          Expanded(
            child: _readField(
              'Title',
              navLabel.title.en.isEmpty ? 'Text Here' : navLabel.title.en,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: _readFieldRtl('العنوان', navLabel.title.ar),
          ),
        ]),
        SizedBox(height: 8.h),
      ],
    );
  }

  // ── Section read view (Vision / Mission) ──────────────────────────────────
  Widget _sectionReadView({
    required String iconUrl, required String svgUrl,
    required String subDescEn, required String subDescAr,
    required String descEn,    required String descAr,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 16.h),
        Row(children: [
          _iconPreviewCircle(label: 'Icon', url: iconUrl),
          SizedBox(width: 24.w),
          _iconPreviewCircle(label: 'SVG', url: svgUrl, isSvg: true),
        ]),
        SizedBox(height: 16.h),
        _readField('Sub Description',
            subDescEn.isEmpty ? 'Text Here' : subDescEn, height: 80),
        SizedBox(height: 8.h),
        _readFieldRtl('وصف فرعي', subDescAr, height: 80),
        SizedBox(height: 10.h),
        _readField('Description', descEn.isEmpty ? 'Text Here' : descEn,
            height: 80),
        SizedBox(height: 8.h),
        _readFieldRtl('الوصف', descAr, height: 80),
      ],
    );
  }

  Widget _iconPreviewCircle({
    required String label,
    required String url,
    bool isSvg = false,
  }) {
    // Standard read-only icon circle — same UI everywhere via
    // NetworkImageView.circle (core/widget/network_image_view.dart).
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: StyleText.fontSize12Weight500.copyWith(color: AppColors.text)),
        SizedBox(height: 6.h),
        NetworkImageView.circle(url: url, diameter: 56.w),
      ],
    );
  }

  Widget _valuesGrid(List<AboutValueItem> items) {
    final rows = <List<AboutValueItem>>[];
    for (int i = 0; i < items.length; i += 4) {
      rows.add(items.skip(i).take(4).toList());
    }
    return Column(
      children: rows.map((row) => Padding(
        padding: EdgeInsets.only(bottom: 8.h),
        // IntrinsicHeight + CrossAxisAlignment.stretch makes every card in the
        // row as tall as the tallest one, so a value with a long title or
        // description no longer leaves its neighbours short.
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...row.map((item) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: 8.w),
                  child: _valueMiniCard(item),
                ),
              )),
              ...List.generate(
                  4 - row.length, (_) => const Expanded(child: SizedBox())),
            ],
          ),
        ),
      )).toList(),
    );
  }

  Widget _valueMiniCard(AboutValueItem item) {
    return Container(
      padding: EdgeInsets.all(10.r),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(8.r)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28.w, height: 28.w,
            decoration: BoxDecoration(
                color: const Color(0xFFE8F5EE),
                borderRadius: BorderRadius.circular(6.r)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6.r),
              child: _networkImage(
                url: item.iconUrl,
                isSvg: false,
                fit: BoxFit.contain,
                iconSize: 16,
              ),
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            item.title.en.isNotEmpty ? FormatHelper.capitalize(item.title.en) : 'Title',
            style: StyleText.fontSize12Weight600
                .copyWith(color: const Color(0xFF1A1A1A)),
            maxLines: 2, overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 4.h),
          Text(
            item.shortDescription.en.isNotEmpty
                ? FormatHelper.capitalize(item.shortDescription.en)
                : 'Short Description',
            style: StyleText.fontSize12Weight400.copyWith(
                color: AppColors.secondaryBlack, height: 1.5),
            maxLines: 3, overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

}