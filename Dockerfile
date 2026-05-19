# --- ETAPA 1: Compilación del Front ---
FROM node:20-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# --- ETAPA 2: Servidor Web Nginx (Mínimo Privilegio) ---
FROM nginx:1.25-alpine

# Copiar archivos estáticos de React/Vite
COPY --from=build /app/dist /usr/share/nginx/html

# Configurar Nginx para escuchar en el puerto 8080
RUN echo 'server { \
    listen 8080; \
    \
    location / { \
        root   /usr/share/nginx/html; \
        index  index.html index.htm; \
        try_files $uri $uri/ /index.html; \
    } \
    \
    # Enrutamiento local usando los nombres de los servicios de docker-compose \
    location /api/v1/ventas { \
        proxy_pass http://back-ventas:8080; \
        proxy_set_header Host $host; \
        proxy_set_header X-Real-IP $remote_addr; \
    } \
    \
    location /api/v1/despachos { \
        proxy_pass http://back-despachos:8081; \
        proxy_set_header Host $host; \
        proxy_set_header X-Real-IP $remote_addr; \
    } \
}' > /etc/nginx/conf.d/default.conf

# Modificar permisos para que el usuario nativo 'nginx' pueda gestionar los directorios internos
RUN chown -R nginx:nginx /usr/share/nginx/html /var/cache/nginx /var/run /var/log/nginx

# 💡 LA SOLUCIÓN DEFINITIVA: Modificar el archivo de configuración maestro y comentarle la línea del usuario 'user nginx;'
RUN sed -i 's|^user|#user|g' /etc/nginx/nginx.conf && \
    sed -i 's|/var/run/nginx.pid|/tmp/nginx.pid|g' /etc/nginx/nginx.conf

# Cambiar al usuario no root
USER nginx

EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]