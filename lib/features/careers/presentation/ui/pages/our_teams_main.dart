// ******************* FILE INFO *******************
// File Name: our_teams_main.dart
// View-only section for "Our Teams" tab inside CareersMainPageMaster.
// Mirrors the style of _sectionBody / _mainBody in careers_main_page.dart.
// Usage inside CareersMainPageMaster:
//   _careersTab == 3 → OurTeamsViewPage()
//
// Wrap with BlocProvider<OurTeamsCubit> at the call-site, e.g.:
//   BlocProvider(
//     create: (_) => OurTeamsCubit()..load(),
//     child: const OurTeamsViewPage(),
//   )

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:web_app_admin/core/widget/network_image_view.dart';
import '../../../../../core/constant/color.dart';
import '../../../../../core/custom_svg.dart';
import '../../../../../core/theme/appcolors.dart';
import '../../../../../core/theme/new_theme.dart';
import '../../../data/models/our_teams_model.dart';
import '../../controller/our_teams_cubit.dart';
import '../../controller/our_teams_state.dart';
import 'our_teams_edit.dart';
import 'our_teams_preview.dart';
import '../../../../../core/custom/3-custom_accordion.dart';
import 'package:web_app_admin/core/custom/circle_progress.dart';


// class _C {
//   static const Color primary   = Color(0xFF008037);
//   static const Color sectionBg = Color(0xFFF5F5F5);
//   static const Color cardBg    = Color(0xFFFFFFFF);
//   static const Color labelText = Color(0xFF333333);
//   static const Color hintText  = Color(0xFFAAAAAA);
// }

// ═══════════════════════════════════════════════════════════════════════════════
class OurTeamsViewPage extends StatefulWidget {
  const OurTeamsViewPage({super.key});

  @override
  State<OurTeamsViewPage> createState() => _OurTeamsViewPageState();
}

class _OurTeamsViewPageState extends State<OurTeamsViewPage> {
  bool _accordionOpen = true;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OurTeamsCubit, OurTeamsState>(
      builder: (context, state) {
        if (state is OurTeamsInitial || state is OurTeamsLoading) {
          return const Center(
            child: CircleProgress(),
          );
        }

        OurTeamsModel? data;
        if (state is OurTeamsLoaded) data = state.data;
        if (state is OurTeamsSaved)  data = state.data;

        if (data == null) {
          return const Center(
            child: CircleProgress(),
          );
        }

        final cubit = context.read<OurTeamsCubit>();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [


            // ── Last updated + Edit Details ───────────────────────────────────
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 14.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color:        ColorPick.white,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    data.lastUpdated != null
                        ? 'Last Updated On ${_formatDate(data.lastUpdated!)}'
                        : 'Last Updated On —',
                    style: StyleText.fontSize13Weight500
                        .copyWith(color: ColorPick.primary),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BlocProvider.value(
                        value: cubit,
                        child: const OurTeamsEditPage(),
                      ),
                    ),
                  ),
                  child: Container(
                    width: 130.w,
                    height: 36.h,
                    decoration: BoxDecoration(
                      color:        ColorPick.white,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Edit Details',
                            style: StyleText.fontSize14Weight500
                                .copyWith(color: Colors.black),
                          ),
                          SizedBox(width: 6.w),
                          CustomSvg(
                            assetPath: 'assets/control/edit_icon_pick.svg',
                            width:     20.w,
                            height:    20.h,
                            fit:       BoxFit.scaleDown,
                            color:     ColorPick.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // ── Accordion ─────────────────────────────────────────────────────
            _accordion(
              title:   'Our Team', // BUG-143
              isOpen:  _accordionOpen,
              onToggle: () =>
                  setState(() => _accordionOpen = !_accordionOpen),
              children: [
                // ── Section header (icon + title) — matches edit design ──────
                _headerView(data),
                if (data.items.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 40.h),
                    alignment: Alignment.center,
                    child: SvgPicture.asset(
                      'assets/images/null.svg',
                      width: 200.w,
                      height: 200.h,
                    ),
                  )
                else
                  ...data.items.asMap().entries.map(
                        (e) => _teamItemView(e.key, e.value),
                  ),
              ],
            ),
            SizedBox(height: 40.h),
          ],
        );
      },
    );
  }

  // ── Section header view (icon + title) — mirrors the edit page ──────────────
  Widget _headerView(OurTeamsModel data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 12.h),
        Text('Icon',
            style: StyleText.fontSize12Weight500
                .copyWith(color: AppColors.text)),
        SizedBox(height: 6.h),
        _iconCircle(data.headerIconUrl),
        SizedBox(height: 14.h),
        Row(children: [
          Expanded(child: _readField('Title', data.headerTitle.en)),
          SizedBox(width: 16.w),
          Expanded(child: _readFieldRtl('العنوان', data.headerTitle.ar)),
        ]),
        SizedBox(height: 14.h),
        Divider(color: const Color(0xFFE8E8E8), height: 1),
      ],
    );
  }

  // ── Single team item view ───────────────────────────────────────────────────
  Widget _teamItemView(int index, OurTeamItem item) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Icon
          Text('Icon',
              style: StyleText.fontSize12Weight500
                  .copyWith(color: AppColors.text)),
          SizedBox(height: 6.h),
          _iconCircle(item.iconUrl),
          SizedBox(height: 14.h),

          // Title EN / AR
          Row(children: [
            Expanded(child: _readField('Title', item.title.en)),
            SizedBox(width: 16.w),
            Expanded(child: _readFieldRtl('العنوان', item.title.ar)),
          ]),
          SizedBox(height: 14.h),

          // Description EN
          _readField('Description', item.description.en, height: 80),
          SizedBox(height: 8.h),

          // الوصف AR
          _readFieldRtl('الوصف', item.description.ar, height: 80),
          SizedBox(height: 14.h),

          // Deliverables EN / AR
          Row(children: [
            Expanded(
                child: _readField('Deliverables', item.deliverables.en)),
            SizedBox(width: 16.w),
            Expanded(
                child: _readFieldRtl(
                    'المخرجات', item.deliverables.ar)),
          ]),


          SizedBox(height: 16.h),
        ],
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────
  Widget _iconCircle(String url) {
    return NetworkImageView.circle(url: url, diameter: 60.w);
  }

  Widget _deliverableChip(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color:        const Color(0xFFE8F5EE),
        borderRadius: BorderRadius.circular(4.r),
        border:       Border.all(color: ColorPick.primary.withValues(alpha: 0.3)),
      ),
      child: Text(
        text.isEmpty ? '—' : text,
        style: StyleText.fontSize11Weight400.copyWith(color: ColorPick.primary),
      ),
    );
  }

  Widget _accordion({
    required String       title,
    required bool         isOpen,
    required VoidCallback onToggle,
    required List<Widget> children,
  }) {
    return CustomAccordion(
      title:    title,
      isOpen:   isOpen,
      onToggle: onToggle,
      child:    Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _readField(String label, String value, {double height = 36}) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: StyleText.fontSize12Weight500
                  .copyWith(color: AppColors.text)),
          SizedBox(height: 4.h),
          Container(
            width:   double.infinity,
            height:  height.h,
            padding: EdgeInsets.symmetric(
                horizontal: 10.w, vertical: height > 36 ? 8.h : 0),
            decoration: BoxDecoration(
              color:        Colors.white,
              borderRadius: BorderRadius.circular(4.r),
            ),
            alignment: height > 36 ? Alignment.topLeft : Alignment.centerLeft,
            child: Text(
              value.isEmpty ? 'Text Here' : value,
              style: StyleText.fontSize12Weight400
                  .copyWith(color: AppColors.secondaryText),
              maxLines: height > 36 ? 5 : 1,
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
              width:   double.infinity,
              height:  height.h,
              padding: EdgeInsets.symmetric(
                  horizontal: 10.w, vertical: height > 36 ? 8.h : 0),
              decoration: BoxDecoration(
                color:        Colors.white,
                borderRadius: BorderRadius.circular(4.r),
              ),
              alignment:
              height > 36 ? Alignment.topRight : Alignment.centerRight,
              child: Text(
                value.isEmpty ? 'أكتب هنا' : value,
                style: StyleText.fontSize12Weight400
                    .copyWith(color: AppColors.secondaryText),
                textDirection: TextDirection.rtl,
                maxLines:      height > 36 ? 5 : 1,
                overflow:      TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );

  String _formatDate(DateTime dt) =>
      '${dt.day} ${_monthName(dt.month)} ${dt.year}';

  String _monthName(int m) => const [
    '',  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ][m];
}