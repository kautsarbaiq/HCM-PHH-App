import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Supported app languages. Client feedback 16/08: Bahasa Malaysia is labelled
/// BM, and Chinese was dropped — only EN and BM ship.
enum AppLang { en, ms }

extension AppLangX on AppLang {
  String get label => switch (this) {
    AppLang.en => 'English',
    AppLang.ms => 'Bahasa Malaysia',
  };
  String get short => switch (this) {
    AppLang.en => 'EN',
    AppLang.ms => 'BM',
  };
  Locale get locale => switch (this) {
    AppLang.en => const Locale('en'),
    AppLang.ms => const Locale('ms'),
  };
}

/// Current UI language. Defaults to English; changed by the language switcher.
final localeProvider = StateProvider<AppLang>((ref) => AppLang.en);

/// Translate [key] for [lang], falling back to English then the raw key.
String trFor(String key, AppLang lang) {
  final row = _strings[key];
  if (row == null) return key;
  return row[lang] ?? row[AppLang.en] ?? key;
}

/// `ref.tr('key')` — watches the locale so the widget rebuilds on change.
extension TrRef on WidgetRef {
  String tr(String key) => trFor(key, watch(localeProvider));
}

/// `context`-free lookup when you already hold the lang.
extension TrLang on AppLang {
  String tr(String key) => trFor(key, this);
}

// ---------------------------------------------------------------------------
// Translations. Add keys here; untranslated keys fall back to English.
// ---------------------------------------------------------------------------
const Map<String, Map<AppLang, String>> _strings = {
  // Bottom navigation
  'nav.home': {AppLang.en: 'Home', AppLang.ms: 'Utama'},
  'nav.access': {AppLang.en: 'Access', AppLang.ms: 'Akses'},
  'nav.bills': {AppLang.en: 'Bills', AppLang.ms: 'Bil'},
  'nav.community': {
    AppLang.en: 'Community',
    AppLang.ms: 'Komuniti',
  },

  // Common actions
  'common.save': {AppLang.en: 'Save', AppLang.ms: 'Simpan'},
  'common.cancel': {
    AppLang.en: 'Cancel',
    AppLang.ms: 'Batal',
  },
  'common.add': {AppLang.en: 'Add', AppLang.ms: 'Tambah'},
  'common.edit': {AppLang.en: 'Edit', AppLang.ms: 'Sunting'},
  'common.delete': {
    AppLang.en: 'Delete',
    AppLang.ms: 'Padam',
  },
  'common.close': {AppLang.en: 'Close', AppLang.ms: 'Tutup'},
  'common.search': {AppLang.en: 'Search', AppLang.ms: 'Cari'},
  'common.retry': {
    AppLang.en: 'Try again',
    AppLang.ms: 'Cuba lagi',
  },
  'common.loading': {
    AppLang.en: 'Loading…',
    AppLang.ms: 'Memuatkan…',
  },
  'common.logout': {
    AppLang.en: 'Logout',
    AppLang.ms: 'Log keluar',
  },
  'common.language': {
    AppLang.en: 'Language',
    AppLang.ms: 'Bahasa',
  },
  'common.viewAll': {
    AppLang.en: 'See all',
    AppLang.ms: 'Lihat semua',
  },

  // Login
  'login.title': {
    AppLang.en: 'HomeCloudAsia',
    AppLang.ms: 'HomeCloudAsia',
  },
  'login.createAccount': {
    AppLang.en: 'Create your account',
    AppLang.ms: 'Cipta akaun anda',
  },
  'login.email': {
    AppLang.en: 'Email Address',
    AppLang.ms: 'Alamat E-mel',
  },
  'login.password': {
    AppLang.en: 'Password',
    AppLang.ms: 'Kata Laluan',
  },
  'login.login': {
    AppLang.en: 'Log In',
    AppLang.ms: 'Log Masuk',
  },
  'login.signup': {
    AppLang.en: 'Sign Up',
    AppLang.ms: 'Daftar',
  },
  'login.needAccount': {
    AppLang.en: 'Need an account? Sign Up',
    AppLang.ms: 'Perlukan akaun? Daftar',
  },
  'login.haveAccount': {
    AppLang.en: 'Already have an account? Log In',
    AppLang.ms: 'Sudah ada akaun? Log Masuk',
  },

  // Dashboard
  'dash.welcomeBack': {
    AppLang.en: 'Welcome back 👋',
    AppLang.ms: 'Selamat kembali 👋',
  },
  'dash.quickActions': {
    AppLang.en: 'Quick Actions',
    AppLang.ms: 'Tindakan Pantas',
  },
  'dash.quickActionsSub': {
    AppLang.en: 'Everything one tap away',
    AppLang.ms: 'Semua dengan satu sentuhan',
  },
  'dash.outstanding': {
    AppLang.en: 'Your outstanding',
    AppLang.ms: 'Tunggakan anda',
  },
  'dash.accountStatus': {
    AppLang.en: 'Account status',
    AppLang.ms: 'Status akaun',
  },
  'dash.allCleared': {
    AppLang.en: 'All cleared',
    AppLang.ms: 'Semua selesai',
  },
  'dash.paidUp': {
    AppLang.en: "You're all paid up 🎉",
    AppLang.ms: 'Anda telah menjelaskan semua 🎉',
  },
  'dash.payNow': {
    AppLang.en: 'Pay now',
    AppLang.ms: 'Bayar sekarang',
  },
  'dash.viewInvoices': {
    AppLang.en: 'View invoices',
    AppLang.ms: 'Lihat invois',
  },
  'dash.noBookings': {
    AppLang.en: 'No upcoming bookings',
    AppLang.ms: 'Tiada tempahan akan datang',
  },
  'dash.tapToBook': {
    AppLang.en: 'Tap to book a facility',
    AppLang.ms: 'Ketik untuk menempah kemudahan',
  },
  'dash.emergency': {
    AppLang.en: 'Emergency',
    AppLang.ms: 'Kecemasan',
  },
  'dash.visitorPass': {
    AppLang.en: 'Visitor Pass',
    AppLang.ms: 'Pas Pelawat',
  },
  'dash.billsPay': {
    AppLang.en: 'Bills & Pay',
    AppLang.ms: 'Bil & Bayar',
  },
  'dash.bookings': {
    AppLang.en: 'Bookings',
    AppLang.ms: 'Tempahan',
  },
  'dash.announcements': {
    AppLang.en: 'Announcements',
    AppLang.ms: 'Pengumuman',
  },

  // Profile
  'profile.title': {
    AppLang.en: 'Profile',
    AppLang.ms: 'Profil',
  },
  'profile.phone': {
    AppLang.en: 'Phone',
    AppLang.ms: 'Telefon',
  },
  'profile.email': {
    AppLang.en: 'Email',
    AppLang.ms: 'E-mel',
  },
  'profile.houseAddress': {
    AppLang.en: 'House Address',
    AppLang.ms: 'Alamat Rumah',
  },
  'profile.documents': {
    AppLang.en: 'Resident Documents',
    AppLang.ms: 'Dokumen Penghuni',
  },
  'profile.financial': {
    AppLang.en: 'Financial Records',
    AppLang.ms: 'Rekod Kewangan',
  },
  'profile.signOut': {
    AppLang.en: 'Sign Out',
    AppLang.ms: 'Log Keluar',
  },

  // Emergency
  'emergency.active': {
    AppLang.en: 'Active Emergency',
    AppLang.ms: 'Kecemasan Aktif',
  },
  'emergency.activePlural': {
    AppLang.en: 'Active Emergencies',
    AppLang.ms: 'Kecemasan Aktif',
  },
  'emergency.resolve': {
    AppLang.en: 'Resolve',
    AppLang.ms: 'Selesai',
  },
  'emergency.cancel': {
    AppLang.en: 'Cancel',
    AppLang.ms: 'Batal',
  },
  'emergency.resolved': {
    AppLang.en: 'Emergency resolved',
    AppLang.ms: 'Kecemasan diselesaikan',
  },
  'emergency.broadcast': {
    AppLang.en: 'Broadcast Alert',
    AppLang.ms: 'Siar Amaran',
  },
  'emergency.broadcastTitle': {
    AppLang.en: 'Broadcast to everyone',
    AppLang.ms: 'Siar kepada semua',
  },
  'emergency.broadcastSub': {
    AppLang.en: 'This alert shows on every resident and guard dashboard.',
    AppLang.ms: 'Amaran ini dipaparkan pada papan pemuka setiap penghuni dan pengawal.',
  },
  'emergency.alertTitle': {
    AppLang.en: 'Title',
    AppLang.ms: 'Tajuk',
  },
  'emergency.message': {
    AppLang.en: 'Message',
    AppLang.ms: 'Mesej',
  },
  'emergency.send': {
    AppLang.en: 'Send Alert',
    AppLang.ms: 'Hantar Amaran',
  },
  'emergency.sent': {
    AppLang.en: 'Emergency broadcast sent',
    AppLang.ms: 'Siaran kecemasan dihantar',
  },

  // -------------------------------------------------------------------------
  // Boss batch 08/08 point 6: Bahasa Malaysia across web + mobile.
  // Side menu (mobile drawer)
  // -------------------------------------------------------------------------
  'menu.eGovernance': {
    AppLang.en: 'E-Governance',
    AppLang.ms: 'E-Tadbir',
  },
  'menu.directory': {
    AppLang.en: 'Directory',
    AppLang.ms: 'Direktori',
  },
  'menu.community': {
    AppLang.en: 'Community',
    AppLang.ms: 'Komuniti',
  },
  'menu.lifestyle': {
    AppLang.en: 'Lifestyle',
    AppLang.ms: 'Gaya Hidup',
  },
  'menu.eform': {
    AppLang.en: 'E-Form',
    AppLang.ms: 'E-Borang',
  },
  'menu.eformSub': {
    AppLang.en: 'Submit forms online',
    AppLang.ms: 'Hantar borang dalam talian',
  },
  'menu.edocument': {
    AppLang.en: 'E-Document',
    AppLang.ms: 'E-Dokumen',
  },
  'menu.edocumentSub': {
    AppLang.en: 'Rules & regulations',
    AppLang.ms: 'Peraturan & undang-undang',
  },
  'menu.scanId': {
    AppLang.en: 'Scan ID',
    AppLang.ms: 'Imbas ID',
  },
  'menu.scanIdSub': {
    AppLang.en: 'Auto-fill from your ID / license',
    AppLang.ms: 'Isi automatik daripada IC / lesen anda',
  },
  'menu.committee': {
    AppLang.en: 'Committee',
    AppLang.ms: 'Jawatankuasa',
  },
  'menu.committeeSub': {
    AppLang.en: 'Management committee',
    AppLang.ms: 'Jawatankuasa pengurusan',
  },
  'menu.guard': {
    AppLang.en: 'Security Guard',
    AppLang.ms: 'Pengawal Keselamatan',
  },
  'menu.guardSub': {
    AppLang.en: 'On duty today',
    AppLang.ms: 'Bertugas hari ini',
  },
  'menu.econtact': {
    AppLang.en: 'E-Contact',
    AppLang.ms: 'E-Hubungi',
  },
  'menu.econtactSub': {
    AppLang.en: 'Essential contacts',
    AppLang.ms: 'Hubungan penting',
  },
  'menu.events': {
    AppLang.en: 'Events (RSVP)',
    AppLang.ms: 'Acara (RSVP)',
  },
  'menu.eventsSub': {
    AppLang.en: 'Upcoming community events',
    AppLang.ms: 'Acara komuniti akan datang',
  },
  'menu.epolling': {
    AppLang.en: 'E-Polling',
    AppLang.ms: 'E-Undian',
  },
  'menu.epollingSub': {
    AppLang.en: 'Vote on community matters',
    AppLang.ms: 'Undi hal ehwal komuniti',
  },
  'menu.marketSquare': {
    AppLang.en: 'Market Square',
    AppLang.ms: 'Medan Pasar',
  },
  'menu.marketSquareSub': {
    AppLang.en: 'Trusted home services',
    AppLang.ms: 'Perkhidmatan rumah dipercayai',
  },
  'menu.facility': {
    AppLang.en: 'Book Facilities',
    AppLang.ms: 'Tempah Kemudahan',
  },
  'menu.facilitySub': {
    AppLang.en: 'Pool, gym, BBQ & more',
    AppLang.ms: 'Kolam, gim, BBQ & lain-lain',
  },
  'menu.rewards': {
    AppLang.en: 'Rewards',
    AppLang.ms: 'Ganjaran',
  },
  'menu.rewardsSub': {
    AppLang.en: 'On-time bill perks & discounts',
    AppLang.ms: 'Faedah & diskaun bayaran tepat masa',
  },
  'menu.viewProfile': {
    AppLang.en: 'Tap to view profile',
    AppLang.ms: 'Ketik untuk lihat profil',
  },

  // Profile extras
  'profile.notifications': {
    AppLang.en: 'Notifications',
    AppLang.ms: 'Pemberitahuan',
  },
  'profile.residentDocuments': {
    AppLang.en: 'Resident Documents',
    AppLang.ms: 'Dokumen Penghuni',
  },
  'profile.financialRecords': {
    AppLang.en: 'Financial Records',
    AppLang.ms: 'Rekod Kewangan',
  },
  'profile.familyLogins': {
    AppLang.en: 'Family Logins',
    AppLang.ms: 'Log Masuk Keluarga',
  },
  'profile.familyLoginsSub': {
    AppLang.en: 'Create a login for your wife or child. They sign in with '
        'their own email and password and see the same home, bills and '
        'visitors as you.',
    AppLang.ms: 'Buat log masuk untuk isteri atau anak anda. Mereka log masuk '
        'dengan e-mel dan kata laluan sendiri dan melihat rumah, bil serta '
        'pelawat yang sama seperti anda.',
  },
  'profile.addFamilyLogin': {
    AppLang.en: 'Add family login',
    AppLang.ms: 'Tambah log masuk keluarga',
  },
  'profile.tenancyAgreement': {
    AppLang.en: 'Tenancy Agreement',
    AppLang.ms: 'Perjanjian Sewa',
  },
  'profile.appVersion': {
    AppLang.en: 'App version',
    AppLang.ms: 'Versi aplikasi',
  },

  // Signup extras (tenancy agreement, resident type)
  'signup.owner': {
    AppLang.en: 'Owner',
    AppLang.ms: 'Pemilik',
  },
  'signup.tenant': {
    AppLang.en: 'Tenant',
    AppLang.ms: 'Penyewa',
  },
  'signup.fullName': {
    AppLang.en: 'Full Name',
    AppLang.ms: 'Nama Penuh',
  },
  'signup.communityCode': {
    AppLang.en: 'Residence Community Code',
    AppLang.ms: 'Kod Komuniti Kediaman',
  },
  'signup.tenancyRequired': {
    AppLang.en: 'Tenancy Agreement (required)',
    AppLang.ms: 'Perjanjian Sewa (wajib)',
  },
  'signup.tenancyOptional': {
    AppLang.en: 'Tenancy Agreement / ownership doc (optional)',
    AppLang.ms: 'Perjanjian Sewa / dokumen pemilikan (pilihan)',
  },
  'signup.tenancyHint': {
    AppLang.en: 'Tap to upload a PDF or photo (max 10 MB)',
    AppLang.ms: 'Ketik untuk memuat naik PDF atau foto (maks 10 MB)',
  },

  // -------------------------------------------------------------------------
  // Web portal (admin / guard / super admin / merchant sidebars)
  // -------------------------------------------------------------------------
  'admin.dashboard': {
    AppLang.en: 'Dashboard',
    AppLang.ms: 'Papan Pemuka',
  },
  'admin.residents': {
    AppLang.en: 'Residents',
    AppLang.ms: 'Penghuni',
  },
  'admin.houses': {
    AppLang.en: 'Houses',
    AppLang.ms: 'Rumah',
  },
  'admin.visitors': {
    AppLang.en: 'Visitors',
    AppLang.ms: 'Pelawat',
  },
  'admin.billings': {
    AppLang.en: 'Billings',
    AppLang.ms: 'Bil',
  },
  'admin.facilities': {
    AppLang.en: 'Facilities',
    AppLang.ms: 'Kemudahan',
  },
  'admin.announcements': {
    AppLang.en: 'Announcements',
    AppLang.ms: 'Pengumuman',
  },
  'admin.events': {
    AppLang.en: 'Events',
    AppLang.ms: 'Acara',
  },
  'admin.alerts': {
    AppLang.en: 'Alerts',
    AppLang.ms: 'Amaran',
  },
  'admin.reports': {
    AppLang.en: 'Reports',
    AppLang.ms: 'Laporan',
  },
  'admin.rewards': {
    AppLang.en: 'Rewards',
    AppLang.ms: 'Ganjaran',
  },
  'admin.guards': {
    AppLang.en: 'Guards',
    AppLang.ms: 'Pengawal',
  },
  'admin.settings': {
    AppLang.en: 'Settings',
    AppLang.ms: 'Tetapan',
  },
  'admin.export': {
    AppLang.en: 'Export',
    AppLang.ms: 'Eksport',
  },
  'admin.all': {AppLang.en: 'All', AppLang.ms: 'Semua'},

  // Shared status words (tables, pills, filters)
  'status.pending': {
    AppLang.en: 'Pending',
    AppLang.ms: 'Menunggu',
  },
  'status.approved': {
    AppLang.en: 'Approved',
    AppLang.ms: 'Diluluskan',
  },
  'status.rejected': {
    AppLang.en: 'Rejected',
    AppLang.ms: 'Ditolak',
  },
  'status.paid': {AppLang.en: 'Paid', AppLang.ms: 'Dibayar'},
  'status.unpaid': {
    AppLang.en: 'Unpaid',
    AppLang.ms: 'Belum Dibayar',
  },
  'status.active': {
    AppLang.en: 'Active',
    AppLang.ms: 'Aktif',
  },
  'status.inactive': {
    AppLang.en: 'Inactive',
    AppLang.ms: 'Tidak Aktif',
  },

  // Guard portal sidebar
  'guard.visitorLogs': {
    AppLang.en: 'Visitor Logs',
    AppLang.ms: 'Log Pelawat',
  },
  'guard.houseDirectory': {
    AppLang.en: 'House Directory',
    AppLang.ms: 'Direktori Rumah',
  },
  'guard.quickActions': {
    AppLang.en: 'QUICK ACTIONS',
    AppLang.ms: 'TINDAKAN PANTAS',
  },
  'guard.scanQr': {
    AppLang.en: 'Scan QR',
    AppLang.ms: 'Imbas QR',
  },
  'guard.manualRegistration': {
    AppLang.en: 'Manual Registration',
    AppLang.ms: 'Pendaftaran Manual',
  },

  // Web portal sidebar (remaining entries) + breadcrumb
  'admin.housesUnits': {
    AppLang.en: 'Houses & Units',
    AppLang.ms: 'Rumah & Unit',
  },
  'admin.communities': {
    AppLang.en: 'Communities',
    AppLang.ms: 'Komuniti',
  },
  'admin.alertHistory': {
    AppLang.en: 'Alert History',
    AppLang.ms: 'Sejarah Amaran',
  },
  'admin.polling': {AppLang.en: 'Polling', AppLang.ms: 'Undian'},
  'admin.documents': {AppLang.en: 'Documents', AppLang.ms: 'Dokumen'},
  'admin.forms': {AppLang.en: 'Forms', AppLang.ms: 'Borang'},
  'admin.contacts': {AppLang.en: 'Contacts', AppLang.ms: 'Hubungan'},
  'admin.market': {AppLang.en: 'Market', AppLang.ms: 'Pasar'},
  'admin.bookings': {AppLang.en: 'Bookings', AppLang.ms: 'Tempahan'},
  'admin.residentIds': {
    AppLang.en: 'Resident IDs',
    AppLang.ms: 'ID Penghuni',
  },
  'admin.marketSquare': {
    AppLang.en: 'Market Square',
    AppLang.ms: 'Medan Pasar',
  },
  'admin.eforms': {AppLang.en: 'E-Forms', AppLang.ms: 'E-Borang'},
  'admin.pages': {AppLang.en: 'Pages', AppLang.ms: 'Halaman'},
  'admin.admin': {AppLang.en: 'Admin', AppLang.ms: 'Admin'},

  // Admin dashboard body
  'adash.welcome': {
    AppLang.en: 'Welcome to',
    AppLang.ms: 'Selamat datang ke',
  },
  'adash.welcomeSub': {
    AppLang.en: 'Here is an overview of the community.',
    AppLang.ms: 'Berikut ialah gambaran keseluruhan komuniti.',
  },
  'adash.overview': {AppLang.en: 'Overview', AppLang.ms: 'Gambaran Keseluruhan'},
  'adash.overviewSub': {
    AppLang.en: 'Key community metrics at a glance',
    AppLang.ms: 'Metrik utama komuniti sepintas lalu',
  },
  'adash.totalResidents': {
    AppLang.en: 'Total Residents',
    AppLang.ms: 'Jumlah Penghuni',
  },
  'adash.totalHouses': {
    AppLang.en: 'Total Houses',
    AppLang.ms: 'Jumlah Rumah',
  },
  'adash.activeBillings': {
    AppLang.en: 'Active Billings',
    AppLang.ms: 'Bil Aktif',
  },
  'adash.todayVisitors': {
    AppLang.en: 'Today Visitors',
    AppLang.ms: 'Pelawat Hari Ini',
  },
  'adash.analytics': {AppLang.en: 'Analytics', AppLang.ms: 'Analitik'},
  'adash.analyticsSub': {
    AppLang.en: 'Collections, billing and visitor flow',
    AppLang.ms: 'Kutipan, bil dan aliran pelawat',
  },
  'adash.thisYear': {AppLang.en: 'This Year', AppLang.ms: 'Tahun Ini'},
  'adash.lastYear': {AppLang.en: 'Last Year', AppLang.ms: 'Tahun Lepas'},
  'adash.totalCollection': {
    AppLang.en: 'Total Collection',
    AppLang.ms: 'Jumlah Kutipan',
  },
  'adash.avgMonth': {AppLang.en: 'Avg / Month', AppLang.ms: 'Purata / Bulan'},
  'adash.thisMonth': {AppLang.en: 'This Month', AppLang.ms: 'Bulan Ini'},
  'adash.billsPaid': {AppLang.en: 'Bills / Paid', AppLang.ms: 'Bil / Dibayar'},
  'adash.outstanding': {
    AppLang.en: 'Outstanding',
    AppLang.ms: 'Tertunggak',
  },
  'adash.revenueAnalysis': {
    AppLang.en: 'REVENUE ANALYSIS',
    AppLang.ms: 'ANALISIS HASIL',
  },
  'adash.visitorFlow': {
    AppLang.en: 'VISITOR FLOW',
    AppLang.ms: 'ALIRAN PELAWAT',
  },
  'adash.billingStatus': {
    AppLang.en: 'BILLING STATUS',
    AppLang.ms: 'STATUS BIL',
  },

  // Reports page
  'reports.title': {AppLang.en: 'Reports', AppLang.ms: 'Laporan'},
  'reports.subtitle': {
    AppLang.en: 'Search, sort and export any list as CSV or PDF',
    AppLang.ms: 'Cari, susun dan eksport senarai sebagai CSV atau PDF',
  },
  'reports.facilityBookings': {
    AppLang.en: 'Facility Bookings',
    AppLang.ms: 'Tempahan Kemudahan',
  },
  'reports.payments': {AppLang.en: 'Payments', AppLang.ms: 'Pembayaran'},

  // Generic states
  'state.error': {
    AppLang.en: 'Something went wrong',
    AppLang.ms: 'Sesuatu tidak kena',
  },
  'state.empty': {
    AppLang.en: 'Nothing here yet',
    AppLang.ms: 'Tiada apa-apa lagi di sini',
  },
  'common.refresh': {AppLang.en: 'Refresh', AppLang.ms: 'Muat semula'},
};

// ---------------------------------------------------------------------------
// Phrase table (client feedback 16/08: "still so many words not translated").
//
// The key-based map above needs a code edit per string, which does not scale to
// the ~20 admin screens. This second table is keyed by the ENGLISH TEXT itself,
// so shared widgets (SectionHeader, ReportTable, StatusPill…) can translate
// whatever they are handed. Anything missing here simply stays English.
// ---------------------------------------------------------------------------
const Map<String, String> _phrasesMs = {
  // Admin page headers
  'Residents Management': 'Pengurusan Penghuni',
  'Manage residents, houses and account status':
      'Urus penghuni, rumah dan status akaun',
  'Houses & Units': 'Rumah & Unit',
  'Manage units and occupancy': 'Urus unit dan penghunian',
  'Communities': 'Komuniti',
  'Alert History': 'Sejarah Amaran',
  'Announcements': 'Pengumuman',
  'Post and manage community notices': 'Siar dan urus notis komuniti',
  'Billings & Payments': 'Bil & Pembayaran',
  'Manage invoices and resident payments':
      'Urus invois dan pembayaran penghuni',
  'Visitors Log': 'Log Pelawat',
  'Track check-ins, evidence photos and status':
      'Jejak daftar masuk, foto bukti dan status',
  'Events': 'Acara',
  'Schedule and manage community events': 'Jadualkan dan urus acara komuniti',
  'Polling': 'Undian',
  'Create and manage community polls': 'Cipta dan urus undian komuniti',
  'Documents': 'Dokumen',
  'Community rules, regulations and shared files':
      'Peraturan komuniti, undang-undang dan fail dikongsi',
  'E-Forms': 'E-Borang',
  'Manage forms and review resident submissions':
      'Urus borang dan semak penghantaran penghuni',
  'E-Contacts': 'E-Hubungan',
  'Manage emergency and community contacts':
      'Urus hubungan kecemasan dan komuniti',
  'Security Guards': 'Pengawal Keselamatan',
  'Manage guard duty status, shift and post':
      'Urus status bertugas, syif dan pos pengawal',
  'Market Square': 'Medan Pasar',
  'Manage neighbourhood home-service listings':
      'Urus senarai perkhidmatan rumah kejiranan',
  'Facilities': 'Kemudahan',
  'Manage bookable community amenities':
      'Urus kemudahan komuniti yang boleh ditempah',
  'Bookings': 'Tempahan',
  'Review and manage facility reservations':
      'Semak dan urus tempahan kemudahan',
  'Rewards': 'Ganjaran',
  'Partner brands, discount offers & owner claims':
      'Jenama rakan, tawaran diskaun & tuntutan pemilik',
  'Resident IDs': 'ID Penghuni',
  'Scanned identity documents & extracted details':
      'Dokumen identiti diimbas & butiran diekstrak',
  'Banners Management': 'Pengurusan Sepanduk',
  'Promotional banners shown to residents':
      'Sepanduk promosi yang dipaparkan kepada penghuni',
  'Reports': 'Laporan',
  'Search, sort and export any list as CSV or PDF':
      'Cari, susun dan eksport senarai sebagai CSV atau PDF',
  'Analytics': 'Analitik',
  'Collections, billing and visitor flow': 'Kutipan, bil dan aliran pelawat',
  'Overview': 'Gambaran Keseluruhan',
  'Key community metrics at a glance': 'Metrik utama komuniti sepintas lalu',
  'Needs Your Attention': 'Perlukan Perhatian Anda',
  'Approvals and reviews waiting for you':
      'Kelulusan dan semakan menunggu anda',
  'Companies': 'Syarikat',
  'Communities, their admin account and app modules':
      'Komuniti, akaun admin dan modul aplikasi mereka',
  'Merchants': 'Peniaga',
  'Shops offering rewards to residents':
      'Kedai yang menawarkan ganjaran kepada penghuni',

  // Resident-app section headers
  'Resident Documents': 'Dokumen Penghuni',
  'Financial Records': 'Rekod Kewangan',
  'Family Logins': 'Log Masuk Keluarga',
  'Notifications': 'Pemberitahuan',
  'My Parking': 'Tempat Letak Kereta Saya',
  'Quick Actions': 'Tindakan Pantas',

  // Common table / control words
  'Name': 'Nama',
  'Email': 'E-mel',
  'Phone': 'Telefon',
  'House': 'Rumah',
  'Role': 'Peranan',
  'Type': 'Jenis',
  'Status': 'Status',
  'Approval': 'Kelulusan',
  'Joined': 'Menyertai',
  'Visitor': 'Pelawat',
  'Purpose': 'Tujuan',
  'Entry': 'Kemasukan',
  'Plate': 'Nombor Plat',
  'Checked in': 'Daftar masuk',
  'Checked out': 'Daftar keluar',
  'Facility': 'Kemudahan',
  'Date': 'Tarikh',
  'Time': 'Masa',
  'Booked at': 'Ditempah pada',
  'Invoice': 'Invois',
  'Title': 'Tajuk',
  'Resident': 'Penghuni',
  'Period': 'Tempoh',
  'Due': 'Tempoh Bayar',
  'Paid at': 'Dibayar pada',
  'Method': 'Kaedah',
  'Event': 'Acara',
  'When': 'Bila',
  'Location': 'Lokasi',
  'Host': 'Hos',
  'Capacity': 'Kapasiti',
  'Actions': 'Tindakan',
  'Search': 'Cari',
  'Export CSV': 'Eksport CSV',
  'Export PDF': 'Eksport PDF',
  'All': 'Semua',
  'Total': 'Jumlah',
  'Save': 'Simpan',
  'Cancel': 'Batal',
  'Delete': 'Padam',
  'Close': 'Tutup',
  'Create': 'Cipta',
  'Update': 'Kemas kini',
  'Add': 'Tambah',
  'Edit': 'Sunting',

  // Sidebar group headings
  'Main': 'Utama',
  'Operations': 'Operasi',
  'Finance': 'Kewangan',
  'Records': 'Rekod',

  // Search hints & inline help
  'Search residents by name or email...': 'Cari penghuni mengikut nama atau e-mel...',
  'Search by house number or owner...': 'Cari mengikut nombor rumah atau pemilik...',
  'Search by visitor, house, or who logged it...': 'Cari mengikut pelawat, rumah, atau siapa yang merekod...',
  'Search invoice, resident, house…': 'Cari invois, penghuni, rumah…',
  'Residents register through the app directly. Use the edit action to assign a house or change status.': 'Penghuni mendaftar terus melalui aplikasi. Gunakan tindakan sunting untuk menetapkan rumah atau menukar status.',
};

/// Translates a raw ENGLISH phrase (not a key). Used by shared widgets so any
/// screen handing them English text gets Bahasa Malaysia for free.
String trTextFor(String english, AppLang lang) {
  if (lang == AppLang.en) return english;
  return _phrasesMs[english] ?? english;
}

/// `ref.trs('Residents Management')` — phrase-based sibling of [TrRef.tr].
extension TrsRef on WidgetRef {
  String trs(String english) => trTextFor(english, watch(localeProvider));
}
