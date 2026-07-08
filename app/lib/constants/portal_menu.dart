import 'package:flutter/material.dart';

/// One tappable card on the dashboard that opens a specific page of the
/// full website inside the in-app WebView.
class PortalItem {
  final String label;
  final IconData icon;
  final String path; // e.g. '/admin/hrm' — appended to the school baseUrl.

  const PortalItem({required this.label, required this.icon, required this.path});
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
    ]),
    PortalSection(title: 'Exams & CBT', items: [
      PortalItem(label: 'CBT Exams', icon: Icons.laptop_chromebook_rounded, path: '/teacher/cbt_exam'),
      PortalItem(label: 'CBT Question Bank', icon: Icons.quiz_rounded, path: '/teacher/cbt_questions'),
      PortalItem(label: 'CBT Results', icon: Icons.leaderboard_rounded, path: '/teacher/cbt_results'),
    ]),
    PortalSection(title: 'Students', items: [
      PortalItem(label: 'Student Remarks', icon: Icons.rate_review_rounded, path: '/teacher/student_remarks'),
      PortalItem(label: 'Result Sheet', icon: Icons.summarize_rounded, path: '/teacher/printResultSheet'),
    ]),
    PortalSection(title: 'My Work', items: [
      PortalItem(label: 'Leave Requests', icon: Icons.event_busy_rounded, path: '/teacher/leave'),
      PortalItem(label: 'Payroll', icon: Icons.request_quote_rounded, path: '/teacher/payroll_list'),
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
      PortalItem(label: 'Online Exam', icon: Icons.edit_document, path: '/student/online_exam'),
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
    PortalSection(title: 'My Child', items: [
      PortalItem(label: 'Find Child', icon: Icons.search_rounded, path: '/parents/search_student'),
      PortalItem(label: 'Class Routine', icon: Icons.schedule_rounded, path: '/parents/class_routine'),
      PortalItem(label: 'Classmates', icon: Icons.groups_rounded, path: '/parents/class_mate'),
      PortalItem(label: 'Subjects', icon: Icons.menu_book_rounded, path: '/parents/subject'),
      PortalItem(label: 'Teachers', icon: Icons.school_rounded, path: '/parents/teacher'),
    ]),
    PortalSection(title: 'Fees & Profile', items: [
      PortalItem(label: 'Invoice', icon: Icons.receipt_long_rounded, path: '/parents/invoice'),
      PortalItem(label: 'Payment History', icon: Icons.history_rounded, path: '/parents/payment_history'),
      PortalItem(label: 'My Profile', icon: Icons.manage_accounts_rounded, path: '/parents/manage_profile'),
    ]),
  ];
}
