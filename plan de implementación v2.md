# 📋 Plan de Implementación Mejorado: `flashcards_estudio`
**Stack:** Flutter + Dart | Firebase (Auth, Firestore, Storage) | Provider | VS Code  
**Plataformas:** Android, iOS, Web, Windows  
**Formato:** Markdown | **Código:** ❌ Ninguno incluido  
**Enfoque:** Arquitectura escalable, separación de responsabilidades, SM-2 nativo, rutas nombradas centralizadas.

---

## 🎯 1. Visión y Alcance (MVP)
| Alcance | Detalle |
|---------|---------|
| **Core** | Autenticación segura, CRUD de Mazos/Flashcards, motor SM-2, seguimiento de progreso |
| **UI/UX** | Tema oscuro profesional, paleta gris/naranja, tipografía limpia, responsive multiplataforma |
| **Datos** | Firestore con colecciones relacionales lógicas, reglas de seguridad por usuario, historial inmutable |
| **Estado** | Provider con `ChangeNotifier` segmentados por dominio, inmutabilidad en UI, carga perezosa |
| **Futuro (Post-MVP)** | Sincronización offline, importación CSV, mazos comunitarios, notificaciones push, métricas avanzadas |

---

## 🛠️ 2. Herramientas y Configuración Multiplataforma
| Categoría | Herramienta | Propósito |
|-----------|-------------|-----------|
| SDK | Flutter 3.24+ | Soporte estable para Android, iOS, Web y Windows |
| IDE | VS Code + Extensiones (`Flutter`, `Dart`, `Error Lens`, `Firebase`) | Desarrollo, depuración, linting, gestión de paquetes |
| CLI | `flutter`, `firebase`, `winget` (Win) / `brew` (Mac) | Scaffolding, emulación, despliegue, gestión de entornos |
| Emuladores | Android Emulator, iOS Simulator, Chrome, Windows Desktop | Pruebas nativas por plataforma |
| Profiling | Flutter DevTools, Firebase Performance Monitoring | Optimización de renders, red y memoria |
| Versionado | Git + Conventional Commits + Branching (`feature/*`, `release/*`) | Trazabilidad y CI/CD futuro |

> 📌 **Nota Windows:** Habilitar soporte desktop requiere `flutter config --enable-windows-desktop` y tener las Build Tools de Visual Studio 2022 instaladas con el workload "C++ desktop development".

---

## 🎨 3. Guía UI/UX y Tema Visual
| Elemento | Especificación |
|----------|----------------|
| **Fondo** | Gris oscuro profundo (`#121212` o `#0F0F0F`) para reducir fatiga visual |
| **Superficies/Tarjetas** | Gris medio-oscuro (`#1E1E1E` a `#242424`) con elevación sutil (sombras suaves o bordes 1px) |
| **Texto Principal** | Blanco puro (`#FFFFFF`) para títulos, gris claro (`#E0E0E0`) para cuerpo |
| **Acentos/Interactivos** | Naranja vibrante (`#FF7A00` a `#FF6600`) en botones, enlaces, estados activos y progreso |
| **Tipografía** | `Inter` o `Roboto` (sans-serif, alta legibilidad), escalas `12/14/16/18/24/32` |
| **Principios** | Espaciado 8pt grid, alto contraste WCAG AA, microinteracciones en volteo de tarjetas, loaders contextuales, feedback táctil/visual en calificaciones |

---

## 🗺️ 4. Arquitectura de la Aplicación & Estructura de Carpetas
Se adopta una arquitectura **Feature-First + Core/Shared**, priorizando la escalabilidad y el aislamiento de dominios.

```
lib/
├── main.dart                 # Punto de entrada, configuración de rutas nombradas, MultiProvider
├── core/
│   ├── routing/              # Definición de rutas, middleware de auth, nombres centralizados
│   ├── theme/                # ThemeData oscuro, paleta, tipografía, componentes base
│   ├── constants/            # Strings, keys, límites, timeouts
│   ├── utils/                # Formateadores, validadores, helpers de fecha/SNTP
│   └── errors/               # Excepciones personalizadas, manejo global de errores
├── features/
│   ├── auth/                 # Pantallas login/registro, AuthNotifier, formularios
│   ├── decks/                # Lista, creación, edición, filtros, DeckNotifier
│   ├── cards/                # CRUD flashcards, editor de contenido, CardNotifier
│   ├── study/                # Motor SM-2, sesión de estudio, StudyNotifier
│   ├── stats/                # Progreso, historial, gráficos, StatsNotifier
│   └── categories/           # Jerarquía de categorías, CategoryNotifier
├── shared/
│   ├── models/               # Entidades Dart inmutables (fromJson/toJson)
│   ├── repositories/         # Abstracción de acceso a Firestore/Auth
│   ├── services/             # Lógica pura (SM-2, validación, cálculo de intervalos)
│   └── widgets/              # Componentes reutilizables (InputField, PrimaryButton, FlashcardView, Loader)
```

---

## 📍 5. Estrategia de Navegación (Rutas Nombradas)
- Todas las rutas se declararán como **constantes string** en un archivo central (`core/routing/app_routes.dart`).
- El mapa de rutas (`RouteTable`) se inicializará y configurará **directamente desde `main.dart`**, cumpliendo el requisito explícito.
- Se implementará un **middleware de protección** que intercepte rutas protegidas (`/dashboard`, `/study`, etc.) y redirija a `/login` si no hay sesión activa.
- Se usarán `onGenerateRoute` o `onUnknownRoute` para manejar 404 y deep linking futuro.
- Cada pantalla recibirá parámetros tipados mediante `RouteSettings.arguments` para evitar acoplamiento.

---

## 📊 6. Modelo de Datos & Firestore (Optimizado)
> ⚠️ **Nota de Seguridad Arquitectónica:** El campo `contraseña` **nunca** se almacenará en Firestore. Firebase Authentication gestiona el hash seguro. En `Usuario` solo se guardará `uid` (clave primaria), referenciada desde Auth.

| Colección | Campos Clave | Relaciones & Índices |
|-----------|--------------|----------------------|
| `usuarios` | `uid`, `nombre`, `email`, `fecha_registro`, `configuracion` (map) | Índice compuesto: `email` (único). `uid` como PK. |
| `mazos` | `id`, `id_usuario`, `nombre`, `descripcion`, `id_categoria`, `fecha_creacion`, `es_publico` | Índice: `id_usuario` + `fecha_creacion` (desc). Filtro por `es_publico`. |
| `flashcards` | `id`, `id_mazo`, `frente`, `reverso`, `pista`, `url_img_frente`, `url_img_reverso`, `fecha_creacion` | Índice: `id_mazo`. Subcolección opcional si se requiere aislamiento estricto. |
| `categorias` | `id`, `nombre`, `descripcion`, `id_padre` (nullable) | Auto-referencia para jerarquías. Índice: `id_padre`. |
| `sesiones_estudio` | `id`, `id_usuario`, `id_mazo`, `fecha_inicio`, `fecha_fin`, `total_vistas` | Índice: `id_usuario` + `fecha_inicio`. |
| `revisiones_tarjeta` | `id`, `id_sesion`, `id_flashcard`, `calificacion`, `tiempo_respuesta_ms` | **Inmutable**. Índice: `id_sesion`, `id_flashcard`. Append-only. |
| `progreso_tarjeta` | `id`, `id_usuario`, `id_flashcard`, `nivel_dominio`, `fecha_ultima_revision`, `fecha_proxima_revision`, `intervalo_dias`, `factor_facilidad` | **Mutable (SM-2)**. Índice compuesto: `id_usuario` + `fecha_proxima_revision`. |
| `estadisticas_mazo` *(opcional)* | `id_mazo`, `id_usuario`, `porcentaje_dominio`, `racha_dias`, `ultima_sesion` | Agregado calculado o actualizado por triggers/lotes. |

**Reglas de Seguridad (Concepto):**
- Solo el `request.auth.uid` coincide con `id_usuario` puede leer/escribir sus datos.
- `es_publico: true` permite lectura anónica limitada.
- `revisiones_tarjeta` solo permite `create` y `read`. `update/delete` denegados.
- `progreso_tarjeta` permite `read/write` solo si el usuario es dueño.

---

## 🧠 7. Motor SM-2 & Gestión de Estado (Provider)
### Flujo Lógico SM-2
1. Al iniciar sesión de estudio, se consultan tarjetas de `progreso_tarjeta` donde `fecha_proxima_revision <= hoy`.
2. Se cargan las flashcards correspondientes.
3. Usuario responde → se mide `tiempo_respuesta_ms` y se selecciona calificación (1–5).
4. **Servicio SM-2 (puro)** calcula:
   - Nuevo `intervalo_días` según fórmula estándar (ajuste por `factor_facilidad` y calificación).
   - Actualización de `factor_facilidad` (disminuye si calificación < 3, aumenta si ≥ 4).
   - `fecha_proxima_revision` = hoy + `intervalo_días`.
   - `nivel_dominio` se escala (0–100) según historial.
5. Se escribe registro inmutable en `revisiones_tarjeta`.
6. Se actualiza estado en `progreso_tarjeta` y se notifica a `StudyNotifier`.
7. Al finalizar sesión, se cierra `sesiones_estudio` y se actualizan métricas.

### Provider Architecture
- `AuthProvider`: Gestiona sesión, persistencia local básica, redirección.
- `DeckProvider`: Lista, filtros, creación, publicación.
- `CardProvider`: CRUD de tarjetas, manejo de imágenes (Firebase Storage).
- `StudyProvider`: Estado de la sesión actual, cola de tarjetas, cálculos SM-2, progreso en tiempo real.
- `StatsProvider`: Agregaciones, historial, gráficos.
- Se usarán `MultiProvider` en `main.dart`, con `ChangeNotifierProvider` por dominio y `Consumer` localizado para evitar rebuilds globales.

---

## 📋 8. Plan de Implementación Paso a Paso (8 Fases)

### 🔹 Fase 1: Setup Multiplataforma & Estructura Base
1. Crear proyecto con `flutter create flashcards_estudio --platforms android,ios,web,windows`
2. Configurar `pubspec.yaml` con dependencias base (Provider, Firebase core/auth/firestore, intl, path_provider, cached_network_image)
3. Implementar estructura de carpetas según arquitectura definida
4. Configurar `main.dart` con `MultiProvider` vacío y esqueleto de `MaterialApp`
5. Validar compilación en las 4 plataformas objetivo

### 🔹 Fase 2: Tema Visual, Componentes UI & Rutas Nombradas
1. Definir `AppTheme` oscuro con paleta gris/naranja y tipografía
2. Crear archivo de constantes de rutas (`app_routes.dart`)
3. Implementar mapa de rutas en `main.dart` con `onGenerateRoute` y middleware de auth
4. Desarrollar widgets base reutilizables (`PrimaryButton`, `DarkTextField`, `Loader`, `ErrorBanner`)
5. Construir pantallas estáticas de Login y Registro con validación visual (sin lógica backend aún)

### 🔹 Fase 3: Firebase Auth & Protección de Rutas
1. Configurar proyecto Firebase, habilitar Email/Password, vincular plataformas
2. Implementar `AuthRepository` y `AuthProvider` (registro, login, logout, reset password)
3. Conectar formularios de Login/Registro con Provider
4. Implementar interceptor de rutas: si no hay sesión → redirigir a `/login`
5. Gestionar estados de carga, errores específicos de Firebase y persistencia de sesión

### 🔹 Fase 4: Modelos de Datos & Capa de Repositorios
1. Definir clases Dart inmutables para todas las entidades (`Usuario`, `Mazo`, `Flashcard`, etc.)
2. Implementar `fromJson`/`toJson` y validación de campos
3. Crear `FirestoreRepository` abstracto con métodos genéricos (CRUD, paginación, filtros)
4. Implementar repositorios concretos por dominio (`DeckRepository`, `CardRepository`, `ProgressRepository`)
5. Configurar índices y estructura de colecciones en Firestore Console

### 🔹 Fase 5: Reglas de Seguridad & Integración Firestore
1. Definir y desplegar reglas de seguridad alineadas al modelo de datos
2. Implementar listeners en tiempo real para listas de mazos y categorías
3. Configurar subcolecciones o documentos raíz según optimización de consultas
4. Integrar Firebase Storage para manejo de imágenes de flashcards
5. Validar flujos de creación/edición con estados de carga y rollback en error

### 🔹 Fase 6: Motor SM-2 & Lógica de Estudio
1. Desarrollar `SM2Engine` como servicio puro (sin dependencias de UI o Firebase)
2. Implementar cálculo de intervalos, factor de facilidad y fecha próxima revisión
3. Crear `StudySessionManager` que ordee la cola de tarjetas a repasar
4. Conectar `StudyProvider` con el motor y los repositorios
5. Implementar registro inmutable de `revisiones_tarjeta` y actualización de `progreso_tarjeta`

### 🔹 Fase 7: Pantallas de Estudio, Estadísticas & Optimización
1. Construir interfaz de modo estudio: volteo de tarjeta, botones de calificación, timer, barra de progreso
2. Implementar pantalla de resultados post-sesión y visualización de racha/dominio
3. Conectar todas las vistas con sus Providers respectivos
4. Optimizar renders: `const` widgets, `ValueListenableBuilder` donde aplique, lazy loading de listas
5. Ajustar responsive layout para tablet y Windows desktop (grid adaptativo, navegación lateral)

### 🔹 Fase 8: Pruebas, Seguridad & Preparación de Despliegue
1. **Unit Tests:** Motor SM-2, validadores, repositorios mockeados
2. **Widget Tests:** Formularios, navegación protegida, estados de carga/error
3. **Integration Tests:** Flujo completo auth → crear mazo → estudiar → registrar progreso
4. Auditoría de reglas de Firestore, sanitización de inputs, límites de tasa
5. Configurar builds firmados, metadatos de tienda, iconos, splash screen
6. Despliegue escalonado: Web (Firebase Hosting) → Android (Play Console) → iOS (App Store) → Windows (MSIX/Store)

---

## ✅ 9. Criterios de Aceptación por Fase
| Fase | Entregable Verificable |
|------|------------------------|
| 1 | Proyecto compila en 4 plataformas, estructura de carpetas válida, `pubspec` estable |
| 2 | Tema oscuro aplicado, rutas nombradas definidas en `main.dart`, componentes base funcionales |
| 3 | Auth funcional, protección de rutas activa, manejo de errores Firebase documentado |
| 4 | Modelos Dart serializables, repositorios implementados, contrato de datos validado |
| 5 | Reglas de seguridad desplegadas, listeners en tiempo real operativos, Storage integrado |
| 6 | Motor SM-2 probado unitariamente, flujo de estudio completo, historial inmutable registrado |
| 7 | Todas las pantallas construidas, navegación fluida, responsive multiplataforma, optimización de rebuilds |
| 8 | Cobertura de pruebas >70%, reglas auditadas, builds listos, documentación técnica actualizada |

---

## 📌 10. Próximos Pasos & Decisiones de Diseño
1. **Validar alcance MVP:** ¿Se incluyen categorías jerárquicas y etiquetas desde la v1.0 o se postergan?
2. **Confirmar estrategia de imágenes:** ¿URLs externas, Firebase Storage local, o base64 ligero para MVP?
3. **Definir umbral SM-2:** ¿Intervalo inicial en días? ¿Escala de calificación 1–4 o 1–5?
4. **Aprobar paleta exacta:** ¿Naranja `#FF7A00` o variante accesible para modo alto contraste?
5. Una vez aprobado este plan, se procederá a generar el código estructurado por fases, comenzando por `pubspec.yaml`, configuración de rutas en `main.dart`, tema visual y esqueleto de Providers.

¿Deseas ajustar algún parámetro del modelo de datos, modificar el alcance de la v1.0 o proceder directamente a la generación del código base?
