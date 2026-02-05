# 🎓 GCcabo - Quiz de Ascenso a Cabo

Una aplicación móvil Flutter para prepararse en el examen de ascenso a **Cabo de la Guardia Civil**. Esta aplicación ofrece un sistema completo de cuestionarios interactivos con 17 temas especializados, seguimiento de progreso y análisis de errores.

## 📋 Tabla de Contenidos

- [Características](#características)
- [Requisitos previos](#requisitos-previos)
- [Instalación](#instalación)
- [Configuración de Firebase](#configuración-de-firebase)
- [Estructura del Proyecto](#estructura-del-proyecto)
- [Uso](#uso)
- [Tecnologías](#tecnologías)
- [Funcionalidades Detalladas](#funcionalidades-detalladas)
- [Contribuyentes](#contribuyentes)

## ✨ Características

### 🎯 Principales

- ✅ **17 Temas especializados** sobre legislación, derecho y procedimientos de la Guardia Civil
- ✅ **Sistema de autenticación** con Firebase (registro e inicio de sesión)
- ✅ **Exámenes personalizables** (aleatorios, por tema, por número de preguntas)
- ✅ **Examen de errores cometidos** - Practica solo con las preguntas que fallaste
- ✅ **Generación de PDFs** para estudiar sin conexión
- ✅ **Historial de resultados** con estadísticas detalladas
- ✅ **Tema oscuro/claro** personalizables
- ✅ **Seguimiento de progreso** en Firebase
- ✅ **Interfaz moderna** con gradientes y animaciones

### 📊 Análisis y Reportes

- Puntuación por examen
- Tiempo invertido en cada test
- Porcentaje de aciertos
- Preguntas incorrectas registradas
- Gráficos de rendimiento
- Historial completo de intentos

## 🛠️ Requisitos Previos

- **Flutter SDK**: 3.0.0 o superior
- **Dart SDK**: 3.0.0 o superior
- **Android Studio** (para emulador Android) o **Xcode** (para iOS)
- **Cuenta de Firebase** (gratuita)
- **Git** para clonar el repositorio

## 📥 Instalación

### 1. Clonar el repositorio

```bash
git clone <tu-repositorio-url>
cd GCcabo
```

### 2. Instalar dependencias

```bash
flutter pub get
```

### 3. Limpiar y preparar la aplicación

```bash
flutter clean
flutter pub get
```

### 4. Ejecutar en emulador o dispositivo

```bash
# Ver dispositivos disponibles
flutter devices

# Ejecutar en emulador
flutter run

# Ejecutar en release
flutter run --release
```

## 🔥 Configuración de Firebase

### Paso 1: Crear proyecto en Firebase Console

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Crea un nuevo proyecto
3. Habilita **Authentication** > Email/Password
4. Habilita **Firestore Database**

### Paso 2: Configurar reglas de Firestore

```firestore
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /resultados/{document=**} {
      allow read, write: if request.auth.uid == resource.data.userId;
      allow create: if request.auth.uid == request.resource.data.userId;
    }
  }
}
```

### Paso 3: Configurar para Android

1. Descarga `google-services.json` desde Firebase Console
2. Colócalo en `android/app/`

### Paso 4: Configurar para iOS

1. Descarga `GoogleService-Info.plist` desde Firebase Console
2. Agrégalo al proyecto Xcode en `ios/Runner/`

### Paso 5: Ejecutar FlutterFire CLI (opcional pero recomendado)

```bash
flutter pub global activate flutterfire_cli
flutterfire configure --project=tu-proyecto-firebase
```

## 📁 Estructura del Proyecto

```
lib/
├── main.dart                    # Punto de entrada
├── auth/
│   ├── login_screen.dart       # Pantalla de inicio de sesión
│   └── register_screen.dart    # Pantalla de registro
├── home_screen.dart            # Pantalla principal con temas
├── quiz_screen.dart            # Pantalla del cuestionario
├── results_screen.dart         # Pantalla de resultados
├── results_list_screen.dart    # Historial de resultados
├── settings_screen.dart        # Configuración
├── splash_screen.dart          # Pantalla de carga
├── theme_provider.dart         # Gestor de tema
└── firebase_options.dart       # Configuración de Firebase

assets/
├── Tema 1-17/                  # Archivos JSON de preguntas
└── fonts/                      # Fuentes personalizadas
```

## 🚀 Uso

### Flujo principal de la aplicación

1. **Splash Screen** → Carga inicial
2. **Login/Register** → Autenticación con Firebase
3. **Home Screen** → Selección de exámenes
   - Examen Aleatorio (50 o 100 preguntas)
   - Examen de Errores Cometidos
   - Temas específicos (17 opciones)
   - Generador de PDFs
4. **Quiz Screen** → Responder preguntas
5. **Results Screen** → Ver puntuación y guardar en Firebase
6. **History** → Consultar histórico de resultados

### Pantallazo de navegación

```
┌─────────────────────┐
│   SPLASH SCREEN     │
└──────────┬──────────┘
           ↓
┌─────────────────────┐
│  LOGIN / REGISTER   │
└──────────┬──────────┘
           ↓
┌─────────────────────┐
│   HOME SCREEN       │
│ - Examen Aleatorio  │
│ - Errores           │
│ - 17 Temas          │
│ - PDF               │
└──────────┬──────────┘
           ↓
┌─────────────────────┐
│   QUIZ SCREEN       │
│ - Preguntas         │
│ - Temporizador      │
└──────────┬──────────┘
           ↓
┌─────────────────────┐
│  RESULTS SCREEN     │
│ - Puntuación        │
│ - Análisis          │
└─────────────────────┘
```

## 💻 Tecnologías

### Framework & Lenguaje
- **Flutter**: 3.0.0+
- **Dart**: 3.0.0+

### Dependencias principales

| Paquete | Versión | Uso |
|---------|---------|-----|
| firebase_core | ^2.31.0 | Inicialización de Firebase |
| firebase_auth | ^4.19.0 | Autenticación |
| cloud_firestore | ^4.17.0 | Base de datos |
| shared_preferences | ^2.2.3 | Almacenamiento local |
| provider | ^6.1.2 | Gestor de estado |
| pdf | ^3.10.7 | Generación de PDFs |
| printing | ^5.13.0 | Impresión y compartir PDFs |
| fl_chart | ^0.66.2 | Gráficos de estadísticas |
| intl | ^0.18.1 | Internacionalización |

## 🎯 Funcionalidades Detalladas

### 1. **Sistema de Autenticación**
- Registro con email y contraseña
- Validación de email (debe estar verificado para guardar resultados)
- Recuperación de contraseña
- Seguridad con Firebase Authentication
- Limpieza de espacios y normalización de emails

### 2. **Cuestionarios Interactivos**
- Preguntas con múltiple opción
- Retroalimentación inmediata (correcto/incorrecto)
- Mostrar respuesta correcta si fallas
- Citas/referencias legales para cada pregunta
- Temporizador de examen
- Navegación entre preguntas

### 3. **Examen de Errores Cometidos**
- Recopila todas las preguntas fallidas del usuario
- Crea un quiz dedicado solo a esos temas
- Perfecto para reforzar conocimientos débiles
- Mezcla aleatoria de preguntas

### 4. **Generador de PDFs**
- Selecciona tema o examen aleatorio
- Elige número de preguntas
- Genera PDF descargable
- Incluye preguntas, opciones y citas
- Compatible con compartir e imprimir

### 5. **Historial de Resultados**
- Guarda automáticamente resultados en Firebase
- Requiere email verificado
- Consultar intentos anteriores
- Mostrar puntuación, tiempo y análisis
- Filtrar por tema o fecha

### 6. **Configuración**
- Tema oscuro/claro
- Cambio de contraseña
- Verificación de email
- Cierre de sesión

## 📈 17 Temas Incluidos

1. **Estatuto del Personal de la Guardia Civil**
2. **Régimen Interior**
3. **Deontología Profesional**
4. **Derechos Humanos**
5. **Derecho Administrativo**
6. **Protección de la Seguridad Ciudadana**
7. **Derecho Fiscal**
8. **Armas, Explosivos y Cartuchería**
9. **Patrimonio Natural y Biodiversidad**
10. **Protección integralcontra la Violencia de Género**
11. **Derecho Penal**
12. **Poder Judicial**
13. **Ley de Enjuiciamiento Criminal**
14. **Igualdad Efectiva de Mujeres y Hombres**
15. **Protección Civil**
16. **Tecnologías de la Información y la Comunicación**
17. **Topografía**

## 🐛 Solución de Problemas

### Error de reCAPTCHA vacío
**Solución**: Asegurate de que tienes Google Play Services configurado:
```gradle
implementation("com.google.android.gms:play-services-auth:21.0.0")
```

### No se guardan resultados
- Verifica que el usuario tenga email verificado
- Comprueba las reglas de Firestore
- Asegúrate de estar autenticado en Firebase

### Emulador sin conexión a internet
```bash
adb emu avd name
emulator -avd <nombre> -dns-server 8.8.8.8,8.8.4.4
```

## 📱 Requisitos del Sistema

- **Android**: 5.0+ (API 24+)
- **iOS**: 11.0+
- **Memoria**: 50MB mínimo
- **Conexión**: Internet (para autenticación y guardar resultados)

## 👥 Contribuyentes

- Desarrollador: Alvaro García Moreau
- Diseño: Alvaro García Moreau

## 📄 Licencia

Este proyecto está bajo licencia privada. Todos los derechos reservados.

## 📞 Soporte

Para reportar bugs o sugerencias, contacta a través de:
- Email: alvarogarciamoreau@gmail.com
- Issues en el repositorio

---

**Última actualización**: Febrero 2026
**Versión**: 1.0.0
