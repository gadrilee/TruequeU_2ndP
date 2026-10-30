# Trueque U

App para intercambiar objetos y materiales entre estudiantes.
Este repositorio contiene la **Tarea 1: manejo de acceso** (registro, inicio y cierre de sesión, recuperación y cambio de contraseña, sesión que se conserva al recargar, ruta pública y ruta privada).

- **Base de datos:** PostgreSQL (`base_de_datos/`)
- **Backend:** Node.js + Express, separado por carpetas (`backend/`)
- **App:** Flutter, probada en el navegador con Chrome (`app/`)
- **Documentación de la tarea:** [`docs/task-01-access.md`](docs/task-01-access.md)

## Requisitos

- Node.js 18 o superior y pnpm (también sirve npm)
- Flutter 3.22 o superior, con Chrome instalado
- PostgreSQL 13 o superior (con pgAdmin)

## Cómo iniciarlo

Los comandos van uno por línea, desde la raíz del repositorio, y funcionan en PowerShell.

### 1. Crear la base de datos (una sola vez)

Con `psql`:

```bash
psql -U postgres -c "CREATE DATABASE trueque_u;"
psql -U postgres -d trueque_u -f base_de_datos/estructura.sql
psql -U postgres -d trueque_u -f base_de_datos/datos.sql
```

O con pgAdmin: crea una base llamada `trueque_u`, abre su *Query Tool*, abre y ejecuta `base_de_datos/estructura.sql` y después `base_de_datos/datos.sql`.

### 2. Backend (queda escuchando en `http://localhost:3000`)

```bash
cd backend
Copy-Item .env.ejemplo .env
```

Abre `backend/.env` y escribe en `BD_CONTRASENA` la contraseña de tu PostgreSQL. Luego:

```bash
pnpm install
pnpm start
```

(En Linux/Mac, en vez de `Copy-Item` usa `cp .env.ejemplo .env`.)

### Alternativa: base de datos en línea (Neon)

En vez de instalar PostgreSQL en tu computador, puedes usar una base gratuita en la nube:

1. Crea una cuenta en [neon.com](https://neon.com) y un proyecto (elige la región **São Paulo**).
2. En su *SQL Editor*, pega y ejecuta `base_de_datos/estructura.sql` y después `base_de_datos/datos.sql`.
3. Copia la *connection string* del proyecto y pégala en `backend/.env` como `BD_URL=...` (ver `.env.ejemplo`).
4. Inicia el backend igual que antes (`pnpm install` y `pnpm start`).

Si `BD_URL` está escrita, los datos `BD_HOST`, `BD_PUERTO`, etc. se ignoran. El archivo `.env` no se sube a git, así la contraseña de la base queda solo en tu computador.

### 3. App Flutter en Chrome (otra terminal)

```bash
cd app
flutter pub get
flutter run -d chrome
```

## Usuarios de prueba

| Nombre | Correo | Contraseña |
|---|---|---|
| Eudenia Flores Veizaga | eudeniaflores@gmail.com | eude1234 |
| Job Contreras | contrerasjob123@gmail.com | contreras123 |
| Carlos Mamani | carlosmamani@ejemplo.com | carlos1234 |

## Rutas de la app

| Ruta | Tipo | Qué es |
|---|---|---|
| `/` | Pública | Inicio |
| `/iniciar-sesion` | Pública | Iniciar sesión |
| `/registro` | Pública | Crear cuenta |
| `/recuperar-contrasena` | Pública | Pedir una contraseña nueva por correo |
| `/perfil` | **Privada** | Muestra el nombre de la persona. Sin sesión redirige a `/iniciar-sesion` |
| `/cambiar-contrasena` | **Privada** | Cambiar contraseña con la sesión iniciada |

En Chrome las rutas llevan `#`, por ejemplo `http://localhost:PUERTO/#/perfil`.

## API

| Método y ruta | Función en el código | Para qué |
|---|---|---|
| `POST /api/usuarios` | `postUsuario` | Registro |
| `PUT /api/usuarios/contrasena` 🔒 | `putContrasena` | Cambiar contraseña |
| `POST /api/sesiones` | `postSesion` | Iniciar sesión |
| `GET /api/sesiones/actual` 🔒 | `getSesionActual` | Saber quién tiene la sesión abierta |
| `DELETE /api/sesiones/actual` 🔒 | `deleteSesion` | Cerrar sesión |
| `POST /api/recuperaciones` | `postRecuperacion` | Crear una contraseña nueva y enviarla al correo |

🔒 = exige sesión iniciada (cabecera `Authorization: Bearer <token>`).

## Recuperar contraseña por correo

El servidor crea una contraseña nueva, la guarda y la envía al correo de la persona. Con ella ya puede entrar; cambiarla es opcional.

Para que el correo salga de verdad, llena en `backend/.env`:

```
CORREO_USUARIO=tucorreo@gmail.com
CORREO_CLAVE=contraseña-de-aplicación-de-16-letras
```

(En Google: Cuenta > Seguridad > Verificación en dos pasos > Contraseñas de aplicaciones.) Si lo dejas vacío, la contraseña nueva aparece en la consola del backend.

## Pruebas

Backend:

```bash
cd backend
npm test
```

E2E (con Docker abierto, cada comando en otra terminal):

```bash
docker compose up -d
node app/integration_test/herramientas/entorno_e2e.js
msedgedriver --port=4445
node app/integration_test/herramientas/puente_edge.js
```

Después, desde `app`, corre un archivo de pruebas:

```bash
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/acceso_test.dart -d web-server --browser-name=chrome --chrome-binary="C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe" --headless
```

Al terminar, apaga todo (ojo: cierra todos los procesos de Node):

```bash
taskkill /IM node.exe /F
taskkill /IM msedgedriver.exe /F
```

## Estructura

```
base_de_datos/   estructura.sql (tablas) y datos.sql (3 usuarios de prueba)
backend/src/
  servidor.js       Arranque: comprueba la base y levanta el puerto
  aplicacion.js     Configura Express: cors, json, rutas, errores
  configuracion/    Puerto, clave JWT y datos de la base (.env)
  rutas/            Qué URL existe y a qué controlador va
  controladores/    Lógica de cada endpoint (postUsuario, getSesionActual...)
  modelos/          Consultas SQL de cada tabla
  middleware/       exigirSesion y manejo de errores
  servicios/        Cifrado de contraseñas y tokens
  utilidades/       Validaciones y ayudas pequeñas
  bd/               Conexión a PostgreSQL
app/lib/
  main.dart         Arranque: restaura la sesión y monta la app
  rutas.dart        Rutas y redirección pública/privada
  estado/           Sesión de la persona
  servicios/        Cliente HTTP
  pantallas/        Una pantalla por archivo
  componentes/      Campos y botones compartidos
docs/            Documentación de la tarea
```
