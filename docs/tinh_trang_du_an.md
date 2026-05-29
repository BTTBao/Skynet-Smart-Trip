# 📊 Báo Cáo Hiện Trạng & Tiến Độ Dự Án — Skynet Smart Trip

Dưới đây là bảng tổng hợp chi tiết những tính năng đã thực hiện, những phần còn thiếu/chưa hoàn thiện và đề xuất hướng cải tiến cho dự án bài tập nhóm này.

---

## 1. Những phần ĐÃ HOÀN THÀNH (Done)

Dự án đã có một nền tảng rất vững chắc ở cả 3 tầng (Database, Backend, và Mobile App). Nhiều logic cốt lõi đã được xây dựng hoàn tất:

### 🗄️ Database (SQL Server)
* **Schema dữ liệu:** Đầy đủ 19 bảng thuộc 6 phân hệ (Người dùng, Điểm đến, Khách sạn, Xe khách, Lịch trình, Hậu mãi). Các mối quan hệ khóa ngoại (Foreign Keys) được thiết lập chặt chẽ.
* **Dữ liệu mẫu:** Có sẵn file `sample_seed_data.sql` để nhập dữ liệu chạy thử (các điểm đến, khách sạn, nhà xe, tài khoản demo).

### 🏗️ Backend (.NET Core Web API)
* **Xác thực hệ thống:** Đã hoàn thiện API Đăng nhập, Đăng ký, Xác thực OTP qua Email, Quên/Đặt lại mật khẩu và làm mới JWT Token (`AuthController`).
* **Hồ sơ cá nhân:** Đã có API lấy thông tin cá nhân (`/user/me`), cập nhật hồ sơ, đổi mật khẩu, lưu danh sách yêu thích (`Wishlist`) và cấu hình cài đặt (`Settings`).
* **Lên lịch trình (`TripController`):** Hỗ trợ đầy đủ các API tạo chuyến đi, thêm/sửa/xóa các dịch vụ (Khách sạn/Phòng, Vé xe/Số ghế) vào lịch trình chi tiết từng ngày.
* **Trợ lý ảo AI Chatbot (`ChatController`):** Tích hợp thành công **Grok AI Service (xAI)**. Hỗ trợ lưu trữ đoạn chat, tóm tắt lịch sử chat và gọi AI trả lời thông minh.
* **Trang quản trị (`AdminController`):** Có sẵn các API CRUD cho Admin quản lý danh mục (Khách sạn, Phòng, Điểm đến, Chuyến xe, Khuyến mãi, Quản lý phân quyền người dùng).

### 📱 Mobile App (Flutter)
* **Cấu trúc & Giao diện:** Thiết kế theo mô hình MVVM, giao diện hiện đại (Premium UI), hỗ trợ đa ngôn ngữ (Việt/Anh) và Dark Mode.
* **Luồng Auth:** Có màn hình Splash, Onboarding giới thiệu, Đăng nhập, Đăng ký, Nhập OTP xác thực email và Quên mật khẩu.
* **Trợ lý ảo AI:** Đã hoàn thiện màn hình Chatbot AI rất đẹp (`chatbot_view.dart`), hỗ trợ gửi nhận tin nhắn dạng Markdown, voice message và lưu trữ lịch sử cuộc hội thoại.
* **Quản lý lịch trình:** Giao diện cho phép tạo chuyến đi mới, xem danh sách chuyến đi hiện tại, chỉnh sửa các đầu mục hoạt động (lựa chọn khách sạn, chuyến xe) hiển thị dưới dạng Timeline rất trực quan.
* **Hồ sơ & Lịch sử:** Đã có màn hình thông tin cá nhân, sửa hồ sơ, xem lịch sử đặt chỗ (khách sạn, vé xe, hóa đơn đã thanh toán) và danh sách yêu thích.

### 💻 Web Admin (React + Vite + TypeScript)
* Đã dựng xong khung dự án, cấu hình router, định dạng CSS bằng Tailwind CSS và hoàn thiện một số giao diện quản lý (Dashboard, Hotels, Destinations).

---

## 2. Những phần CHƯA HOÀN THÀNH (Todo / Placeholders)

Một số vị trí trong dự án hiện mới chỉ là phần giao diện giả lập (Mock) hoặc stub chờ xử lý:

1. **Google Sign-In trên Mobile:**
   * Nút bấm "Tiếp tục với Google" trên màn hình Đăng nhập hiện chỉ hiển thị thông báo SnackBar giả lập chứ chưa thực sự kết nối với SDK.
2. **Cổng thanh toán thực tế (Payments):**
   * Mặc dù cơ sở dữ liệu có bảng `PAYMENTS` và thực hiện đặt trạng thái giao dịch (`PENDING`, `PAID`), ứng dụng di động chưa tích hợp cổng thanh toán trực tuyến thực tế (như WebView thanh toán VNPAY/MoMo sandbox).
3. **Thông báo đẩy (Push Notifications):**
   * App có tính năng thông báo nhưng hoạt động theo cơ chế kéo dữ liệu (Pull) từ API, chưa hỗ trợ đẩy thông báo theo thời gian thực (Push Notification) từ server xuống khi có cập nhật mới về lịch trình/vé xe.
4. **Trang Web Admin (React):**
   * Một số chức năng quản lý người dùng, thống kê báo cáo tài chính (`Reports`) và lịch trình chi tiết vẫn ở dạng trang trống (Placeholder).

---

## 3. Hướng cải tiến để đạt điểm tối đa (Điểm cộng bài tập lớn)

Để biến đây thành một bài tập lớn xuất sắc và thuyết phục tuyệt đối giảng viên, nhóm nên tập trung vào các hướng cải tiến sau:

### 🌟 Hướng 1: Chuyển đổi công nghệ xác thực & Lưu trữ sang Firebase (Hybrid)
* **Firebase Auth:** Triển khai đăng nhập Google thực tế trên App Flutter. Việc đăng nhập chỉ với 1 chạm sẽ làm phần demo trực tiếp trước giảng viên trở nên cực kỳ trơn tru.
* **Firebase Storage:** Chuyển tính năng upload avatar người dùng lên Firebase Storage trực tuyến thay vì lưu file cục bộ trong thư mục `wwwroot` của server (tránh được lỗi quyền ghi file và mất file khi restart server).
* **Firebase Cloud Messaging (FCM):** Đẩy thông báo tức thời (ví dụ: đặt vé xe thành công, nhắc nhở trước giờ xuất phát 1 tiếng) hiển thị ngay trên thanh thông báo điện thoại của giảng viên.

### 💳 Hướng 2: Tích hợp cổng thanh toán VNPay Sandbox
* Khi người dùng nhấn "Thanh toán chuyến đi", app sẽ mở ra một WebView hiển thị trang cổng thanh toán VNPay Sandbox. Người dùng có thể quét mã QR hoặc nhập số thẻ ATM demo để trải nghiệm luồng thanh toán hoàn chỉnh. Sau khi thanh toán thành công, hệ thống tự động đổi trạng thái chuyến đi thành `PAID` và sinh hóa đơn PDF.

### 🤖 Hướng 3: Nâng cấp Trợ lý AI (AI Function Calling)
* Cho phép chatbot AI tương tác trực tiếp với hệ thống. Ví dụ: khi người dùng chat *"Hãy gợi ý cho tôi 1 phòng khách sạn đẹp ở Đà Nẵng"*, AI không chỉ trả lời bằng văn bản mà còn tự động trả về thông tin phòng khách sạn có trong DB để người dùng bấm nút đặt trực tiếp ngay trên khung chat.
