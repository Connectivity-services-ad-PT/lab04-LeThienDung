# # syntax=docker/dockerfile:1.7

# FROM python:3.11-slim AS builder

# ENV PYTHONDONTWRITEBYTECODE=1
# ENV PYTHONUNBUFFERED=1

# WORKDIR /build

# RUN python -m venv /opt/venv

# COPY requirements.txt .

# RUN /opt/venv/bin/pip install --no-cache-dir --upgrade pip \
#     && /opt/venv/bin/pip install --no-cache-dir -r requirements.txt


# FROM python:3.11-slim AS runtime

# ENV PYTHONDONTWRITEBYTECODE=1
# ENV PYTHONUNBUFFERED=1
# ENV PATH="/opt/venv/bin:$PATH"
# ENV APP_HOST=0.0.0.0
# ENV APP_PORT=8000
# ENV AUTH_TOKEN=local-dev-token

# WORKDIR /app

# RUN addgroup --system appgroup \
#     && adduser --system --ingroup appgroup --home /app appuser

# COPY --from=builder /opt/venv /opt/venv
# COPY src/ ./src/

# RUN chown -R appuser:appgroup /app

# USER appuser

# EXPOSE 8000

# HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
#   CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/health', timeout=3).read()" || exit 1

# CMD ["sh", "-c", "uvicorn iot_app.main:app --app-dir src --host ${APP_HOST} --port ${APP_PORT}"]


# Sử dụng base image Python nhẹ nhàng
FROM python:3.10-slim

# Cài đặt curl (phục vụ lệnh HEALTHCHECK) và thư viện hệ thống cho OpenCV/AI model
RUN apt-get update && apt-get install -y \
    curl \
    libgl1 \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Chuyển thư mục làm việc mặc định vào /app
WORKDIR /app

# Copy requirements.txt và cài đặt thư viện trước để tối ưu Docker cache
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy thư mục mã nguồn vào container
COPY src/ src/

# LƯU Ý: Nếu nhóm bạn để model YOLO (.pt) ở một thư mục khác không nằm trong src/,
# ví dụ thư mục 'models/', hãy bỏ comment dòng bên dưới để copy nó vào:
# COPY models/ models/

# Tạo user non-root có tên là 'appuser' và cấp quyền sở hữu thư mục /app cho user này
RUN useradd -m appuser && chown -R appuser /app

# Chuyển sang sử dụng user non-root để tăng tính bảo mật
USER appuser

# Khai báo port mở ra bên ngoài
EXPOSE 8000

# Cấu hình Healthcheck gọi vào endpoint /health
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8000/health || exit 1

# Lệnh khởi chạy ứng dụng
# CHÚ Ý: Nếu code của bạn đổi tên thư mục 'iot_app' thành tên khác (ví dụ: vision_app),
# hãy nhớ sửa lại đoạn 'iot_app.main:app' cho tương ứng.
CMD ["uvicorn", "iot_app.main:app", "--app-dir", "src", "--host", "0.0.0.0", "--port", "8000"]