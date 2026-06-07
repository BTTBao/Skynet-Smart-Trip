# SmartTrip Backend Business Logic

## Muc dich

File nay tach rieng phan "logic tung module" khoi `README.md`.

Neu `README.md` la ban do tong quan, thi file nay tap trung vao:

- request di qua dau
- service nao xu ly
- rule nghiep vu chinh la gi
- du lieu nao bi anh huong
- output / side effect nao duoc tao ra

File nay phu hop de dua vao bai bao cao, thuyet trinh, hoac dung lam tai lieu doc logic code.

## 1. Auth logic

### 1.1 Dang nhap thuong

Flow:

1. `AuthController` nhan `identifier` va `password`.
2. `AuthService.LoginAsync` kiem tra `identifier` la email hay username.
3. Tim user trong DB qua `UserRepository`.
4. Verify password bang BCrypt.
5. Chan login neu:
   - khong ton tai user
   - sai password
   - tai khoan bi khoa
   - email chua verify va user khong phai Admin/Staff
6. Tao `access token` va `refresh token`.
7. Luu `refresh token`, han su dung, `LastLoginAt`.
8. Tra ve token cho client.

Rule chinh:

- Access token het han theo `Jwt:ExpireMinutes`.
- Refresh token het han theo `Jwt:RefreshTokenExpireDays`.
- Email verification la bat buoc cho user thuong.

DB tac dong:

- `Users`

### 1.2 Dang nhap Google

Flow:

1. Client gui `idToken`.
2. `AuthService.LoginWithGoogleAsync` verify token voi Google.
3. Tim user theo email.
4. Neu chua co user:
   - tao user moi
   - set `AuthProvider = Google`
   - luu `SocialId`
5. Neu da co user:
   - update provider neu can
   - danh dau email da verify
6. Tao access/refresh token nhu login thuong.

Rule chinh:

- Google user moi khong can qua buoc register local.
- Email tu Google duoc xem la nguon dang tin de verify.

### 1.3 Dang ky va verify email

Flow register:

1. Kiem tra email chua ton tai.
2. Kiem tra username chua ton tai.
3. Tao OTP 6 so.
4. Tao user moi voi:
   - password hash
   - role `User`
   - `IsEmailVerified = false`
   - OTP va han 15 phut
5. Gui email verify.

Flow verify:

1. Nhan `email` + `otp`.
2. Tim user theo email.
3. So khop OTP.
4. Kiem tra OTP con han.
5. Set `IsEmailVerified = true`.
6. Xoa OTP.
7. Tao notification va gui welcome email.

Rule chinh:

- OTP verify het han sau 15 phut.
- Verify thanh cong se tao side effect thong bao + welcome email.

### 1.4 Quen mat khau / doi lai mat khau

Forgot password:

1. Tim user theo email.
2. Neu khong ton tai van tra success de tranh email enumeration.
3. Tao reset token.
4. Luu han 15 phut.
5. Gui link reset ve frontend.

Reset password:

1. Tim user theo reset token.
2. Kiem tra token con han.
3. Hash mat khau moi.
4. Xoa reset token.
5. Xoa refresh token hien tai de bat dang nhap lai.

## 2. User profile logic

### 2.1 Lay profile

Flow:

1. `UserController` lay `userId` tu JWT.
2. `UserService.GetUserProfileAsync` doc `Users`.
3. Tong hop them:
   - loyalty points tu `UserWallets`
   - so trip tu `Trips`
   - so voucher kha dung tu `Promotions`
4. Build `UserDto`.

Rule chinh:

- Member tier duoc tinh theo loyalty points:
  - `>= 1000`: Platinum
  - `>= 500`: Gold
  - `>= 100`: Silver
  - con lai: Member

### 2.2 Cap nhat profile

Flow:

1. Controller validate:
   - ten khong rong
   - phone 10-11 so
   - birth date hop le va nho hon ngay hien tai
   - identity number phai 9 hoac 12 so
2. `UserService.UpdateUserProfileAsync` check CCCD/CMND co trung user khac khong.
3. Update `FullName`, `Phone`, `BirthDate`, `IdentityNumber`.

Rule chinh:

- So giay to la unique tren he thong.
- Format validation dang lam mot phan o controller, mot phan o service.

### 2.3 Upload avatar va anh giay to

Flow:

1. Controller nhan file multipart.
2. Validate:
   - co file
   - <= 5MB
   - dung dinh dang JPG/PNG/WEBP
3. Goi `IImageStorageService.UploadImageAsync`.
4. Service upload len Firebase hoac fallback local.
5. Luu URL vao user.

Rule chinh:

- Dev co the fallback local neu Firebase chua setup.
- URL luu vao DB la absolute URL hop le.

### 2.4 Favorites / wishlist

Flow:

1. User chon item hotel hoac bus.
2. Service parse `ItemType`.
3. Check item ton tai trong bang dich vu tuong ung.
4. Neu da favorite roi thi tra item hien tai, khong tao duplicate.
5. Neu chua co thi insert vao `Wishlists`.

Rule chinh:

- He thong hien support 2 loai:
  - `Hotel`
  - `Bus`

### 2.5 User settings

Flow:

1. Settings duoc luu theo key-value trong `UserPreferences`.
2. `GetUserSettingsAsync` doc tat ca preference cua user.
3. `UpdateUserSettingsAsync` upsert cac key:
   - `push_notifications`
   - `email_notifications`
   - `email_offers`
   - `dark_mode`
   - `language`
   - `currency`

Rule chinh:

- Kieu du lieu luu o DB la string.
- Service convert string -> bool/string khi tra ve DTO.

### 2.6 Doi mat khau

Flow:

1. Chi ho tro user local.
2. Check day du current/new/confirm password.
3. Verify current password.
4. Check password moi:
   - >= 8 ky tu
   - khac password cu
   - confirm khop
5. Hash password moi.
6. Xoa refresh token.
7. Tao notification va gui email neu user bat email notification.

## 3. Catalog logic

### 3.1 Home data

`CatalogService.GetHomeAsync`

Flow:

1. Tinh booking count theo destination dua tren `Trips`.
2. Lay destinations va sort theo:
   - booking count giam dan
   - `IsHot`
   - ten
3. Lay hotels available, rooms, amenities.
4. Tinh rating hotel tu `Reviews`.
5. Lay bus schedules sap chay.
6. Tinh rating bus company tu `Reviews`.
7. Tra ve:
   - `PopularDestinations`
   - `FeaturedHotels`
   - `RecommendedHotels`
   - `FeaturedBuses`

### 3.2 Search hotel

Flow:

1. Lay danh sach hotel available.
2. Join destination, rooms, amenities.
3. Build hotel card DTO.
4. Filter theo:
   - keyword
   - destinationId
   - min/max price
   - min rating
   - star ratings
5. Sort theo:
   - `priceAsc`
   - `priceDesc`
   - `ratingDesc`
   - default `popular`

Rule chinh:

- Gia hotel card lay tu room re nhat.
- Rating neu chua co review thi gan gia tri mac dinh.

### 3.3 Room availability

Flow:

1. Nhan `roomId`, `checkInDate`, `checkOutDate`, `quantity`.
2. Validate quantity > 0, checkout > checkin.
3. Lay room + hotel.
4. Kiem tra `AvailableQty`.
5. Doc cac `TripItinerary` hotel chua bi cancel co overlap date.
6. Tinh `peak booked qty` trong khoang ngay chon.
7. `remainingQty = totalQty - bookedQty`.
8. Tra ve con phong hay khong.

Rule chinh:

- Availability duoc tinh theo khoang overlap tung ngay, khong chi la dem tong.
- `HotelCheckOutDate` duoc uu tien, neu khong co thi fallback `Trip.EndDate`.

### 3.4 Search bus

Flow:

1. Lay bus schedules + company + from/to destination.
2. Filter theo:
   - keyword
   - fromDestinationId
   - toDestinationId
   - min/max price
3. Tinh rating tu reviews cua bus company.
4. Sort theo gia hoac gio khoi hanh.

## 4. Trip va booking logic

## 4.1 Tao trip thu cong

Flow:

1. User gui thong tin trip.
2. `TripService.CreateTripAsync` validate input.
3. Tao `Trip` moi voi status mac dinh.
4. Tra ve `TripSummaryDto`.

Trip la container chua hanh trinh, chua chac da thanh toan.

### 4.2 Them itinerary

Flow:

1. User phai so huu trip.
2. Neu them `HOTEL`, controller check profile completeness.
3. `ItineraryService.AddItineraryAsync` tao ban ghi itinerary.
4. Service cap nhat tong tien/tong profit cua trip.

Rule chinh:

- Itinerary la don vi nghiep vu chi tiet trong mot trip.
- Mot trip co the chua hotel, bus va cac service khac.

### 4.3 Tao hotel booking nhanh

Endpoint: `POST /api/trips/hotel-bookings`

Flow:

1. Kiem tra current user ton tai.
2. Kiem tra profile da du:
   - name
   - phone
   - birthDate
   - identityNumber
   - identityCardPhoto
3. Validate `HotelId`, `RoomId`.
4. Lay room + hotel.
5. Kiem tra room thuoc hotel do va hotel dang available.
6. Validate suc chua:
   - moi phong it nhat 1 nguoi lon
   - co gioi han tong khach / phong
   - infant toi da 1 / phong
7. Tinh tong gia:
   - `price * nights * quantity`
   - them phu thu extra guest
8. Tao `Trip` status `PENDING`.
9. Tao `TripItinerary` loai `HOTEL`.
10. Commit transaction.

Rule chinh:

- Hotel booking nhanh thuc chat la tao 1 trip + 1 itinerary.
- Booked commission rate uu tien commission cua hotel, neu khong co thi dung cua room.

### 4.4 Thanh toan trip noi bo

Endpoint: `POST /api/trips/{tripId}/pay`

Flow:

1. User phai so huu trip.
2. Load trip + user + itineraries + payments + invoices.
3. Neu da co payment `Paid` hoac da co invoice thi tra ket qua da thanh toan.
4. Validate amount va payment method.
5. Tao `Payment` status `Paid`.
6. Update trip status:
   - thuong se thanh `Paid`
   - tinh `TotalProfit`
7. Tao `Invoice`.
8. Neu trip co bus itinerary:
   - tim cac ghe dang lock boi trip
   - hoac doc `SelectedSeats`
   - doi status ghe thanh `Booked`
9. Save changes.
10. Tao notification booking thanh cong.
11. Gui email xac nhan dat cho theo background task.

Rule chinh:

- Logic nay mang tinh "confirm payment noi bo/demo".
- Loi nhuan trip duoc chia theo ti le tung itinerary va `BookedCommissionRate`.

### 4.5 Re-lock seat

Flow:

1. User phai so huu trip.
2. Trip phai co bus itinerary va `SelectedSeats`.
3. Nap seats theo schedule.
4. Kiem tra:
   - seat co ton tai
   - seat chua bi book boi nguoi khac
   - neu dang lock boi nguoi khac va chua het han thi khong cho giu lai
5. Set:
   - `Status = Locked`
   - `LockedUntil = now + 10 phut`
   - `LockedByTripId = tripId`

## 5. Payment gateway logic

## 5.1 PayOS

Flow tao payment:

1. Validate request.
2. Check cau hinh PayOS da day du.
3. Check `OrderCode` da ton tai chua.
4. Tao local payment status `Pending`.
5. Goi PayOS `/v2/payment-requests`.
6. Neu thanh cong:
   - luu `CheckoutUrl`
   - luu `QrCode`
   - luu `PaymentLinkId`
7. Neu loi:
   - danh dau `Failed`

Webhook:

1. Verify signature.
2. Tim payment theo `OrderCode`.
3. Resolve status tu payload.
4. Update payment.
5. Neu paid:
   - set `PaidAt`
   - update trip thanh `Paid`
   - tinh profit
   - book bus seats neu metadata la bus
   - gui notification + email
6. Neu failed/cancelled/expired:
   - gui notification that bai neu co

### 5.2 VNPAY

Flow tao payment:

1. Validate amount.
2. Check config VNPAY day du.
3. Tao `OrderCode` unique.
4. Tao local payment `Pending`.
5. Build signed URL theo tham so `vnp_*`.
6. Tra ve checkout URL.

IPN/return:

1. Verify secure hash.
2. Tim payment theo `vnp_TxnRef`.
3. Check amount khop.
4. Resolve payment status:
   - `00/00` => `Paid`
   - `24` => `Cancelled`
   - `11` => `Expired`
   - con lai => `Failed`
5. Neu paid:
   - update trip
   - book seat neu can
   - gui notification/email

## 6. Review logic

Flow:

1. User phai dang nhap.
2. Rating phai tu 1 den 5.
3. `TargetType` phai parse duoc.
4. Trip phai ton tai, thuoc user do.
5. Trip phai da thanh toan.
6. Check nghiep vu "da su dung xong dich vu chua":
   - Hotel: phai qua ngay checkout
   - Bus: phai qua gio arrival
7. Check user chua review dich vu nay cho trip nay.
8. Tao review.

Rule chinh:

- Khong cho review truoc khi ket thuc dich vu.
- Moi trip, moi target, moi user chi duoc review 1 lan.

## 7. Explore logic

### 7.1 List post

Flow:

1. Chi lay post `IsVisible = true`.
2. Apply filter:
   - keyword
   - city / cities
   - province
   - region
   - min rating
   - cost level
3. Apply sort:
   - newest
   - mostViewed
   - topRated
4. Phan trang.

### 7.2 Create post

Flow:

1. Validate:
   - title 5-200
   - content 10-10000
   - location hop le
   - cost level 1-4
   - max 10 images
   - lat/long nam trong range
2. Resolve location thanh:
   - slug
   - province
   - region
3. Loai duplicate URL anh.
4. Noi image block vao content.
5. Tao `ExplorePost`.
6. Tao `ExplorePostImage`.

### 7.3 Like / save / rate

Like:

- Neu chua like thi insert
- Neu da like thi remove
- Tra ve so luong moi

Save:

- Tuong tu like

Rate:

1. Moi user co 1 rating / post.
2. Neu da rate roi thi update.
3. Recompute `AverageRating` va `RatingCount`.

### 7.4 Comment / reply

Flow:

1. Comment phai co text hoac image.
2. Validate do dai text va image URL.
3. Neu la reply:
   - parent phai ton tai
   - parent phai la root comment
4. Tao comment.
5. Tao notification cho:
   - chu bai viet
   - tac gia comment cha neu la reply

Rule chinh:

- Comment reply hien tai chi support 1 tang reply.

## 8. Chat AI logic

### 8.1 Tong quan

`ChatService` la module lai giua AI va du lieu he thong.

Flow tong:

1. Nhan `message`, `userId`, `sessionId`, `lat/long`.
2. Neu co user thi lay user personalization + chat history.
3. Detect intent.
4. Build DB context tu destinations, hotels, buses, promotions...
5. Goi `GrokAiService`.
6. Normalize response.
7. Neu response kem chat luong thi fallback deterministic.
8. Enrich them cards / itinerary / weather / quick actions.
9. Luu chat history.

### 8.2 Detect intent

He thong tu phan loai y dinh nhu:

- `destination_query`
- `hotel_query`
- `bus_query`
- `weather_query`
- `itinerary_request`
- `promotion_query`
- `budget_query`
- `package_query`
- `booking_request`
- `food_query`
- `general`

Y nghia:

- Intent quyet dinh database context, kieu response, va quick actions.

### 8.3 AI fallback

Neu khong co API key hoac AI loi:

- Service tra response mac dinh than thien
- Sau do bo sung data tu DB de van ra goi y duoc

Nghia la:

- Chat module khong chet hoan toan neu AI provider loi
- Van co kha nang "semi-rule-based assistant"

### 8.4 Weather

Flow:

1. `OpenMeteoWeatherService` geocode dia diem.
2. Goi forecast API.
3. Map ve:
   - nhiet do
   - do am
   - gio
   - condition
   - advice
   - du bao ngan ngay

### 8.5 Itinerary generation

Rule chinh:

- He thong khong nen len plan neu chua du:
  - diem den
  - diem xuat phat
  - so nguoi
  - ngan sach
- Neu thieu thi hoi tiep.
- Neu du thong tin thi moi generate plan.

## 9. Notification logic

Flow tao notification:

1. Validate title, message, userId.
2. Check duplicate trong 5 phut theo:
   - user
   - type
   - reference
   - title
   - message
3. Tao `Notification`.
4. Neu request bat `SendPush` va user cho phep push:
   - gui FCM

Rule chinh:

- Notification co co che chong spam duplicate.
- Email notification va push notification duoc dieu khien bang `UserPreferences`.

## 10. Admin logic

## 10.1 Dashboard

`AdminService.GetDashboardStatsAsync`

Flow:

1. Resolve range date.
2. Tong hop:
   - total users
   - new users today
   - active trips
   - revenue
   - profit
3. Build chart series theo ngay hoac thang.
4. Build activity feed tu:
   - user tao moi
   - trip moi
   - payment
5. Build recent booking list.

### 10.2 Quan ly user

Create:

- validate name/email
- email unique
- tao user local mac dinh password `123456`

Update:

- email unique
- doi role / status / thong tin co ban
- neu status doi thi gui notification/email

Delete:

- khong xoa cung DB
- chi khoa account (`IsActive = false`)
- xoa refresh token

### 10.3 Booking management

Admin booking stats tong hop tu `Trips`, `Payments`, `TripItineraries`.

Tinh:

- total revenue
- total profit
- total bookings
- new customers
- paid / pending / cancelled

### 10.4 Transport management

Admin co the:

- tao / sua / xoa bus schedule
- tao / sua / xoa bus company
- sua seat map

Transport stats tinh:

- occupancy
- expected revenue
- affiliate revenue
- tang truong theo thang
- trang thai route: `running`, `upcoming`, `completed`

### 10.5 Catalog management

Admin CRUD:

- destination
- hotel
- room
- promotion

Logic chung:

- validate truong bat buoc
- check quan he FK ton tai
- update data + tra DTO cho frontend admin

### 10.6 Explore va notification management

Admin co the:

- CRUD explore post
- an/hien bai viet
- xem thong ke notification
- send notification broadcast

## 11. Seed data logic

Khi app chay trong `Development`:

1. Auto migrate DB.
2. Chay `DevelopmentDataSeeder`.
3. Seed:
   - admin user
   - demo user
   - destinations
   - hotels / rooms / amenities
   - bus companies / schedules / seats
   - promotions
   - trips / reviews / invoices / payments
   - explore posts

Y nghia:

- Local dev co du data de test frontend nhanh
- Khong can nhap tay toan bo catalog tu dau

## 12. Diem hay de dua vao bai bao cao

Neu ban can trich phan "logic he thong", nhung y sau rat de viet:

1. He thong khong chi CRUD ma co nhieu rule nghiep vu thuc:
   - chi duoc review sau khi su dung xong dich vu
   - dat phong can day du ho so
   - ghe xe co co che lock/tranh tranh chap
   - thanh toan thanh cong moi phat sinh hoa don va thong bao
2. Module chat AI khong phu thuoc hoan toan vao model:
   - co intent detection
   - co database context
   - co fallback deterministic
3. Notification va email duoc gan vao cac su kien nghiep vu:
   - verify email
   - doi mat khau
   - booking thanh cong
   - thay doi trang thai tai khoan
4. He thong ho tro ca local dev va external service:
   - Firebase co fallback local
   - Payment co PayOS va VNPAY
   - DB auto migrate + auto seed

## 13. Nen doc cung file nao

- Tong quan: `backend/README.md`
- Logic chi tiet: `backend/BUSINESS_LOGIC.md`

Neu can, buoc tiep theo co the tach tiep thanh:

- `backend/API_MAP.md`
- `backend/SETUP_GUIDE.md`
- `backend/REFactor_NOTES.md`