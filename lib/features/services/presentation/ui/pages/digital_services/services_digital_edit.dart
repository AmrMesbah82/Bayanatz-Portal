// ******************* FILE INFO *******************
// File Name: services_digital_edit.dart
// Screen 4 — Services CMS: Digital Journey tab list page
// Shows subtitle + all journey item cards with edit button
// Navigates to: ServicesDigitalJourneyEditPage (screen 5/6)

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:web_app_admin/core/widget/network_image_view.dart';
import '../../../../../../core/constant/color.dart';
import '../../../../../../core/theme/appcolors.dart';
import '../../../../../../core/theme/text.dart';
import '../../../../data/models/services_model.dart';
import '../../../controller/services_cubit.dart';
import '../../../controller/services_state.dart';
import 'services_digital_main.dart';
import 'package:web_app_admin/core/custom/circle_progress.dart';

part '../../widgets/services_digital_edit/d_j_section_card.dart';
part '../../widgets/services_digital_edit/journey_grid.dart';
part '../../widgets/services_digital_edit/journey_mini_card.dart';

class ServicesDigitalJourneyPage extends StatefulWidget {
  const ServicesDigitalJourneyPage({super.key});

  @override
  State<ServicesDigitalJourneyPage> createState() =>
      _ServicesDigitalJourneyPageState();
}

class _ServicesDigitalJourneyPageState
    extends State<ServicesDigitalJourneyPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ServiceCmsCubit>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ServiceCmsCubit, ServiceCmsState>(
      builder: (context, state) {
        final ServicePageModel model = switch (state) {
          ServiceCmsLoaded s => s.data,
          ServiceCmsSaved s  => s.data,
          _                  => ServicePageModel.empty(),
        };

        final bool isLoading = state is ServiceCmsLoading;
        // BUG-25: was a hard-coded 'Last Updated On 12 Jul 2026'.
        final DateTime? lu = model.lastUpdatedAt;
        const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
        final String lastUpdated = lu == null
            ? 'Last Updated On —'
            : 'Last Updated On ${lu.day} ${months[lu.month - 1]} ${lu.year}';

        return Scaffold(
          backgroundColor: AppColors.background,
          body: isLoading
              ? const Center(child: CircleProgress())
              : SingleChildScrollView(
            padding: EdgeInsets.all(24.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Page title ──────────────────────────────────
                Text(
                  'Services',
                  style:
                  AppTextStyles.font28BlackSemiBoldCairo.copyWith(
                    fontSize:   22.sp,
                    color:      ColorPick.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 20.h),

                // ── Digital Journey accordion ───────────────────
                _DJSectionCard(
                  lastUpdated: lastUpdated,
                  model:       model,
                  onEditTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BlocProvider.value(
                        value: context.read<ServiceCmsCubit>(),
                        child: ServicesDigitalJourneyEditPage(
                            model: model),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── DJ Section Card ──────────────────────────────────────────────────────────
