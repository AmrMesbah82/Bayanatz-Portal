// ******************* FILE INFO *******************
// File Name: admin_back_link.dart
// Purpose: Small "← Parent" breadcrumb shown at the top of admin sub-pages
//          (BUG-26). Pops back when there is history, otherwise goes to the
//          parent section's URL — so it also works after a page reload.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../constant/color.dart';
import '../theme/new_theme.dart';

class AdminBackLink extends StatelessWidget {
  const AdminBackLink({
    super.key,
    required this.parentLabel,
    required this.parentRoute,
  });

  /// e.g. 'Job Listing'
  final String parentLabel;

  /// e.g. '/jobs'
  final String parentRoute;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {
            // BUG-298: sub-pages are opened both as routes and with
            // Navigator.push — pop whichever is on top, else go to the parent.
            final nav = Navigator.of(context);
            if (nav.canPop()) {
              nav.pop();
              return;
            }
            final router = GoRouter.of(context);
            if (router.canPop()) {
              router.pop();
            } else {
              router.go(parentRoute);
            }
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_back_ios_new_rounded,
                  size: 14.sp, color: ColorPick.primary),
              SizedBox(width: 6.w),
              Text(
                parentLabel,
                style: StyleText.fontSize14Weight500
                    .copyWith(color: ColorPick.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
