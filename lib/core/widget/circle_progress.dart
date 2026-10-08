import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/appcolors.dart';


// date:April/30/2024
// by:Amr Mesbah
// lastUpdate:April/30/2024
// This class is used to create a circular progress indicator with a light primary color.
// It is used to indicate that an operation is in progress.
class CircleProgressMaster extends StatelessWidget {
  const CircleProgressMaster({super.key});

  @override
  Widget build(BuildContext context) {
    bool isTablet = MediaQuery.of(context).size.shortestSide > 600;
    bool orientation =
        MediaQuery.of(context).orientation == Orientation.portrait;
    return Center(
      child: SizedBox(
        width: isTablet
            ? orientation
            ? .045.h
            : .06.h
            : .045.h,
        height: isTablet
            ? orientation
            ? .045.h
            : .06.h
            : .045.h,
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          backgroundColor: Colors.white60,
          strokeWidth: 2.0,
        ),
      ),
    );
  }
}
