# SmartTrip Backend Overview

## Muc dich

Tai lieu nay duoc viet lai tu source code trong thu muc `backend/` de phuc vu viec setup lai du an, onboard nguoi moi, va lam moc cho viec reorganize backend sau nay.

Backend hien tai la mot API ASP.NET Core 8 chia thanh 4 project:

- `SmartTrip.API`: diem vao chay app, controllers, middleware, Swagger, startup config.
- `SmartTrip.Application`: DTOs, interfaces, application services, auth/email/chat/trip/catalog/explore/notification logic.
- `SmartTrip.Domain`: entities va enums nghiep vu.
- `SmartTrip.Infrastructure`: `ApplicationDbContext`, migrations, repositories, Firebase storage, payment, admin service, user service.

Noi ngan gon: day la mot backend theo huong layered architecture / clean-ish architecture, nhung chua tach lop hoan toan nghiem ngat. Van co mot so cho controller va service truy cap `ApplicationDbContext` truc tiep.

## Cau truc thu muc

```text
backend/
|- SmartTrip.API/
|- SmartTrip.Application/
|- SmartTrip.Domain/
|- SmartTrip.Infrastructure/
|- Dockerfile
|- .dockerignore
```

Chi tiet hon:

```text
SmartTrip.API/
|- Controllers/              # REST endpoints
|- Middlewares/              # DI, JWT, Swagger, API behavior
|- Data/DevelopmentDataSeeder.cs
|- Filters/
|- Utilities/
|- Properties/launchSettings.json
|- appsettings.json
|- wwwroot/uploads/          # local uploaded files fallback

SmartTrip.Application/
|- DTOs/
|- Interfaces/
|- Services/
|- Configurations/

SmartTrip.Domain/
|- Entities/
|- Enums/

SmartTrip.Infrastructure/
|- Data/ApplicationDbContext.cs
|- Migrations/
|- Repositories/
|- Services/
```

## Nen tang ky thuat

- .NET 8 (`net8.0`)
- ASP.NET Core Web API
- Entity Framework Core 8 + SQL Server
- JWT authentication
- Swagger (chi mo trong `Development`)
- MailKit de gui email
- Google Sign-In
- Firebase Storage / local file fallback
- PayOS va VNPAY
- AI chat qua Groq-compatible API (`GrokAiService`)
- Weather lookup qua Open-Meteo

## Startup flow

File startup chinh la `backend/SmartTrip.API/Program.cs`.

Khi app boot:

1. Doc file `.env` tu thu muc hien tai va cac thu muc cha.
2. Nap them environment variables vao `Configuration`.
3. Neu co `API_PORT` thi bind API vao `http://localhost:{API_PORT}`.
4. Dang ky controllers, CORS, JWT, Swagger, services.
5. Dang ky `ApplicationDbContext` voi SQL Server.
6. Tu dong chay `Database.MigrateAsync()` luc startup.
7. Neu dang o `Development` thi chay `DevelopmentDataSeeder.SeedAsync(...)`.
8. Bat `UseStaticFiles()` de phuc vu file local trong `wwwroot/uploads`.

Luu y:

- CORS hien tai dang la `AllowAll`.
- Swagger chi bat trong `Development`.
- App co dang ky mot so service bi lap giua `Program.cs` va `ServiceExtensions.cs`. Khong gay loi ngay, nhung la diem nen cleanup khi reorganize.

## Architecture ghi nhan tu code

Backend dang chia theo 4 lop, nhung thuc te hoat dong nhu sau:

- `API` nhan request, auth, validation nhe, tra response HTTP.
- `Application` chua phan lon logic nghiep vu va DTO mapping.
- `Domain` chua entity nhu `User`, `Trip`, `Hotel`, `BusSchedule`, `Payment`, `ExplorePost`...
- `Infrastructure` chua EF Core, migrations, repositories, va mot so service phu thuoc ben ngoai.

Nhung co vai diem can biet:

- `UserService` hien dang nam trong `Infrastructure/Services/User`, du interface nam trong `Application`.
- `AdminService` cung nam trong `Infrastructure`.
- Nhieu controller su dung truc tiep `ApplicationDbContext` thay vi di qua abstraction.
- `TripController` chua kha nhieu business flow lon thay vi day het xuong service.

Neu sau nay ban muon setup lai folder cho dep hon, day la nhom nen uu tien refactor.

## Module nghiep vu chinh

### 1. Auth va account

Controller: `AuthController`

Chuc nang:

- login bang email/username + password
- login bang Google ID token
- register
- verify email bang OTP
- forgot/reset password
- refresh token
- logout
- lay thong tin user hien tai

Service chinh:

- `AuthService`
- `TokenService`
- `EmailService`

Ghi chu:

- User thuong phai verify email truoc khi login.
- Admin/Staff duoc nop long hon o buoc verify email.
- Refresh token duoc luu trong bang `Users`.

### 2. User profile

Controller: `UserController`

Chuc nang:

- lay / cap nhat profile
- upload avatar
- upload anh CCCD/CMND
- doi mat khau
- quan ly favorites / wishlist
- quan ly settings thong bao
- lay activity history

Service chinh:

- `Infrastructure/Services/User/UserService`

### 3. Catalog / discovery

Controllers:

- `CatalogController`
- `HotelController`
- `DestinationController`
- `BusController`

Chuc nang:

- home data
- search hotel
- hotel detail
- room availability
- search bus
- bus detail
- validate promotion
- list destination
- list bus seats

Service chinh:

- `CatalogService`

Ghi chu nghiep vu:

- Hotel availability duoc tinh tu `Rooms.AvailableQty` va cac `TripItinerary` dang book.
- Bus controller co logic don gian de tra schedule va seats, ke ca cleanup ghe bi lock het han.

### 4. Trip / booking

Controller: `TripController`

Chuc nang:

- CRUD trip
- CRUD itinerary
- tao booking khach san nhanh (`POST /api/trips/hotel-bookings`)
- fake payment cho demo
- confirm payment tai endpoint `/api/trips/{tripId}/pay`
- re-lock seats cho bus booking
- lay service options cho trip planner

Service chinh:

- `TripService`
- `ItineraryService`
- `TripServiceOptionService`

Business rules quan trong:

- Dat phong khach san yeu cau profile day du: ten, so dien thoai, ngay sinh, so giay to, anh giay to.
- Hotel booking co tinh so dem, so phong, phu thu khach phu.
- Ghe xe co co che `Locked` / `Booked`.
- Re-lock seat giu ghe them 10 phut.

### 5. Payment

Controller: `PaymentController`

Chuc nang:

- tao payment PayOS
- tao payment VNPAY
- tra cuu trang thai payment theo `paymentId` / `orderCode`
- nhan webhook PayOS
- nhan return + IPN tu VNPAY

Service chinh:

- `PayOsPaymentService`

Luu y:

- Ten service la `PayOsPaymentService` nhung dang handle ca PayOS va VNPAY.
- Payment thanh cong co cap nhat `Trip`, tao notification, gui email, va voi bus thi danh dau ghe da book.
- Ngoai flow gateway nay, `TripController` van co endpoint `/api/trips/{tripId}/pay` de xac nhan thanh toan theo kieu noi bo/demo.

### 6. Explore / social content

Controller: `ExploreController`

Chuc nang:

- list / detail bai viet explore
- tao bai viet
- upload anh bai viet
- like / save
- rating
- comment / reply
- filter data
- location suggestions

Service chinh:

- `ExploreService`

Ghi chu:

- Explore support visibility (`IsVisible`)
- ratings duoc tong hop lai vao `AverageRating` va `RatingCount`
- comment reply co tao notification

### 7. Chat AI

Controller: `ChatController`

Chuc nang:

- gui tin nhan cho AI
- lay lich su chat
- lay danh sach session
- xoa history
- lay suggestions nhanh

Service chinh:

- `ChatService`
- `GrokAiService`
- `OpenMeteoWeatherService`
- `ChatRepository`

Thuc te hoat dong:

- Detect intent tu message: destination, hotel, bus, weather, itinerary, promotion...
- Lay context tu DB de boi du lieu cho AI
- Neu AI tra loi khong dung / thieu thi fallback bang deterministic response
- Luu lich su chat vao `ChatHistories`

### 8. Notification

Controller: `NotificationController`

Chuc nang:

- list notifications
- unread count
- mark read / mark all read
- register / unregister FCM token

Service chinh:

- `NotificationService`
- `FcmPushService`

### 9. Review

Controller: `ReviewController`

Chuc nang:

- tao review cho hotel / bus company / trip

### 10. Admin

Controller: `AdminController`

Role:

- `[Authorize(Roles = "Admin,Staff")]`

Nhom chuc nang:

- dashboard
- user management
- transport companies / schedules / seat map
- booking management
- destination / hotel / room / promotion CRUD
- explore post management
- notification broadcast
- upload image cho room / destination / logo nha xe

Service chinh:

- `Infrastructure/Services/Admin/AdminService*.cs`

## Database

`ApplicationDbContext` nam o:

- `backend/SmartTrip.Infrastructure/Data/ApplicationDbContext.cs`

DB dang dung:

- SQL Server

Migrations nam o:

- `backend/SmartTrip.Infrastructure/Migrations/`

Cac nhom bang chinh:

- User va auth: `Users`, `UserWallets`, `UserPreferences`, `UserFcmTokens`
- Catalog: `Destinations`, `Hotels`, `Rooms`, `Amenities`, `Galleries`
- Transport: `BusCompanies`, `BusSchedules`, `Seats`
- Booking: `Trips`, `TripItineraries`, `Payments`, `Invoices`, `Promotions`, `Reviews`, `Wishlists`
- Social: `ExplorePosts`, `ExplorePostImages`, `ExplorePostLikes`, `ExplorePostSaves`, `ExplorePostRatings`, `ExploreComments`
- AI/history: `ChatHistories`
- Notification: `Notifications`

## Seed data trong Development

Neu app chay voi `ASPNETCORE_ENVIRONMENT=Development`, backend se auto seed data.

Seeder:

- `backend/SmartTrip.API/Data/DevelopmentDataSeeder.cs`

No tao:

- admin user
- demo user
- destinations
- hotels / rooms / amenities
- bus companies / schedules / seats
- promotions
- trips / payments / reviews / invoices / wishlist
- explore posts, comments, ratings

Tai khoan dev duoc seed:

- `admin@smarttrip.vn` / `12345678`
- `test@example.com` / `12345678`

Chi nen dung trong local dev.

## Storage va upload anh

Service upload anh:

- `FirebaseImageStorageService`

Backend uu tien upload len Firebase Storage. Neu Firebase chua cau hinh:

- trong `Development`, no co the fallback ve local file storage
- file local duoc ghi vao `SmartTrip.API/wwwroot/uploads/...`

Vi vay backend hien tai dang song song 2 kieu storage:

- cloud storage (Firebase)
- local static files (`wwwroot/uploads`)

Day cung la mot diem nen chuan hoa neu ban sap xep lai he thong file sau nay.

## Cau hinh can biet

File config mac dinh:

- `backend/SmartTrip.API/appsettings.json`

Backend cung doc `.env` va environment variables.

### Nhom config chinh

- DB: `ConnectionStrings__SmartTrip`
- JWT: `Jwt__Key`, `Jwt__Issuer`, `Jwt__Audience`, `Jwt__ExpireMinutes`, `Jwt__RefreshTokenExpireDays`
- Frontend URL: `FrontendUrl`
- Email: `EmailSettings__SmtpHost`, `EmailSettings__SmtpPort`, `EmailSettings__Username`, `EmailSettings__Password`, `EmailSettings__SenderEmail`, `EmailSettings__SenderName`
- Google login: `GoogleAuthSettings__GoogleClientIds__Web`, `GoogleAuthSettings__GoogleClientIds__Android`, `GoogleAuthSettings__GoogleClientIds__Ios`
- Firebase:
  - `Firebase__ProjectId`
  - `Firebase__StorageBucket`
  - `Firebase__ServiceAccountPath`
  - hoac `FIREBASE_PROJECT_ID`, `FIREBASE_STORAGE_BUCKET`, `FIREBASE_SERVICE_ACCOUNT_PATH`
  - hoac `GOOGLE_APPLICATION_CREDENTIALS`
- Storage fallback: `Storage__UseLocalFallback` hoac `USE_LOCAL_IMAGE_STORAGE_FALLBACK`
- Groq/Grok:
  - `Grok__ApiKey`
  - `Grok__BaseUrl`
  - `Grok__Model`
  - `Grok__MaxTokens`
- PayOS:
  - `PAYOS_CLIENT_ID`
  - `PAYOS_API_KEY`
  - `PAYOS_CHECKSUM_KEY`
- VNPAY:
  - `VNPAY_TMN_CODE`
  - `VNPAY_HASH_SECRET`
  - `VNPAY_PAYMENT_URL`
  - `VNPAY_RETURN_URL`
  - `VNPAY_IPN_URL`
- Port: `API_PORT`

### Luu y rat quan trong ve DB password

Trong code, `Program.cs` va `ServiceExtensions.cs` co logic thay `DB_PASSWORD` vao connection string bang cach replace chuoi:

```text
Password= ;
```

Nghia la:

- Neu ban muon dung env `DB_PASSWORD`, connection string goc phai de placeholder theo dung format tren.
- Neu `appsettings.json` dang ghi san password that, `DB_PASSWORD` se khong thay duoc.

Vi vay de setup gon hon, de xuat uu tien:

```env
ConnectionStrings__SmartTrip=Server=localhost,1434;Database=SkynetSmartTrip;User Id=sa;Password=YourStrongPassword;Encrypt=False;TrustServerCertificate=True;
```

thay vi phu thuoc vao `DB_PASSWORD`.

## Vi du `.env` toi thieu cho local

```env
ASPNETCORE_ENVIRONMENT=Development
API_PORT=5110

ConnectionStrings__SmartTrip=Server=localhost,1434;Database=SkynetSmartTrip;User Id=sa;Password=YourStrongPassword;Encrypt=False;TrustServerCertificate=True;

Jwt__Key=replace-with-a-long-secret-key-at-least-32-chars
Jwt__Issuer=http://localhost:5110
Jwt__Audience=http://localhost:5110
Jwt__ExpireMinutes=60
Jwt__RefreshTokenExpireDays=7

FrontendUrl=http://localhost:5173

EmailSettings__SmtpHost=smtp.gmail.com
EmailSettings__SmtpPort=587
EmailSettings__Username=your-email@gmail.com
EmailSettings__Password=your-app-password
EmailSettings__SenderEmail=your-email@gmail.com
EmailSettings__SenderName=SkynetSmartTrip

GoogleAuthSettings__GoogleClientIds__Web=

Firebase__ProjectId=
Firebase__StorageBucket=
Firebase__ServiceAccountPath=
Storage__UseLocalFallback=true

Grok__ApiKey=
Grok__BaseUrl=https://api.groq.com/openai/v1
Grok__Model=openai/gpt-oss-120b
Grok__MaxTokens=2048

PAYOS_CLIENT_ID=
PAYOS_API_KEY=
PAYOS_CHECKSUM_KEY=

VNPAY_TMN_CODE=
VNPAY_HASH_SECRET=
VNPAY_PAYMENT_URL=https://sandbox.vnpayment.vn/paymentv2/vpcpay.html
VNPAY_RETURN_URL=http://localhost:5110/api/payments/vnpay/return
VNPAY_IPN_URL=http://localhost:5110/api/payments/vnpay/ipn
```

## Cach chay local

Yeu cau:

- .NET SDK 8
- SQL Server
- database co the tao moi, vi app se auto migrate luc startup

Lenh chay:

```powershell
dotnet restore .\Skynet-Smart-Trip.sln
dotnet run --project .\backend\SmartTrip.API
```

Mac dinh:

- launch profile dev dang dung `http://localhost:5110`
- Swagger: `http://localhost:5110/swagger`

Neu set `API_PORT`, app se uu tien port do.

## EF Core commands huu ich

Tao migration moi:

```powershell
dotnet ef migrations add <MigrationName> --project .\backend\SmartTrip.Infrastructure --startup-project .\backend\SmartTrip.API
```

Apply migration:

```powershell
dotnet ef database update --project .\backend\SmartTrip.Infrastructure --startup-project .\backend\SmartTrip.API
```

Tuy nhien trong flow binh thuong, app da auto migrate khi boot.

## Docker

Dockerfile:

- `backend/Dockerfile`

Build:

```powershell
docker build -f .\backend\Dockerfile -t smarttrip-api .\backend
```

Run:

```powershell
docker run --rm -p 8080:8080 --env-file .env smarttrip-api
```

Ghi chu:

- Dockerfile expose port `8080`
- neu ban muon config them connection string, JWT, payment, Firebase... thi dua qua `.env` hoac `-e`

## Map nhanh cac controller

- `AuthController`: auth, register, verify email, password reset
- `UserController`: profile, upload avatar/identity, favorites, settings
- `CatalogController`: home, search hotel/bus, promotion validate
- `HotelController`: hotel listing / detail / calendar
- `DestinationController`: destination listing
- `BusController`: bus schedules, seat status
- `TripController`: trip + itinerary + booking flow
- `PaymentController`: PayOS + VNPAY
- `ExploreController`: explore posts, comments, likes, saves, ratings
- `ChatController`: AI chat, history, sessions
- `NotificationController`: in-app notifications + FCM token
- `ReviewController`: review creation
- `AdminController`: admin CMS + dashboard + uploads

## Diem nen cleanup neu ban dang "set up lai file"

Neu muc tieu tiep theo cua ban la sap xep lai backend cho de maintain hon, day la nhung diem uu tien:

1. Gom DI dang bi lap trong `Program.cs` va `ServiceExtensions.cs`.
2. Day business logic lon ra khoi `TripController`.
3. Chuan hoa vi tri service: `UserService`, `AdminService` co the dua ve application layer hoac tach ro interface/implementation hon.
4. Giam viec controller/service truy cap truc tiep `ApplicationDbContext`.
5. Dua secrets ra khoi `appsettings.json`, uu tien `.env` hoac secret manager.
6. Chuan hoa storage strategy: chi Firebase, hoac local cho dev va cloud cho prod theo rule ro rang.
7. Tach tai lieu API/route thanh mot file rieng neu can team frontend dung chung.

## Ket luan

Backend nay da kha day du cho mot he thong du lich:

- auth
- profile
- catalog hotel/bus
- trip planning / booking
- payment
- notifications
- social explore
- AI chat
- admin dashboard

Neu xem theo goc do "setup lai file", `backend/README.md` nay la tam ban do de ban tiep tuc buoc sau: tach folder, doi naming, cleanup config, va viet tai lieu API chi tiet hon.
