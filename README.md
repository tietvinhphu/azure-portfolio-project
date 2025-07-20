# Dự án: Ứng dụng Ghi chú An toàn trên Azure

## 1. Mô tả
Đây là một dự án full-stack hoàn chỉnh, trình bày cách triển khai một ứng dụng web Node.js được đóng gói bằng Docker lên Azure. Toàn bộ hạ tầng (Mạng, App Service, Key Vault) được quản lý bằng Terraform theo nguyên tắc Infrastructure as Code (IaC). Ứng dụng được bảo mật bằng cách sử dụng Managed Identity để truy xuất "secrets" từ Azure Key Vault mà không cần lưu trữ bất kỳ thông tin nhạy cảm nào trong code.

## 2. Sơ đồ kiến trúc
*(Dùng https://draw.io để vẽ một sơ đồ đơn giản rồi chèn ảnh vào đây)*

## 3. Công nghệ sử dụng
- **Cloud:** Microsoft Azure
- **IaC:** Terraform
- **Containerization:** Docker
- **Application:** Node.js, Express

## 4. Hướng dẫn triển khai
1.  Clone repository này.
2.  Đăng nhập Azure CLI (`az login`).
3.  Trong thư mục gốc của dự án, chạy các lệnh sau:
    ```bash
    terraform init
    terraform plan
    terraform apply
    ```
4.  Sau khi hạ tầng được tạo, cần phải xây dựng và đẩy Docker image của ứng dụng lên một container registry (như Azure Container Registry hoặc Docker Hub) và cập nhật cấu hình App Service để trỏ đến image đó.