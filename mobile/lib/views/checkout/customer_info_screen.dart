import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/resort_model.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/checkout/checkout_stepper.dart';
import '../profile/edit_profile_view.dart';
import 'payment_confirm_screen.dart';

class CustomerInfoScreen extends StatefulWidget {
  final ResortModel hotel;
  final RoomModel? selectedRoom;
  final DateTime checkIn;
  final DateTime checkOut;
  final int adultCount;
  final int childCount;
  final int infantCount;
  final int roomQuantity;
  final double totalPrice;
  final int? existingTripId;
  final int? existingTripDayNumber;
  final DateTime? existingTripStartDate;
  final DateTime? existingTripEndDate;

  const CustomerInfoScreen({
    Key? key,
    required this.hotel,
    this.selectedRoom,
    required this.checkIn,
    required this.checkOut,
    required this.adultCount,
    required this.childCount,
    required this.infantCount,
    required this.roomQuantity,
    required this.totalPrice,
    this.existingTripId,
    this.existingTripDayNumber,
    this.existingTripStartDate,
    this.existingTripEndDate,
  }) : super(key: key);

  @override
  State<CustomerInfoScreen> createState() => _CustomerInfoScreenState();
}

class _CustomerInfoScreenState extends State<CustomerInfoScreen> {
  bool isPassenger = true;
  bool _isCheckingProfile = true;
  bool _redirectingToProfile = false;

  late final TextEditingController _fullNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _specialRequestController;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _specialRequestController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfileInfo());
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _specialRequestController.dispose();
    super.dispose();
  }

  String _formatPriceFull(double price) {
    final formatted = price
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
    return '$formatted₫';
  }

  bool _hasRequiredProfileInfo() {
    return _fullNameController.text.trim().isNotEmpty &&
        _emailController.text.trim().isNotEmpty &&
        _phoneController.text.trim().isNotEmpty;
  }

  Future<void> _loadProfileInfo({bool forceRefresh = false}) async {
    final provider = context.read<ProfileProvider>();
    if (provider.profileData == null || forceRefresh) {
      await provider.fetchProfile(forceRefresh: true);
    }

    if (!mounted) return;

    final profile = provider.profileData;
    _fullNameController.text = profile?.name ?? '';
    _emailController.text = profile?.email ?? '';
    _phoneController.text = profile?.phone ?? '';

    setState(() => _isCheckingProfile = false);

    if (!_hasRequiredProfileInfo() && !_redirectingToProfile) {
      _redirectingToProfile = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui long cap nhat ho so truoc khi dat phong.'),
        ),
      );
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const EditProfileView()),
      );
      if (!mounted) return;
      await _loadProfileInfo(forceRefresh: true);
      _redirectingToProfile = false;
    }
  }

  Future<void> _continueToPayment() async {
    if (!_hasRequiredProfileInfo()) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const EditProfileView()),
      );
      if (!mounted) return;
      await _loadProfileInfo(forceRefresh: true);
      if (!mounted) return;
      if (!_hasRequiredProfileInfo()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ho so van thieu ho ten, email hoac so dien thoai.'),
          ),
        );
        return;
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentConfirmScreen(
          hotel: widget.hotel,
          selectedRoom: widget.selectedRoom,
          checkIn: widget.checkIn,
          checkOut: widget.checkOut,
          adultCount: widget.adultCount,
          childCount: widget.childCount,
          infantCount: widget.infantCount,
          roomQuantity: widget.roomQuantity,
          totalPrice: widget.totalPrice,
          fullName: _fullNameController.text,
          email: _emailController.text,
          phone: _phoneController.text,
          specialRequest: _specialRequestController.text,
          existingTripId: widget.existingTripId,
          existingTripDayNumber: widget.existingTripDayNumber,
          existingTripStartDate: widget.existingTripStartDate,
          existingTripEndDate: widget.existingTripEndDate,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Thông tin khách hàng',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isCheckingProfile
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: const CheckoutStepper(currentStep: 2),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Tôi là người đi',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tự động điền thông tin cá nhân của bạn',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          Switch(
                            value: isPassenger,
                            onChanged: (val) =>
                                setState(() => isPassenger = val),
                            activeColor: Colors.white,
                            activeTrackColor: Colors.green[400],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Chi tiết liên hệ',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInputField(
                    'Họ và tên',
                    'Nguyễn Văn A',
                    _fullNameController,
                    isRequired: true,
                  ),
                  _buildInputField(
                    'Địa chỉ Email',
                    'vanta@example.com',
                    _emailController,
                    isRequired: true,
                  ),
                  _buildPhoneField(_phoneController),
                  _buildTextAreaField(_specialRequestController),
                  const SizedBox(height: 32),
                ],
              ),
            ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildInputField(
    String label,
    String hint,
    TextEditingController controller, {
    bool isRequired = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontSize: 14,
              ),
              children: isRequired
                  ? const [
                      TextSpan(
                        text: ' *',
                        style: TextStyle(color: Colors.red),
                      ),
                    ]
                  : [],
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.black87),
              filled: true,
              fillColor: Colors.white,
              suffixIcon: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 20,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneField(TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: const TextSpan(
              text: 'Số điện thoại',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontSize: 14,
              ),
              children: [
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: Colors.red),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: const Text('+84', style: TextStyle(color: Colors.grey)),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: '0901234567',
                    hintStyle: const TextStyle(color: Colors.black87),
                    filled: true,
                    fillColor: Colors.white,
                    suffixIcon: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 20,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
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

  Widget _buildTextAreaField(TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Yêu cầu đặc biệt',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Ví dụ: Phòng không hút thuốc, check-in sớm...',
              hintStyle: TextStyle(color: Colors.grey[400]),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -2),
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TỔNG THANH TOÁN',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      _formatPriceFull(widget.totalPrice),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'CHI TIẾT',
                      style: TextStyle(
                        color: Colors.green[400],
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.green[400],
                      size: 16,
                    ),
                  ],
                ),
              ],
            ),
            ElevatedButton(
              onPressed: _continueToPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[300],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Row(
                children: [
                  Text(
                    'Tiếp tục',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, color: Colors.black, size: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
