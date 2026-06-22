# Sơ đồ Use Case - Skynet Smart Trip

Tài liệu này chứa mã PlantUML cho các sơ đồ use case chính của hệ thống Skynet Smart Trip.

## 1. Sơ đồ use case tổng quát

```plantuml
@startuml
left to right direction
skinparam packageStyle rectangle
skinparam actorStyle awesome

actor "Khách" as Guest
actor "Người dùng" as User
actor "Quản trị viên" as Admin
actor "Dịch vụ AI" as AI
actor "Cổng thanh toán\nPayOS" as PayOS
actor "Dịch vụ email" as Email

rectangle "Skynet Smart Trip" {
  usecase "Đăng ký tài khoản" as UC_Register
  usecase "Đăng nhập" as UC_Login
  usecase "Khôi phục mật khẩu" as UC_ResetPassword
  usecase "Tìm kiếm điểm đến" as UC_SearchDestination
  usecase "Xem khách sạn\nvà phòng" as UC_ViewHotel
  usecase "Đặt phòng" as UC_BookRoom
  usecase "Thanh toán" as UC_Payment
  usecase "Tạo chuyến đi" as UC_CreateTrip
  usecase "Quản lý lịch trình" as UC_ManageItinerary
  usecase "Chat với AI chatbot" as UC_Chatbot
  usecase "Xem blog du lịch" as UC_ViewBlog
  usecase "Viết blog" as UC_WriteBlog
  usecase "Quản lý người dùng" as UC_ManageUser
  usecase "Quản lý dữ liệu du lịch" as UC_ManageCatalog
  usecase "Quản lý đặt phòng\nvà thanh toán" as UC_ManageBooking
  usecase "Xem báo cáo thống kê" as UC_Report
}

Guest --> UC_Register
Guest --> UC_Login
Guest --> UC_ResetPassword
Guest --> UC_SearchDestination
Guest --> UC_ViewHotel
Guest --> UC_ViewBlog

User --> UC_SearchDestination
User --> UC_ViewHotel
User --> UC_BookRoom
User --> UC_CreateTrip
User --> UC_ManageItinerary
User --> UC_Chatbot
User --> UC_ViewBlog
User --> UC_WriteBlog

Admin --> UC_ManageUser
Admin --> UC_ManageCatalog
Admin --> UC_ManageBooking
Admin --> UC_Report
Admin --> UC_WriteBlog

UC_BookRoom .> UC_Payment : <<include>>
UC_Chatbot --> AI
UC_Payment --> PayOS
UC_Register --> Email
UC_ResetPassword --> Email
@enduml
```

## 2. Use case đăng nhập và đăng ký

```plantuml
@startuml
left to right direction
skinparam packageStyle rectangle
skinparam actorStyle awesome

actor "Khách" as Guest
actor "Người dùng" as User
actor "Google OAuth" as Google
actor "Dịch vụ email" as Email

rectangle "Xác thực tài khoản" {
  usecase "Đăng ký tài khoản" as Register
  usecase "Nhập thông tin cá nhân" as FillInfo
  usecase "Kiểm tra email tồn tại" as CheckEmail
  usecase "Mã hóa mật khẩu" as HashPassword
  usecase "Gửi email xác thực" as SendVerifyEmail
  usecase "Xác thực email" as VerifyEmail

  usecase "Đăng nhập bằng email\nvà mật khẩu" as Login
  usecase "Đăng nhập bằng Google" as GoogleLogin
  usecase "Kiểm tra thông tin đăng nhập" as ValidateCredential
  usecase "Tạo access token\nvà refresh token" as IssueToken
  usecase "Lưu phiên đăng nhập" as SaveSession

  usecase "Quên mật khẩu" as ForgotPassword
  usecase "Gửi mã đặt lại mật khẩu" as SendResetCode
  usecase "Đặt lại mật khẩu" as ResetPassword
  usecase "Đăng xuất" as Logout
}

Guest --> Register
Guest --> Login
Guest --> GoogleLogin
Guest --> ForgotPassword
Guest --> VerifyEmail
User --> Logout
User --> ResetPassword

Register .> FillInfo : <<include>>
Register .> CheckEmail : <<include>>
Register .> HashPassword : <<include>>
Register .> SendVerifyEmail : <<include>>
SendVerifyEmail --> Email
VerifyEmail --> Email

Login .> ValidateCredential : <<include>>
Login .> IssueToken : <<include>>
Login .> SaveSession : <<include>>

GoogleLogin --> Google
GoogleLogin .> IssueToken : <<include>>
GoogleLogin .> SaveSession : <<include>>

ForgotPassword .> SendResetCode : <<include>>
SendResetCode --> Email
ResetPassword .> HashPassword : <<include>>
@enduml
```

## 3. Use case đặt phòng

```plantuml
@startuml
left to right direction
skinparam packageStyle rectangle
skinparam actorStyle awesome

actor "Khách" as Guest
actor "Người dùng" as User
actor "Cổng thanh toán\nPayOS" as PayOS
actor "Quản trị viên" as Admin

rectangle "Đặt phòng khách sạn" {
  usecase "Tìm kiếm khách sạn" as SearchHotel
  usecase "Lọc theo điểm đến,\nngày, giá, tiện nghi" as FilterHotel
  usecase "Xem chi tiết khách sạn" as ViewHotel
  usecase "Xem danh sách phòng" as ViewRooms
  usecase "Kiểm tra phòng trống" as CheckAvailability
  usecase "Chọn phòng" as SelectRoom
  usecase "Nhập thông tin đặt phòng" as FillBooking
  usecase "Tạo đơn đặt phòng" as CreateBooking
  usecase "Áp dụng khuyến mãi" as ApplyPromotion
  usecase "Thanh toán đặt phòng" as PayBooking
  usecase "Nhận kết quả thanh toán" as ReceivePaymentResult
  usecase "Xem lịch sử đặt phòng" as ViewBookingHistory
  usecase "Hủy đặt phòng" as CancelBooking
  usecase "Quản lý đặt phòng" as ManageBooking
}

Guest --> SearchHotel
Guest --> ViewHotel

User --> SearchHotel
User --> ViewHotel
User --> SelectRoom
User --> FillBooking
User --> CreateBooking
User --> PayBooking
User --> ViewBookingHistory
User --> CancelBooking

Admin --> ManageBooking

SearchHotel .> FilterHotel : <<include>>
ViewHotel .> ViewRooms : <<include>>
SelectRoom .> CheckAvailability : <<include>>
CreateBooking .> FillBooking : <<include>>
CreateBooking .> CheckAvailability : <<include>>
CreateBooking .> ApplyPromotion : <<extend>>
PayBooking .> CreateBooking : <<include>>
PayBooking --> PayOS
PayOS --> ReceivePaymentResult
ReceivePaymentResult .> ViewBookingHistory : <<extend>>
ManageBooking .> CancelBooking : <<extend>>
@enduml
```

## 4. Use case tạo chuyến đi và quản lý lịch trình

```plantuml
@startuml
left to right direction
skinparam packageStyle rectangle
skinparam actorStyle awesome

actor "Người dùng" as User
actor "AI chatbot" as Chatbot
actor "Dịch vụ bản đồ\n/ geocoding" as Map

rectangle "Chuyến đi và lịch trình" {
  usecase "Tạo chuyến đi" as CreateTrip
  usecase "Nhập tên chuyến đi" as EnterTripName
  usecase "Chọn điểm đến" as ChooseDestination
  usecase "Chọn ngày bắt đầu\nvà kết thúc" as ChooseDate
  usecase "Lưu chuyến đi" as SaveTrip
  usecase "Xem danh sách chuyến đi" as ViewTrips
  usecase "Xem chi tiết chuyến đi" as ViewTripDetail
  usecase "Cập nhật chuyến đi" as UpdateTrip
  usecase "Xóa chuyến đi" as DeleteTrip

  usecase "Tạo lịch trình ngày" as CreateItinerary
  usecase "Thêm hoạt động" as AddActivity
  usecase "Thêm khách sạn\n/ phương tiện" as AddService
  usecase "Sắp xếp thời gian" as ArrangeTime
  usecase "Cập nhật lịch trình" as UpdateItinerary
  usecase "Xóa mục lịch trình" as DeleteItineraryItem
  usecase "Xem lịch trình trên bản đồ" as ViewMap
  usecase "Nhận gợi ý lịch trình từ AI" as SuggestItinerary
}

User --> CreateTrip
User --> ViewTrips
User --> ViewTripDetail
User --> UpdateTrip
User --> DeleteTrip
User --> CreateItinerary
User --> UpdateItinerary
User --> DeleteItineraryItem
User --> ViewMap
User --> SuggestItinerary

CreateTrip .> EnterTripName : <<include>>
CreateTrip .> ChooseDestination : <<include>>
CreateTrip .> ChooseDate : <<include>>
CreateTrip .> SaveTrip : <<include>>

ViewTripDetail .> CreateItinerary : <<extend>>
CreateItinerary .> AddActivity : <<include>>
CreateItinerary .> AddService : <<extend>>
CreateItinerary .> ArrangeTime : <<include>>
UpdateItinerary .> AddActivity : <<extend>>
UpdateItinerary .> AddService : <<extend>>
UpdateItinerary .> ArrangeTime : <<include>>
ViewMap --> Map
SuggestItinerary --> Chatbot
SuggestItinerary .> CreateItinerary : <<extend>>
@enduml
```

## 5. Use case AI chatbot

```plantuml
@startuml
left to right direction
skinparam packageStyle rectangle
skinparam actorStyle awesome

actor "Người dùng" as User
actor "Grok/Gemini AI" as AI
actor "Cơ sở dữ liệu\nSmart Trip" as Database
actor "Dịch vụ thời tiết" as Weather
actor "Dịch vụ vị trí" as Location

rectangle "AI chatbot du lịch" {
  usecase "Mở chatbot" as OpenChat
  usecase "Gửi tin nhắn" as SendMessage
  usecase "Nhận câu trả lời" as ReceiveAnswer
  usecase "Nhận diện ý định" as DetectIntent
  usecase "Lấy ngữ cảnh người dùng" as LoadUserContext
  usecase "Tra cứu điểm đến" as QueryDestination
  usecase "Gợi ý khách sạn" as SuggestHotel
  usecase "Gợi ý lịch trình" as SuggestItinerary
  usecase "Xem dự báo thời tiết" as GetWeather
  usecase "Dùng vị trí hiện tại" as UseLocation
  usecase "Hiển thị quick actions" as ShowQuickActions
  usecase "Lưu lịch sử chat" as SaveChatHistory
  usecase "Xem lịch sử chat" as ViewChatHistory
}

User --> OpenChat
User --> SendMessage
User --> ReceiveAnswer
User --> ViewChatHistory

SendMessage .> DetectIntent : <<include>>
SendMessage .> LoadUserContext : <<include>>
SendMessage .> SaveChatHistory : <<include>>
ReceiveAnswer .> ShowQuickActions : <<include>>

DetectIntent --> AI
LoadUserContext --> Database
QueryDestination --> Database
SuggestHotel --> Database
SuggestItinerary --> AI
GetWeather --> Weather
UseLocation --> Location

DetectIntent .> QueryDestination : <<extend>>
DetectIntent .> SuggestHotel : <<extend>>
DetectIntent .> SuggestItinerary : <<extend>>
DetectIntent .> GetWeather : <<extend>>
GetWeather .> UseLocation : <<extend>>
SaveChatHistory --> Database
ViewChatHistory --> Database
@enduml
```

## 6. Use case viết blog

```plantuml
@startuml
left to right direction
skinparam packageStyle rectangle
skinparam actorStyle awesome

actor "Người dùng" as User
actor "Quản trị viên" as Admin
actor "Kho lưu trữ ảnh" as Storage

rectangle "Blog du lịch" {
  usecase "Xem danh sách blog" as ViewBlogs
  usecase "Tìm kiếm blog" as SearchBlog
  usecase "Xem chi tiết blog" as ViewBlogDetail
  usecase "Viết blog" as WriteBlog
  usecase "Nhập tiêu đề" as EnterTitle
  usecase "Soạn nội dung" as ComposeContent
  usecase "Chọn điểm đến liên quan" as ChooseDestination
  usecase "Tải ảnh đại diện" as UploadThumbnail
  usecase "Lưu bản nháp" as SaveDraft
  usecase "Gửi duyệt bài viết" as SubmitReview
  usecase "Xuất bản blog" as PublishBlog
  usecase "Chỉnh sửa blog" as EditBlog
  usecase "Xóa blog" as DeleteBlog
  usecase "Quản lý blog" as ManageBlog
}

User --> ViewBlogs
User --> SearchBlog
User --> ViewBlogDetail
User --> WriteBlog
User --> EditBlog
User --> DeleteBlog

Admin --> ViewBlogs
Admin --> ViewBlogDetail
Admin --> ManageBlog
Admin --> PublishBlog
Admin --> EditBlog
Admin --> DeleteBlog

WriteBlog .> EnterTitle : <<include>>
WriteBlog .> ComposeContent : <<include>>
WriteBlog .> ChooseDestination : <<extend>>
WriteBlog .> UploadThumbnail : <<extend>>
WriteBlog .> SaveDraft : <<include>>
WriteBlog .> SubmitReview : <<extend>>

UploadThumbnail --> Storage
ManageBlog .> PublishBlog : <<include>>
ManageBlog .> EditBlog : <<extend>>
ManageBlog .> DeleteBlog : <<extend>>
SearchBlog .> ViewBlogDetail : <<extend>>
@enduml
```
