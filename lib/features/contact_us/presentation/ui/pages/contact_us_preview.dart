// ******************* FILE INFO *******************
// File Name: contact_us_preview.dart
// Created by: Claude Assistant

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';

import 'package:web_app_admin/core/widget/network_image_view.dart';
import '../../../../../core/constant/color.dart';
import '../../../../../core/main_widgets/admin_sticky_body.dart';
import '../../../../../core/main_widgets/admin_back_link.dart';
import '../../../../../core/main_widgets/admin_sub_navbar.dart';
import '../../../../../core/main_widgets/app_footer.dart';
import '../../../../../core/two_tab.dart';
import '../../../../../core/theme/appcolors.dart';
import '../../../../../core/theme/new_theme.dart';
import '../../../data/models/contact_us_model_location.dart';
import '../../controller/contact_us_location_cubit.dart';
import '../../controller/contact_us_location_state.dart';
import 'package:web_app_admin/core/custom/circle_progress.dart';
import 'package:web_app_admin/core/main_widgets/app_admin_navbar.dart';
import 'package:web_app_admin/features/careers/presentation/ui/pages/careers_main.dart';
import 'package:web_app_admin/features/main/presentation/ui/pages/main_main.dart';
import 'package:web_app_admin/features/job/presentation/ui/pages/job_listing_main.dart';

part '../widgets/contact_us_preview/preview_view.dart';
part '../widgets/contact_us_preview/desktop_preview.dart';
part '../widgets/contact_us_preview/mobile_preview.dart';
part '../widgets/contact_us_preview/info_card.dart';
part '../widgets/contact_us_preview/mobile_info_card.dart';
part '../widgets/contact_us_preview/form_placeholder.dart';
part '../widgets/contact_us_preview/office_card.dart';
part '../widgets/contact_us_preview/office_card_mobile.dart';
part '../widgets/contact_us_preview/social_icon_scaled.dart';
part '../widgets/contact_us_preview/social_icon_raw.dart';

// const Color ColorPick.primary      = Color(0xFF2D8C4E);
// const Color ColorPick.primaryLight = Color(0xFFE8F5EE);
// const Color _kDivider    = Color(0xFFDDE8DD);

// ═══════════════════════════════════════════════════════════════════════════════
// PAGE
// ═══════════════════════════════════════════════════════════════════════════════

class ContactUsCmsPreviewPage extends StatelessWidget {
  const ContactUsCmsPreviewPage({super.key, this.draft});

  /// BUG-53: the model being edited. When given, the preview shows these
  /// unsaved edits; without it (opened from the Contact Us tab) it shows what
  /// is published.
  final ContactUsCmsModel? draft;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = ContactUsCmsCubit();
        if (draft != null) {
          cubit.showDraft(draft!);
        } else {
          cubit.load();
        }
        return cubit;
      },
      child: _PreviewView(isDraft: draft != null), // admin-only preview
    );
  }
}

