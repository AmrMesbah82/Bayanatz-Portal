part of '../../pages/contact_us_preview.dart';

class _PreviewView extends StatelessWidget {
  const _PreviewView({this.isDraft = false});

  final bool isDraft;

  @override
  Widget build(BuildContext context) {
    final double w = MediaQuery.of(context).size.width;
    final bool isMobile = w < 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocBuilder<ContactUsCmsCubit, ContactUsCmsState>(
        builder: (context, state) {
          if (state is ContactUsCmsLoading || state is ContactUsCmsInitial) {
            return const Center(child: CircleProgress());
          }

          if (state is ContactUsCmsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${state.message}'),
                  SizedBox(height: 16.h),
                  ElevatedButton(
                    onPressed: () => context.read<ContactUsCmsCubit>().load(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is ContactUsCmsLoaded) {
            return SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 20.h),
                  AdminSubNavBar(activeIndex: 4),
                  // BUG-52: a real way back. Pops to the edit form (which
                  // still holds the unsaved changes) or, after a reload,
                  // goes to the Contact Us tab — never a blank page.
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: AdminBackLink(
                        parentLabel: isDraft ? 'Back to editing' : 'Contact Us',
                        parentRoute: '/admin/contact-cms',
                      ),
                    ),
                  ),
                  if (isMobile)
                    _MobilePreview(data: state.data)
                  else
                    _DesktopPreview(data: state.data),
                  const AppFooter(),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// DESKTOP PREVIEW
// ═══════════════════════════════════════════════════════════════════════════════
