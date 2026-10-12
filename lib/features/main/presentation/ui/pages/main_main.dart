/// ******************* FILE INFO *******************
/// File Name: main_main.dart
/// Page 1 — "Main" read-only overview page (Figma screens 1 & 2)
/// UPDATED: Navigation field strips leading '/' before display.
/// UPDATED: Added Navigation Items read-only accordion section.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import 'package:web_app_admin/core/widget/network_image_view.dart';
import 'package:web_app_admin/features/main/data/models/main_model.dart';

import '../../../../../core/custom_svg.dart';
import '../../../../../core/constant/color.dart';
import '../../../../../core/main_widgets/admin_sticky_body.dart';
import '../../../../../core/main_widgets/admin_sub_navbar.dart';
import '../../../../../core/main_widgets/app_admin_navbar.dart';
import '../../../../../core/theme/appcolors.dart';
import '../../../../../core/theme/new_theme.dart';
import '../../../../careers/presentation/ui/pages/careers_main.dart';
import '../../../../home/data/models/home_model.dart';
import '../../../../home/presentation/controller/home_cubit.dart';
import '../../../../home/presentation/controller/home_state.dart';
import '../../controller/main_cubit.dart';
import '../../controller/main_state.dart';
import '../../../../job/presentation/ui/pages/job_listing_main.dart';
import '../../../../../core/custom/3-custom_accordion.dart';
import 'package:web_app_admin/core/custom/circle_progress.dart';

// class _C {
//   static const Color primary   = Color(0xFF008037);
//   static const Color sectionBg = Color(0xFFF5F5F5);
//   static const Color cardBg    = Color(0xFFFFFFFF);
//   static const Color border    = Color(0xFFE0E0E0);
//   static const Color labelText = Color(0xFF333333);
//   static const Color hintText  = Color(0xFFAAAAAA);
//   static const Color back      = Color(0xFFF1F2ED);
// }

// ── Helper: strip leading slash for display ───────────────────────────────────
String _displayRoute(String route) {
  if (route.isEmpty) return 'None';
  return route.startsWith('/') ? route.substring(1) : route;
}

// ── Helper: friendly display name for a route (instead of the raw slug) ───────
String _routeDisplayName(String route) {
  if (route.isEmpty) return 'None';
  final r = route.startsWith('/') ? route : '/$route';
  const names = <String, String>{
    '/':          'Home',
    '/services':  'Services',
    '/about':     'About Us',
    '/contact':   'Contact Us',
    '/careers':   'Careers',
    '/jobs':      'Jobs',
    '/careers?tab=why-join-our-team':  'Why Join Our Team',
    '/careers?tab=interns':            'Our Interns',
    '/careers?tab=our-team':           'Our Team',
    '/about?tab=our-strategy':         'Our Strategy',
    '/about?tab=terms-and-conditions': 'Terms and Conditions',
    '/about?tab=privacy-policy':       'Privacy Policy',
    '/about?tab=vision':               'Vision',
    '/about?tab=mission':              'Mission',
    '/about?tab=values':               'Values',
  };
  return names[r] ?? _displayRoute(route);
}

class MainMainPage extends StatefulWidget {
  const MainMainPage({super.key});
  @override
  State<MainMainPage> createState() => _MainMainPageState();
}

class _MainMainPageState extends State<MainMainPage> {
  final Map<String, bool> _open = {
    'theme':  true,
    'nav':    true,
    'header': true,
    'footer': true,
    'links':  true,
  };

  int _subNavIndex = 0;
  final List<String> _subNavItems = [
    'Main', 'Home', 'Services', 'About Us', 'Contact Us', 'Careers'
  ];

  void _goToEdit() => context.pushNamed('home_edit');

  // ── Date formatter ──────────────────────────────────────────────────────────
  String _fmtDate(DateTime? d) {
    if (d == null) return '—';
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${months[d.month]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MainCmsCubit, MainCmsState>(
      builder: (context, state) {
        if (state is MainCmsInitial || state is MainCmsLoading) {
          return const Scaffold(
            backgroundColor: ColorPick.background,
            body: Center(child: CircleProgress()),
          );
        }

        MainPageModel? data;
        if (state is MainCmsLoaded) data = state.data;
        if (state is MainCmsSaved)  data = state.data;

        return BlocBuilder<HomeCmsCubit, HomeCmsState>(
            builder: (context, _) {
        return Scaffold(
          backgroundColor: ColorPick.background,
          body: AdminStickyBody(
  children: [
                  AppAdminNavbar(
                    activeLabel:    'Web Page',
                    homePage:       CareersMainPageDashboard(),
                    webPage:        MainMainPage(),
                    jobListingPage: JobListingMainPage(),
                  ),
                  SizedBox(height: 20.h),
                  AdminSubNavBar(activeIndex: 0),
                  SingleChildScrollView(
                    padding: EdgeInsets.only(left: 20.sp, right: 20.sp,bottom: 20.sp),
                    child: SizedBox(
                      width: 1000.w,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Title row ──────────────────────────────────────
                          Row(
                            children: [
                              Text(
                                'Main',
                                style: StyleText.fontSize45Weight600.copyWith(
                                  color: ColorPick.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () => context.pushNamed('home_preview'),
                                child: Container(
                                  width: 130.w, height: 36.h,
                                  decoration: BoxDecoration(
                                    color: ColorPick.primary,
                                    borderRadius: BorderRadius.circular(6.r),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Preview Screen',
                                      style: StyleText.fontSize14Weight500.copyWith(color: Colors.white),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12.h),

                          // ── Last updated + Edit row ────────────────────────
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                                decoration: BoxDecoration(
                                  color: ColorPick.white,
                                  borderRadius: BorderRadius.circular(4.r),
                                ),
                                child: Text(
                                  data?.lastUpdatedAt != null
                                      ? 'Last Updated On ${_fmtDate(data!.lastUpdatedAt)}'
                                      : 'Last Updated On —',
                                  style: StyleText.fontSize13Weight500.copyWith(color: ColorPick.primary),
                                ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: _goToEdit,
                                child: Container(
                                  width: 130.w, height: 36.h,
                                  decoration: BoxDecoration(
                                    color: ColorPick.white,
                                    borderRadius: BorderRadius.circular(4.r),
                                  ),
                                  child: Center(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Edit Details',
                                          style: StyleText.fontSize14Weight500.copyWith(color: Colors.black),
                                        ),
                                        SizedBox(width: 6.w),
                                        CustomSvg(
                                          assetPath: 'assets/control/edit_icon_pick.svg',
                                          width: 20.w, height: 20.h,
                                          fit: BoxFit.scaleDown,
                                          color: ColorPick.primary,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16.h),

                          // ── Content ────────────────────────────────────────
                          if (data != null) ...[
                            _accordion(
                              key: 'theme',
                              title: 'Theme and Logo',
                              children: [_readOnlyLogoSection(data)],
                            ),
                            SizedBox(height: 10.h),
                            _accordion(
                              key: 'nav',
                              title: 'Navigation Items',
                              children: [
                                _readOnlyNavSection(
                                    data ?? MainPageModel.defaultModel)
                              ],
                            ),
                            SizedBox(height: 10.h),
                            _accordion(
                              key: 'footer',
                              title: 'Footer',
                              children: [_readOnlyFooterSection(data)],
                            ),
                            SizedBox(height: 10.h),
                            _accordion(
                              key: 'links',
                              title: 'Links',
                              children: [_readOnlyLinksSection(data)],
                            ),
                          ] else ...[
                            const Center(child: CircleProgress()),
                          ],

                          SizedBox(height: 40.h),
                        ],
                      ),
                    ),
                  ),
                ],
),
        );
            });
      },
    );
  }

  // ── Accordion ───────────────────────────────────────────────────────────────
  Widget _accordion({
    required String key,
    required String title,
    required List<Widget> children,
  }) {
    final isOpen = _open[key] ?? true;
    return CustomAccordion(
      title:    title,
      isOpen:   isOpen,
      onToggle: () => setState(() => _open[key] = !isOpen),
      child:    Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  // ── Read-only Logo / Theme section ──────────────────────────────────────────
  Widget _readOnlyLogoSection(MainPageModel data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 15.h),
        Text('Logo', style: StyleText.fontSize14Weight500.copyWith(color: AppColors.text)),
        SizedBox(height: 8.h),
        // BUG-25: with no uploaded logo the site falls back to the bundled
        // logo, but this field showed an empty placeholder. Show what visitors
        // actually see.
        data.branding.logoUrl.isNotEmpty
            ? NetworkImageView.circle(url: data.branding.logoUrl, diameter: 70.w)
            : Row(children: [
                ClipOval(
                  child: Image.asset('assets/images/logo.jpg',
                      width: 70.w, height: 70.w, fit: BoxFit.cover),
                ),
                SizedBox(width: 10.w),
                Text('Default logo (no custom logo uploaded)',
                    style: StyleText.fontSize12Weight400
                        .copyWith(color: AppColors.secondaryText)),
              ]),
        SizedBox(height: 16.h),
        Row(children: [
          Expanded(child: _colorReadField('Primary Color', data.branding.primaryColor)),
          SizedBox(width: 16.w),
          Expanded(child: _colorReadField('Secondary', data.branding.secondaryColor) /* Figma */),
        ]),
        SizedBox(height: 12.h),
        Row(children: [
          Expanded(child: _colorReadField('Background',
              data.branding.backgroundColor.isNotEmpty ? data.branding.backgroundColor : '#D9D9D9')),
          SizedBox(width: 16.w),
          Expanded(child: _colorReadField('Header and Footer',
              data.branding.headerFooterColor.isNotEmpty ? data.branding.headerFooterColor : '#D9D9D9')),
        ]),
        SizedBox(height: 12.h),
        Row(children: [
          Expanded(child: _colorReadField('Main Widget Color',
              data.branding.mainWidgetColor.isNotEmpty ? data.branding.mainWidgetColor : '#D9D9D9')),
          SizedBox(width: 16.w),
          const Expanded(child: SizedBox()),
        ]),
        SizedBox(height: 12.h),
        Row(children: [
          Expanded(child: _readField('English Font',
              data.branding.englishFont.isEmpty ? 'Select Font' : data.branding.englishFont)),
          SizedBox(width: 16.w),
          Expanded(child: _readField('Arabic Font',
              data.branding.arabicFont.isEmpty ? 'Select Font' : data.branding.arabicFont)),
        ]),
      ],
    );
  }

  // ── Read-only Navigation Items section ──────────────────────────────────────
  // Reads the MAIN navbar items (mainPage/main), matching the editor.
  Widget _readOnlyNavSection(MainPageModel data) {
    if (data.navButtons.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 20.h),
        child: Center(
          child: Text(
            'No navigation items configured',
            style: StyleText.fontSize13Weight400.copyWith(color: AppColors.secondaryText),
          ),
        ),
      );
    }


    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: data.navButtons.asMap().entries.map((entry) {
        final i   = entry.key;
        final btn = entry.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 15.h),

            // ── Title EN / AR fields ───────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _readField(
                    'Title',
                    btn.name.en.isEmpty ? 'Text Here' : btn.name.en,
                    status: btn.status,
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: _readFieldRtl(
                    'عنصر التنقل',
                    btn.name.ar.isEmpty ? 'أدخل النص هنا' : btn.name.ar,
                  ),
                ),
              ],
            ),
            SizedBox(height: 6.h),
          ],
        );
      }).toList(),
    );
  }

  // ── Read-only Header section ─────────────────────────────────────────────────
  Widget _readOnlyHeaderSection(HomePageModel data) {
    return Column(
      children: data.headerItems.map((item) => Padding(
        padding: EdgeInsets.only(bottom: 10.h),
        child: Row(
          children: [
            Icon(Icons.drag_indicator_rounded, size: 18.sp, color: AppColors.secondaryText),
            SizedBox(width: 8.w),
            Expanded(child: _readFieldWithStatus('Title', item.title.en, item.status)),
            SizedBox(width: 8.w),
            Expanded(child: _readFieldRtl('العنوان', item.title.ar)),
          ],
        ),
      )).toList(),
    );
  }

  // ── Read-only Footer section ─────────────────────────────────────────────────
  Widget _readOnlyFooterSection(MainPageModel data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: data.footerColumns.asMap().entries.map((entry) {
        final i   = entry.key;
        final col = entry.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 15.h),
            if (i > 0) ...[
              Divider(color: const Color(0xFFE8E8E8), height: 1),
              SizedBox(height: 12.h),
            ],
            Text(
              '${i + 1}${_ord(i + 1)} Column',
              style: StyleText.fontSize13Weight600.copyWith(color: AppColors.text),
            ),
            SizedBox(height: 8.h),
            Row(children: [
              Expanded(child: _readField('Group Title',
                  col.title.en.isEmpty ? 'Read Us' : col.title.en)),
              SizedBox(width: 16.w),
              Expanded(child: _readFieldRtl('عنوان المجموعة', col.title.ar)),
            ]),
            SizedBox(height: 8.h),
            Row(children: [
              // ✅ Strip leading '/' from navigation route
              Expanded(child: _readField('Navigation', _routeDisplayName(col.route))),
              SizedBox(width: 10.w),
              const Expanded(child: SizedBox()),
            ]),
            SizedBox(height: 8.h),
            // Caption shown ONCE — the rows below are this column's labels
            // (one box per label; they are separate labels, not duplicates).
            if (col.labels.isNotEmpty) ...[
              Row(children: [
                Expanded(
                  child: Text('Navigation Label',
                      style: StyleText.fontSize12Weight500
                          .copyWith(color: AppColors.text)),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text('تسمية التنقل',
                        style: StyleText.fontSize12Weight500
                            .copyWith(color: AppColors.text)),
                  ),
                ),
              ]),
              SizedBox(height: 4.h),
            ],
            ...col.labels.map((lbl) => Padding(
              padding: EdgeInsets.only(bottom: 6.h),
              child: Row(children: [
                Expanded(child: _valueBox(
                    lbl.label.en.isEmpty ? 'Text Here' : lbl.label.en)),
                SizedBox(width: 8.w),
                Expanded(child: _valueBoxRtl(lbl.label.ar)),
              ]),
            )),
            SizedBox(height: 8.h),
          ],
        );
      }).toList(),
    );
  }

  // ── Read-only Links section ──────────────────────────────────────────────────
  Widget _readOnlyLinksSection(MainPageModel data) {
    final rows = (data.socialLinks.length / 2).ceil();
    return Column(
      children: List.generate(rows, (rowIndex) {
        final left  = rowIndex * 2;
        final right = left + 1;
        return Padding(
          padding: EdgeInsets.only(bottom: 14.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _readLinkItem(data.socialLinks[left], left)),
              SizedBox(width: 16.w),
              right < data.socialLinks.length
                  ? Expanded(child: _readLinkItem(data.socialLinks[right], right))
                  : const Expanded(child: SizedBox()),
            ],
          ),
        );
      }),
    );
  }

  Widget _readLinkItem(dynamic link, int i) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 15.h),
        Text('Icon', style: StyleText.fontSize12Weight500.copyWith(color: AppColors.text)),
        SizedBox(height: 6.h),
        NetworkImageView.circle(url: link.iconUrl, diameter: 60.w),
        SizedBox(height: 6.h),
        _readField('Insert Link', link.url.isEmpty ? 'Insert Links' : link.url),
      ],
    );
  }

  // ── Caption-less value boxes (used when the caption is rendered once) ───────
  Widget _valueBox(String value) => Container(
    width: double.infinity, height: 36.h,
    padding: EdgeInsets.symmetric(horizontal: 15.w), // BUG-158: one inset
    decoration: BoxDecoration(
        color: AppColors.card, borderRadius: BorderRadius.circular(4.r)),
    alignment: Alignment.centerLeft,
    child: Text(value,
        style: StyleText.fontSize12Weight400
            .copyWith(color: AppColors.secondaryText),
        overflow: TextOverflow.ellipsis),
  );

  Widget _valueBoxRtl(String value) => Container(
    width: double.infinity, height: 36.h,
    padding: EdgeInsets.symmetric(horizontal: 15.w), // BUG-158: one inset
    decoration: BoxDecoration(
        color: AppColors.card, borderRadius: BorderRadius.circular(4.r)),
    alignment: Alignment.centerRight,
    child: Text(
      value.isEmpty ? 'أدخل النص هنا' : value,
      style: StyleText.fontSize12Weight400
          .copyWith(color: AppColors.secondaryText),
      overflow: TextOverflow.ellipsis,
      textDirection: TextDirection.rtl,
    ),
  );

  // ── Shared read-only field helpers ───────────────────────────────────────────
  Widget _readField(String label, String value, {bool? status}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Text(label, style: StyleText.fontSize14Weight500.copyWith(color: AppColors.text)),


          Spacer(),
          if (status != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Status ',
                    style: StyleText.fontSize11Weight400
                        .copyWith(color: AppColors.text)),
                Container(
                  width: 32.w,
                  height: 18.h,
                  decoration: BoxDecoration(
                    color: status
                        ? ColorPick.primary
                        : Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Align(
                    alignment: status
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      width: 14.w,
                      height: 14.h,
                      margin: EdgeInsets.symmetric(horizontal: 2.w),
                      decoration: const BoxDecoration(
                          color: Colors.white, shape: BoxShape.circle),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
      SizedBox(height: 4.h),
      // BUG-158: same 16 px text inset and text colour as the other inputs
      // (font fields were inset 10 px and greyer).
      Container(
        width: double.infinity, height: 36.h,
        padding: EdgeInsets.symmetric(horizontal: 15.w),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(4.r)),
        alignment: Alignment.centerLeft,
        child: Text(value,
            style: StyleText.fontSize12Weight400.copyWith(color: AppColors.text),
            overflow: TextOverflow.ellipsis),
      ),
    ],
  );

  Widget _readFieldRtl(String label, String value) => Directionality(
    textDirection: TextDirection.rtl,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: StyleText.fontSize14Weight500.copyWith(color: AppColors.text)),
        SizedBox(height: 4.h),
        Container(
          width: double.infinity, height: 36.h,
          padding: EdgeInsets.symmetric(horizontal: 15.w), // BUG-158
          decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(4.r)),
          alignment: Alignment.centerRight,
          child: Text(
            value.isEmpty ? 'أدخل النص هنا' : value,
            style: StyleText.fontSize12Weight400.copyWith(color: AppColors.secondaryText),
            overflow: TextOverflow.ellipsis,
            textDirection: TextDirection.rtl,
          ),
        ),
      ],
    ),
  );

  Widget _readFieldWithStatus(String label, String value, bool status) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: StyleText.fontSize12Weight500.copyWith(color: AppColors.text)),
          Row(mainAxisSize: MainAxisSize.min, children: [
            Text('Status: ', style: StyleText.fontSize11Weight400.copyWith(color: AppColors.text)),
            Container(
              width: 32.w, height: 18.h,
              decoration: BoxDecoration(
                color: status ? ColorPick.primary : Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Align(
                alignment: status ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 14.w, height: 14.h,
                  margin: EdgeInsets.symmetric(horizontal: 2.w),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                ),
              ),
            ),
          ]),
        ],
      ),
      SizedBox(height: 4.h),
      Container(
        width: double.infinity, height: 36.h,
        padding: EdgeInsets.symmetric(horizontal: 15.w), // BUG-158: one inset
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(4.r)),
        alignment: Alignment.centerLeft,
        child: Text(
          value.isEmpty ? 'Text Here' : value,
          style: StyleText.fontSize12Weight400.copyWith(color: AppColors.secondaryText),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );

  Widget _colorReadField(String label, String hex) {
    Color color;
    try {
      final clean = hex.replaceAll('#', '');
      color = clean.length == 6
          ? Color(int.parse('FF$clean', radix: 16))
          : Colors.grey.shade300;
    } catch (_) {
      color = Colors.grey.shade300;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: StyleText.fontSize14Weight500.copyWith(color: AppColors.text)),
        SizedBox(height: 4.h),
        Container(
          height: 36.h,
          padding: EdgeInsets.symmetric(horizontal: 15.w), // BUG-158: one inset
          decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(4.r)),
          child: Row(children: [
            Container(
              width: 14.w, height: 14.h,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            SizedBox(width: 8.w),
            Text(hex.isEmpty ? '#D9D9D9' : hex,
                style: StyleText.fontSize12Weight400.copyWith(color: AppColors.secondaryText)),
          ]),
        ),
      ],
    );
  }

  String _ord(int n) {
    if (n == 1) return 'st';
    if (n == 2) return 'nd';
    if (n == 3) return 'rd';
    return 'th';
  }
}
