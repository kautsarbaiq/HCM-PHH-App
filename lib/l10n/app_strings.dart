import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Supported app languages (Indonesian intentionally excluded).
enum AppLang { en, ms, zh }

extension AppLangX on AppLang {
  String get label => switch (this) {
    AppLang.en => 'English',
    AppLang.ms => 'Bahasa Melayu',
    AppLang.zh => '中文',
  };
  String get short => switch (this) {
    AppLang.en => 'EN',
    AppLang.ms => 'MS',
    AppLang.zh => '中',
  };
  Locale get locale => switch (this) {
    AppLang.en => const Locale('en'),
    AppLang.ms => const Locale('ms'),
    AppLang.zh => const Locale('zh'),
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
  'nav.home': {AppLang.en: 'Home', AppLang.ms: 'Utama', AppLang.zh: '主页'},
  'nav.access': {AppLang.en: 'Access', AppLang.ms: 'Akses', AppLang.zh: '通行'},
  'nav.bills': {AppLang.en: 'Bills', AppLang.ms: 'Bil', AppLang.zh: '账单'},
  'nav.community': {
    AppLang.en: 'Community',
    AppLang.ms: 'Komuniti',
    AppLang.zh: '社区',
  },

  // Common actions
  'common.save': {AppLang.en: 'Save', AppLang.ms: 'Simpan', AppLang.zh: '保存'},
  'common.cancel': {
    AppLang.en: 'Cancel',
    AppLang.ms: 'Batal',
    AppLang.zh: '取消',
  },
  'common.add': {AppLang.en: 'Add', AppLang.ms: 'Tambah', AppLang.zh: '添加'},
  'common.edit': {AppLang.en: 'Edit', AppLang.ms: 'Sunting', AppLang.zh: '编辑'},
  'common.delete': {
    AppLang.en: 'Delete',
    AppLang.ms: 'Padam',
    AppLang.zh: '删除',
  },
  'common.close': {AppLang.en: 'Close', AppLang.ms: 'Tutup', AppLang.zh: '关闭'},
  'common.search': {AppLang.en: 'Search', AppLang.ms: 'Cari', AppLang.zh: '搜索'},
  'common.retry': {
    AppLang.en: 'Try again',
    AppLang.ms: 'Cuba lagi',
    AppLang.zh: '重试',
  },
  'common.loading': {
    AppLang.en: 'Loading…',
    AppLang.ms: 'Memuatkan…',
    AppLang.zh: '加载中…',
  },
  'common.logout': {
    AppLang.en: 'Logout',
    AppLang.ms: 'Log keluar',
    AppLang.zh: '退出登录',
  },
  'common.language': {
    AppLang.en: 'Language',
    AppLang.ms: 'Bahasa',
    AppLang.zh: '语言',
  },
  'common.viewAll': {
    AppLang.en: 'See all',
    AppLang.ms: 'Lihat semua',
    AppLang.zh: '查看全部',
  },

  // Login
  'login.title': {
    AppLang.en: 'HomeCloudAsia',
    AppLang.ms: 'HomeCloudAsia',
    AppLang.zh: 'HomeCloudAsia',
  },
  'login.createAccount': {
    AppLang.en: 'Create your account',
    AppLang.ms: 'Cipta akaun anda',
    AppLang.zh: '创建您的账号',
  },
  'login.email': {
    AppLang.en: 'Email Address',
    AppLang.ms: 'Alamat E-mel',
    AppLang.zh: '电子邮箱',
  },
  'login.password': {
    AppLang.en: 'Password',
    AppLang.ms: 'Kata Laluan',
    AppLang.zh: '密码',
  },
  'login.login': {
    AppLang.en: 'Log In',
    AppLang.ms: 'Log Masuk',
    AppLang.zh: '登录',
  },
  'login.signup': {
    AppLang.en: 'Sign Up',
    AppLang.ms: 'Daftar',
    AppLang.zh: '注册',
  },
  'login.needAccount': {
    AppLang.en: 'Need an account? Sign Up',
    AppLang.ms: 'Perlukan akaun? Daftar',
    AppLang.zh: '需要账号？注册',
  },
  'login.haveAccount': {
    AppLang.en: 'Already have an account? Log In',
    AppLang.ms: 'Sudah ada akaun? Log Masuk',
    AppLang.zh: '已有账号？登录',
  },

  // Dashboard
  'dash.welcomeBack': {
    AppLang.en: 'Welcome back 👋',
    AppLang.ms: 'Selamat kembali 👋',
    AppLang.zh: '欢迎回来 👋',
  },
  'dash.quickActions': {
    AppLang.en: 'Quick Actions',
    AppLang.ms: 'Tindakan Pantas',
    AppLang.zh: '快捷操作',
  },
  'dash.quickActionsSub': {
    AppLang.en: 'Everything one tap away',
    AppLang.ms: 'Semua dengan satu sentuhan',
    AppLang.zh: '一键直达',
  },
  'dash.outstanding': {
    AppLang.en: 'Your outstanding',
    AppLang.ms: 'Tunggakan anda',
    AppLang.zh: '您的欠款',
  },
  'dash.accountStatus': {
    AppLang.en: 'Account status',
    AppLang.ms: 'Status akaun',
    AppLang.zh: '账户状态',
  },
  'dash.allCleared': {
    AppLang.en: 'All cleared',
    AppLang.ms: 'Semua selesai',
    AppLang.zh: '全部结清',
  },
  'dash.paidUp': {
    AppLang.en: "You're all paid up 🎉",
    AppLang.ms: 'Anda telah menjelaskan semua 🎉',
    AppLang.zh: '您已全部付清 🎉',
  },
  'dash.payNow': {
    AppLang.en: 'Pay now',
    AppLang.ms: 'Bayar sekarang',
    AppLang.zh: '立即支付',
  },
  'dash.viewInvoices': {
    AppLang.en: 'View invoices',
    AppLang.ms: 'Lihat invois',
    AppLang.zh: '查看账单',
  },
  'dash.noBookings': {
    AppLang.en: 'No upcoming bookings',
    AppLang.ms: 'Tiada tempahan akan datang',
    AppLang.zh: '暂无预订',
  },
  'dash.tapToBook': {
    AppLang.en: 'Tap to book a facility',
    AppLang.ms: 'Ketik untuk menempah kemudahan',
    AppLang.zh: '点击预订设施',
  },
  'dash.emergency': {
    AppLang.en: 'Emergency',
    AppLang.ms: 'Kecemasan',
    AppLang.zh: '紧急',
  },
  'dash.visitorPass': {
    AppLang.en: 'Visitor Pass',
    AppLang.ms: 'Pas Pelawat',
    AppLang.zh: '访客通行',
  },
  'dash.billsPay': {
    AppLang.en: 'Bills & Pay',
    AppLang.ms: 'Bil & Bayar',
    AppLang.zh: '账单支付',
  },
  'dash.bookings': {
    AppLang.en: 'Bookings',
    AppLang.ms: 'Tempahan',
    AppLang.zh: '预订',
  },
  'dash.announcements': {
    AppLang.en: 'Announcements',
    AppLang.ms: 'Pengumuman',
    AppLang.zh: '公告',
  },

  // Profile
  'profile.title': {
    AppLang.en: 'Profile',
    AppLang.ms: 'Profil',
    AppLang.zh: '个人资料',
  },
  'profile.phone': {
    AppLang.en: 'Phone',
    AppLang.ms: 'Telefon',
    AppLang.zh: '电话',
  },
  'profile.email': {
    AppLang.en: 'Email',
    AppLang.ms: 'E-mel',
    AppLang.zh: '电子邮箱',
  },
  'profile.houseAddress': {
    AppLang.en: 'House Address',
    AppLang.ms: 'Alamat Rumah',
    AppLang.zh: '住址',
  },
  'profile.documents': {
    AppLang.en: 'Resident Documents',
    AppLang.ms: 'Dokumen Penghuni',
    AppLang.zh: '住户文件',
  },
  'profile.financial': {
    AppLang.en: 'Financial Records',
    AppLang.ms: 'Rekod Kewangan',
    AppLang.zh: '财务记录',
  },
  'profile.signOut': {
    AppLang.en: 'Sign Out',
    AppLang.ms: 'Log Keluar',
    AppLang.zh: '退出登录',
  },

  // Emergency
  'emergency.active': {
    AppLang.en: 'Active Emergency',
    AppLang.ms: 'Kecemasan Aktif',
    AppLang.zh: '紧急警报',
  },
  'emergency.activePlural': {
    AppLang.en: 'Active Emergencies',
    AppLang.ms: 'Kecemasan Aktif',
    AppLang.zh: '紧急警报',
  },
  'emergency.resolve': {
    AppLang.en: 'Resolve',
    AppLang.ms: 'Selesai',
    AppLang.zh: '解除',
  },
  'emergency.cancel': {
    AppLang.en: 'Cancel',
    AppLang.ms: 'Batal',
    AppLang.zh: '取消',
  },
  'emergency.resolved': {
    AppLang.en: 'Emergency resolved',
    AppLang.ms: 'Kecemasan diselesaikan',
    AppLang.zh: '紧急情况已解除',
  },
  'emergency.broadcast': {
    AppLang.en: 'Broadcast Alert',
    AppLang.ms: 'Siar Amaran',
    AppLang.zh: '发布警报',
  },
  'emergency.broadcastTitle': {
    AppLang.en: 'Broadcast to everyone',
    AppLang.ms: 'Siar kepada semua',
    AppLang.zh: '向所有人发布',
  },
  'emergency.broadcastSub': {
    AppLang.en: 'This alert shows on every resident and guard dashboard.',
    AppLang.ms: 'Amaran ini dipaparkan pada papan pemuka setiap penghuni dan pengawal.',
    AppLang.zh: '此警报将显示在每位住户和保安的仪表板上。',
  },
  'emergency.alertTitle': {
    AppLang.en: 'Title',
    AppLang.ms: 'Tajuk',
    AppLang.zh: '标题',
  },
  'emergency.message': {
    AppLang.en: 'Message',
    AppLang.ms: 'Mesej',
    AppLang.zh: '内容',
  },
  'emergency.send': {
    AppLang.en: 'Send Alert',
    AppLang.ms: 'Hantar Amaran',
    AppLang.zh: '发送警报',
  },
  'emergency.sent': {
    AppLang.en: 'Emergency broadcast sent',
    AppLang.ms: 'Siaran kecemasan dihantar',
    AppLang.zh: '紧急广播已发送',
  },

  // -------------------------------------------------------------------------
  // Boss batch 08/08 point 6: Bahasa Malaysia across web + mobile.
  // Side menu (mobile drawer)
  // -------------------------------------------------------------------------
  'menu.eGovernance': {
    AppLang.en: 'E-Governance',
    AppLang.ms: 'E-Tadbir',
    AppLang.zh: '电子政务',
  },
  'menu.directory': {
    AppLang.en: 'Directory',
    AppLang.ms: 'Direktori',
    AppLang.zh: '通讯录',
  },
  'menu.community': {
    AppLang.en: 'Community',
    AppLang.ms: 'Komuniti',
    AppLang.zh: '社区',
  },
  'menu.lifestyle': {
    AppLang.en: 'Lifestyle',
    AppLang.ms: 'Gaya Hidup',
    AppLang.zh: '生活',
  },
  'menu.eform': {
    AppLang.en: 'E-Form',
    AppLang.ms: 'E-Borang',
    AppLang.zh: '电子表格',
  },
  'menu.eformSub': {
    AppLang.en: 'Submit forms online',
    AppLang.ms: 'Hantar borang dalam talian',
    AppLang.zh: '在线提交表格',
  },
  'menu.edocument': {
    AppLang.en: 'E-Document',
    AppLang.ms: 'E-Dokumen',
    AppLang.zh: '电子文件',
  },
  'menu.edocumentSub': {
    AppLang.en: 'Rules & regulations',
    AppLang.ms: 'Peraturan & undang-undang',
    AppLang.zh: '规章制度',
  },
  'menu.scanId': {
    AppLang.en: 'Scan ID',
    AppLang.ms: 'Imbas ID',
    AppLang.zh: '扫描证件',
  },
  'menu.scanIdSub': {
    AppLang.en: 'Auto-fill from your ID / license',
    AppLang.ms: 'Isi automatik daripada IC / lesen anda',
    AppLang.zh: '从证件自动填写',
  },
  'menu.committee': {
    AppLang.en: 'Committee',
    AppLang.ms: 'Jawatankuasa',
    AppLang.zh: '管委会',
  },
  'menu.committeeSub': {
    AppLang.en: 'Management committee',
    AppLang.ms: 'Jawatankuasa pengurusan',
    AppLang.zh: '管理委员会',
  },
  'menu.guard': {
    AppLang.en: 'Security Guard',
    AppLang.ms: 'Pengawal Keselamatan',
    AppLang.zh: '保安人员',
  },
  'menu.guardSub': {
    AppLang.en: 'On duty today',
    AppLang.ms: 'Bertugas hari ini',
    AppLang.zh: '今日值班',
  },
  'menu.econtact': {
    AppLang.en: 'E-Contact',
    AppLang.ms: 'E-Hubungi',
    AppLang.zh: '联系簿',
  },
  'menu.econtactSub': {
    AppLang.en: 'Essential contacts',
    AppLang.ms: 'Hubungan penting',
    AppLang.zh: '重要联系方式',
  },
  'menu.events': {
    AppLang.en: 'Events (RSVP)',
    AppLang.ms: 'Acara (RSVP)',
    AppLang.zh: '活动 (报名)',
  },
  'menu.eventsSub': {
    AppLang.en: 'Upcoming community events',
    AppLang.ms: 'Acara komuniti akan datang',
    AppLang.zh: '即将举行的社区活动',
  },
  'menu.epolling': {
    AppLang.en: 'E-Polling',
    AppLang.ms: 'E-Undian',
    AppLang.zh: '电子投票',
  },
  'menu.epollingSub': {
    AppLang.en: 'Vote on community matters',
    AppLang.ms: 'Undi hal ehwal komuniti',
    AppLang.zh: '就社区事务投票',
  },
  'menu.marketSquare': {
    AppLang.en: 'Market Square',
    AppLang.ms: 'Medan Pasar',
    AppLang.zh: '生活市集',
  },
  'menu.marketSquareSub': {
    AppLang.en: 'Trusted home services',
    AppLang.ms: 'Perkhidmatan rumah dipercayai',
    AppLang.zh: '可信赖的家居服务',
  },
  'menu.facility': {
    AppLang.en: 'Book Facilities',
    AppLang.ms: 'Tempah Kemudahan',
    AppLang.zh: '预订设施',
  },
  'menu.facilitySub': {
    AppLang.en: 'Pool, gym, BBQ & more',
    AppLang.ms: 'Kolam, gim, BBQ & lain-lain',
    AppLang.zh: '泳池、健身房、烧烤等',
  },
  'menu.rewards': {
    AppLang.en: 'Rewards',
    AppLang.ms: 'Ganjaran',
    AppLang.zh: '奖励',
  },
  'menu.rewardsSub': {
    AppLang.en: 'On-time bill perks & discounts',
    AppLang.ms: 'Faedah & diskaun bayaran tepat masa',
    AppLang.zh: '准时缴费优惠',
  },
  'menu.viewProfile': {
    AppLang.en: 'Tap to view profile',
    AppLang.ms: 'Ketik untuk lihat profil',
    AppLang.zh: '点击查看个人资料',
  },

  // Profile extras
  'profile.notifications': {
    AppLang.en: 'Notifications',
    AppLang.ms: 'Pemberitahuan',
    AppLang.zh: '通知',
  },
  'profile.residentDocuments': {
    AppLang.en: 'Resident Documents',
    AppLang.ms: 'Dokumen Penghuni',
    AppLang.zh: '住户文件',
  },
  'profile.financialRecords': {
    AppLang.en: 'Financial Records',
    AppLang.ms: 'Rekod Kewangan',
    AppLang.zh: '财务记录',
  },
  'profile.familyLogins': {
    AppLang.en: 'Family Logins',
    AppLang.ms: 'Log Masuk Keluarga',
    AppLang.zh: '家庭账号',
  },
  'profile.familyLoginsSub': {
    AppLang.en: 'Create a login for your wife or child. They sign in with '
        'their own email and password and see the same home, bills and '
        'visitors as you.',
    AppLang.ms: 'Buat log masuk untuk isteri atau anak anda. Mereka log masuk '
        'dengan e-mel dan kata laluan sendiri dan melihat rumah, bil serta '
        'pelawat yang sama seperti anda.',
    AppLang.zh: '为配偶或子女创建登录账号。他们使用自己的邮箱和密码登录，看到与您相同的住家、账单和访客信息。',
  },
  'profile.addFamilyLogin': {
    AppLang.en: 'Add family login',
    AppLang.ms: 'Tambah log masuk keluarga',
    AppLang.zh: '添加家庭账号',
  },
  'profile.tenancyAgreement': {
    AppLang.en: 'Tenancy Agreement',
    AppLang.ms: 'Perjanjian Sewa',
    AppLang.zh: '租赁协议',
  },
  'profile.appVersion': {
    AppLang.en: 'App version',
    AppLang.ms: 'Versi aplikasi',
    AppLang.zh: '应用版本',
  },

  // Signup extras (tenancy agreement, resident type)
  'signup.owner': {
    AppLang.en: 'Owner',
    AppLang.ms: 'Pemilik',
    AppLang.zh: '业主',
  },
  'signup.tenant': {
    AppLang.en: 'Tenant',
    AppLang.ms: 'Penyewa',
    AppLang.zh: '租户',
  },
  'signup.fullName': {
    AppLang.en: 'Full Name',
    AppLang.ms: 'Nama Penuh',
    AppLang.zh: '姓名',
  },
  'signup.communityCode': {
    AppLang.en: 'Residence Community Code',
    AppLang.ms: 'Kod Komuniti Kediaman',
    AppLang.zh: '社区代码',
  },
  'signup.tenancyRequired': {
    AppLang.en: 'Tenancy Agreement (required)',
    AppLang.ms: 'Perjanjian Sewa (wajib)',
    AppLang.zh: '租赁协议（必填）',
  },
  'signup.tenancyOptional': {
    AppLang.en: 'Tenancy Agreement / ownership doc (optional)',
    AppLang.ms: 'Perjanjian Sewa / dokumen pemilikan (pilihan)',
    AppLang.zh: '租赁协议／产权文件（选填）',
  },
  'signup.tenancyHint': {
    AppLang.en: 'Tap to upload a PDF or photo (max 10 MB)',
    AppLang.ms: 'Ketik untuk memuat naik PDF atau foto (maks 10 MB)',
    AppLang.zh: '点击上传 PDF 或照片（最大 10 MB）',
  },

  // -------------------------------------------------------------------------
  // Web portal (admin / guard / super admin / merchant sidebars)
  // -------------------------------------------------------------------------
  'admin.dashboard': {
    AppLang.en: 'Dashboard',
    AppLang.ms: 'Papan Pemuka',
    AppLang.zh: '仪表板',
  },
  'admin.residents': {
    AppLang.en: 'Residents',
    AppLang.ms: 'Penghuni',
    AppLang.zh: '住户',
  },
  'admin.houses': {
    AppLang.en: 'Houses',
    AppLang.ms: 'Rumah',
    AppLang.zh: '房屋',
  },
  'admin.visitors': {
    AppLang.en: 'Visitors',
    AppLang.ms: 'Pelawat',
    AppLang.zh: '访客',
  },
  'admin.billings': {
    AppLang.en: 'Billings',
    AppLang.ms: 'Bil',
    AppLang.zh: '账单',
  },
  'admin.facilities': {
    AppLang.en: 'Facilities',
    AppLang.ms: 'Kemudahan',
    AppLang.zh: '设施',
  },
  'admin.announcements': {
    AppLang.en: 'Announcements',
    AppLang.ms: 'Pengumuman',
    AppLang.zh: '公告',
  },
  'admin.events': {
    AppLang.en: 'Events',
    AppLang.ms: 'Acara',
    AppLang.zh: '活动',
  },
  'admin.alerts': {
    AppLang.en: 'Alerts',
    AppLang.ms: 'Amaran',
    AppLang.zh: '警报',
  },
  'admin.reports': {
    AppLang.en: 'Reports',
    AppLang.ms: 'Laporan',
    AppLang.zh: '报表',
  },
  'admin.rewards': {
    AppLang.en: 'Rewards',
    AppLang.ms: 'Ganjaran',
    AppLang.zh: '奖励',
  },
  'admin.guards': {
    AppLang.en: 'Guards',
    AppLang.ms: 'Pengawal',
    AppLang.zh: '保安',
  },
  'admin.settings': {
    AppLang.en: 'Settings',
    AppLang.ms: 'Tetapan',
    AppLang.zh: '设置',
  },
  'admin.export': {
    AppLang.en: 'Export',
    AppLang.ms: 'Eksport',
    AppLang.zh: '导出',
  },
  'admin.all': {AppLang.en: 'All', AppLang.ms: 'Semua', AppLang.zh: '全部'},

  // Shared status words (tables, pills, filters)
  'status.pending': {
    AppLang.en: 'Pending',
    AppLang.ms: 'Menunggu',
    AppLang.zh: '待处理',
  },
  'status.approved': {
    AppLang.en: 'Approved',
    AppLang.ms: 'Diluluskan',
    AppLang.zh: '已批准',
  },
  'status.rejected': {
    AppLang.en: 'Rejected',
    AppLang.ms: 'Ditolak',
    AppLang.zh: '已拒绝',
  },
  'status.paid': {AppLang.en: 'Paid', AppLang.ms: 'Dibayar', AppLang.zh: '已付'},
  'status.unpaid': {
    AppLang.en: 'Unpaid',
    AppLang.ms: 'Belum Dibayar',
    AppLang.zh: '未付',
  },
  'status.active': {
    AppLang.en: 'Active',
    AppLang.ms: 'Aktif',
    AppLang.zh: '启用',
  },
  'status.inactive': {
    AppLang.en: 'Inactive',
    AppLang.ms: 'Tidak Aktif',
    AppLang.zh: '停用',
  },

  // Guard portal sidebar
  'guard.visitorLogs': {
    AppLang.en: 'Visitor Logs',
    AppLang.ms: 'Log Pelawat',
    AppLang.zh: '访客记录',
  },
  'guard.houseDirectory': {
    AppLang.en: 'House Directory',
    AppLang.ms: 'Direktori Rumah',
    AppLang.zh: '房屋目录',
  },
  'guard.quickActions': {
    AppLang.en: 'QUICK ACTIONS',
    AppLang.ms: 'TINDAKAN PANTAS',
    AppLang.zh: '快捷操作',
  },
  'guard.scanQr': {
    AppLang.en: 'Scan QR',
    AppLang.ms: 'Imbas QR',
    AppLang.zh: '扫描二维码',
  },
  'guard.manualRegistration': {
    AppLang.en: 'Manual Registration',
    AppLang.ms: 'Pendaftaran Manual',
    AppLang.zh: '手动登记',
  },
};
