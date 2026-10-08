import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:web_app_admin/core/constant/color.dart';




// date:April/30/2024
// by:Amr Mesbah
// lastUpdate:April/30/2024
// This class is used to create a circular progress indicator with a light primary color.
// It is used to indicate that an operation is in progress.
class CircleProgress extends StatelessWidget {
  const CircleProgress({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        height: 50.sp,
        width: 50.sp,
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(ColorPick.primary), // primary color of any company
          backgroundColor: Colors.white60,
          strokeWidth: 2.0,
        ),
      ),
    );
  }
}

