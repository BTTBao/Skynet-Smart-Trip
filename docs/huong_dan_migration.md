# Hướng dẫn thao tác Database Migration (EF Core)

Sử dụng **Package Manager Console** hoặc tự chuyển sang lệnh **CMD** tương ứng trong Visual Studio để thực thi các lệnh Migration.

## 1. Tạo Migration mới
Khi có thay đổi về cấu trúc Entity, chạy lệnh sau để tạo file migration:

```powershell
Add-Migration <tên_migration> -Project SmartTrip.Infrastructure -StartupProject SmartTrip.API
```
*(Thay `<tên_migration>` bằng tên mô tả ngắn gọn, ví dụ: `AddUserTable`)*

## 2. Cập nhật Database
Để áp dụng file migration vừa sinh ra (hoặc các migration chưa cập nhật) vào cơ sở dữ liệu:

```powershell
Update-Database
```