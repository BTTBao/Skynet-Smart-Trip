# Skynet Smart Trip - Hướng Dẫn Chạy Dự Án (Manual & Setup)

Chào mừng bạn đến với **Skynet Smart Trip**, ứng dụng hỗ trợ lên lịch trình du lịch thông minh, tích hợp Trợ lý ảo AI (Grok AI Chatbot), đặt phòng khách sạn, vé xe khách và thanh toán hóa đơn. 

Dự án gồm 4 phần chính: **Mobile App (Flutter)**, **Backend API (.NET 8)**, **Database (SQL Server)** và một trang quản trị **Web Admin (React)**.

---

## 📋 PHẦN 1: THÔNG TIN DỰ ÁN & HƯỚNG DẪN CHẠY PHẦN MỀM

### 🛠️ 1. Công Nghệ Sử Dụng

*   **Mobile App:** Flutter & Dart.
*   **Backend API:** C#, .NET 8.0 Web API, Entity Framework Core 8.
*   **Database:** Microsoft SQL Server 2022.
*   **Web Admin:** React, TypeScript, Vite, Tailwind CSS.
*   **Dịch vụ bên ngoài:**
    *   **Firebase Core & Messaging (FCM):** Quản lý thông báo đẩy thời gian thực.
    *   **Firebase Storage:** Lưu trữ avatar và hình ảnh người dùng trực tuyến.
    *   **xAI Grok API / Groq Cloud SDK:** Trí tuệ nhân tạo hỗ trợ chatbot tư vấn du lịch.
    *   **PayOS & VnPay Sandbox:** Hỗ trợ cổng thanh toán trực tuyến.
    *   **Gmail SMTP:** Gửi mã xác thực OTP qua Email khi đăng ký/quên mật khẩu.

### 📱 2. Phiên Bản Flutter & Dart Yêu Cầu

*   **Flutter SDK:** `>= 3.16.0` (Khuyên dùng bản mới nhất `3.19.x` hoặc `3.22.x`).
*   **Dart SDK:** `^3.11.0` (được quy định ràng buộc trong [mobile/pubspec.yaml](file:///d:/lap_trinh_di_dong/BaiGiuaKy/Skynet-Smart-Trip/mobile/pubspec.yaml)).

### 📦 3. Các Thư Viện / Dependency Cần Cài Đặt

#### a. Thư viện Mobile (Flutter pubspec)
Các thư viện quan trọng đã cấu hình sẵn trong [mobile/pubspec.yaml](file:///d:/lap_trinh_di_dong/BaiGiuaKy/Skynet-Smart-Trip/mobile/pubspec.yaml) gồm:
*   `provider`: Quản lý trạng thái (State Management).
*   `http` & `http_parser`: Thực hiện gọi API và gửi file đa phần (Multipart).
*   `flutter_secure_storage`: Lưu trữ an toàn Token JWT.
*   `geolocator` & `flutter_map` & `latlong2`: Hiển thị bản đồ và lấy vị trí GPS.
*   `google_sign_in`: Hỗ trợ luồng đăng nhập Google Auth.
*   `firebase_core` & `firebase_messaging`: Tích hợp các dịch vụ Firebase & Nhận thông báo.
*   `flutter_local_notifications`: Hiển thị thông báo cục bộ khi nhận FCM ở chế độ Foreground.
*   `qr_flutter`: Tạo mã QR thanh toán chuyến đi.
*   `flutter_dotenv`: Tải cấu hình bảo mật từ file `.env`.

#### b. Thư viện Backend (NuGet Packages)
Được khai báo trong các tệp `.csproj` ở thư mục `backend/`:
*   `Microsoft.EntityFrameworkCore.SqlServer` (EF Core Provider cho SQL Server).
*   `Microsoft.AspNetCore.Authentication.JwtBearer` (Middleware xác thực Token JWT).
*   `DotNetEnv` (Đọc các cấu hình từ file `.env` ở gốc dự án).
*   `Google.Cloud.Storage.V1` (Google Cloud SDK hỗ trợ upload ảnh lên Firebase Storage).
*   `Swashbuckle.AspNetCore` (Phục vụ tài liệu hướng dẫn API Swagger UI).

---

### 🚀 4. Các Bước Cài Đặt và Chạy Dự Án

Chúng tôi hỗ trợ 2 cách khởi động dự án: dùng **Docker Compose (Khuyên dùng)** hoặc **Chạy thủ công bằng tay**.

#### CÁCH 1: Sử Dụng Docker Compose (Nhanh & Tự Động Hóa 100%)
Docker sẽ tự động tạo cơ sở dữ liệu SQL Server, import dữ liệu mẫu, build và chạy API Backend lẫn Web Admin mà không cần cài đặt .NET hay SQL Server cục bộ trên máy.

1.  Mở terminal tại thư mục gốc chứa file [docker-compose.yml](file:///d:/lap_trinh_di_dong/BaiGiuaKy/Skynet-Smart-Trip/docker-compose.yml).
2.  Chạy lệnh khởi động:
    ```bash
    docker compose up -d --build
    ```
3.  **Địa chỉ truy cập dịch vụ:**
    *   **Swagger API Backend:** [http://localhost:5555/swagger](http://localhost:5555/swagger)
    *   **Web Admin:** [http://localhost:3333](http://localhost:3333)
    *   **Cổng SQL Server Docker:** `localhost,1434` (Tài khoản: `sa` / Mật khẩu: `@Abcd@1234`).
4.  Để dừng và xóa môi trường: `docker compose down` hoặc reset data: `docker compose down -v`.

---

#### CÁCH 2: Chạy Thủ Công Bằng Tay (Manual)

##### Bước 1: Thiết Lập Database (SQL Server)
1. Khởi động SQL Server cục bộ trên máy của bạn (Cổng mặc định `1433` hoặc cổng `1434` tùy cấu hình).
2. Sử dụng SSMS (SQL Server Management Studio) kết nối vào Database Server.
3. Mở và thực thi lần lượt hai file Script SQL theo thứ tự sau:
    *   [database/database.sql](file:///d:/lap_trinh_di_dong/BaiGiuaKy/Skynet-Smart-Trip/database/database.sql): Script tạo database và định nghĩa toàn bộ 19 bảng kèm các ràng buộc quan hệ toàn vẹn.
    *   [database/sample_seed_data.sql](file:///d:/lap_trinh_di_dong/BaiGiuaKy/Skynet-Smart-Trip/database/sample_seed_data.sql): Dữ liệu mẫu (Các địa điểm du lịch, khách sạn, nhà xe, tài khoản).

##### Bước 2: Cấu Hình và Khởi Chạy Backend API
1. Đi tới thư mục gốc dự án, tạo file `.env` bằng cách sao chép từ file ví dụ:
   ```bash
   cp .env.example .env
   ```
2. Cập nhật chuỗi kết nối SQL Server của bạn tại mục `ConnectionStrings:SmartTrip` trong tệp [backend/SmartTrip.API/appsettings.json](file:///d:/lap_trinh_di_dong/BaiGiuaKy/Skynet-Smart-Trip/backend/SmartTrip.API/appsettings.json) hoặc biến `DB_PASSWORD` trong file `.env`.
3. Mở terminal tại thư mục `backend/` và thực thi:
   ```bash
   dotnet restore
   dotnet run --project SmartTrip.API
   ```
4. API sẽ chạy tại cổng [http://localhost:5110](http://localhost:5110). Bạn có thể truy cập trang tài liệu Swagger tại [http://localhost:5110/swagger](http://localhost:5110/swagger).

##### Bước 3: Cấu Hướng Chạy Ứng Dụng Flutter (Mobile)
1. Tạo một file `.env` bên trong thư mục `mobile/` với nội dung tương tự file `.env` ở thư mục gốc (quy định các cổng và khóa).
2. Di chuyển vào thư mục `mobile/` và tải các package:
   ```bash
   cd mobile
   flutter pub get
   ```
3. Khởi động thiết bị giả lập (Android Emulator / iOS Simulator) hoặc kết nối thiết bị thật.
4. Chạy ứng dụng:
   ```bash
   flutter run
   ```
   *Lưu ý:* Cơ chế gọi API trong file [api_service_base.dart](file:///d:/lap_trinh_di_dong/BaiGiuaKy/Skynet-Smart-Trip/mobile/lib/services/api_service_base.dart) đã tự động nhận dạng thiết bị:
   - Giả lập Android: tự động kết nối qua IP `10.0.2.2` tương ứng với port API trong `.env` (ví dụ `5555` hoặc `5110`).
   - Giả lập iOS / Desktop / Web: tự động kết nối qua `localhost` với port API.
   - Thiết bị thật: cấu hình bằng cách truyền thêm flag khi chạy app: `--dart-define=API_BASE_URL=http://<IP_LAN_MAY_TINH>:<PORT_API>/api`.

---

### 🔑 5. Danh Sách Tài Khoản Thử Nghiệm (Test Accounts)

Các tài khoản dưới đây đã được nạp sẵn vào hệ thống cơ sở dữ liệu để phục vụ kiểm thử:

| Email đăng nhập | Mật khẩu | Phân quyền (Role) | Ghi chú |
| :--- | :--- | :--- | :--- |
| **admin@smarttrip.vn** | `12345678` | **Admin** | Tài khoản quản trị hệ thống, quản lý dữ liệu đối tác, khách sạn, xe khách. |
| **test@example.com** | `12345678` | **User** | Tài khoản người dùng phổ thông, đã có sẵn một số lịch trình du lịch mẫu và ví tiền. |
| **traveler01@smarttrip.vn** | *Google Auth* | **User** | Tài khoản liên kết đăng nhập bằng Google. |

---

## 🔥 PHẦN 2: CẤU HÌNH HỆ THỐNG FIREBASE

Dự án này sử dụng mô hình kết hợp (Hybrid) với Firebase để xử lý các tác vụ thông báo thời gian thực và lưu trữ đám mây.

### 📁 1. File Cấu Hình Firebase Đính Kèm
*   **Android:** File [google-services.json](file:///d:/lap_trinh_di_dong/BaiGiuaKy/Skynet-Smart-Trip/mobile/android/app/google-services.json) cấu hình sẵn kết nối tới Firebase Project `test-fcm-8ddcc` đã được đặt chính xác tại thư mục `mobile/android/app/`.
*   **iOS:** Nếu biên dịch app trên môi trường iOS (macOS), vui lòng tải file `GoogleService-Info.plist` từ bảng điều khiển Firebase Console và đặt vào đường dẫn `mobile/ios/Runner/`.

### 🛠️ 2. Hướng Dẫn Cấu Hình Firebase Từ Đầu (Nếu Tự Setup Project Mới)
Nếu bạn muốn chuyển sang cấu hình dự án Firebase cá nhân của mình, hãy làm theo các bước sau:

1.  Truy cập [Firebase Console](https://console.firebase.google.com/) và tạo một Project mới.
2.  **Đăng ký ứng dụng Android:**
    *   Package Name: `com.skynet.mobile` (quy định trong tệp cấu hình Gradle của ứng dụng di động).
    *   Tải file `google-services.json` mới về và ghi đè vào thư mục [mobile/android/app/](file:///d:/lap_trinh_di_dong/BaiGiuaKy/Skynet-Smart-Trip/mobile/android/app/).
3.  **Kích hoạt Firebase Cloud Messaging (FCM):**
    *   Vào mục *Project Settings* > *Cloud Messaging* để lấy thông tin key hoặc kích hoạt API.
4.  **Kích hoạt Firebase Storage:**
    *   Vào mục *Storage* > bấm *Get Started* để tạo Bucket lưu trữ hình ảnh.
    *   Cập nhật tên bucket vào biến `FIREBASE_STORAGE_BUCKET` trong tệp `.env` ở Backend hoặc cấu hình `Firebase:StorageBucket` trong `appsettings.json` (VD: `test-fcm-8ddcc.firebasestorage.app`).
5.  **Cấu hình quyền ghi (Rules) cho Firebase Storage:**
    *   Mở tab *Rules* trong Storage trên Firebase Console và cấu hình luật như trong tệp [storage.rules](file:///d:/lap_trinh_di_dong/BaiGiuaKy/Skynet-Smart-Trip/storage.rules):
    ```javascript
    rules_version = '2';
    service firebase.storage {
      match /b/{bucket}/o {
        match /{allPaths=**} {
          allow read: if true;
          allow write: if false; // Chỉ cho phép Backend (sử dụng Admin SDK) ghi đè/tải lên file.
        }
      }
    }
    ```
6.  **Tạo khóa dịch vụ Backend (Firebase Admin SDK Service Account):**
    *   Vào mục *Project Settings* > *Service Accounts*.
    *   Chọn *Generate new private key*, một tệp `.json` chứa khóa bí mật sẽ được tải xuống.
    *   Lưu tệp này vào máy (không đưa lên GitHub công khai).
    *   Khai báo đường dẫn tuyệt đối dẫn đến tệp này vào biến `FIREBASE_SERVICE_ACCOUNT_PATH` hoặc `GOOGLE_APPLICATION_CREDENTIALS` trong file `.env` ở Backend.

*   **Lưu ý về Firestore/Realtime Database Collections:**
    *   Dự án này chỉ tích hợp Firebase **Cloud Messaging (FCM)** để đẩy thông báo và **Cloud Storage** để lưu trữ tệp hình ảnh (avatar).
    *   Dự án **không sử dụng** Firestore hay Realtime Database (toàn bộ cấu trúc thực thể nghiệp vụ đã được lưu trữ tập trung tại SQL Server). Do đó, giảng viên **không cần thiết lập hoặc import bất kỳ cấu trúc Collection/Document mẫu nào** trên trang console của Firebase.

---

## 🗄️ PHẦN 3: CẤU HÌNH CƠ SỞ DỮ LIỆU SQL SERVER

Hệ thống lưu trữ dữ liệu nghiệp vụ quan trọng (Người dùng, Điểm đến, Khách sạn, Xe khách, Lịch trình, Hóa đơn, Đánh giá) trên **SQL Server 2022**.

### 📁 1. Các File Script SQL Đính Kèm
Tất cả mã nguồn cơ sở dữ liệu được đặt tại thư mục [database/](file:///d:/lap_trinh_di_dong/BaiGiuaKy/Skynet-Smart-Trip/database/):
*   [database/database.sql](file:///d:/lap_trinh_di_dong/BaiGiuaKy/Skynet-Smart-Trip/database/database.sql): Script tạo database và định nghĩa toàn bộ 19 bảng kèm các ràng buộc quan hệ toàn vẹn.
*   [database/sample_seed_data.sql](file:///d:/lap_trinh_di_dong/BaiGiuaKy/Skynet-Smart-Trip/database/sample_seed_data.sql): Chứa dữ liệu thực tế bao gồm 10 địa điểm nổi tiếng, danh sách phòng/khách sạn, lịch trình chuyến xe chạy, ví tiền và đánh giá của các khách hàng thử nghiệm.
*   [scripts/sql/seed_test_data_users_1000_plus.sql](file:///d:/lap_trinh_di_dong/BaiGiuaKy/Skynet-Smart-Trip/scripts/sql/seed_test_data_users_1000_plus.sql): Script bổ sung hơn 1000 bản ghi người dùng giả lập phục vụ cho việc kiểm thử hiệu năng và phân trang hệ thống.

### 🛠️ 2. Hướng Dẫn Import / Chạy Database
Bạn có thể cài đặt CSDL này theo 2 cách:

#### Cách 1: Sử dụng công cụ SSMS (Thủ công)
1. Mở SQL Server Management Studio (SSMS) và kết nối tới instance SQL Server của bạn.
2. Tạo một database mới tên là `SkynetSmartTrip` (hoặc chạy trực tiếp script `database.sql` vì script đã chứa lệnh khởi tạo).
3. Mở tệp [database.sql](file:///d:/lap_trinh_di_dong/BaiGiuaKy/Skynet-Smart-Trip/database/database.sql) và nhấn **Execute** (F5) để dựng khung bảng.
4. Mở tệp [sample_seed_data.sql](file:///d:/lap_trinh_di_dong/BaiGiuaKy/Skynet-Smart-Trip/database/sample_seed_data.sql) và nhấn **Execute** (F5) để nạp dữ liệu chạy thử.

#### Cách 2: Sử dụng Entity Framework Core Migrations
Nếu bạn muốn áp dụng cơ chế code-first migrations từ mã nguồn C#:
1. Đảm bảo cấu hình đúng Connection String dẫn tới SQL Server trống của bạn trong `appsettings.json`.
2. Mở Package Manager Console hoặc terminal tại thư mục dự án và chạy:
   ```bash
   dotnet ef database update --project SmartTrip.Infrastructure --startup-project SmartTrip.API
   ```

### 🔗 3. Cấu Hình Kết Nối (Connection String)
*   **Backend config:** Chuỗi kết nối được khai báo trong [appsettings.json](file:///d:/lap_trinh_di_dong/BaiGiuaKy/Skynet-Smart-Trip/backend/SmartTrip.API/appsettings.json) dưới khóa `ConnectionStrings:SmartTrip`.
*   **Docker dev config:** Khi khởi động bằng docker compose, connection string trỏ tới container SQL Server thông qua cổng chuyển tiếp `1434` với tài khoản quản trị hệ thống:
    ```json
    "SmartTrip": "Server=localhost,1434;Database=SkynetSmartTrip;User Id=sa;Password=@Abcd@1234;Encrypt=False;TrustServerCertificate=True;"
    ```

---
