// ******************* FILE INFO *******************
// File Name: contact_us_main.dart
// UPDATED: Dynamic last-updated date from model.lastUpdatedAt (no more hardcoded string)

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constant/color.dart';
import '../../../../../core/custom_svg.dart';
import 'package:web_app_admin/core/widget/network_image_view.dart';
import '../../../../../core/main_widgets/admin_sticky_body.dart';
import '../../../../../core/main_widgets/admin_sub_navbar.dart';
import '../../../../../core/main_widgets/app_admin_navbar.dart';
import '../../../../../core/theme/appcolors.dart';
import '../../../../../core/theme/new_theme.dart';
import '../../../../main/presentation/ui/pages/main_main.dart';
import '../../../data/models/contact_us_model_location.dart';
import '../../controller/contact_us_location_cubit.dart';
import '../../controller/contact_us_location_state.dart';
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

// ═══════════════════════════════════════════════════════════════════════════════
// CONTACT US MAIN PAGE
// ═══════════════════════════════════════════════════════════════════════════════

class ContactUsMainPage extends StatefulWidget {
  const ContactUsMainPage({super.key});

  @override
  State<ContactUsMainPage> createState() => _ContactUsMainPageState();
}

class _ContactUsMainPageState extends State<ContactUsMainPage> {
  int _subNavIndex = 4;
  final List<String> _subNavLabels = [
    'Main', 'Home', 'Services', 'About Us', 'Contact Us', 'Careers'
  ];

  final Map<String, bool> _open = {
    'info':     true,
    'followUs': true,
    'offices':  true,
    'confirm':  true,
  };

  // ── Date formatter ─────────────────────────────────────────────────────────
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
    return BlocBuilder<ContactUsCmsCubit, ContactUsCmsState>(
      builder: (context, state) {
        if (state is ContactUsCmsInitial || state is ContactUsCmsLoading) {
          return const Scaffold(
            backgroundColor: ColorPick.background,
            body: Center(child: CircleProgress()),
          );
        }

        ContactUsCmsModel? data;
        if (state is ContactUsCmsLoaded) data = state.data;
        if (state is ContactUsCmsSaved)  data = state.data;

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
                  AdminSubNavBar(activeIndex: 4),
                  Container(
                    width: 1000.w,
                    child: data == null
                        ? const Center(
                        child: CircleProgress())
                        : _body(data),
                  ),
                ],
),
        );
      },
    );
  }

  // ── Body ───────────────────────────────────────────────────────────────────
  Widget _body(ContactUsCmsModel data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Title + Preview Screen ─────────────────────────────────────────
        Row(
          children: [
            Text(
              'Contact Us',
              style: StyleText.fontSize45Weight600.copyWith(
                color: ColorPick.primary, fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => context.push('/admin/contact-cms/preview'),
              // BUG-155: same 130.w × 36.h as the other Web Page tabs.
              child: Container(
                width: 130.w,
                height: 36.h,
                decoration: BoxDecoration(
                  color: ColorPick.primary,
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Center(
                  child: Text('Preview Screen',
                      style: StyleText.fontSize14Weight500
                          .copyWith(color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 14.h),

        // ── Last Updated + Edit ────────────────────────────────────────────
        Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: ColorPick.white,
                borderRadius: BorderRadius.circular(4.r),
              ),
              // ── FIXED: dynamic date from model.lastUpdatedAt ──
              child: Text(
                'Last Updated On ${_fmtDate(data.lastUpdatedAt)}',
                style: StyleText.fontSize13Weight500
                    .copyWith(color: ColorPick.primary),
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => context.push('/admin/contact-cms/edit'),
              child: Container(
                width: 130.w, height: 36.h, // BUG-155
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Center(
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('Edit Details',
                        style: StyleText.fontSize14Weight500
                            .copyWith(color: Colors.black)),
                    SizedBox(width: 6.w),
                    CustomSvg(
                        assetPath: "assets/control/edit_icon_pick.svg",
                        width: 20.w, height: 20.h,
                        fit: BoxFit.scaleDown, color: ColorPick.primary),
                  ]),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),

        // ── Info Section ───────────────────────────────────────────────────
        _accordion(
          key: 'info',
          title: 'Info',
          children: [
            SizedBox(height: 15.h),
            _readField('Short Description', /* BUG-157 */ data.subDescription.en,height: 72.h),
            SizedBox(height: 10.h),
            _readFieldRtl('وصف فرعي', data.subDescription.ar,height: 72.h),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(child: _readField('Email', data.email)),
                SizedBox(width: 16.w),
                const Expanded(child: SizedBox()),
              ],
            ),
          ],
        ),
        SizedBox(height: 10.h),

        // ── Follow Us Section ──────────────────────────────────────────────
        _accordion(
          key: 'followUs',
          title: 'Follow Us',
          children: [
            SizedBox(height: 15.h),
            if (data.socialIcons.isEmpty)
              Text('No social icons added',
                  style: StyleText.fontSize12Weight400
                      .copyWith(color: AppColors.secondaryText))
            else
              _socialIconsGrid(data.socialIcons),
          ],
        ),
        SizedBox(height: 10.h),

        // ── Office Locations ───────────────────────────────────────────────
        _accordion(
          key: 'offices',
          title: 'Office Locations',
          children: [
            SizedBox(height: 15.h),
            if (data.officeLocations.isEmpty)
              Text('No office locations added',
                  style: StyleText.fontSize12Weight400
                      .copyWith(color: AppColors.secondaryText))
            else
              ...data.officeLocations.asMap().entries.map((e) {
                return Padding(
                  padding: EdgeInsets.only(bottom: 16.h),
                  child: _officeLocationItem(e.value, e.key),
                );
              }),
          ],
        ),
        SizedBox(height: 10.h),

        // ── Confirm Message ────────────────────────────────────────────────
        _accordion(
          key: 'confirm',
          title: 'Confirm Message',
          children: [
            SizedBox(height: 15.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SVG',
                        style: StyleText.fontSize12Weight500
                            .copyWith(color: AppColors.text)),
                    SizedBox(height: 6.h),
                    _imgCircle(data.confirmMessage.svgUrl, isSvg: true),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(child: _readField(
                    'Title', data.confirmMessage.title.en)),
                SizedBox(width: 16.w),
                Expanded(child: _readFieldRtl(
                    'العنوان', data.confirmMessage.title.ar)),
              ],
            ),
            SizedBox(height: 10.h),
            _readField('Description',
                data.confirmMessage.description.en, height: 80),
            SizedBox(height: 10.h),
            _readFieldRtl('الوصف',
                data.confirmMessage.description.ar, height: 80),
          ],
        ),
        SizedBox(height: 40.h),
      ],
    );
  }

  // ── Social Icons Grid (2 per row) ──────────────────────────────────────────
  Widget _socialIconsGrid(List<ContactSocialIcon> icons) {
    final rows = (icons.length / 2).ceil();
    return Column(
      children: List.generate(rows, (rowIndex) {
        final left  = rowIndex * 2;
        final right = left + 1;
        return Padding(
          padding: EdgeInsets.only(bottom: 14.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _socialIconItem(icons[left])),
              SizedBox(width: 16.w),
              right < icons.length
                  ? Expanded(child: _socialIconItem(icons[right]))
                  : const Expanded(child: SizedBox()),
            ],
          ),
        );
      }),
    );
  }

  Widget _socialIconItem(ContactSocialIcon icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 15.h),
        Text('Icon',
            style: StyleText.fontSize12Weight500.copyWith(color: AppColors.text)),
        SizedBox(height: 6.h),
        _imgCircle(icon.iconUrl),
        SizedBox(height: 8.h),
        _readField('Selected Link',
            icon.link.isEmpty ? 'Insert Links' : icon.link),
      ],
    );
  }

  // ── Office Location Item ───────────────────────────────────────────────────
  Widget _officeLocationItem(ContactOfficeLocation office, int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Location ${index + 1}',
            style: StyleText.fontSize13Weight600.copyWith(color: AppColors.text)),
        SizedBox(height: 8.h),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Icon',
                    style: StyleText.fontSize12Weight500
                        .copyWith(color: AppColors.text)),
                SizedBox(height: 6.h),
                _imgCircle(office.iconUrl),
              ],
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(child: _readField(
                'Location Name', office.locationName.en)),
            SizedBox(width: 16.w),
            Expanded(child: _readFieldRtl(
                'اسم الموقع', office.locationName.ar)),
          ],
        ),
        SizedBox(height: 10.h),
        Row(
          children: [
            Expanded(child: _readField('Text', office.text1.en)),
            SizedBox(width: 16.w),
            Expanded(child: _readFieldRtl('النص', office.text1.ar)),
          ],
        ),
      ],
    );
  }

  // ── Image Circle ───────────────────────────────────────────────────────────
  Widget _imgCircle(String url, {bool isSvg = false}) {
    return NetworkImageView.circle(url: url, diameter: 60.w);
  }

  // ── Accordion ──────────────────────────────────────────────────────────────
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

  // ── Read Field ─────────────────────────────────────────────────────────────
  Widget _readField(String label, String value, {double height = 36}) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: StyleText.fontSize12Weight500.copyWith(color: AppColors.text)),
          SizedBox(height: 4.h),
          Container(
            width: double.infinity, height: height.h,
            padding: EdgeInsets.symmetric(
                horizontal: 10.w, vertical: height > 36 ? 8.h : 0),
            decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(4.r)),
            alignment: height > 36 ? Alignment.topLeft : Alignment.centerLeft,
            child: Text(
              value.isEmpty ? 'Text Here' : value,
              style: StyleText.fontSize12Weight400.copyWith(color: AppColors.secondaryText),
              maxLines: height > 36 ? 4 : 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );

  Widget _readFieldRtl(String label, String value, {double height = 36}) =>
      Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: StyleText.fontSize12Weight500
                    .copyWith(color: AppColors.text)),
            SizedBox(height: 4.h),
            Container(
              width: double.infinity, height: height.h,
              padding: EdgeInsets.symmetric(
                  horizontal: 10.w, vertical: height > 36 ? 8.h : 0),
              decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(4.r)),
              alignment:
              height > 36 ? Alignment.topRight : Alignment.centerRight,
              child: Text(
                value.isEmpty ? 'أكتب هنا' : value,
                style: StyleText.fontSize12Weight400.copyWith(color: AppColors.secondaryText),
                textDirection: TextDirection.rtl,
                maxLines: height > 36 ? 4 : 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
}