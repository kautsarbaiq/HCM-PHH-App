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
    AppLang.en: 'Home Cloud Asia',
    AppLang.ms: 'Home Cloud Asia',
    AppLang.zh: 'Home Cloud Asia',
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
};
