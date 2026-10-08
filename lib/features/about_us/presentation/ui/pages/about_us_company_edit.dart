// ═══════════════════════════════════════════════════════════════════
// FILE 7: about_company_edit_page.dart  (Edit Page) — UPDATED
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import '../../../../../core/widget/success_toast.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:web_app_admin/core/constant/color.dart';

import 'package:go_router/go_router.dart';
import 'package:web_app_admin/core/widget/textfield.dart';



import '../../../../../core/main_widgets/admin_sticky_body.dart';
import '../../../../../core/main_widgets/app_admin_navbar.dart';
import '../../../../../core/theme/appcolors.dart';
import '../../../../../core/theme/new_theme.dart';
import '../../../../careers/presentation/ui/pages/careers_main.dart';
import '../../../../job/presentation/ui/pages/job_listing_main.dart';
import '../../../../main/presentation/ui/pages/main_main.dart';
import '../../controller/about_us_company_cubit.dart';
import '../../../../../core/custom/3-custom_accordion.dart';
import '../../../../../core/custom/15-custom_action_buttons.dart';
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

class AboutCompanyEditPage extends StatefulWidget {
  const AboutCompanyEditPage({super.key});

  @override
  State<AboutCompanyEditPage> createState() => _AboutCompanyEditPageState();
}

class _AboutCompanyEditPageState extends State<AboutCompanyEditPage> {
  final Map<String, bool> _open = {
    'company_info': true,
  };

  final TextEditingController _aboutEnController = TextEditingController();
  final TextEditingController _aboutArController = TextEditingController();

  bool _submitted = false;
  bool _isSaving  = false;
  bool _didLoad   = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didLoad) {
      _didLoad = true;
      _loadExistingData();
    }
  }

  void _loadExistingData() {
    final cubit = context.read<AboutCompanyCubit>();
    final cached = cubit.cachedData;
    if (cached != null) {
      _aboutEnController.text = cached.aboutEn;
      _aboutArController.text = cached.aboutAr;
    }
  }

  @override
  void dispose() {
    _aboutEnController.dispose();
    _aboutArController.dispose();
    super.dispose();
  }

  void _onDiscard() => _leave();

  /// After a page reload this page can be the only one in the stack (it has
  /// its own URL now — BUG-05), so fall back to its parent route.
  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/admin/about-company');
    }
  }

  Future<void> _onSave() async {
    setState(() => _submitted = true);

    if (_aboutEnController.text.trim().isEmpty ||
        _aboutArController.text.trim().isEmpty) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      await context.read<AboutCompanyCubit>().saveAboutCompany(
        aboutEn: _aboutEnController.text.trim(),
        aboutAr: _aboutArController.text.trim(),
      );

      if (mounted) {
        setState(() => _isSaving = false);
        // BUG-46: confirm the save (root-overlay toast survives _leave()).
        showSuccessToast(context, 'About Company saved');
        _leave();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPick.background,
      body: Stack(
        children: [
          AdminStickyBody(
  children: [
                  AppAdminNavbar(
                    activeLabel:    'Job Listing',
                    homePage:       CareersMainPageDashboard(),
                    // Web Page tab must open the Web Page section — pointing
                    // it at this page made the tab look dead.
                    webPage:        const MainMainPage(),
                    jobListingPage: JobListingMainPage(),
                  ),

                  SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                        horizontal: 20.w, vertical: 20.h),
                    child: SizedBox(
                      width: 1000.w,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Title ──────────────────────────────────
                          Text(
                            'Editing About Company',
                            style:
                            StyleText.fontSize45Weight600.copyWith(
                              color: ColorPick.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 16.h),

                          // ── Company Information Accordion ──────────
                          _accordion(
                            key: 'company_info',
                            title: 'Company Information',
                            children: [_editableCompanyInfoSection()],
                          ),

                          SizedBox(height: 24.h),

                          // ── Discard / Save — shared admin action buttons
                          //    (core/custom/15-custom_action_buttons.dart) ──
                          Row(
                            children: [
                              Expanded(
                                child: customDiscardButton(
                                  onTap: _onDiscard,
                                  width: double.infinity,
                                ),
                              ),
                              SizedBox(width: 400.w),
                              Expanded(
                                child: customPublishButton(
                                  title: 'Save',
                                  onTap: _onSave,
                                  enabled: !_isSaving,
                                  width: double.infinity,
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 40.h),
                        ],
                      ),
                    ),
                  ),
                ],
),

          // ── Saving overlay ──
          if (_isSaving)
            Container(
              color: Colors.black26,
              child: const Center(
                child:
                CircleProgress(),
              ),
            ),
        ],
      ),
    );
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

  // ── Editable Company Info ──────────────────────────────────────────────────
  Widget _editableCompanyInfoSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(6.r),
          bottomRight: Radius.circular(6.r),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20.h),

          // ── English ──
          CustomValidatedTextFieldMaster(
            label: 'About Company',
            hint: 'Text Here',
            controller: _aboutEnController,
            height: 80,
            maxLines: 4,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.start,
            showCharCount: false,
            maxLength: 800,
            minLength: 0,
            submitted: _submitted,
            primaryColor: ColorPick.primary,
            fillColor: AppColors.card,
            textStyle: StyleText.fontSize12Weight400
                .copyWith(color:AppColors.text),
            hintStyle: StyleText.fontSize12Weight400
                .copyWith(color: AppColors.secondaryText),
          ),

          SizedBox(height: 16.h),

          // ── Arabic — Directionality wrapper so label + hint + text
          //    all start from the RIGHT (RTL) ──
          Directionality(
            textDirection: TextDirection.rtl,
            child: CustomValidatedTextFieldMaster(
              label: 'عن الشركة',
              hint: 'ادخل النص هنا',
              controller: _aboutArController,
              height: 80,
              maxLines: 4,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.start,
              showCharCount: false,
              maxLength: 800,
              minLength: 0,
              submitted: _submitted,
              primaryColor: ColorPick.primary,
              fillColor: AppColors.card,
              textStyle: StyleText.fontSize12Weight400
                  .copyWith(color: AppColors.text),
              hintStyle: StyleText.fontSize12Weight400
                  .copyWith(color: AppColors.secondaryText),
            ),
          ),
        ],
      ),
    );
  }
}