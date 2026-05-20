# Frontend - Despachos SmartLogix

Frontend de la aplicación SmartLogix para gestión de despachos y ventas. Hecho con React + Vite, se sirve a través de Nginx dentro de un contenedor Docker desplegado en EC2.

## Tecnologías

- React 18 + Vite 5
- Tailwind CSS
- React Router DOM
- Axios
- Nginx 1.25 (servidor de producción y proxy inverso)
- Docker

## Estructura

```
front_despacho/
├── .github/workflows/deploy.yml   # pipeline CI/CD
├── src/
│   ├── Routes/AppRoutes.jsx
│   ├── componentes/
│   │   ├── CrudAdmin/             # tablas, formularios, modales
│   │   └── Layouts/               # navbar, footer, carrusel
│   └── main.jsx
├── Dockerfile
├── vite.config.js
└── package.json
```

## Cómo correr el proyecto

### Con docker-compose (stack completo)

Desde la carpeta raíz donde está el `docker-compose.yml`:

```bash
docker-compose up --build
```

Abre en: `http://localhost`

### Solo el frontend en Docker

```bash
docker build -t smartlogix-frontend .
docker run -d -p 80:8080 --name frontend-app smartlogix-frontend
```

Abre en: `http://localhost`

### Modo desarrollo local

```bash
npm install
npm run dev
```

Abre en: `http://localhost:5173`

## Puertos y proxy

| | Valor | Para qué sirve |
|---|---|---|
| Puerto interno del contenedor | 8080 | Nginx escucha acá |
| Puerto externo | 80 | Lo que ve el navegador |
| `/api/v1/ventas` | `http://back-ventas:8080` | Proxy al backend ventas |
| `/api/v1/despachos` | `http://back-despachos:8081` | Proxy al backend despachos |

En producción los backends están en subred privada, solo accesibles desde el frontend según los Security Groups de AWS.

## Dockerfile

Se usa multi-stage build con dos etapas:

- **Etapa 1:** imagen `node:20-alpine`, instala dependencias y genera el build con `npm run build`
- **Etapa 2:** imagen `nginx:1.25-alpine`, copia el `/dist` y lo sirve. Corre con el usuario `nginx` (no root)

Nginx también actúa como proxy inverso hacia los dos backends usando los nombres de servicio de la red Docker interna.

## Pipeline CI/CD

El pipeline se dispara con cada push a la rama `deploy`.

Pasos:
1. Checkout del código
2. Configura credenciales AWS con los secrets del repo
3. Login en Amazon ECR
4. Build y push de la imagen Docker a ECR
5. Conexión SSH a la EC2 pública
6. Pull de la nueva imagen y reemplazo del contenedor

Secrets necesarios en el repo:

| Secret | Descripción |
|---|---|
| `AWS_ACCESS_KEY_ID` | Credencial AWS Academy |
| `AWS_SECRET_ACCESS_KEY` | Credencial AWS Academy |
| `AWS_SESSION_TOKEN` | Token de sesión AWS Academy |
| `EC2_HOST` | IP pública de la EC2 del frontend |
| `EC2_SSH_KEY` | Clave privada PEM para SSH |

## Notas

- Las credenciales nunca están en el código, solo en GitHub Secrets
- Solo el frontend es accesible desde internet, los backends viven en subred privada