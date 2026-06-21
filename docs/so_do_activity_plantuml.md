# Sơ đồ Activity - Skynet Smart Trip

Tài liệu này chứa mã PlantUML cho 5 sơ đồ activity của các module chính trong hệ thống.

## 1. Đăng nhập và đăng ký

```plantuml
@startuml
start

:Mở màn hình xác thực;

if (Chọn chức năng?) then (Đăng nhập)
  :Nhập email và mật khẩu;
  :Gửi yêu cầu đăng nhập;
  :Kiểm tra tài khoản;

  if (Thông tin hợp lệ?) then (Có)
    :Tạo access token và refresh token;
    :Lưu phiên đăng nhập;
    :Đi đến màn hình chính;
  else (Không)
    :Hiển thị lỗi đăng nhập;
  endif

else (Đăng ký)
  :Nhập thông tin tài khoản;
  :Gửi yêu cầu đăng ký;
  :Kiểm tra email đã tồn tại;

  if (Email hợp lệ?) then (Có)
    :Tạo tài khoản mới;
    :Gửi email xác thực;
    :Thông báo đăng ký thành công;
  else (Không)
    :Hiển thị lỗi email đã tồn tại;
  endif
endif

stop
@enduml
```

## 2. Đặt phòng khách sạn

```plantuml
@startuml
start

:Tìm kiếm khách sạn;
:Chọn khách sạn;
:Xem danh sách phòng;
:Chọn phòng và ngày đặt;
:Kiểm tra phòng trống;

if (Còn phòng?) then (Có)
  :Tạo đơn đặt phòng chờ thanh toán;
  :Tạo yêu cầu thanh toán;
  :Chuyển đến PayOS;
  :Người dùng thanh toán;

  if (Thanh toán thành công?) then (Có)
    :Cập nhật booking đã thanh toán;
    :Hiển thị xác nhận đặt phòng;
  else (Không)
    :Giữ booking chờ hoặc hủy booking;
    :Hiển thị thanh toán thất bại;
  endif

else (Không)
  :Thông báo hết phòng;
  :Yêu cầu chọn phòng hoặc ngày khác;
endif

stop
@enduml
```

## 3. Tạo chuyến đi và quản lý lịch trình

```plantuml
@startuml
start

:Mở màn hình chuyến đi;

if (Chọn thao tác?) then (Tạo chuyến đi)
  :Nhập thông tin chuyến đi;
  :Chọn điểm đến và thời gian;
  :Lưu chuyến đi;
  :Hiển thị chi tiết chuyến đi;
else (Quản lý lịch trình)
  :Chọn chuyến đi đã có;
  :Tải lịch trình hiện tại;
endif

:Mở lịch trình chuyến đi;

if (Thao tác lịch trình?) then (Thêm mới)
  :Thêm hoạt động hoặc dịch vụ;
  :Chọn ngày và thời gian;
  :Lưu mục lịch trình;
elseif (Cập nhật)
  :Chỉnh sửa nội dung lịch trình;
  :Lưu thay đổi;
else (Xóa)
  :Chọn mục lịch trình;
  :Xóa mục đã chọn;
endif

:Tải lại timeline;
:Hiển thị lịch trình mới;

stop
@enduml
```

## 4. AI chatbot

```plantuml
@startuml
start

:Mở màn hình chatbot;
:Nhập câu hỏi du lịch;
:Gửi tin nhắn;
:Lấy lịch sử chat và ngữ cảnh người dùng;
:Phân tích ý định câu hỏi;

if (Cần dữ liệu hệ thống?) then (Có)
  :Tra cứu điểm đến, khách sạn hoặc chuyến đi;
endif

if (Cần gợi ý AI?) then (Có)
  :Gửi ngữ cảnh đến AI service;
  :Nhận câu trả lời từ AI;
else (Không)
  :Tạo phản hồi từ dữ liệu hệ thống;
endif

:Lưu tin nhắn và phản hồi;
:Hiển thị câu trả lời;

if (Có itinerary đề xuất?) then (Có)
  :Hiển thị itinerary card;

  if (Người dùng lưu lịch trình?) then (Có)
    :Lưu itinerary vào chuyến đi;
    :Thông báo lưu thành công;
  endif
endif

stop
@enduml
```

## 5. Viết blog

```plantuml
@startuml
start

:Mở màn hình viết blog;
:Nhập tiêu đề và nội dung;

if (Có ảnh đại diện?) then (Có)
  :Upload ảnh;
  :Lưu thumbnail URL;
endif

if (Có điểm đến liên quan?) then (Có)
  :Gắn bài viết với điểm đến;
endif

:Lưu bài viết;

if (Cần quản trị viên duyệt?) then (Có)
  :Đặt trạng thái chờ duyệt;
  :Thông báo gửi duyệt thành công;
  :Quản trị viên xem bài viết;

  if (Bài viết đạt yêu cầu?) then (Có)
    :Xuất bản blog;
  else (Không)
    :Yêu cầu chỉnh sửa;
  endif

else (Không)
  :Xuất bản blog;
endif

:Hiển thị bài viết trong danh sách blog;

stop
@enduml
```
