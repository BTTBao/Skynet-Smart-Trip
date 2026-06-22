# Sơ đồ Sequence - Skynet Smart Trip

Tài liệu này chứa mã PlantUML cho các sơ đồ sequence của các module chính. Các sơ đồ được viết theo hướng ngắn gọn, dễ đọc, tập trung vào luồng nghiệp vụ chính và không dùng role "Khách".

## 1. Đăng nhập

```plantuml
@startuml
autonumber
actor "Người dùng" as User
participant "Mobile App" as App
participant "Auth API" as AuthApi
participant "Auth Service" as AuthService
database "Database" as DB

User -> App: Gửi email và mật khẩu
App -> AuthApi: POST /api/auth/login
AuthApi -> AuthService: Login(request)
AuthService -> DB: Tìm user theo email
DB --> AuthService: Thông tin user

alt Thông tin hợp lệ
  AuthService --> AuthApi: Access token, refresh token, user profile
  AuthApi --> App: 200 OK
  App --> User: Vào màn hình chính
else Sai email hoặc mật khẩu
  AuthService --> AuthApi: Lỗi xác thực
  AuthApi --> App: 401 Unauthorized
  App --> User: Hiển thị lỗi đăng nhập
end
@enduml
```

## 2. Đăng ký

```plantuml
@startuml
autonumber
actor "Người dùng" as User
participant "Mobile App" as App
participant "Auth API" as AuthApi
participant "Auth Service" as AuthService
database "Database" as DB
participant "Email Service" as Email

User -> App: Gửi thông tin đăng ký
App -> AuthApi: POST /api/auth/register
AuthApi -> AuthService: Register(request)
AuthService -> DB: Kiểm tra email

alt Email chưa tồn tại
  AuthService -> DB: Tạo tài khoản mới
  AuthService -> Email: Gửi email xác thực
  AuthService --> AuthApi: Đăng ký thành công
  AuthApi --> App: 201 Created
  App --> User: Yêu cầu xác thực email
else Email đã tồn tại
  AuthService --> AuthApi: Email đã được sử dụng
  AuthApi --> App: 409 Conflict
  App --> User: Hiển thị lỗi
end
@enduml
```

## 3. Đặt phòng khách sạn

```plantuml
@startuml
autonumber
actor "Người dùng" as User
participant "Mobile App" as App
participant "Trip API" as TripApi
participant "Trip Service" as TripService
participant "Payment API" as PaymentApi
participant "Payment Service" as PaymentService
participant "PayOS" as PayOS
database "Database" as DB

User -> App: Chọn phòng và ngày đặt
App -> TripApi: POST /api/trips/hotel-bookings
TripApi -> TripService: CreateHotelBooking(request)
TripService -> DB: Kiểm tra phòng trống

alt Còn phòng
  TripService -> DB: Tạo booking chờ thanh toán
  TripService --> App: Thông tin booking
  App -> PaymentApi: POST /api/payments
  PaymentApi -> PaymentService: CreatePayment(bookingId)
  PaymentService -> PayOS: Tạo link thanh toán
  PayOS --> PaymentService: Payment URL
  PaymentService --> App: Payment URL
  App --> User: Mở màn hình thanh toán

  PayOS -> PaymentApi: Webhook kết quả thanh toán
  PaymentApi -> PaymentService: ConfirmPayment(webhook)
  PaymentService -> DB: Cập nhật trạng thái booking
else Hết phòng
  TripService --> App: Không còn phòng phù hợp
  App --> User: Chọn phòng hoặc ngày khác
end
@enduml
```

## 4. Tạo chuyến đi

```plantuml
@startuml
autonumber
actor "Người dùng" as User
participant "Mobile App" as App
participant "Trip API" as TripApi
participant "Trip Service" as TripService
database "Database" as DB

User -> App: Tạo chuyến đi mới
App -> TripApi: POST /api/trips
TripApi -> TripService: CreateTrip(request)
TripService -> DB: Lưu chuyến đi
DB --> TripService: Trip vừa tạo
TripService --> TripApi: Trip detail
TripApi --> App: 201 Created
App --> User: Hiển thị chuyến đi
@enduml
```

## 5. Quản lý lịch trình

```plantuml
@startuml
autonumber
actor "Người dùng" as User
participant "Mobile App" as App
participant "Itinerary API" as ItineraryApi
participant "Itinerary Service" as ItineraryService
database "Database" as DB

User -> App: Mở chi tiết chuyến đi
App -> ItineraryApi: GET /api/trips/{tripId}/itineraries
ItineraryApi -> ItineraryService: GetByTrip(tripId)
ItineraryService -> DB: Lấy lịch trình
DB --> ItineraryService: Danh sách lịch trình
ItineraryService --> App: Timeline theo ngày
App --> User: Hiển thị lịch trình

User -> App: Thêm hoặc chỉnh sửa mục lịch trình
App -> ItineraryApi: POST/PUT itinerary
ItineraryApi -> ItineraryService: SaveItinerary(request)
ItineraryService -> DB: Lưu thay đổi
DB --> ItineraryService: Lịch trình đã cập nhật
ItineraryService --> App: Timeline mới
App --> User: Cập nhật giao diện
@enduml
```

## 6. AI chatbot

```plantuml
@startuml
autonumber
actor "Người dùng" as User
participant "Mobile App" as App
participant "Chat API" as ChatApi
participant "Chat Service" as ChatService
participant "AI Service" as AI
database "Database" as DB

User -> App: Gửi câu hỏi du lịch
App -> ChatApi: POST /api/chat
ChatApi -> ChatService: SendMessage(request)
ChatService -> DB: Lấy ngữ cảnh và lịch sử chat
DB --> ChatService: Context
ChatService -> AI: Tạo câu trả lời theo ngữ cảnh
AI --> ChatService: Nội dung trả lời
ChatService -> DB: Lưu tin nhắn và phản hồi
ChatService --> ChatApi: Chat response
ChatApi --> App: 200 OK
App --> User: Hiển thị câu trả lời
@enduml
```

## 7. AI gợi ý lịch trình

```plantuml
@startuml
autonumber
actor "Người dùng" as User
participant "Mobile App" as App
participant "Chat API" as ChatApi
participant "Chat Service" as ChatService
participant "AI Service" as AI
database "Database" as DB

User -> App: Yêu cầu gợi ý lịch trình
App -> ChatApi: POST /api/chat
ChatApi -> ChatService: SuggestItinerary(message, userId)
ChatService -> DB: Lấy điểm đến, khách sạn, sở thích
DB --> ChatService: Dữ liệu gợi ý
ChatService -> AI: Sinh lịch trình phù hợp
AI --> ChatService: Suggested itinerary
ChatService --> ChatApi: Lịch trình đề xuất
ChatApi --> App: 200 OK
App --> User: Hiển thị itinerary card

opt Người dùng lưu lịch trình
  App -> ChatApi: POST /api/trips/{tripId}/itineraries/from-ai
  ChatApi -> DB: Lưu lịch trình vào chuyến đi
  DB --> App: Lưu thành công
end
@enduml
```

## 8. Viết blog

```plantuml
@startuml
autonumber
actor "Người dùng" as User
actor "Quản trị viên" as Admin
participant "Mobile App" as App
participant "Blog API" as BlogApi
participant "Blog Service" as BlogService
participant "Storage" as Storage
database "Database" as DB

User -> App: Tạo bài viết blog
App -> Storage: Upload ảnh đại diện
Storage --> App: Thumbnail URL
App -> BlogApi: POST /api/blogs
BlogApi -> BlogService: CreatePost(request)
BlogService -> DB: Lưu bài viết chờ duyệt
DB --> BlogService: Blog post
BlogService --> App: Tạo bài thành công
App --> User: Hiển thị bài viết

Admin -> BlogApi: Duyệt bài viết
BlogApi -> BlogService: PublishPost(blogId)
BlogService -> DB: Cập nhật trạng thái xuất bản
BlogService --> Admin: Xuất bản thành công
@enduml
```

## 9. Chỉnh sửa hoặc xóa blog

```plantuml
@startuml
autonumber
actor "Người dùng" as User
participant "Mobile App" as App
participant "Blog API" as BlogApi
participant "Blog Service" as BlogService
database "Database" as DB

User -> App: Chỉnh sửa hoặc xóa blog

alt Chỉnh sửa
  App -> BlogApi: PUT /api/blogs/{id}
  BlogApi -> BlogService: UpdatePost(id, request)
  BlogService -> DB: Cập nhật bài viết
  DB --> BlogService: Blog post mới
  BlogService --> App: Cập nhật thành công
  App --> User: Hiển thị nội dung mới
else Xóa
  App -> BlogApi: DELETE /api/blogs/{id}
  BlogApi -> BlogService: DeletePost(id)
  BlogService -> DB: Xóa bài viết
  BlogService --> App: Xóa thành công
  App --> User: Quay về danh sách blog
end
@enduml
```
