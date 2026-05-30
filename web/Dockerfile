# Stage 1: Build
FROM node:24-alpine AS build 
WORKDIR /app

# Khai báo file package
COPY package.json package-lock.json* yarn.lock* ./ 
RUN npm install

# Copy source code và build
COPY . .
RUN npm run build

# Stage 2: Serve với Nginx 
FROM nginx:alpine 
# Copy file build từ thư mục dist (của Vite) sang thư mục html của nginx
COPY --from=build /app/dist /usr/share/nginx/html

# Cấu hình lại Nginx để support React Router (SPA)
RUN echo 'server { \
    listen 80; \
    location / { \
        root /usr/share/nginx/html; \
        index index.html index.htm; \
        try_files $uri $uri/ /index.html; \
    } \
}' > /etc/nginx/conf.d/default.conf 

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"] 