# 🚀 SmartTrip - Docker Setup

Sử dụng Docker và Docker Compose để quản lý môi trường chạy cho cả Backend (.NET 8), Frontend (React/Vite) và Database (SQL Server 2022).

## 📋 Yêu cầu hệ thống

- Đã cài đặt Docker và Docker Compose (hoặc Docker Desktop).
- Các port sau trên máy đang trống: **3333**, **5555**, **(1434 - tắt sql đang chạy trên docker - nếu có )**.

## 🌐 Danh sách Ports

Sau khi chạy thành công, có thể truy cập các dịch vụ qua:

- **Frontend (Web):** http://localhost:3333
- **Backend (API):** http://localhost:5555/swagger
- **SQL Server:** `localhost,1434` 

## 🛠️ Chạy môi trường Development

Môi trường Dev hỗ trợ Hot-reload cho cả Backend (`dotnet watch`) và Frontend (Vite). Code đến đâu, code sẽ tự cập nhật đến đó mà không cần build lại image.

1. Mở terminal tại thư mục gốc của project (nơi chứa file `docker-compose.yml`).
2. Chạy lệnh sau:

```bash
docker compose up -d --build
```
**Lưu ý kiểm tra trạng thái:**
- Xem log backend: `docker logs -f skynet_backend_dev`
  -> Khi nào thấy dòng chữ `Now listening on: http://0.0.0.0:8080` thì lúc đó Swagger mới truy cập được.
- Xem log frontend: `docker logs -f skynet_web_dev`
  -> Khi thấy bảng thông tin mạng của Vite xuất hiện (VD: `Local: http://localhost:5173/`, `Network: http://172.x.x.x:5173/`) thì web đã sẵn sàng.

*Nếu gặp lỗi không chạy được hoặc cần tải thêm thư viện, hãy làm sạch và khởi động lại bằng lệnh:*
```bash
docker compose down
docker compose up -d --build
```
## 🚀 Chạy môi trường Production (Không cần chạy)

Môi trường Prod sẽ build source code thành các bản release tối ưu nhất và sử dụng Nginx để phục vụ Frontend.

1. Mở terminal tại thư mục gốc của project.
2. Chạy lệnh sau để build và chạy bằng file cấu hình production:

```bash
docker compose -f docker-compose.prod.yml up -d --build
```

## 🛑 Các lệnh hữu ích khác

**Dừng và xóa các container đang chạy (Dev):**
```bash
docker compose down
```

**Dừng và xóa các container đang chạy (Prod):**
```bash
docker compose -f docker-compose.prod.yml down
```

**Xem logs của một service cụ thể (ví dụ: backend):**
```bash
docker compose logs -f backend
```

**Xóa toàn bộ data của database (Reset Database):**
```bash
docker compose down -v
```