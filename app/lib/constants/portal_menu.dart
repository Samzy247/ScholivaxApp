import 'package:flutter/material.dart';

/// One tappable card on the dashboard that opens a specific page of the
/// full website inside the in-app WebView — unless [nativeRoute] is set,
/// in which case it opens that native offline-capable screen instead
/// (e.g. the Marksheet item opens the native Marks entry screen so
/// teachers can score offline instead of needing the website's page).
class PortalItem {
  final String label;
  final IconData icon;
  final String path; // e.g. '/admin/hrm' — appended to the school baseUrl.
  final String? nativeRoute;

  const PortalItem({required this.label, required this.icon, required this.path, this.nativeRoute});
}

/// A named group of [PortalItem]s (rendered as a heading + card grid).
class PortalSection {
  final String title;
  final List<PortalItem> items;

  const PortalSection({required this.title, required this.items});
}

/// Everything below mirrors real controller actions in the CodeIgniter
/// backend (Admin.php, Teacher.php, Student.php, Parents.php), so a tap
/// opens `https://<subdomain>.scholivax.top/<path>` and lands straight on
/// that page. Circulars, Attendance and Marks are deliberately left out —
/// those stay as native, offline-first cards on the dashboard instead of
/// WebView links.
class PortalMenu {
  static List<PortalSection> forRole(String userType) {
    switch (userType) {
      case 'admin':
        return _admin;
      case 'teacher':
        return _teacher;
      case 'student':
        return _student;
      case 'parent':
        return _parent;
      default:
        return _admin;
    }
  }

  static const _admin = <PortalSection>[
    PortalSection(title: 'Students', items: [
      PortalItem(label: 'Student Information', icon: Icons.groups_rounded, path: '/admin/student_information'),
      PortalItem(label: 'New Admission', icon: Icons.person_add_alt_1_rounded, path: '/admin/new_student'),
      PortalItem(label: 'Pending Admissions', icon: Icons.pending_actions_rounded, path: '/admin/pending_admission'),
      PortalItem(label: 'Promote Students', icon: Icons.trending_up_rounded, path: '/admin/promote_student'),
    ]),
    PortalSection(title: 'Academics', items: [
      PortalItem(label: 'Classes & Sections', icon: Icons.class_rounded, path: '/admin/classes'),
      PortalItem(label: 'Class Routine', icon: Icons.schedule_rounded, path: '/admin/class_routine'),
      PortalItem(label: 'Syllabus', icon: Icons.menu_book_rounded, path: '/admin/academic_syllabus'),
    ]),
    PortalSection(title: 'Staff & HR', items: [
      PortalItem(label: 'Teaching Staff', icon: Icons.school_rounded, path: '/admin/teacher'),
      PortalItem(label: 'Human Resources', icon: Icons.badge_rounded, path: '/admin/hrm'),
      PortalItem(label: 'Leave Requests', icon: Icons.event_busy_rounded, path: '/admin/leave'),
    ]),
    PortalSection(title: 'Finance', items: [
      PortalItem(label: 'Accountant', icon: Icons.account_balance_wallet_rounded, path: '/admin/accountant'),
      PortalItem(label: 'Fee Types', icon: Icons.payments_rounded, path: '/admin/fee_type'),
      PortalItem(label: 'Student Invoices', icon: Icons.receipt_long_rounded, path: '/admin/student_invoice'),
      PortalItem(label: 'Expenses', icon: Icons.request_quote_rounded, path: '/expense'),
    ]),
    PortalSection(title: 'Exams & CBT', items: [
      PortalItem(label: 'Create Examination', icon: Icons.fact_check_rounded, path: '/admin/createExamination'),
      PortalItem(label: 'CBT Exams', icon: Icons.laptop_chromebook_rounded, path: '/admin/cbt_exam'),
      PortalItem(label: 'CBT Question Bank', icon: Icons.quiz_rounded, path: '/admin/cbt_questions'),
      PortalItem(label: 'CBT Results', icon: Icons.leaderboard_rounded, path: '/admin/cbt_results'),
      PortalItem(label: 'Mark Approvals', icon: Icons.rule_rounded, path: '/admin/mark_approvals'),
      PortalItem(label: 'Tabulation Sheet', icon: Icons.table_chart_rounded, path: '/admin/tabulation_sheet'),
    ]),
    PortalSection(title: 'Facilities', items: [
      PortalItem(label: 'Hostel', icon: Icons.holiday_village_rounded, path: '/admin/hostel'),
      PortalItem(label: 'Library', icon: Icons.local_library_rounded, path: '/admin/librarian'),
      PortalItem(label: 'Transportation', icon: Icons.directions_bus_filled_rounded, path: '/transportation'),
    ]),
    PortalSection(title: 'Communication', items: [
      PortalItem(label: 'Noticeboard', icon: Icons.campaign_rounded, path: '/admin/noticeboard'),
      PortalItem(label: 'News', icon: Icons.article_rounded, path: '/admin/news'),
      PortalItem(label: 'Gallery', icon: Icons.photo_library_rounded, path: '/admin/gallery'),
      PortalItem(label: 'Messages', icon: Icons.forum_rounded, path: '/admin/message'),
    ]),
    PortalSection(title: 'Settings', items: [
      PortalItem(label: 'My Profile', icon: Icons.manage_accounts_rounded, path: '/admin/manage_profile'),
      PortalItem(label: 'Website Settings', icon: Icons.language_rounded, path: '/admin/website_setting'),
      PortalItem(label: 'System Settings', icon: Icons.settings_rounded, path: '/systemsetting'),
      PortalItem(label: 'Manage Campuses', icon: Icons.apartment_rounded, path: '/admin/manage_schools'),
    ]),
  ];

  static const _teacher = <PortalSection>[
    PortalSection(title: 'Classes', items: [
      PortalItem(label: 'Live Class', icon: Icons.videocam_rounded, path: '/teacher/live_class'),
      PortalItem(label: 'Video Lessons', icon: Icons.ondemand_video_rounded, path: '/teacher/video_class'),
      PortalItem(label: 'Assignment', icon: Icons.assignment_rounded, path: '/assignment/assignment'),
      PortalItem(label: 'Study Materials', icon: Icons.folder_copy_rounded, path: '/studymaterial/study_material'),
    ]),
    PortalSection(title: 'Exams & CBT', items: [
      PortalItem(label: 'CBT Exams', icon: Icons.laptop_chromebook_rounded, path: '/teacher/cbt_exam'),
    ]),
    // "Student Remarks" used to point at /teacher/student_remarks, which is
    // a POST-only save handler with no page to actually show — always
    // blank. /teacher/bulk_remarks_page is the real page (auto-selects the
    // teacher's first class if none given) and has a matching view.
    // "Result Sheet" used to point at /teacher/printResultSheet, whose view
    // file (application/views/backend/teacher/printResultSheet.php) simply
    // doesn't exist on the server — only the admin/parent/student versions
    // do — so the content area always rendered empty. Pointing at the
    // subject marksheet page instead, since that one has a real view.
    PortalSection(title: 'Report Card', items: [
      PortalItem(label: 'Enter Remarks', icon: Icons.rate_review_rounded, path: '/teacher/bulk_remarks_page'),
      PortalItem(label: 'Marksheet', icon: Icons.summarize_rounded, path: '/teacher/student_marksheet_subject', nativeRoute: 'marks'),
    ]),
    PortalSection(title: 'Messages', items: [
      PortalItem(label: 'Parent Messages', icon: Icons.forum_rounded, path: '', nativeRoute: 'chat_inbox'),
    ]),
    PortalSection(title: 'Profile', items: [
      PortalItem(label: 'My Profile', icon: Icons.manage_accounts_rounded, path: '/teacher/manage_profile'),
    ]),
  ];

  static const _student = <PortalSection>[
    PortalSection(title: 'Academics', items: [
      PortalItem(label: 'Class Routine', icon: Icons.schedule_rounded, path: '/student/class_routine'),
      PortalItem(label: 'Subjects', icon: Icons.menu_book_rounded, path: '/student/subject'),
      PortalItem(label: 'Classmates', icon: Icons.groups_rounded, path: '/student/class_mate'),
      PortalItem(label: 'Result / Marksheet', icon: Icons.summarize_rounded, path: '/student/student_marksheet'),
    ]),
    PortalSection(title: 'Exams', items: [
      PortalItem(label: 'CBT Exams', icon: Icons.laptop_chromebook_rounded, path: '/student/cbt_exams'),
    ]),
    PortalSection(title: 'Classes', items: [
      PortalItem(label: 'Live Class', icon: Icons.videocam_rounded, path: '/student/live_class'),
      PortalItem(label: 'Video Lessons', icon: Icons.ondemand_video_rounded, path: '/student/video_class'),
    ]),
    PortalSection(title: 'Fees & Profile', items: [
      PortalItem(label: 'Invoice', icon: Icons.receipt_long_rounded, path: '/student/invoice'),
      PortalItem(label: 'Payment History', icon: Icons.history_rounded, path: '/student/payment_history'),
      PortalItem(label: 'My Profile', icon: Icons.manage_accounts_rounded, path: '/student/manage_profile'),
    ]),
  ];

  static const _parent = <PortalSection>[
    PortalSection(title: 'Chat Teacher', items: [
      PortalItem(label: 'Chat Teacher', icon: Icons.chat_bubble_rounded, path: '', nativeRoute: 'chat_teacher'),
    ]),
    PortalSection(title: 'Profile', items: [
      PortalItem(label: 'My Profile', icon: Icons.manage_accounts_rounded, path: '/parents/manage_profile'),
    ]),
  ];

  /// Used only by the child-dashboard screen (opened by tapping a child's
  /// name) — NOT part of the main parent dashboard's own nav, since that
  /// now only has Home/Chat/Profile. This is the "logged into that
  /// child's own portal" experience: academics + fees for that one child.
  static const childPortalSections = <PortalSection>[
    PortalSection(title: 'Academics', items: [
      PortalItem(label: 'Class Routine', icon: Icons.schedule_rounded, path: '/parents/class_routine'),
      PortalItem(label: 'Subjects', icon: Icons.menu_book_rounded, path: '/parents/subject'),
    ]),
    PortalSection(title: 'Fees', items: [
      PortalItem(label: 'Invoice', icon: Icons.receipt_long_rounded, path: '/parents/invoice'),
      PortalItem(label: 'Payment History', icon: Icons.history_rounded, path: '/parents/payment_history'),
    ]),
  ];
}
