// ******************* FILE INFO *******************
// File Name: careers_main_page.dart
// Updated: Our Teams tab now uses OurTeamsCubit + OurTeamsViewPage
// FIXED: Properly load data in Main tab and handle empty statistics
// ADDED: Character counters (0/500 EN, ٥٠٠/٠ AR) on description fields
// FIXED: Tab bar now always visible when switching between tabs

import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:web_app_admin/core/custom_dialog.dart' show confirmDiscard;
import 'package:web_app_admin/core/widget/date_pic.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:web_app_admin/core/custom/image_upload_circle.dart';
import 'package:web_app_admin/core/widget/network_image_view.dart';
import 'package:web_app_admin/features/careers/presentation/ui/pages/why_join_edit.dart';
import 'package:web_app_admin/features/careers/presentation/ui/pages/why_join_preview.dart';

import '../../../../../core/constant/color.dart';
import 'careers_preview.dart';
import '../../../../../core/custom/2-custom_textfield.dart';
import '../../../../../core/custom_svg.dart';
import '../../../../../core/main_widgets/admin_sticky_body.dart';
import '../../../../../core/main_widgets/admin_sub_navbar.dart';
import '../../../../../core/main_widgets/cms_sub_tabs.dart'; // BUG-155
import '../../../../../core/main_widgets/app_admin_navbar.dart';
import '../../../../../core/theme/appcolors.dart';
import '../../../../../core/theme/new_theme.dart';
import '../../../../../core/widget/button.dart';
import '../../../../main/presentation/ui/pages/main_main.dart';
import '../../../../main/presentation/controller/main_cubit.dart';
import '../../../../main/presentation/controller/main_state.dart';
import '../../../data/models/careers_model.dart';
import '../../../data/models/careers_section_model.dart';
import '../../../data/models/intern_model.dart';
import '../../controller/careers_cubit.dart';
import '../../controller/careers_state.dart';
import '../../controller/careers_section_cubit.dart';
import '../../controller/careers_section_state.dart';
import '../../controller/intern_cubit.dart';
import '../../controller/intern_state.dart';
import '../../controller/our_teams_cubit.dart';
import 'add_intern.dart';
import 'our_teams_main.dart';
import '../../../../../core/custom/3-custom_accordion.dart';
import 'package:web_app_admin/core/custom/circle_progress.dart';

part '../widgets/careers_main_page/interns_tab_body.dart';
part '../widgets/careers_main_page/grid_view.dart';
part '../widgets/careers_main_page/intern_table_view.dart';
part '../widgets/careers_main_page/intern_card.dart';
part '../widgets/careers_main_page/intern_export_dialog.dart';

// class _C {
//   static const Color primary   = Color(0xFF008037);
//   static const Color sectionBg = Color(0xFFF5F5F5);
//   static const Color cardBg    = Color(0xFFFFFFFF);
//   static const Color labelText = Color(0xFF333333);
//   static const Color hintText  = Color(0xFFAAAAAA);
//   static const Color discard   = Color(0xFF797979);
// }

// ═══════════════════════════════════════════════════════════════════════════════

class CareersMainPageMaster extends StatefulWidget {
  const CareersMainPageMaster({super.key});

  @override
  State<CareersMainPageMaster> createState() => _CareersMainPageMasterState();
}

class _CareersMainPageMasterState extends State<CareersMainPageMaster> {
  final Map<String, bool> _open = {
    'overview':   true,
    'statistics': true,
  };

  int _careersTab = 0;
  final List<String> _careersTabLabels = [
    'Main', 'Why Join Our Team', 'Our Interns', 'Our Team', // BUG-143
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CareersCmsCubit>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CareersCmsCubit, CareersCmsState>(
      builder: (context, state) {
        if (state is CareersCmsInitial || state is CareersCmsLoading) {
          return const Scaffold(
            backgroundColor: ColorPick.white,
            body: Center(child: CircleProgress()),
          );
        }

        if (state is CareersCmsError) {
          return Scaffold(
            backgroundColor: ColorPick.white,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error loading data: ${state.message}',
                      style: StyleText.fontSize14Weight400
                          .copyWith(color: Colors.red)),
                  SizedBox(height: 16.h),
                  ElevatedButton(
                    onPressed: () => context.read<CareersCmsCubit>().load(),
                    child: Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        CareersCmsModel data;
        if (state is CareersCmsLoaded) {
          data = state.data;
        } else if (state is CareersCmsSaved) {
          data = state.data;
        } else {
          data = CareersCmsModel.empty();
        }

        return Scaffold(
          backgroundColor: Color(0xFFF1F2ED),
          body: AdminStickyBody(
  contentWidth: 1000.w,
  children: [

                        AppAdminNavbar(
                          activeLabel: 'Web Page',
                          homePage: MainMainPage(),
                          webPage: MainMainPage(),
                          jobListingPage: MainMainPage(),
                        ),
                        SizedBox(height: 20.h),
                        AdminSubNavBar(activeIndex: 5),
                        Container(
                          width: 1000.w,
                          child: _buildFullTabLayout(data),
                        ),
                        SizedBox(height: 40.h),
                      ],
),
        );
      },
    );
  }

  // ── Preview button handler — respects the active tab ────────────────────────
  //
  // Every tab opens the REAL public Careers page on its matching tab, READ-ONLY
  // (showSave: false): this button shows what is already live, so there is
  // nothing here to publish. Save belongs to the edit screens.
  void _onPreviewTap() {
    final int? tab = switch (_careersTab) {
      1 => SiteCareersTab.whyJoin,
      2 => SiteCareersTab.interns,
      3 => SiteCareersTab.ourTeam,
      _ => null, // Main tab: the page opens at the top, above the tabs.
    };
    final String title = switch (_careersTab) {
      1 => 'Preview Why Join Our Team',
      2 => 'Preview Our Interns',
      3 => 'Preview Our Team',
      _ => 'Preview Main Details',
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<CareersCmsCubit>(),
          child: CareersPreviewPage(
            initialTab: tab,
            showSave:   false,
            title:      title,
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // ALWAYS-VISIBLE HEADER: title + preview button + tab bar
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildFullTabLayout(CareersCmsModel data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Title + Preview button (always visible) ──────────────────────────
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Text('Careers',
              style: StyleText.fontSize45Weight600.copyWith(
                  color: ColorPick.primary, fontWeight: FontWeight.w700)),
          const Spacer(),
          GestureDetector(
            onTap: _onPreviewTap,
            child: Container(
              width: 130.w, height: 36.h,
              decoration: BoxDecoration(
                  color: ColorPick.primary, borderRadius: BorderRadius.circular(6.r)),
              child: Center(
                child: Text('Preview Screen',
                    style: StyleText.fontSize14Weight500.copyWith(color: Colors.white)),
              ),
            ),
          ),
        ]),
        SizedBox(height: 14.h),

        // ── Tab bar (always visible) ─────────────────────────────────────────
        // BUG-155: shared sub-tab row — Careers drew padded boxes with dark
        // text and no gaps, unlike Services / About Us.
        CmsSubTabs(
          labels: _careersTabLabels,
          activeIndex: _careersTab,
          onTap: (i) => setState(() => _careersTab = i),
        ),
        SizedBox(height: 16.h),

        // ── Tab body ─────────────────────────────────────────────────────────
        _buildTabBody(data),
      ],
    );
  }

  Widget _buildTabBody(CareersCmsModel data) {
    switch (_careersTab) {
      case 0:  return _mainBody(data);
      case 1:  return _sectionBody('whyJoinOurTeam', 'Why Join Our Team');
      case 2:  return _internsBody();
      case 3:  return _ourTeamsBody();
      default: return const SizedBox();
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  Widget _ourTeamsBody() {
    return BlocProvider(
      create: (_) => OurTeamsCubit()..load(),
      child: const OurTeamsViewPage(),
    );
  }

  Widget _internsBody() {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => InternCubit()..load()),
        BlocProvider(
          create: (_) =>
              CareersSectionCubit(sectionKey: 'ourInterns')..load(),
        ),
      ],
      child: _InternsTabBody(),
    );
  }

  Widget _sectionBody(String sectionKey, String sectionTitle) {
    return BlocProvider(
      create: (context) => CareersSectionCubit(sectionKey: sectionKey)..load(),
      child: BlocBuilder<CareersSectionCubit, CareersSectionState>(
        builder: (context, state) {
          if (state is CareersSectionInitial || state is CareersSectionLoading) {
            return const Center(child: CircleProgress());
          }

          CareersSectionModel? data;
          if (state is CareersSectionLoaded) data = state.data;
          if (state is CareersSectionSaved)  data = state.data;

          if (data == null) {
            return const Center(child: CircleProgress());
          }

          final cubit = context.read<CareersSectionCubit>();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                    decoration: BoxDecoration(color: ColorPick.white, borderRadius: BorderRadius.circular(4.r)),
                    child: Text(
                      data.lastUpdated != null
                          ? 'Last Updated On ${_formatDate(data.lastUpdated!)}'
                          : 'Last Updated On —',
                      style: StyleText.fontSize13Weight500.copyWith(color: ColorPick.primary),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => BlocProvider.value(
                        value: cubit,
                        child: CareersSectionEditPage(
                          sectionKey: sectionKey, sectionTitle: sectionTitle,
                        ),
                      ),
                    )),
                    child: Container(
                      width: 130.w, height: 36.h,
                      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(4.r)),
                      child: Center(
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text('Edit Details',
                              style: StyleText.fontSize14Weight500.copyWith(color: Colors.black)),
                          SizedBox(width: 6.w),
                          CustomSvg(
                              assetPath: 'assets/control/edit_icon_pick.svg',
                              width: 20.w, height: 20.h,
                              fit: BoxFit.scaleDown, color: ColorPick.primary),
                        ]),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.sp),
              _accordion(
                key: 'section_$sectionKey',
                title: sectionTitle,
                children: [
                  if (data.items.isEmpty)
                  Container()
                  else
                    ...data.items.asMap().entries.map((e) => _itemView(e.key, e.value)),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _itemView(int index, CareersSectionItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (index > 0) ...[
          Divider(color: const Color(0xFFE8E8E8), height: 1),
          SizedBox(height: 12.h),
        ] else
          SizedBox(height: 12.h),
        // Icon + Title belong only to the first item (the section header).
        if (index == 0) ...[
          Text('Icon', style: StyleText.fontSize12Weight500.copyWith(color: AppColors.text)),
          SizedBox(height: 6.h),
          _imgCircle(item.iconUrl, isAdd: true),
          SizedBox(height: 14.h),
          Row(children: [
            Expanded(child: _readField('Title', item.title.en)),
            SizedBox(width: 16.w),
            Expanded(child: _readFieldRtl('العنوان', item.title.ar)),
          ]),
          SizedBox(height: 14.h),
        ],
        // BUG-63: the per-reason "SVG" was shown here although the edit form
        // has no such field (it was removed there) — removed from view too.
        _readField('Sub description', item.description.en, height: 80),
        SizedBox(height: 8.h),
        _readFieldRtl('الوصف', item.description.ar, height: 80),
        SizedBox(height: 16.h),
      ],
    );
  }

  Widget _imgCircle(String url, {bool isAdd = false}) {
    return NetworkImageView.circle(url: url, diameter: 60.w);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // MAIN TAB BODY  (title/preview/tab-bar removed – now in _buildFullTabLayout)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _mainBody(CareersCmsModel data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
            decoration: BoxDecoration(
                color: ColorPick.white, borderRadius: BorderRadius.circular(4.r)),
            child: Text(
              data.lastUpdated != null
                  ? 'Last Updated On ${_formatDate(data.lastUpdated!)}'
                  : 'Last Updated On —',
              style: StyleText.fontSize13Weight500.copyWith(color: ColorPick.primary),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => context.pushNamed('careers-cms-edit'),
            child: Container(
              width: 130.w, height: 36.h,
              decoration: BoxDecoration(
                  color: AppColors.card, borderRadius: BorderRadius.circular(4.r)),
              child: Center(
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('Edit Details',
                      style: StyleText.fontSize14Weight500.copyWith(color: Colors.black)),
                  SizedBox(width: 6.w),
                  CustomSvg(
                      assetPath: 'assets/control/edit_icon_pick.svg',
                      width: 20.w, height: 20.h,
                      fit: BoxFit.scaleDown, color: ColorPick.primary),
                ]),
              ),
            ),
          ),
        ]),


        SizedBox(height: 15.sp),

        _accordion(
          key: 'overview',
          title: 'Careers Overview',
          children: [
            _readField(
              'Description',
              data.overview.description.en,
              height: 80,
              maxLength: 500,
            ),
            SizedBox(height: 10.h),
            _readFieldRtl(
              'الوصف',
              data.overview.description.ar,
              height: 80,
              maxLength: 500,
            ),
            SizedBox(height: 16.h),
            Row(children: [
              Expanded(
                child: _readField(
                    'Action Button',
                    data.overview.actionButtonLabel.en.isEmpty
                        ? 'Text Here'
                        : data.overview.actionButtonLabel.en),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: _readFieldRtl(
                    'زر الإجراء',
                    data.overview.actionButtonLabel.ar.isEmpty
                        ? 'أدخل النص'
                        : data.overview.actionButtonLabel.ar),
              ),
            ]),
          ],
        ),

        // A collapsed accordion has no body, so its header would sit flush
        // against the next one — add the gap only while Overview is closed.
        SizedBox(height: (_open['overview'] ?? true) ? 0 : 10.sp),

        _accordion(
          key: 'statistics',
          title: 'Career Statistics',
          children: [
            if (data.statistics.isEmpty)
             Container()
            else
              ...data.statistics.asMap().entries.map((e) {
                final i    = e.key;
                final stat = e.value;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                      SizedBox(height: 12.h),

                    Text('${_ordLabel(i + 1)} Statistics',
                        style: StyleText.fontSize16Weight400.copyWith(color: AppColors.text)),
                    SizedBox(height: 8.h),
                    Row(children: [
                      Expanded(child: _readField('Title', stat.title.en)),
                      SizedBox(width: 16.w),
                      Expanded(child: _readFieldRtl('العنوان', stat.title.ar)),
                    ]),
                    SizedBox(height: 8.h),
                    _readField('Short Description', stat.shortDescription.en, height: 60),
                    SizedBox(height: 8.h),
                    _readFieldRtl('وصف مختصر', stat.shortDescription.ar, height: 60),
                    SizedBox(height: 12.h),
                  ],
                );
              }),
          ],
        ),
        SizedBox(height: 40.h),
      ],
    );
  }

  // ── Accordion ───────────────────────────────────────────────────────────────
  Widget _accordion({
    required String       key,
    required String       title,
    required List<Widget> children,
  }) {
    final isOpen = _open[key] ?? true;
    return CustomAccordion(
      title:    title,
      isOpen:   isOpen,
      onToggle: () => setState(() => _open[key] = !isOpen),
      child:    Padding(
        padding: EdgeInsets.symmetric(vertical: 15.sp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  // ── Read-only fields ─────────────────────────────────────────────────────────

  Widget _readField(String label, String value,
      {double height = 36, int? maxLength}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: StyleText.fontSize12Weight500.copyWith(color: AppColors.text)),
      SizedBox(height: 4.h),
      Container(
        width: double.infinity,
        height: height.h,
        padding: EdgeInsets.symmetric(
            horizontal: 10.w, vertical: height > 36 ? 8.h : 0),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(4.r)),
        alignment: height > 36 ? Alignment.topLeft : Alignment.centerLeft,
        child: Text(
          value.isEmpty ? 'Text Here' : value,
          style: StyleText.fontSize12Weight400
              .copyWith(color: value.isEmpty ? AppColors.secondaryText : AppColors.text),
          maxLines: height > 36 ? 5 : 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      // Character counter removed (app-wide rule: no counters shown)
    ]);
  }

  Widget _readFieldRtl(String label, String value,
      {double height = 36, int? maxLength}) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: StyleText.fontSize12Weight500.copyWith(color: AppColors.text)),
        SizedBox(height: 4.h),
        Container(
          width: double.infinity,
          height: height.h,
          padding: EdgeInsets.symmetric(
              horizontal: 10.w, vertical: height > 36 ? 8.h : 0),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(4.r)),
          alignment: height > 36 ? Alignment.topRight : Alignment.centerRight,
          child: Text(
            value.isEmpty ? 'أكتب هنا' : value,
            style: StyleText.fontSize12Weight400
                .copyWith(color: value.isEmpty ? AppColors.secondaryText : AppColors.text),
            textDirection: TextDirection.rtl,
            maxLines: height > 36 ? 5 : 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // Character counter removed (app-wide rule: no counters shown)
      ]),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  String _ordLabel(int n) {
    if (n == 1) return '1st';
    if (n == 2) return '2nd';
    if (n == 3) return '3rd';
    return '${n}th';
  }

  String _formatDate(DateTime dt) =>
      '${dt.day} ${_monthName(dt.month)} ${dt.year}';

  String _monthName(int m) => const [
    '',    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ][m];
}

// ═══════════════════════════════════════════════════════════════════════════════
// INTERNS TAB BODY  (unchanged)
// ═══════════════════════════════════════════════════════════════════════════════
