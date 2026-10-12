# Bài 4: Custom Network & Named Volume bằng Docker CLI

## 1. Mục tiêu

- Tạo Custom Bridge Network `app-net` để các container gọi nhau bằng tên (DNS nội bộ).
- Tạo Named Volume `db-data` để lưu dữ liệu PostgreSQL bền vững, không phụ thuộc vòng đời container.

## 2. Kiến trúc

| Thành phần | Tên | Ghi chú |
|---|---|---|
| Network | `app-net` | Bridge tự tạo, có DNS resolution theo tên container |
| Volume | `db-data` | Mount vào `/var/lib/postgresql/data` |
| Database | `db-server` | Image `postgres:15-alpine` |
| Backend | `app-container` | Kết nối DB qua hostname `db-server` |

## 3. Cách chạy

```bash
chmod +x commands.sh
./commands.sh
# Dùng image backend riêng:
BACKEND_IMAGE=my-backend:latest ./commands.sh
```

## 4. Các bước script thực hiện

1. Dọn tài nguyên cũ để script chạy lại được nhiều lần.
2. `docker network create --driver bridge app-net`
3. `docker volume create db-data`
4. Chạy `db-server` với `--network app-net` và `-v db-data:/var/lib/postgresql/data`.
5. Chạy `app-container` với `--network app-net`, truyền biến môi trường kết nối DB:
   `SPRING_DATASOURCE_URL=jdbc:postgresql://db-server:5432/appdb`
6. Test Data Persistence:
    - Tạo bảng `students` và thêm 2 bản ghi.
    - `docker rm -f db-server` (xóa cứng container).
    - Chạy lại `db-server` mới, gắn cùng volume `db-data`.
    - Truy vấn lại bảng `students`: dữ liệu vẫn còn nguyên.

## 5. Lệnh kiểm tra

```bash
docker network ls | grep app-net
docker volume ls | grep db-data
docker network inspect app-net
docker exec -it app-container ping -c 2 db-server
```

## 6. Kết quả mong đợi

- `ping db-server` từ `app-container` phân giải ra IP nội bộ của DB (dạng `172.x.x.x`).
- `docker network inspect app-net` liệt kê cả hai container trong mục `Containers`.
- Sau khi tái tạo `db-server`, lệnh `SELECT * FROM students;` vẫn trả về 2 bản ghi.
- Script in `[PASS]` ở bước xác minh dữ liệu.

## 7. Giải thích

- **Vì sao gọi được bằng tên `db-server`?** Network mặc định (`bridge`) không có DNS theo tên
  container. Custom bridge network có DNS nội bộ của Docker nên tên container được phân giải
  thành IP.
- **Vì sao dữ liệu không mất?** Dữ liệu nằm trong Named Volume do Docker quản lý, tách rời khỏi
  lớp ghi của container. Xóa container không xóa volume.
- **Vì sao tái tạo container vẫn khởi động bình thường?** Khi thư mục dữ liệu đã có sẵn,
  PostgreSQL bỏ qua bước khởi tạo (initdb) và dùng lại dữ liệu cũ.

## 8. Dọn dẹp

```bash
docker rm -f app-container db-server
docker network rm app-net
docker volume rm db-data
```