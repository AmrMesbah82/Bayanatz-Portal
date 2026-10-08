// ******************* FILE INFO *******************
// File Name: inquiry_status_colors.dart
// Description: UI-layer extension mapping InquiryStatus → Color.
//              Kept here so the data model stays Flutter-free.
// Created by: Amr Mesbah

import 'package:flutter/material.dart';

import '../../../data/models/inquiry_model.dart';

extension InquiryStatusColor on InquiryStatus {
  Color get color {
    switch (this) {
      case InquiryStatus.newInquiry:
        return const Color(0xFF008037);
      case InquiryStatus.replied:
        return const Color(0xFFFF814A); // Figma 7126:65498
      case InquiryStatus.closed:
        // BUG-152: Figma 7126:65503 — red; "New" is green, so they differ.
        return const Color(0xFFD31426);
    }
  }
}
