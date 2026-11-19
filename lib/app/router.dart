import 'package:go_router/go_router.dart';

import '../features/history/presentation/history_detail_page.dart';
import '../features/history/presentation/history_page.dart';
import '../features/home/presentation/home_page.dart';
import '../features/quote/presentation/quote_page.dart';
import '../features/result/presentation/result_page.dart';
import '../features/review/presentation/review_page.dart';
import '../features/scanner/presentation/scan_page.dart';
import '../features/settings/presentation/demo_settings_page.dart';

/// Route table (docs/03, docs/09).
final GoRouter goldPayRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/scan',
      name: 'scan',
      builder: (context, state) => const ScanPage(),
    ),
    GoRoute(
      path: '/review',
      name: 'review',
      builder: (context, state) => const ReviewPage(),
    ),
    GoRoute(
      path: '/quote',
      name: 'quote',
      builder: (context, state) => const QuotePage(),
    ),
    GoRoute(
      path: '/result',
      name: 'result',
      builder: (context, state) => const ResultPage(),
    ),
    GoRoute(
      path: '/history',
      name: 'history',
      builder: (context, state) => const HistoryPage(),
    ),
    GoRoute(
      path: '/history/:id',
      name: 'history-detail',
      builder: (context, state) =>
          HistoryDetailPage(transactionId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/demo-settings',
      name: 'demo-settings',
      builder: (context, state) => const DemoSettingsPage(),
    ),
  ],
);
