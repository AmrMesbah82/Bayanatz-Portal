/// ******************* FILE INFO *******************
/// File Name: home_main.dart
/// Pages 1–3 — Read-only overview (Figma screens 1, 2, 3)
/// Sub-navbar: Main | Home(active) | Services | About Us | Contact Us | Careers
///
/// UPDATED: Status tabs are now driven by what actually exists. "Published" is
///          always there; "Scheduled" and "Draft" appear only once a scheduled
///          release or a draft has been saved, and disappear again when they
///          are removed or published.
/// UPDATED: Each tab renders ITS OWN stored version — the three documents are
///          loaded together, so switching tabs shows genuinely different data
///          instead of the same model filtered by publishStatus.
/// UPDATED: A "Remove" button sits top-right while a removable version is
///          selected, behind a confirm dialog.
/// UPDATED: TabController replaced by a plain slot selector — the tab count is
///          no longer fixed at three.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui' as ui;
import 'package:web_app_admin/core/widget/navigator.dart';
import 'package:web_app_admin/core/widget/network_image_view.dart';

import '../../../../../core/constant/color.dart';
import '../../../../../core/custom_dialog.dart';
import '../../../../../core/widget/branding_helper.dart';
import '../../../../../core/custom_svg.dart';
import '../../../../../core/main_widgets/admin_page_scaffold.dart';
import '../../../../../core/main_widgets/admin_sub_navbar.dart';
import '../../../../../core/main_widgets/app_admin_navbar.dart';
import '../../../../../core/theme/appcolors.dart';
import '../../../../../core/theme/new_theme.dart';
import '../../../../careers/presentation/ui/pages/careers_main.dart';
import '../../../../job/presentation/ui/pages/job_listing_main.dart';
import '../../../../main/presentation/ui/pages/main_main.dart';
import '../../../../services/presentation/ui/pages/services_main/services_main.dart';
import '../../../data/models/home_model.dart';
import '../../controller/home_cubit.dart';
import '../../controller/home_state.dart';
import 'home_edit.dart';
import 'home_preview.dart';
import '../../../../../core/custom/3-custom_accordion.dart';
import 'package:web_app_admin/core/custom/circle_progress.dart';

part '../widgets/home_main/home_main_builders.dart';
part '../widgets/home_main/home_main_read_only.dart';

/// Available route labels for display in the read-only view.
/// Mirrors the "Navigate To" destinations (_kLabelDestinations) so saved
/// routes render with the same labels shown in the edit dropdown. Legacy
/// top-level routes are kept so previously saved buttons still display.
const Map<String, String> _kRouteLabelMap = {
  // Navigate To destinations
  '/about?tab=our-strategy':         'Our Strategy',
  '/about?tab=terms-and-conditions': 'Terms and Conditions',
  '/about?tab=privacy-policy':       'Privacy Policy',
  '/about?tab=vision':               'Vision',
  '/about?tab=mission':              'Mission',
  '/about?tab=values':               'Values',
  '/careers?tab=why-join-our-team':  'Why Join Our Team',
  '/careers?tab=interns':            'Our Interns',
  '/careers?tab=our-team':           'Our Team',
  '/contact':                        'Contact Form',
  // Legacy top-level routes (previously saved buttons)
  '/':         'Home',
  '/services': 'Services',
  '/about':    'About',
  '/careers':  'Careers',
};

// ─────────────────────────────────────────────────────────────────────────────
class HomeMainPageMaster extends StatefulWidget {
  const HomeMainPageMaster({super.key});
  @override
  State<HomeMainPageMaster> createState() => _HomeMainPageMasterState();
}

class _HomeMainPageMasterState extends State<HomeMainPageMaster> {
  int _subNavIndex = 1; // "Home" tab is active
  final List<String> _subNavLabels = [
    'Main', 'Home', 'Services', 'About Us', 'Contact Us', 'Careers'
  ];

  /// Which stored version the overview is showing.
  HomeVersionSlot _activeSlot = HomeVersionSlot.published;

  @override
  void initState() {
    super.initState();

    // Re-load when this page is created (e.g. after navigating back from the
    // editor) so the tabs always reflect what is actually stored.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeCmsCubit>().load();
    });
  }

  final Map<String, bool> _open = {
    'headings':   true,
    'navButtons': true,
    'navBtn':     true,
    's1': true, 's2': true, 's3': true, 's4': true,
  };

  Color _hexColor(String hex) {
    try {
      final c = hex.replaceAll('#', '');
      if (c.length == 6) return Color(int.parse('FF$c', radix: 16));
    } catch (_) {}
    return ColorPick.primary;
  }

  // ── Remove the selected version ─────────────────────────────────────────
  void _confirmRemove(HomeCmsCubit cubit, HomeVersionSlot slot) {
    final bool isDraft = slot == HomeVersionSlot.draft;
    showConfirmDialog(
      context: context,
      title: isDraft ? 'REMOVE DRAFT' : 'REMOVE SCHEDULED VERSION',
      subtitle: isDraft
          ? 'This deletes the saved draft. The published page stays live and '
              'unchanged. This cannot be undone.'
          : 'This cancels the scheduled release. The published page stays live '
              'and unchanged. This cannot be undone.',
      confirmLabel: 'Remove',
      cancelLabel: 'Cancel',
      onConfirm: () {
        if (isDraft) {
          cubit.removeDraft();
        } else {
          cubit.removeScheduled();
        }
        setState(() => _activeSlot = HomeVersionSlot.published);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HomeCmsCubit, HomeCmsState>(
      listener: (context, state) {
        // A slot was removed — reload so the tabs drop it.
        if (state is HomeCmsDraftDeleted || state is HomeCmsScheduledDeleted) {
          context.read<HomeCmsCubit>().load();
        }
      },
      builder: (context, state) {
        final cubit = context.read<HomeCmsCubit>();

        if (state is HomeCmsInitial ||
            state is HomeCmsLoading ||
            state is HomeCmsDraftDeleted ||
            state is HomeCmsScheduledDeleted) {
          return const Scaffold(
            backgroundColor: ColorPick.background,
            body: Center(child: CircleProgress()),
          );
        }

        // Which tabs exist right now.
        final slots = <HomeVersionSlot>[
          HomeVersionSlot.published,
          if (cubit.hasScheduled) HomeVersionSlot.scheduled,
          if (cubit.hasDraft)     HomeVersionSlot.draft,
        ];

        // The selected tab may have just been removed or published away.
        if (!slots.contains(_activeSlot)) {
          _activeSlot = HomeVersionSlot.published;
        }

        // The two top bars stay pinned — only _body scrolls beneath them.
        return AdminPageScaffold(
          activeLabel:    'Web Page',
          homePage:       CareersMainPageDashboard(),
          webPage:        MainMainPage(),
          jobListingPage: JobListingMainPage(),
          subNavIndex:    1,
          homeCubit:      cubit,
          child: _body(cubit, slots),
        );
      },
    );
  }
}
