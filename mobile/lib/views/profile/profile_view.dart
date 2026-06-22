import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/user_profile.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/profile_provider.dart';
import '../../services/payment_service.dart';
import '../../utils/app_currency_formatter.dart';
import '../../utils/app_text.dart';
import '../../widgets/widgets.dart';
import '../auth/login_screen.dart';
import 'activity_history_view.dart';
import 'change_password_view.dart';
import 'edit_profile_view.dart';
import 'favorites_view.dart';
import 'notifications_view.dart';
import 'profile_session_helper.dart';
import 'settings_view.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> with WidgetsBindingObserver {
  static const primaryColor = Color(0xFF80ED99);
  bool _handledSessionExpired = false;

  int? _pendingDepositOrderCode;
  String? _pendingDepositPaymentMethod;
  bool _isDepositPendingDialogOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().fetchProfile(forceRefresh: false);
      context.read<NotificationProvider>().fetchUnreadCount();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_pendingDepositOrderCode != null) {
        _checkPendingDepositStatus();
      }
    }
  }

  Future<void> _checkPendingDepositStatus() async {
    final orderCode = _pendingDepositOrderCode;
    final paymentMethod = _pendingDepositPaymentMethod;
    if (orderCode == null) return;

    // Reset immediately to avoid double checking if lifecycle state changes rapidly
    _pendingDepositOrderCode = null;
    _pendingDepositPaymentMethod = null;

    // Show loading dialog
    if (mounted) {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => const Center(
          child: CircularProgressIndicator(color: primaryColor),
        ),
      );
    }

    try {
      final status = await PaymentService().getPaymentByOrderCode(orderCode);
      if (!mounted) return;
      
      Navigator.of(context).pop(); // Close loading dialog

      if (_isDepositPendingDialogOpen) {
        Navigator.of(context).pop(); // Close the pending instruction dialog
        _isDepositPendingDialogOpen = false;
      }

      if (status.isPaid) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nạp tiền vào ví qua $paymentMethod thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Giao dịch qua $paymentMethod chưa hoàn tất hoặc thất bại.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      context.read<ProfileProvider>().fetchProfile(forceRefresh: true);
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        context.read<ProfileProvider>().fetchProfile(forceRefresh: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Consumer<ProfileProvider>(
          builder: (context, provider, _) {
            _handleSessionExpired(provider);

            if (provider.isLoading && provider.profileData == null) {
              return const Center(
                child: CircularProgressIndicator(color: primaryColor),
              );
            }

            if (provider.error != null &&
                provider.profileData == null &&
                !provider.hasSessionExpired) {
              return _ErrorState(
                message: provider.error!,
                onRetry: () => provider.fetchProfile(forceRefresh: true),
              );
            }

            final user = provider.profileData;
            if (user == null) {
              return _ErrorState(
                message: 'Không thể tải thông tin hồ sơ.',
                onRetry: () => provider.fetchProfile(forceRefresh: true),
              );
            }

            return RefreshIndicator(
              color: primaryColor,
              onRefresh: () => provider.fetchProfile(forceRefresh: true),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          context.tr(vi: 'Hồ sơ', en: 'Profile'),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const EditProfileView(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: context.tr(
                          vi: 'Chỉnh sửa hồ sơ',
                          en: 'Edit profile',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _ProfileHero(user: user),
                  const SizedBox(height: 16),
                  _WalletCard(
                    user: user,
                    onDeposit: () => _showDepositBottomSheet(context, provider),
                    onWithdraw: () => _showWithdrawBottomSheet(context, provider),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      StatCard(
                        value: '${user.tripsCount}',
                        label: context.tr(vi: 'Chuyến đi', en: 'Trips'),
                        color: primaryColor,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ActivityHistoryView(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      StatCard(
                        value: '${user.coins}',
                        label: context.tr(vi: 'Xu', en: 'Coins'),
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 12),
                      StatCard(
                        value: '${user.vouchers}',
                        label: context.tr(vi: 'Voucher', en: 'Vouchers'),
                        color: Colors.pink,
                        onTap: () =>
                            _showVouchersBottomSheet(context, provider),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _SectionTitle(
                    title: context.tr(
                      vi: 'Thông tin tài khoản',
                      en: 'Account info',
                    ),
                  ),
                  _CardSection(
                    children: [
                      _InfoTile(
                        icon: Icons.mail_outline,
                        title: context.tr(vi: 'Email', en: 'Email'),
                        subtitle: user.email,
                        trailingText: user.isEmailVerified
                            ? context.tr(vi: 'Đã xác thực', en: 'Verified')
                            : context.tr(
                                vi: 'Chưa xác thực',
                                en: 'Not verified',
                              ),
                      ),
                      const Divider(height: 1),
                      _InfoTile(
                        icon: Icons.phone_outlined,
                        title: context.tr(vi: 'Số điện thoại', en: 'Phone'),
                        subtitle: user.phone.isEmpty
                            ? context.tr(vi: 'Chưa cập nhật', en: 'Not updated')
                            : user.phone,
                      ),
                      const Divider(height: 1),
                      _InfoTile(
                        icon: Icons.cake_outlined,
                        title: context.tr(vi: 'Ngày sinh', en: 'Birth date'),
                        subtitle: user.birthDate.isEmpty
                            ? context.tr(vi: 'Chưa cập nhật', en: 'Not updated')
                            : user.birthDate,
                      ),
                      const Divider(height: 1),
                      _InfoTile(
                        icon: Icons.credit_card_outlined,
                        title: context.tr(
                          vi: 'Số CCCD / CMND',
                          en: 'ID Card Number',
                        ),
                        subtitle:
                            (user.identityNumber == null ||
                                user.identityNumber!.isEmpty)
                            ? context.tr(vi: 'Chưa cập nhật', en: 'Not updated')
                            : user.identityNumber!,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _SectionTitle(
                    title: context.tr(vi: 'Tiện ích', en: 'Utilities'),
                  ),
                  _CardSection(
                    children: [
                      Consumer<NotificationProvider>(
                        builder: (context, notificationProvider, _) {
                          return MenuItemTile(
                            icon: Icons.notifications_outlined,
                            title: context.tr(
                              vi: 'Thông báo',
                              en: 'Notifications',
                            ),
                            color: primaryColor,
                            badgeCount: notificationProvider.unreadCount,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const NotificationsView(),
                                ),
                              );
                            },
                          );
                        },
                      ),
                      const MenuDivider(),
                      MenuItemTile(
                        icon: Icons.person_outline,
                        title: context.tr(
                          vi: 'Chỉnh sửa hồ sơ',
                          en: 'Edit profile',
                        ),
                        color: primaryColor,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const EditProfileView(),
                            ),
                          );
                        },
                      ),
                      const MenuDivider(),
                      MenuItemTile(
                        icon: Icons.lock_outline,
                        title: context.tr(
                          vi: 'Đổi mật khẩu',
                          en: 'Change password',
                        ),
                        color: primaryColor,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ChangePasswordView(),
                            ),
                          );
                        },
                      ),
                      const MenuDivider(),
                      MenuItemTile(
                        icon: Icons.favorite_outline,
                        title: context.tr(
                          vi: 'Dịch vụ yêu thích',
                          en: 'Favorites',
                        ),
                        color: primaryColor,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const FavoritesView(),
                            ),
                          );
                        },
                      ),
                      const MenuDivider(),
                      MenuItemTile(
                        icon: Icons.history,
                        title: context.tr(
                          vi: 'Lịch sử hoạt động',
                          en: 'Activity history',
                        ),
                        color: primaryColor,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ActivityHistoryView(),
                            ),
                          );
                        },
                      ),
                      const MenuDivider(),
                      MenuItemTile(
                        icon: Icons.settings_outlined,
                        title: context.tr(vi: 'Cài đặt', en: 'Settings'),
                        color: primaryColor,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SettingsView(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    onPressed: _confirmLogout,
                    icon: const Icon(Icons.logout),
                    label: Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(context.tr(vi: 'Đăng xuất', en: 'Sign out')),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade600,
                      side: BorderSide(color: Colors.red.shade200),
                      backgroundColor: Colors.red.shade50,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final shouldLogout =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: Text(context.tr(vi: 'Đăng xuất', en: 'Sign out')),
              content: Text(
                context.tr(
                  vi: 'Bạn có chắc muốn đăng xuất khỏi tài khoản?',
                  en: 'Do you want to sign out of this account?',
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(context.tr(vi: 'Hủy', en: 'Cancel')),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: Text(context.tr(vi: 'Đăng xuất', en: 'Sign out')),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!shouldLogout || !mounted) {
      return;
    }

    await context.read<AuthProvider>().logout();
    if (!mounted) {
      return;
    }

    context.read<ChatProvider>().resetForSignedOutUser();
    context.read<NotificationProvider>().reset();
    context.read<ProfileProvider>().logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _handleSessionExpired(ProfileProvider provider) async {
    if (_handledSessionExpired || !provider.hasSessionExpired || !mounted) {
      return;
    }

    _handledSessionExpired = true;
    await showSessionExpiredDialog(context, message: provider.error);
  }

  void _showDepositBottomSheet(BuildContext context, ProfileProvider provider) {
    final TextEditingController amountController = TextEditingController();
    bool isDepositing = false;
    int selectedPaymentMethod = 1; // 1 = VNPAY, 0 = PayOS

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.tr(vi: 'Nạp tiền vào ví', en: 'Deposit to wallet'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () => Navigator.pop(sheetContext),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: context.tr(vi: 'Số tiền nạp (VND)', en: 'Amount (VND)'),
                        hintText: 'Ví dụ: 200.000',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.monetization_on_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [100000, 200000, 500000, 1000000, 2000000].map((val) {
                        return InkWell(
                          onTap: () {
                            setSheetState(() {
                              amountController.text = val.toString();
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              border: Border.all(color: Colors.green[200]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              AppCurrencyFormatter.format(val),
                              style: const TextStyle(
                                color: Color(0xFF0D6B42),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.tr(vi: 'Phương thức thanh toán', en: 'Payment Method'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<int>(
                            title: const Text('VNPAY'),
                            value: 1,
                            groupValue: selectedPaymentMethod,
                            onChanged: (val) => setSheetState(() => selectedPaymentMethod = val!),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<int>(
                            title: const Text('PayOS'),
                            value: 0,
                            groupValue: selectedPaymentMethod,
                            onChanged: (val) => setSheetState(() => selectedPaymentMethod = val!),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: isDepositing
                          ? null
                          : () async {
                              final amountStr = amountController.text.replaceAll('.', '').replaceAll(',', '').trim();
                              final amount = double.tryParse(amountStr) ?? 0.0;
                              if (amount <= 0) {
                                ScaffoldMessenger.of(sheetContext).showSnackBar(
                                  SnackBar(
                                    content: Text(context.tr(
                                      vi: 'Vui lòng nhập số tiền hợp lệ lớn hơn 0.',
                                      en: 'Please enter a valid amount greater than 0.',
                                    )),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              } else if (amount > 50000000) {
                                ScaffoldMessenger.of(sheetContext).showSnackBar(
                                  SnackBar(
                                    content: Text(context.tr(
                                      vi: 'Số tiền nạp tối đa là 50.000.000 VND.',
                                      en: 'Maximum deposit amount is 50,000,000 VND.',
                                    )),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }

                              setSheetState(() => isDepositing = true);
                              try {
                                final paymentMethodStr = selectedPaymentMethod == 0 ? 'PAYOS' : 'VNPAY';
                                final orderCodeForPayOs = selectedPaymentMethod == 0 ? DateTime.now().millisecondsSinceEpoch % 1000000000 : null;
                                final result = await PaymentService().createWalletDeposit(
                                    amount: amount, 
                                    paymentMethod: paymentMethodStr, 
                                    orderCode: orderCodeForPayOs
                                );
                                final checkoutUrl = result.checkoutUrl;
                                final orderCode = result.orderCode;

                                if (checkoutUrl == null || checkoutUrl.isEmpty) {
                                  throw Exception('Không tạo được link thanh toán $paymentMethodStr.');
                                }

                                Navigator.pop(sheetContext); // Close sheet
                                _pendingDepositOrderCode = orderCode;
                                _pendingDepositPaymentMethod = paymentMethodStr;
                                await launchUrl(Uri.parse(checkoutUrl), mode: LaunchMode.externalApplication);
                                if (context.mounted) {
                                  _showDepositPendingDialog(context, orderCode ?? 0, paymentMethodStr);
                                }
                              } catch (e) {
                                setSheetState(() => isDepositing = false);
                                ScaffoldMessenger.of(sheetContext).showSnackBar(
                                  SnackBar(content: Text('Lỗi nạp tiền: ${e.toString()}')),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D6B42),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isDepositing
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              context.tr(vi: 'Tiếp tục thanh toán', en: 'Proceed to Payment'),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showDepositPendingDialog(BuildContext context, int orderCode, String paymentMethod) async {
    _isDepositPendingDialogOpen = true;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Hoàn tất nạp tiền $paymentMethod'),
          content: Text(
            'Trang nạp tiền $paymentMethod đã được mở trên trình duyệt. Sau khi nạp tiền thành công, hãy nhấn Xác nhận bên dưới để kiểm tra số dư mới.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                _pendingDepositOrderCode = null;
                _pendingDepositPaymentMethod = null;
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Để sau'),
            ),
            FilledButton(
              onPressed: () async {
                _pendingDepositOrderCode = null;
                _pendingDepositPaymentMethod = null;
                Navigator.of(dialogContext).pop();
                try {
                  final status = await PaymentService().getPaymentByOrderCode(orderCode);
                  if (status.isPaid) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Nạp tiền vào ví thành công!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      context.read<ProfileProvider>().fetchProfile(forceRefresh: true);
                    }
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Giao dịch chưa hoàn tất hoặc thất bại.'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      context.read<ProfileProvider>().fetchProfile(forceRefresh: true);
                    }
                  }
                } catch (_) {
                  if (context.mounted) {
                    context.read<ProfileProvider>().fetchProfile(forceRefresh: true);
                  }
                }
              },
              child: const Text('Xác nhận'),
            ),
          ],
        );
      },
    );
    _isDepositPendingDialogOpen = false;
  }

  void _showWithdrawBottomSheet(BuildContext context, ProfileProvider provider) {
    final TextEditingController amountController = TextEditingController();
    String? selectedBankCode;
    final TextEditingController accountController = TextEditingController();
    final TextEditingController nameController = TextEditingController();
    bool isWithdrawing = false;

    String? bankError;
    String? accountError;
    String? nameError;
    String? amountError;

    final Map<String, String> bankList = {
      'VCB': 'Vietcombank',
      'TCB': 'Techcombank',
      'MB': 'MBBank',
      'VIB': 'VIB',
      'ACB': 'ACB',
      'VPB': 'VPBank',
      'BIDV': 'BIDV',
      'CTG': 'VietinBank',
      'STB': 'Sacombank',
      'HDB': 'HDBank',
      'TPB': 'TPBank',
    };

    final balance = provider.profileData?.walletBalance ?? 0.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            context.tr(vi: 'Rút tiền về tài khoản', en: 'Withdraw from wallet'),
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.grey),
                            onPressed: () => Navigator.pop(sheetContext),
                          ),
                        ],
                      ),
                      const Divider(),
                      const SizedBox(height: 8),
                      Text(
                        'Số dư hiện tại: ${AppCurrencyFormatter.format(balance)}',
                        style: const TextStyle(
                          color: Color(0xFF0D6B42),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedBankCode,
                        decoration: InputDecoration(
                          labelText: context.tr(vi: 'Chọn Ngân hàng đích', en: 'Select Destination Bank'),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.account_balance_outlined),
                          errorText: bankError,
                        ),
                        items: bankList.entries.map((e) {
                          return DropdownMenuItem<String>(
                            value: e.key,
                            child: Text('${e.key} - ${e.value}'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setSheetState(() {
                            selectedBankCode = value;
                            bankError = null;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: accountController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: InputDecoration(
                          labelText: context.tr(vi: 'Số tài khoản', en: 'Account Number'),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.badge_outlined),
                          errorText: accountError,
                        ),
                        onChanged: (value) {
                          if (accountError != null) {
                            setSheetState(() => accountError = null);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: nameController,
                        inputFormatters: [UpperUnaccentedFormatter()],
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          labelText: context.tr(vi: 'Tên chủ tài khoản (Viết hoa không dấu)', en: 'Account Name (Uppercase without tone)'),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.person_outline),
                          errorText: nameError,
                        ),
                        onChanged: (value) {
                          if (nameError != null) {
                            setSheetState(() => nameError = null);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: context.tr(vi: 'Số tiền rút (VND)', en: 'Amount (VND)'),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.monetization_on_outlined),
                          errorText: amountError,
                        ),
                        onChanged: (value) {
                          if (amountError != null) {
                            setSheetState(() => amountError = null);
                          }
                        },
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: isWithdrawing
                            ? null
                            : () async {
                                setSheetState(() {
                                  bankError = null;
                                  accountError = null;
                                  nameError = null;
                                  amountError = null;
                                });

                                bool hasError = false;

                                if (selectedBankCode == null) {
                                  setSheetState(() => bankError = 'Vui lòng chọn ngân hàng đích.');
                                  hasError = true;
                                }

                                final accountNumber = accountController.text.trim();
                                if (accountNumber.isEmpty) {
                                  setSheetState(() => accountError = 'Vui lòng nhập số tài khoản.');
                                  hasError = true;
                                } else if (!RegExp(r'^\d{6,18}$').hasMatch(accountNumber)) {
                                  setSheetState(() => accountError = 'Số tài khoản không hợp lệ (từ 6 đến 18 chữ số).');
                                  hasError = true;
                                }

                                final accountName = nameController.text.trim().toUpperCase();
                                if (accountName.isEmpty) {
                                  setSheetState(() => nameError = 'Vui lòng nhập tên chủ tài khoản.');
                                  hasError = true;
                                } else if (!RegExp(r'^[A-Z ]+$').hasMatch(accountName)) {
                                  setSheetState(() => nameError = 'Tên chủ tài khoản phải viết hoa không dấu.');
                                  hasError = true;
                                }

                                final amountStr = amountController.text.replaceAll('.', '').replaceAll(',', '').trim();
                                final amount = double.tryParse(amountStr) ?? 0.0;
                                if (amountStr.isEmpty) {
                                  setSheetState(() => amountError = 'Vui lòng nhập số tiền rút.');
                                  hasError = true;
                                } else if (amount < 50000) {
                                  setSheetState(() => amountError = 'Số tiền rút tối thiểu là 50.000 VND.');
                                  hasError = true;
                                } else if (amount > balance) {
                                  setSheetState(() => amountError = 'Số dư ví không đủ.');
                                  hasError = true;
                                }

                                if (hasError) return;

                                setSheetState(() => isWithdrawing = true);
                                try {
                                  final result = await PaymentService().withdrawFromWallet(
                                    amount: amount,
                                    bankName: selectedBankCode!,
                                    accountNumber: accountNumber,
                                    accountName: accountName,
                                  );

                                  Navigator.pop(sheetContext); // Close sheet
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(result['message'] ?? 'Yêu cầu rút tiền đang được xử lý.'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                    context.read<ProfileProvider>().fetchProfile(forceRefresh: true);
                                  }
                                } catch (e) {
                                  setSheetState(() => isWithdrawing = false);
                                  ScaffoldMessenger.of(sheetContext).showSnackBar(
                                    SnackBar(content: Text('Lỗi rút tiền: ${e.toString()}')),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D6B42),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isWithdrawing
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                context.tr(vi: 'Yêu cầu rút tiền', en: 'Request Withdrawal'),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showVouchersBottomSheet(
    BuildContext context,
    ProfileProvider provider,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Color(0xFFE0E0E0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.tr(
                            vi: 'Mã khuyến mãi khả dụng',
                            en: 'Your Voucher Inventory',
                          ),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: provider.myVouchers.every((v) => v.quantity == 0)
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.card_giftcard,
                                  size: 64,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  context.tr(
                                    vi: 'Hiện chưa có mã khuyến mãi khả dụng.',
                                    en: 'Inventory is empty. You have no vouchers.',
                                  ),
                                  style: TextStyle(color: Colors.grey[500]),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.all(20),
                            itemCount: provider.myVouchers.length,
                            itemBuilder: (context, index) {
                              final voucher = provider.myVouchers[index];
                              if (voucher.quantity <= 0)
                                return const SizedBox.shrink();
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Color(0xFFEEEEEE)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.02,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE8F5EE),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: const Color(0xFFC2E8D4),
                                        ),
                                      ),
                                      child: Text(
                                        voucher.code,
                                        style: const TextStyle(
                                          color: Color(0xFF0D6B42),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            voucher.title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            voucher.description,
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            voucher.expiry,
                                            style: TextStyle(
                                              color: Colors.grey[400],
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Color(0xFFF5F5F5),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'x${voucher.quantity}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.user});

  final UserProfile user;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF80ED99), Color(0xFF57CC99)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          ProfileAvatar(
            avatarUrl: user.avatarUrl,
            heroTag: 'profile_avatar_main',
          ),
          const SizedBox(height: 16),
          Text(
            user.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              user.memberTier,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade500,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

class _CardSection extends StatelessWidget {
  const _CardSection({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black26
                : Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailingText,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? trailingText;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: trailingText == null
          ? null
          : Text(
              trailingText!,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              child: Text(context.tr(vi: 'Thử lại', en: 'Retry')),
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletCard extends StatelessWidget {
  const _WalletCard({required this.user, required this.onDeposit, required this.onWithdraw});

  final UserProfile user;
  final VoidCallback onDeposit;
  final VoidCallback onWithdraw;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D6B42), Color(0xFF1A9C62)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D6B42).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.account_balance_wallet, color: Colors.white70, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    context.tr(vi: 'VÍ SMARTTRIP', en: 'SMARTTRIP WALLET'),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const Icon(Icons.nfc, color: Colors.white24, size: 28),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            AppCurrencyFormatter.format(user.walletBalance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: onDeposit,
                  icon: const Icon(Icons.add_rounded, color: Colors.white),
                  label: Text(
                    context.tr(vi: 'Nạp tiền', en: 'Deposit'),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.18),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextButton.icon(
                  onPressed: onWithdraw,
                  icon: const Icon(Icons.arrow_outward_rounded, color: Colors.white),
                  label: Text(
                    context.tr(vi: 'Rút tiền', en: 'Withdraw'),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.18),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class UpperUnaccentedFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final newText = removeDiacritics(newValue.text).toUpperCase();
    return TextEditingValue(
      text: newText,
      selection: newValue.selection.copyWith(
        baseOffset: newValue.selection.baseOffset > newText.length ? newText.length : newValue.selection.baseOffset,
        extentOffset: newValue.selection.extentOffset > newText.length ? newText.length : newValue.selection.extentOffset,
      ),
    );
  }

  String removeDiacritics(String str) {
    const vietnamese = 'aAeEoOuUiIdDyY';
    const vietnameseRegex = [
      '[àáạảãâầấậẩẫăằắặẳẵ]',
      '[ÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴ]',
      '[èéẹẻẽêềếệểễ]',
      '[ÈÉẸẺẼÊỀẾỆỂỄ]',
      '[òóọỏõôồốộổỗơờớợởỡ]',
      '[ÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠ]',
      '[ùúụủũưừứựửữ]',
      '[ÙÚỤỦŨƯỪỨỰỬỮ]',
      '[ìíịỉĩ]',
      '[ÌÍỊỈĨ]',
      '[đ]',
      '[Đ]',
      '[ỳýỵỷỹ]',
      '[ỲÝỴỶỸ]'
    ];

    for (var i = 0; i < vietnameseRegex.length; i++) {
      str = str.replaceAll(RegExp(vietnameseRegex[i]), vietnamese[i]);
    }
    return str;
  }
}


