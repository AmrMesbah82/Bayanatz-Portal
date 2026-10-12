// ******************* FILE INFO *******************
// File Name: services_main_page_master.dart
// Screen 1 — Services CMS: Main tab list page
// Status tabs: Main | Cards | Important Reads
// Main tab            → Headings accordion
// Cards tab           → DJ accordion with subtitle + journey items grid
// Important Reads tab → Blog posts card grid with filter tabs + search
// FIXED: _lastUpdatedRow now shows dynamic date from model (not static)
// FIXED: Preview Screen button hidden on Important Reads tab
// FIXED: Tab bar restyled to match job_listing_detail_page pattern
// DEBUG: Added comprehensive logging for blog post loading/filtering

import 'dart:async';
import 'dart:typed_data';
import 'dart:html' as html; // Flutter Web only

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:web_app_admin/core/constant/color.dart';
import 'package:web_app_admin/core/widget/format.dart';
import 'package:web_app_admin/core/widget/network_image_view.dart';
import 'package:web_app_admin/features/services/presentation/ui/pages/services_main/services_edit.dart';
import 'package:web_app_admin/features/services/presentation/ui/pages/services_main/services_preview.dart';

import '../../../../../../core/custom/2-custom_textfield.dart';
import '../../../../../../core/custom_dialog.dart'; // BUG-92: shared confirm dialog
import '../../../../../../core/custom_svg.dart';
import '../../../../../../core/main_widgets/admin_sticky_body.dart';
import '../../../../../../core/main_widgets/admin_sub_navbar.dart';
import '../../../../../../core/main_widgets/cms_sub_tabs.dart';
import '../../../../../../core/main_widgets/app_admin_navbar.dart';
import '../../../../../../core/theme/appcolors.dart';
import '../../../../../../core/theme/new_theme.dart';
import '../../../../../careers/presentation/ui/pages/careers_main.dart';
import '../../../../../job/presentation/ui/pages/job_listing_main.dart';
import '../../../../../main/presentation/ui/pages/main_main.dart';
import '../../../../data/models/blog_model.dart';
import '../../../../data/models/services_model.dart';
import '../../../controller/blog_cubit.dart';
import '../../../controller/blog_state.dart';
import '../../../controller/services_cubit.dart';
import '../../../controller/services_state.dart';
import '../blog_services/blog_edit.dart';
import '../digital_services/services_digital_layout.dart';
import '../digital_services/services_digital_main.dart';
import '../digital_services/services_digital_preview.dart';
import '../../../../../../core/custom/3-custom_accordion.dart';
import 'package:web_app_admin/core/custom/circle_progress.dart';

part '../../widgets/services_main/blog_card.dart';
part '../../widgets/services_main/xhr_image.dart';
part '../../widgets/services_main/services_main_tabs.dart';
part '../../widgets/services_main/services_main_helpers.dart';

// class _C {
//   static const Color primary    = Color(0xFF008037);
//   static const Color sectionBg  = Color(0xFFF5F5F5);
//   static const Color cardBg     = Color(0xFFFFFFFF);
//   static const Color border     = Color(0xFFDDE8DD);
//   static const Color labelText  = Color(0xFF333333);
//   static const Color hintText   = Color(0xFFAAAAAA);
//   static const Color greenLight = Color(0xFFE8F5EE);
//   static const Color back       = Color(0xFFF1F2ED);
//
//   // status badge colors
//   static const Color activeColor   = Color(0xFF008037);
//   static const Color inactiveColor = Color(0xFFFF8C00);
//   static const Color draftColor    = Color(0xFF666666);
//   static const Color removedColor  = Color(0xFFCC0000);
// }

// ── Blog status enum ──────────────────────────────────────────────────────────
enum _PostStatus { all, posted, inactive, draft, removed }

extension _PostStatusLabel on _PostStatus {
  String get label => switch (this) {
    _PostStatus.all      => 'All',
    _PostStatus.posted   => 'Posted',
    _PostStatus.inactive => 'Inactive',
    _PostStatus.draft    => 'Draft',
    _PostStatus.removed  => 'Removed',
  };

  /// Maps to the BlogPostModel.status string values
  String? get statusKey => switch (this) {
    _PostStatus.all      => null,
    _PostStatus.posted   => 'published',
    _PostStatus.inactive => 'inactive',
    _PostStatus.draft    => 'draft',
    _PostStatus.removed  => 'removed',
  };
}

// ─────────────────────────────────────────────────────────────────────────────

class ServicesMainPageMaster extends StatefulWidget {
  const ServicesMainPageMaster({super.key});

  @override
  State<ServicesMainPageMaster> createState() => _ServicesMainPageMasterState();
}

class _ServicesMainPageMasterState extends State<ServicesMainPageMaster> {
  // ── Status tabs ────────────────────────────────────────────────────────────
  int _statusIndex = 0;
  final List<String> _statusLabels = ['Main', 'Cards', 'Important Reads'];

  // ── Accordion open state ────────────────────────────────────────────────
  final Map<String, bool> _open = {
    'headings':       true,
    'digitalJourney': true,
  };

  // ── Important Reads sub-state ──────────────────────────────────────────────
  _PostStatus                _activeFilter = _PostStatus.all;
  final TextEditingController _searchCtrl  = TextEditingController();
  String                     _searchQuery  = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.toLowerCase().trim());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ServiceCmsCubit>().load();
      context.read<BlogCubit>().load();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

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
    return BlocBuilder<ServiceCmsCubit, ServiceCmsState>(
      builder: (context, state) {
        if (state is ServiceCmsLoading) {
          return const Scaffold(
            backgroundColor: ColorPick.background,
            body: Center(child: CircleProgress()),
          );
        }

        final ServicePageModel model = switch (state) {
          ServiceCmsLoaded s => s.data,
          ServiceCmsSaved  s => s.data,
          _                  => ServicePageModel.empty(),
        };

        return Scaffold(
          backgroundColor: ColorPick.background,
          body: AdminStickyBody(
  children: [
                  AppAdminNavbar(
                    activeLabel:     'Web Page',
                    homePage:       CareersMainPageDashboard(),
                    webPage:        MainMainPage(),
                    jobListingPage: JobListingMainPage(),
                  ),
                  SizedBox(height: 20.h),
                  AdminSubNavBar(activeIndex: 2),
                  SizedBox(
                    width: 1000.w,
                    child: _body(model),
                  ),
                ],
),
        );
      },
    );
  }

  // ── Preview button handler — respects the active tab ───────────────────────
  //
  // All three tabs open the real public Services page from package:website_app,
  // READ-ONLY (showSave: false). The Digital Journey tab opens it through its
  // own preview screen so the heading matches the tab; Save stays on the edit
  // screens.
  void _onPreviewTap(ServicePageModel model) {
    final cubit = context.read<ServiceCmsCubit>();

    late final Widget page;
    switch (_statusIndex) {
      case 1:
        page = ServicesDigitalJourneyPreviewPage(
          model:    model,
          showSave: false,
          title:    'Preview Digital Journey Details',
        );
      case 2:
        page = ServicesMainPreviewPage(
          model:    model,
          showSave: false,
          title:    'Preview Important Reads Details',
        );
      default:
        page = ServicesMainPreviewPage(
          model:    model,
          showSave: false,
          title:    'Preview Services Details',
        );
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(value: cubit, child: page),
      ),
    );
  }

  // ── Page body ──────────────────────────────────────────────────────────────
  Widget _body(ServicePageModel model) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Title + Preview Screen ───────────────────────────────────────
        Row(
          children: [
            Text('Services',
              style: StyleText.fontSize45Weight600.copyWith(
                color: ColorPick.primary, fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            // Every tab previews the REAL public Services page, read-only:
            // this button shows what is already live, so it carries no Save.
            GestureDetector(
                onTap: () => _onPreviewTap(model),
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

        // ── ✅ FIX 3: Tab bar — job_listing_detail_page style ────────────
        _buildTabBar(),
        SizedBox(height: 12.h),

        // ── Tab content ──────────────────────────────────────────────────
        if (_statusIndex == 0) _mainTab(model),
        if (_statusIndex == 1) _digitalJourneyTab(model),
        if (_statusIndex == 2) _readMoreTab(),

        SizedBox(height: 40.h),
      ],
    );
  }

}

// ══════════════════════════════════════════════════════════════════════════════
// BLOG CARD  (matches Figma card in the grid)
// ══════════════════════════════════════════════════════════════════════════════
