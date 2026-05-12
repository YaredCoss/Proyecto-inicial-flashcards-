# 📋 Plan de Implementación Mejorado: `flashcards_estudio`
**Stack:** Flutter (Dart) + Firebase (Auth + Firestore) | **State:** Provider | **Rutas:** Nombradas centralizadas en `main.dart` | **Plataformas:** Android, iOS, Web, Windows | **Restricciones:** ✅ Estándar | ❌ Opciones de producción en A | ❌ Analíticas/Telemetría

---

## 🛠️ 1. Entorno y Configuración Base
| Componente | Configuración |
|------------|---------------|
| **Flutter SDK** | Canal estable, multiplataforma habilitada (`android, ios, web, windows`) |
| **IDE** | VS Code (estándar) o Antigravity en modo desarrollo. **Se desactiva cualquier flag de producción, pre-compilación agresiva o modo release durante la fase de implementación** |
| **Firebase** | `firebase_core`, `firebase_auth`, `cloud_firestore` inicializados en modo desarrollo. **Se omiten explícitamente `firebase_analytics`, `firebase_crashlytics` y cualquier SDK de telemetría** |
| **Control de Versiones** | Git con ramas `main` (estable), `dev` (integración), `feature/*` (funcionalidades) |
| **Emuladores/Dispositivos** | Chrome (Web), Android Emulator, iOS Simulator, Windows Desktop |

---

## 📐 2. Arquitectura y Patrones
- **Arquitectura en Capas (Clean-ish):** 
  `Presentación (UI) → Gestión de Estado (Provider/ChangeNotifier) → Dominio (Lógica de Negocio/SM-2) → Datos (Repositorios) → Servicios (Firebase SDK)`
- **Gestión de Estado:** `provider` con `ChangeNotifier` segregados por dominio. Cada notifier expone solo el estado necesario a la UI y delega operaciones pesadas a repositorios.
- **Enrutamiento:** Tabla de rutas nombradas definida y expuesta desde `main.dart`. Protección de rutas basada en estado de autenticación.
- **Repositorios:** Interfaz clara que abstrae la fuente de datos. Implementaciones específicas para Firestore y caché local (si aplica).
- **Separación de Responsabilidades:** 
  - `Services` → Comunicación directa con Firebase SDKs
  - `Repositories` → Orquestación de datos, transformación de modelos, manejo de errores
  - `Providers` → Estado reactivo, coordinación con UI
  - `Domain/Logic` → Algoritmos puros (SM-2, validaciones, cálculos)

---

## 🎨 3. Identidad Visual y UX
- **Paleta de Colores:** 
  - Fondo principal y barras: Gris oscuro (`#1A1A1A` / `#2B2B2B`)
  - Tarjetas y texto principal: Blanco (`#FFFFFF`)
  - Acentos/interactivos: Naranja vibrante (`#FF6A00`)
- **Tipografía:** Fuente sans-serif limpia y legible (ej. `Inter` o `Roboto`), pesos regulares/medium para cuerpo, semi-bold para títulos.
- **Componentes UI:** 
  - Tarjetas con elevación sutil, bordes redondeados, alto contraste
  - Inputs con estados claros (focus, error, disabled)
  - Botones primarios en naranja, secundarios en gris medio
  - Feedback háptico/visual mínimo y contextual
- **Responsive:** Layout adaptativo para móvil (navegación inferior), tablet/web (navegación lateral), escritorio Windows (grid expandido).

---

## 🗄️ 4. Modelo de Datos y Lógica SM-2
### 🔹 Colecciones en Firestore (Mapeo exacto)
| Colección | Campos Clave | Notas Técnicas |
|-----------|--------------|----------------|
| `Usuario` | `id`, `nombre`, `email`, `fecha_registro`, `configuración` | `contraseña` se gestiona **exclusivamente** vía Firebase Auth. No se almacena en Firestore. |
| `Mazo` | `id`, `nombre`, `descripción`, `id_usuario`, `id_categoria`, `fecha_creación`, `es_público` | Indexación por `id_usuario` y `es_público`. |
| `Categoría` | `id`, `nombre`, `descripción`, `id_padre` | Auto-referenciada. Soporta jerarquías N-niveles. |
| `Flashcard` | `id`, `id_mazo`, `frente`, `reverso`, `pista`, `imagen_frente`, `imagen_reverso`, `fecha_creación` | Imágenes almacenadas en Firebase Storage (referencias en Firestore). |
| `Sesión_Estudio` | `id`, `id_usuario`, `id_mazo`, `fecha_inicio`, `fecha_fin`, `total_tarjetas_vistas` | Registro por bloque. |
| `Revisión_Tarjeta` | `id`, `id_sesión`, `id_flashcard`, `calificación` (1-5), `tiempo_respuesta_ms` | **Inmutable**. Solo operaciones de `add`. Historial de aprendizaje. |
| `Progreso_Tarjeta` | `id`, `id_usuario`, `id_flashcard`, `nivel_dominio`, `fecha_última_revisión`, `fecha_próxima_revisión`, `intervalo_días`, `factor_facilidad` | **Mutable**. Estado actual para SM-2. |
| `Etiqueta` + `Flashcard_Etiqueta` | `id`, `nombre` / `id_flashcard`, `id_etiqueta` | Relación M:N para clasificación cruzada. |
| `Estadística_Mazo` | `id_mazo`, `id_usuario`, `porcentaje_dominio`, `racha_días`, `última_sesión` | Agregación calculada post-sesión. |

### 🧠 Lógica SM-2
- Implementación en capa de **Dominio** (`SM2Engine` o similar). Pura Dart, sin dependencias de Firebase.
- Entradas: `calificación` (1-5), `intervalo_días`, `factor_facilidad`, `nivel_actual`.
- Salidas: Nuevo `intervalo_días`, `factor_facilidad` ajustado, `fecha_próxima_revisión`.
- Flujo: Usuario califica → `StudyProvider` invoca SM-2 → Actualiza `Progreso_Tarjeta` → Append `Revisión_Tarjeta` → Recalcula `Estadística_Mazo`.

---

## 📦 5. Dependencias Conceptuales (`pubspec.yaml`)
| Paquete | Propósito | Restricción |
|---------|-----------|-------------|
| `firebase_core` | Inicialización del ecosistema | `^3.x.x` |
| `firebase_auth` | Autenticación email/password | `^5.x.x` |
| `cloud_firestore` | Base de datos y sincronización | `^5.x.x` |
| `firebase_storage` *(opcional)* | Gestión de imágenes de tarjetas | `^12.x.x` |
| `provider` | Gestión de estado reactivo | `^6.x.x` |
| `go_router` o `Navigator` nativo | Rutas nombradas centralizadas | Elegir según preferencia, sin analíticas |
| `intl` | Formateo de fechas y localización | `^0.20.x` |
| `shared_preferences` | Preferencias de usuario y configuración | `^2.x.x` |
| `cached_network_image` | Caché de imágenes en tarjetas | `^3.x.x` |
| `uuid` | Generación de IDs estables offline/online | `^4.x.x` |
| **EXCLUIDOS EXPLÍCITAMENTE** | `firebase_analytics`, `firebase_crashlytics`, `sentry`, `mixpanel`, `amplitude` o cualquier SDK de telemetría | ❌ Prohibidos |

---

## 🗺️ 6. Plan de Implementación Paso a Paso

### 🔹 Fase 1: Configuración del Entorno y Proyecto
1. Instalar Flutter SDK, configurar `PATH`, ejecutar `flutter doctor`
2. Crear proyecto: `flutter create flashcards_estudio --platforms android,ios,web,windows`
3. Configurar VS Code con extensiones oficiales (Flutter, Dart, Error Lens, Pubspec Assist)
4. Inicializar repositorio Git, crear ramas base (`main`, `dev`)
5. Desactivar explícitamente cualquier configuración de producción en el IDE, flags de optimización avanzada o herramientas externas que generen telemetría

### 🔹 Fase 2: Identidad Visual y Componentes Base
1. Definir `ThemeData` en `core/theme/` con paleta gris oscuro/blanco/naranja
2. Crear sistema de tipografía, espaciado y constantes de diseño
3. Construir widgets reutilizables: `PrimaryButton`, `InputField`, `FlashcardContainer`, `LoaderOverlay`, `ErrorBanner`
4. Validar contraste WCAG AA y escalado de texto accesible
5. Ajustar layouts responsive para las 4 plataformas objetivo

### 🔹 Fase 3: Arquitectura, Enrutamiento y Firebase
1. Estructurar carpetas según modelo limpio (ver sección 7)
2. Definir tabla de rutas nombradas en `main.dart` (`AppRoutes.login`, `AppRoutes.register`, `AppRoutes.dashboard`, etc.)
3. Configurar `MultiProvider` en `main.dart` con placeholders por dominio
4. Inicializar Firebase (`firebase_core`, `firebase_auth`, `cloud_firestore`)
5. Configurar Firebase Console: Auth (email/password), Firestore (modo prueba inicial), Storage (si aplica)
6. Establecer reglas de seguridad iniciales por `uid` y `es_público`

### 🔹 Fase 4: Autenticación y Gestión de Sesión
1. Implementar servicios de Firebase Auth (registro, login, logout, reset password)
2. Crear `AuthNotifier` (ChangeNotifier) para exponer estado de autenticación
3. Construir pantallas de Login y Registro con validación en tiempo real
4. Conectar formularios con `AuthNotifier` y manejar estados (carga, éxito, errores específicos)
5. Implementar protección de rutas: si `!auth.isAuthenticated`, redirigir a `/login`
6. Validar flujo completo sin persistir contraseñas en Firestore

### 🔹 Fase 5: Modelo de Datos y Repositorios
1. Definir clases modelo en Dart para cada entidad (`Usuario`, `Mazo`, `Flashcard`, `Categoría`, etc.)
2. Implementar `Repository` interfaces y sus concreciones para Firestore
3. Configurar CRUD básico para `Mazo`, `Flashcard`, `Categoría`
4. Establecer índices compuestos y consultas optimizadas (listado por usuario, búsqueda por nombre/filtro)
5. Implementar manejo de imágenes: subida a Storage, almacenamiento de URL en Firestore, carga con caché

### 🔹 Fase 6: Entidades de Estudio y Algoritmo SM-2
1. Crear `SM2Engine` en capa de dominio (lógica pura, determinista, sin efectos secundarios)
2. Implementar `StudyService` para gestionar `Sesión_Estudio`, `Revisión_Tarjeta`, `Progreso_Tarjeta`
3. Configurar escritura append-only para `Revisión_Tarjeta` y actualización transaccional para `Progreso_Tarjeta`
4. Calcular métricas agregadas y actualizar `Estadística_Mazo` al cerrar sesión
5. Validar cálculos de intervalos, factores de facilidad y fechas de próxima revisión

### 🔹 Fase 7: Integración con Provider y State Management
1. Implementar `DeckProvider`, `StudyProvider`, `CategoryProvider`, `TagProvider`
2. Conectar repositorios con notifiers, exponer streams de carga, datos y errores
3. Optimizar `notifyListeners()`: usar `select` o `Consumer` granular para evitar rebuilds innecesarios
4. Implementar lógica de filtrado, búsqueda y ordenación en memoria antes de renderizar
5. Asegurar separación estricta: UI solo consume estado, no invoca servicios directamente

### 🔹 Fase 8: Vistas, Navegación y Modo Estudio
1. Construir pantallas completas: Dashboard, Editor de Mazo, Editor de Flashcard, Modo Estudio, Historial, Configuración
2. Implementar navegación nombrada desde `main.dart` con parámetros seguros (`deckId`, `cardId`, etc.)
3. Diseñar flujo de estudio: selección de mazo → carga de progreso SM-2 → volteo de tarjeta → calificación → siguiente
4. Añadir feedback visual/háptico, barra de progreso, marcadores de dificultad
5. Ajustar layouts para Windows/Desktop y Web (teclado, mouse, hover states)

### 🔹 Fase 9: Optimización, Pruebas y Preparación Final
1. Pruebas unitarias: `SM2Engine`, validaciones, repositorios (mock Firestore)
2. Pruebas de widgets: formularios, estados de carga/error, navegación protegida
3. Pruebas de integración: flujo completo auth → crear mazo → estudiar → guardar progreso
4. Perfilado con Flutter DevTools: evitar memory leaks, optimizar listados, lazy loading de imágenes
5. Revisión de reglas de Firestore, sanitización de inputs, límites de tasa
6. Generar builds de desarrollo estándar para las 4 plataformas. **Sin flags de producción, sin analíticas, sin telemetría**
7. Documentar arquitectura, decisiones técnicas y guía de despliegue

---

## 📁 7. Estructura de Carpetas (Alineada al Plan)
```
lib/
├── core/
│   ├── routes/          # Tabla de rutas nombradas (exportada a main.dart)
│   ├── theme/           # Paleta, tipografía, constantes de diseño
│   ├── utils/           # Helpers, formateadores, validadores
│   └── errors/          # Clases de error personalizadas, mapeo Firebase
├── features/
│   ├── auth/            # UI, AuthNotifier, AuthService
│   ├── decks/           # UI, DeckNotifier, DeckRepository
│   ├── study/           # UI, StudyNotifier, StudyService, SM2Engine
│   ├── categories/      # UI, CategoryNotifier, CategoryRepository
│   ├── tags/            # UI, TagNotifier, TagRepository
│   └── stats/           # UI, StatsNotifier, StatsService
├── shared/
│   ├── models/          # Entidades DTO/Domain (Usuario, Mazo, Flashcard, etc.)
│   ├── widgets/         # Componentes reutilizables
│   ├── repositories/    # Interfaces genéricas, contratos de datos
│   └── services/        # Abstracciones de Firebase SDK, Storage, LocalPrefs
└── main.dart            # Punto de entrada, MultiProvider, MaterialApp, NamedRoutes
```

---

## 🔒 8. Seguridad, Privacidad y Restricciones
- **Sin Analíticas/Telemetría:** Se excluyen explícitamente todos los SDKs de tracking. No se envían eventos, errores ni métricas a terceros.
- **Sin Opciones de Producción en A:** Se mantiene configuración estándar de desarrollo. No se activan flags de optimización agresiva, minificación extrema o precompilación avanzada del IDE hasta validación completa.
- **Reglas de Firestore:** 
  - Lectura/escritura estricta por `request.auth.uid == resource.data.id_usuario`
  - Mazos públicos: lectura permitida para usuarios autenticados, escritura solo al creador
  - `Revisión_Tarjeta`: solo `create` (append-only), sin `update`/`delete`
- **Almacenamiento Local:** Solo configuración de usuario y preferencias de UI. Sin caché de datos sensibles.

---

## ✅ Validación y Próximos Pasos
| Criterio | Estado en Plan |
|----------|----------------|
| Multiplataforma (Android/Web/Windows/iOS) | ✅ Configurado y validado en Fase 1/8 |
| Provider + Separación de responsabilidades | ✅ Arquitectura en capas y Notifiers por dominio |
| Rutas nombradas en `main.dart` | ✅ Centralizadas en `core/routes/` e inyectadas en `main.dart` |
| Paleta gris oscuro/blanco/naranja + UI sobria | ✅ Definida en Fase 2 |
| Entidades exactas + relaciones jerárquicas | ✅ Mapeo completo en Fase 5 |
| SM-2 (Progreso mutable vs Revisión inmutable) | ✅ Separación lógica clara en Fase 6 |
| Sin producción en A, sin analíticas/telemetría | ✅ Restricción explícita y aplicada en todo el ciclo |

📌 **Siguiente paso recomendado:** 
1. Confirmar aprobación de este plan estructurado.
2. Validar si se desea añadir soporte offline básico (Hive/Isar) o mantener solo Firebase sincronizado.
3. Una vez validado, procederé a generar el código fase por fase, iniciando con `pubspec.yaml`, configuración de rutas nombradas en `main.dart`, tema visual, y estructura base de Provider sin lógica de negocio aún.

¿Deseas ajustar algún punto del modelo, priorizar una fase específica o autorizar el inicio de la generación de código?


## Prompt 

Por supuesto. Aquí tienes el prompt final completamente mejorado, con los elementos solicitados al inicio y la mención explícita del provider, manteniendo el formato elegante por párrafos y los títulos con almohadillas (#).

---

## Antigravity
## Flutter para Android / web / Windows / iOS
## Usar estándar, no utilizar la opción de producción en A, no utilizar analíticas

# 🐱 Actuación como ingeniero de software

Actúa como un ingeniero de software especializado en desarrollo multiplataforma. Deseo construir una aplicación robusta y escalable utilizando Flutter (con Dart) como framework frontend y Firebase como backend. La aplicación debe ser compatible con Android, web, Windows e iOS, y su gestión de navegación deberá implementarse mediante rutas nombradas definidas desde el archivo `main.dart`, asegurando una arquitectura clara y mantenible.

Se utilizará **Provider** como solución de gestión de estado, aplicando buenas prácticas de separación de responsabilidades (patrón repositorio, servicios y notifiers). No se empleará la opción de producción en A, y queda estrictamente prohibida la inclusión de analíticas o telemetría de ningún tipo.

# 🎨 Identidad visual y primeras pantallas

La interfaz de usuario incluirá inicialmente una pantalla de autenticación (login) y otra de registro. El lenguaje visual deberá apoyarse en una paleta de colores sobria y contemporánea: fondo y barras en gris oscuro, tarjetas y texto principal en blanco, y acentos (botones, elementos interactivos) en naranja vibrante. Se valorará una tipografía limpia, una disposición elegante y un diseño cuidado que transmita profesionalismo y confianza.

# 🗃️ Estructura de datos: entidades core

La lógica de datos se estructurará en torno a las siguientes tablas (colecciones en Firestore), organizadas por dominios funcionales:

- `Usuario`: almacena la información base del usuario (`id`, `nombre`, `email`, `contraseña`, `fecha_registro`, `configuración`).  
- `Mazo` (Deck): representa colecciones temáticas de tarjetas (`id`, `nombre`, `descripción`, `id_usuario`, `id_categoria`, `fecha_creación`, `es_público`).  
- `Flashcard`: cada tarjeta de estudio (`id`, `id_mazo`, `frente` (pregunta), `reverso` (respuesta), `pista`, `imagen_frente`, `imagen_reverso`, `fecha_creación`).  
- `Categoría`: estructura jerarquizable para organizar mazos (`id`, `nombre`, `descripción`, `id_padre` — permite subcategorías).

# 📚 Entidades de estudio y algoritmo SM-2

- `Sesión_Estudio`: registra cada bloque de estudio (`id`, `id_usuario`, `id_mazo`, `fecha_inicio`, `fecha_fin`, `total_tarjetas_vistas`).  
- `Revisión_Tarjeta`: historial inmutable de cada interacción con una tarjeta durante una sesión (`id`, `id_sesión`, `id_flashcard`, `calificación` (1–5 o Bien/Mal), `tiempo_respuesta_ms`).  
- `Progreso_Tarjeta`: estado acumulado por usuario y tarjeta (`id`, `id_usuario`, `id_flashcard`, `nivel_dominio`, `fecha_última_revisión`, `fecha_próxima_revisión`, `intervalo_días`, `factor_facilidad`). Esta entidad implementa el algoritmo de repetición espaciada SM-2.

# 🧩 Entidades auxiliares (opcionales pero recomendadas)

- `Etiqueta` (`id`, `nombre`) y tabla pivote `Flashcard_Etiqueta` (`id_flashcard`, `id_etiqueta`) para clasificación flexible M:N.  
- `Estadística_Mazo`: métricas consolidadas por mazo y usuario (`id_mazo`, `id_usuario`, `porcentaje_dominio`, `racha_días`, `última_sesión`).

# 🔗 Diagrama de relaciones clave

```
Usuario ──< Mazo >── Categoría
           │
           └──< Flashcard >──< Revisión_Tarjeta >── Sesión_Estudio
                    │
                    └── Progreso_Tarjeta (por usuario)
```

# 📌 Puntos de diseño importantes

- Diferenciar claramente `Revisión_Tarjeta` (historial inmutable) de `Progreso_Tarjeta` (estado mutable), siendo esta última fundamental para la lógica SM-2.  
- Los mazos pueden ser públicos o privados, lo que permitirá en el futuro funcionalidades de compartir o clonar contenido.  
- La tabla `Categoría` es auto-referenciada para sustentar jerarquías complejas (ej. Idiomas → Inglés → Vocabulario).  
- El campo `factor_facilidad` en `Progreso_Tarjeta` es neurálgico para el algoritmo SM-2, ya que ajusta dinámicamente los intervalos de repaso según el desempeño histórico.  
- La gestión del estado se apoyará en **Provider**, distribuyendo lógica en ChangeNotifier separados por dominio (AuthProvider, DeckProvider, StudyProvider, etc.).

# 🚀 Solicitud final

Por favor, genera la estructura inicial del proyecto Flutter (carpetas, pantallas, servicios, modelos y providers) que refleje fielmente este diseño, priorizando buenas prácticas, separación de responsabilidades y escalabilidad futura, sin incluir opciones de producción en A ni analíticas de ningún tipo.
