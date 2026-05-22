# --- ETAPA 1: Compilación del Front ---
FROM node:20-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# --- ETAPA 2: Servidor Web Nginx (Mínimo Privilegio) ---
FROM nginx:1.25-alpine

COPY --from=build /app/dist /usr/share/nginx/html

RUN echo 'server { \
    listen 8080; \
    location / { \
    root   /usr/share/nginx/html; \
    index  index.html index.htm; \
    try_files $uri $uri/ /index.html; \
    } \
    location /api/v1/ventas { \
    proxy_pass http://10.0.0.147:8080; \
    proxy_set_header Host $host; \
    proxy_set_header X-Real-IP $remote_addr; \
    } \
    location /api/v1/despachos { \
    proxy_pass http://10.0.0.147:8081; \
    proxy_set_header Host $host; \
    proxy_set_header X-Real-IP $remote_addr; \
    } \
    }' > /etc/nginx/conf.d/default.conf

RUN chown -R nginx:nginx /usr/share/nginx/html /var/cache/nginx /var/run /var/log/nginx
RUN sed -i 's|^user|#user|g' /etc/nginx/nginx.conf && \
    sed -i 's|/var/run/nginx.pid|/tmp/nginx.pid|g' /etc/nginx/nginx.conf

USER nginx
EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]