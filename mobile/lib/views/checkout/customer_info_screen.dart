import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/resort_model.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/app_network_image.dart';
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

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfileInfo());
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
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

  List<String> _missingProfileFields() {
    final profile = context.read<ProfileProvider>().profileData;
    final missing = <String>[];
    final identityNumber = profile?.identityNumber?.trim() ?? '';
    final birthDate = DateTime.tryParse(profile?.birthDate.trim() ?? '');
    final phone = profile?.phone.replaceAll(RegExp(r'[^0-9]'), '') ?? '';

    if ((profile?.name.trim() ?? '').isEmpty) missing.add('ho va ten');
    if ((profile?.email.trim() ?? '').isEmpty) missing.add('email');
    if (phone.length < 10 || phone.length > 11) missing.add('so dien thoai');
    if (birthDate == null || !birthDate.isBefore(DateTime.now())) {
      missing.add('ngay sinh');
    }
    if (!RegExp(r'^(\d{9}|\d{12})$').hasMatch(identityNumber)) {
      missing.add('so CCCD/CMND');
    }
    if ((profile?.identityCardPhotoUrl?.trim() ?? '').isEmpty) {
      missing.add('anh mat truoc CCCD');
    }

    return missing;
  }

  bool _hasRequiredProfileInfo() => _missingProfileFields().isEmpty;

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
          content: Text(
            'Vui lòng cập nhật đầy đủ thông tin cá nhân và ảnh CCCD để đặt phòng.',
          ),
        ),
      );
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const EditProfileView(requiredForBooking: true),
        ),
      );
      if (!mounted) return;
      await _loadProfileInfo(forceRefresh: true);
      _redirectingToProfile = false;
    }
  }

  Future<void> _continueToPayment() async {
    if (!_hasRequiredProfileInfo()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Vui lòng hoàn tất thông tin cá nhân và chụp ảnh CCCD trong hồ sơ.',
          ),
        ),
      );
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const EditProfileView(requiredForBooking: true),
        ),
      );
      if (!mounted) return;
      await _loadProfileInfo(forceRefresh: true);
      if (!mounted) return;
      if (!_hasRequiredProfileInfo()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Hồ sơ vẫn thiếu thông tin liên hệ hoặc ảnh chụp CCCD.',
            ),
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
          specialRequest: '',
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
                  _buildIdentityCardSection(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildIdentityCardSection() {
    final profile = context.watch<ProfileProvider>().profileData;
    if (profile == null) return const SizedBox.shrink();

    final hasCCCD = RegExp(
      r'^(\d{9}|\d{12})$',
    ).hasMatch(profile.identityNumber?.trim() ?? '');
    final hasCCCDPhoto =
        profile.identityCardPhotoUrl != null &&
        profile.identityCardPhotoUrl!.trim().isNotEmpty;
    final birthDate = DateTime.tryParse(profile.birthDate.trim());
    final hasBirthDate =
        birthDate != null && birthDate.isBefore(DateTime.now());

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasCCCD && hasCCCDPhoto && hasBirthDate
                ? const Color(0xFF0D6B42).withOpacity(0.2)
                : Colors.orange.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.badge_outlined,
                  color: hasCCCD && hasCCCDPhoto && hasBirthDate
                      ? const Color(0xFF0D6B42)
                      : Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Căn cước công dân (CCCD)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                if (hasCCCD && hasCCCDPhoto && hasBirthDate)
                  const Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Color(0xFF0D6B42),
                        size: 16,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Hợp lệ',
                        style: TextStyle(
                          color: Color(0xFF0D6B42),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.orange, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Chưa cập nhật',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ngay sinh:',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                Text(
                  hasBirthDate ? profile.birthDate : 'Trong',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: hasBirthDate ? Colors.black87 : Colors.red,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Số CCCD / CMND:',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                Text(
                  hasCCCD ? profile.identityNumber! : 'Trống',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: hasCCCD ? Colors.black87 : Colors.red,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Ảnh chụp mặt trước CCCD:',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 8),
            if (hasCCCDPhoto)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AppNetworkImage(
                  imageUrl: profile.identityCardPhotoUrl!,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 120,
                    color: Colors.grey[100],
                    child: const Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              )
            else
              Container(
                height: 80,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.grey[200]!,
                    style: BorderStyle.solid,
                  ),
                ),
                child: const Center(
                  child: Text(
                    'Chưa có ảnh chụp CCCD',
                    style: TextStyle(color: Colors.orange, fontSize: 12),
                  ),
                ),
              ),
            if (!hasCCCD || !hasCCCDPhoto || !hasBirthDate) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const EditProfileView(requiredForBooking: true),
                      ),
                    );
                    _loadProfileInfo(forceRefresh: true);
                  },
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Cập nhật CCCD ngay'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF0D6B42),
                    backgroundColor: const Color(0xFF0D6B42).withOpacity(0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
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
                    InkWell(
                      onTap: () => _showBookingDetails(context),
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        child: Row(
                          children: [
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
                      ),
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

  void _showBookingDetails(BuildContext context) {
    final nights = widget.checkOut.difference(widget.checkIn).inDays;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Chi tiết đặt phòng',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 10),
              Text(
                widget.hotel.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D6B42),
                ),
              ),
              const SizedBox(height: 8),
              if (widget.selectedRoom != null) ...[
                Text(
                  'Loại phòng: ${widget.selectedRoom!.roomType}',
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(height: 4),
              ],
              Text(
                'Thời gian: ${widget.checkIn.day}/${widget.checkIn.month}/${widget.checkIn.year} - ${widget.checkOut.day}/${widget.checkOut.month}/${widget.checkOut.year} ($nights đêm)',
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 4),
              Text(
                'Số lượng: ${widget.roomQuantity} phòng x ${widget.adultCount} Người lớn, ${widget.childCount} Trẻ em',
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tổng tiền thanh toán:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    _formatPriceFull(widget.totalPrice),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
