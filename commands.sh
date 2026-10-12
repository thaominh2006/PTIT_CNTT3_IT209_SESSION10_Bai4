#!/usr/bin/env bash
# Bài 4: Custom Bridge Network & Named Volume bằng Docker CLI

set -e

# 1. Tạo Custom Bridge Network
docker network create --driver bridge app-net

# 2. Tạo Named Volume
docker volume create db-data

# 3. Chạy Database Container (mount volume db-data)
docker run -d \
  --name db-server \
  --network app-net \
  -v db-data:/var/lib/postgresql/data \
  -e POSTGRES_DB=appdb \
  -e POSTGRES_USER=appuser \
  -e POSTGRES_PASSWORD=apppass123 \
  postgres:15-alpine

# Chờ PostgreSQL khởi động
sleep 10
docker exec db-server pg_isready -U appuser -d appdb

# 4. Chạy Backend Container, kết nối DB qua hostname db-server
docker run -d \
  --name app-container \
  --network app-net \
  -e SPRING_DATASOURCE_URL=jdbc:postgresql://db-server:5432/appdb \
  -e SPRING_DATASOURCE_USERNAME=appuser \
  -e SPRING_DATASOURCE_PASSWORD=apppass123 \
  -e DB_HOST=db-server \
  -p 8081:80 \
  nginx:alpine

# 5. Kiểm tra network, volume, DNS
docker network ls | grep app-net
docker volume ls | grep db-data
docker network inspect app-net
docker exec app-container ping -c 2 db-server

# 6. Test Data Persistence
# 6.1 Thêm dữ liệu
docker exec db-server psql -U appuser -d appdb -c "CREATE TABLE students (id SERIAL PRIMARY KEY, name VARCHAR(100));"
docker exec db-server psql -U appuser -d appdb -c "INSERT INTO students (name) VALUES ('Nguyen Van A'), ('Tran Thi B');"
docker exec db-server psql -U appuser -d appdb -c "SELECT * FROM students;"

# 6.2 Xóa cứng container DB
docker rm -f db-server

# 6.3 Tạo lại container DB, gắn cùng volume db-data
docker run -d \
  --name db-server \
  --network app-net \
  -v db-data:/var/lib/postgresql/data \
  -e POSTGRES_DB=appdb \
  -e POSTGRES_USER=appuser \
  -e POSTGRES_PASSWORD=apppass123 \
  postgres:15-alpine

sleep 10
docker exec db-server pg_isready -U appuser -d appdb

# 6.4 Xác minh dữ liệu còn nguyên
docker exec db-server psql -U appuser -d appdb -c "SELECT * FROM students;"