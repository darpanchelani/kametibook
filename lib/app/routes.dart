import 'package:flutter/material.dart';

import '../core/widgets/protected_kameti_route.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/signup_screen.dart';
import '../features/bidding/screens/bidding_detail_screen.dart';
import '../features/bidding/screens/bidding_history_screen.dart';
import '../features/bidding/screens/bidding_screen.dart';
import '../features/cloud/screens/invite_member_screen.dart';
import '../features/cloud/screens/join_kameti_screen.dart';
import '../features/home/screens/main_layout.dart';
import '../features/kameti/screens/create_kameti_screen.dart';
import '../features/kameti/screens/kameti_details_screen.dart';
import '../features/ledger/screens/financial_summary_screen.dart';
import '../features/ledger/screens/group_ledger_screen.dart';
import '../features/ledger/screens/ledger_detail_screen.dart';
import '../features/ledger/screens/manual_ledger_entry_screen.dart';
import '../features/lucky_draw/screens/draw_detail_screen.dart';
import '../features/lucky_draw/screens/draw_history_screen.dart';
import '../features/lucky_draw/screens/lucky_draw_screen.dart';
import '../features/member/screens/add_member_screen.dart';
import '../features/member/screens/edit_member_screen.dart';
import '../features/member/screens/member_details_screen.dart';
import '../features/member/screens/members_list_screen.dart';
import '../features/notifications/screens/kameti_alerts_screen.dart';
import '../features/notifications/screens/notification_preferences_screen.dart';
import '../features/notifications/screens/reminder_settings_screen.dart';
import '../features/onboarding/screens/onboarding_screen.dart';
import '../features/onboarding/screens/splash_screen.dart';
import '../features/payment/screens/cycle_payments_screen.dart';
import '../features/payment/screens/payment_cycles_screen.dart';
import '../features/payment/screens/submit_payment_proof_screen.dart';
import '../features/receiver/models/receiver_allocation_model.dart';
import '../features/receiver/screens/fixed_order_setup_screen.dart';
import '../features/receiver/screens/manual_receiver_selection_screen.dart';
import '../features/receiver/screens/owner_first_settings_screen.dart';
import '../features/reports/models/report_model.dart';
import '../features/reports/screens/report_history_screen.dart';
import '../features/reports/screens/report_preview_screen.dart';
import '../features/reports/screens/reports_dashboard_screen.dart';
import '../features/security/screens/audit_detail_screen.dart';
import '../features/security/screens/audit_log_screen.dart';
import '../features/security/screens/create_dispute_screen.dart';
import '../features/security/screens/dispute_detail_screen.dart';
import '../features/security/screens/disputes_screen.dart';
import '../features/security/screens/privacy_settings_screen.dart';
import '../features/security/screens/report_user_screen.dart';
import '../features/security/screens/security_center_screen.dart';
import '../features/security/screens/trust_score_detail_screen.dart';

class AppRoutes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const signup = '/signup';
  static const forgotPassword = '/forgot-password';
  static const main = '/main';
  static const createKameti = '/create-kameti';
  static const kametiDetails = '/kameti-details';
  static const members = '/members';
  static const addMember = '/add-member';
  static const editMember = '/edit-member';
  static const memberDetails = '/member-details';
  static const paymentCycles = '/payment-cycles';
  static const cyclePayments = '/cycle-payments';
  static const luckyDraw = '/lucky-draw';
  static const drawHistory = '/draw-history';
  static const drawDetail = '/draw-detail';
  static const bidding = '/bidding';
  static const biddingHistory = '/bidding-history';
  static const biddingDetail = '/bidding-detail';
  static const manualReceiver = '/manual-receiver';
  static const fixedOrderSetup = '/fixed-order-setup';
  static const ownerFirstSettings = '/owner-first-settings';
  static const groupLedger = '/group-ledger';
  static const ledgerDetail = '/ledger-detail';
  static const financialSummary = '/financial-summary';
  static const manualLedgerEntry = '/manual-ledger-entry';
  static const reportsDashboard = '/reports-dashboard';
  static const reportPreview = '/report-preview';
  static const reportHistory = '/report-history';
  static const kametiAlerts = '/kameti-alerts';
  static const reminderSettings = '/reminder-settings';
  static const notificationPreferences = '/notification-preferences';
  static const inviteMember = '/invite-member';
  static const joinKameti = '/join-kameti';
  static const submitPaymentProof = '/submit-payment-proof';
  static const securityCenter = '/security-center';
  static const auditLogs = '/audit-logs';
  static const auditDetail = '/audit-detail';
  static const disputes = '/disputes';
  static const disputeDetail = '/dispute-detail';
  static const createDispute = '/create-dispute';
  static const trustScore = '/trust-score';
  static const privacySettings = '/privacy-settings';
  static const reportUser = '/report-user';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    return MaterialPageRoute(
      settings: settings,
      builder: (_) {
        switch (settings.name) {
          case splash:
            return const SplashScreen();
          case onboarding:
            return const OnboardingScreen();
          case login:
            return const LoginScreen();
          case signup:
            return const SignupScreen();
          case forgotPassword:
            return const ForgotPasswordScreen();
          case main:
            final initialTab = settings.arguments is int ? settings.arguments as int : 0;
            return MainLayout(initialTab: initialTab);
          case createKameti:
            return const CreateKametiScreen();
          case kametiDetails:
            final kametiId = settings.arguments! as String;
            return ProtectedKametiRoute(kametiId: kametiId, child: KametiDetailsScreen(kametiId: kametiId));
          case members:
            final kametiId = settings.arguments! as String;
            return ProtectedKametiRoute(kametiId: kametiId, child: MembersListScreen(kametiId: kametiId));
          case addMember:
            final kametiId = settings.arguments! as String;
            return ProtectedKametiRoute(kametiId: kametiId, requireManager: true, child: AddMemberScreen(kametiId: kametiId));
          case editMember:
            final args = settings.arguments! as Map<String, String>;
            return EditMemberScreen(kametiId: args['kametiId']!, memberId: args['memberId']!);
          case memberDetails:
            return MemberDetailsScreen(memberId: settings.arguments! as String);
          case paymentCycles:
            final kametiId = settings.arguments! as String;
            return ProtectedKametiRoute(kametiId: kametiId, child: PaymentCyclesScreen(kametiId: kametiId));
          case cyclePayments:
            return CyclePaymentsScreen(cycleId: settings.arguments! as String);
          case luckyDraw:
            final kametiId = settings.arguments! as String;
            return ProtectedKametiRoute(kametiId: kametiId, child: LuckyDrawScreen(kametiId: kametiId));
          case drawHistory:
            final kametiId = settings.arguments! as String;
            return ProtectedKametiRoute(kametiId: kametiId, child: DrawHistoryScreen(kametiId: kametiId));
          case drawDetail:
            return DrawDetailScreen(drawId: settings.arguments! as String);
          case bidding:
            final kametiId = settings.arguments! as String;
            return ProtectedKametiRoute(kametiId: kametiId, child: BiddingScreen(kametiId: kametiId));
          case biddingHistory:
            final kametiId = settings.arguments! as String;
            return ProtectedKametiRoute(kametiId: kametiId, child: BiddingHistoryScreen(kametiId: kametiId));
          case biddingDetail:
            return BiddingDetailScreen(sessionId: settings.arguments! as String);
          case manualReceiver:
            final args = settings.arguments! as Map<String, Object>;
            final kametiId = args['kametiId']! as String;
            return ProtectedKametiRoute(
              kametiId: kametiId,
              requireManager: true,
              child: ManualReceiverSelectionScreen(
                kametiId: kametiId,
                allocationType: args['allocationType']! as ReceiverAllocationType,
              ),
            );
          case fixedOrderSetup:
            final kametiId = settings.arguments! as String;
            return ProtectedKametiRoute(kametiId: kametiId, requireManager: true, child: FixedOrderSetupScreen(kametiId: kametiId));
          case ownerFirstSettings:
            final kametiId = settings.arguments! as String;
            return ProtectedKametiRoute(kametiId: kametiId, requireManager: true, child: OwnerFirstSettingsScreen(kametiId: kametiId));
          case groupLedger:
            final kametiId = settings.arguments! as String;
            return ProtectedKametiRoute(kametiId: kametiId, child: GroupLedgerScreen(kametiId: kametiId));
          case ledgerDetail:
            return LedgerDetailScreen(entryId: settings.arguments! as String);
          case financialSummary:
            final kametiId = settings.arguments! as String;
            return ProtectedKametiRoute(kametiId: kametiId, child: FinancialSummaryScreen(kametiId: kametiId));
          case manualLedgerEntry:
            final kametiId = settings.arguments! as String;
            return ProtectedKametiRoute(kametiId: kametiId, requireManager: true, child: ManualLedgerEntryScreen(kametiId: kametiId));
          case reportsDashboard:
            final kametiId = settings.arguments! as String;
            return ProtectedKametiRoute(kametiId: kametiId, child: ReportsDashboardScreen(kametiId: kametiId));
          case reportPreview:
            return ReportPreviewScreen(data: settings.arguments! as ReportData);
          case reportHistory:
            final kametiId = settings.arguments! as String;
            return ProtectedKametiRoute(kametiId: kametiId, child: ReportHistoryScreen(kametiId: kametiId));
          case kametiAlerts:
            final kametiId = settings.arguments! as String;
            return ProtectedKametiRoute(kametiId: kametiId, child: KametiAlertsScreen(kametiId: kametiId));
          case reminderSettings:
            final kametiId = settings.arguments! as String;
            return ProtectedKametiRoute(kametiId: kametiId, requireManager: true, child: ReminderSettingsScreen(kametiId: kametiId));
          case notificationPreferences:
            return const NotificationPreferencesScreen();
          case inviteMember:
            final kametiId = settings.arguments! as String;
            return ProtectedKametiRoute(kametiId: kametiId, requireManager: true, child: InviteMemberScreen(kametiId: kametiId));
          case joinKameti:
            return const JoinKametiScreen();
          case submitPaymentProof:
            return SubmitPaymentProofScreen(paymentId: settings.arguments! as String);
          case securityCenter:
            final kametiId = settings.arguments is String ? settings.arguments! as String : '';
            return kametiId.isEmpty ? SecurityCenterScreen(kametiId: kametiId) : ProtectedKametiRoute(kametiId: kametiId, child: SecurityCenterScreen(kametiId: kametiId));
          case auditLogs:
            final kametiId = settings.arguments! as String;
            return ProtectedKametiRoute(kametiId: kametiId, requireManager: true, child: AuditLogScreen(kametiId: kametiId));
          case auditDetail:
            return AuditDetailScreen(auditId: settings.arguments! as String);
          case disputes:
            final kametiId = settings.arguments! as String;
            return ProtectedKametiRoute(kametiId: kametiId, child: DisputesScreen(kametiId: kametiId));
          case disputeDetail:
            return DisputeDetailScreen(disputeId: settings.arguments! as String);
          case createDispute:
            return CreateDisputeScreen(args: settings.arguments! as CreateDisputeArgs);
          case trustScore:
            return TrustScoreDetailScreen(memberId: settings.arguments! as String);
          case privacySettings:
            return const PrivacySettingsScreen();
          case reportUser:
            return ReportUserScreen(args: settings.arguments! as ReportUserArgs);
          default:
            return const SplashScreen();
        }
      },
    );
  }
}
