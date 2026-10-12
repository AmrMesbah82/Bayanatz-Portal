// ******************* FILE INFO *******************
// File Name: job_status_style.dart
// Purpose: BUG-279 / BUG-295 — ONE name and ONE colour per job status,
//          shared by the job cards, the Job Listing tabs and every dashboard
//          chart. "Inactive" and "Scheduled" were the same orange on the
//          cards, the two Home charts coloured the same statuses differently,
//          and one status had up to four names ("Closed" / "Recruitment End"
//          / "Inactive" / "Ended", "Draft" / "Drafted").
// Created by: Amr Mesbah

import 'package:flutter/material.dart';

import '../../features/job/data/models/job_listing_model.dart';

class JobStatusStyle {
  JobStatusStyle._();

  static const Color active    = Color(0xFF008037); // green
  static const Color scheduled = Color(0xFFF59E0B); // orange
  static const Color inactive  = Color(0xFFD32F2F); // red
  static const Color ended     = Color(0xFF7B1F2A); // dark red
  static const Color draft     = Color(0xFF9E9E9E); // grey
  static const Color removed   = Color(0xFF5F5F5F); // dark grey

  static Color color(JobStatus s) => switch (s) {
        JobStatus.active    => active,
        JobStatus.scheduled => scheduled,
        JobStatus.inactive  => inactive,
        JobStatus.ended     => ended,
        JobStatus.drafted   => draft,
        JobStatus.removed   => removed,
      };

  /// The one display name per status: Active · Scheduled · Inactive · Ended
  /// · Draft · Removed.
  static String name(JobStatus s) => s.displayLabel;

  /// Colour for a display name (charts keyed by label).
  static Color colorForName(String name) {
    switch (name.trim().toLowerCase()) {
      case 'active':    return active;
      case 'scheduled': return scheduled;
      case 'inactive':
      case 'closed':    return inactive;
      case 'ended':
      case 'recruitment end': return ended;
      case 'draft':
      case 'drafted':   return draft;
      case 'removed':   return removed;
      default:          return draft;
    }
  }
}
