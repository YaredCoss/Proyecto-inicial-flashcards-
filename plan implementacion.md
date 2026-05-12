# 📋 Plan de Implementación: `flashcards_estudio`
**Framework:** Flutter (Dart) | **Backend:** Firebase (Auth + Firestore) | **IDE:** VS Code | **Estado:** Provider | **Formato:** Markdown | **Código:** ❌ Ninguno incluido

---

## 🧰 1. Herramientas y Entorno de Desarrollo Requeridas
| Categoría | Herramienta | Propósito |
|-----------|-------------|-----------|
| SDK | Flutter SDK + Dart SDK | Compilación multiplataforma (Android, iOS, Web, Desktop) |
| IDE | Visual Studio Code | Edición, depuración, terminal integrada |
| Extensiones VS Code | `Flutter`, `Dart`, `Pubspec Assist`, `Error Lens`, `Firebase`, `GitLens` | Autocompletado, gestión de paquetes, diagnóstico, control de versiones |
| CLI | `flutter`, `dart`, `firebase`, `git` | Creación de proyectos, emulación, despliegue, versionado |
| Emuladores/Dispositivos | Android Emulator, iOS Simulator, Navegador, Chrome DevTools | Pruebas multiplataforma y profiling |
| Diseño UI/UX | Figma / Penpot | Wireframing, prototipado, sistema de diseño, exportación de assets |
| Control de Calidad | `flutter_test`, `mockito`, `patrol` (opcional) | Pruebas unitarias, de widgets y de integración |

> 📝 **Nota sobre Antigravity:** No es un IDE estándar para Flutter. Se recomienda VS Code o Android Studio como entornos principales. Si te refieres a otro editor, la configuración de Flutter/Dart es equivalente.

---

## 🎨 2. Guía UI/UX y Arquitectura de la App
### Flujo de Usuario
1. **Onboarding** → Explicación rápida de valor (3 pantallas)
2. **Autenticación** → Login / Registro / Recuperar contraseña
3. **Dashboard** → Lista de mazos, crear nuevo, buscar, estadísticas
4. **Editor de Mazo** → Añadir/editar/eliminar tarjetas, importar/exportar
5. **Modo Estudio** → Tarjetas con volteo, progreso, marcación de dificultad
6. **Resultados** → Resumen de sesión, recomendaciones, historial

### Principios de Diseño
- **Minimalista y enfocado:** Fondo neutro, alto contraste en texto, paleta limitada (1 primario, 1 secundario, escala de grises)
- **Accesibilidad:** Tamaño de texto adaptable, contraste WCAG AA, soporte para lectores de pantalla
- **Responsive:** Grid adaptable para móvil/tablet, navegación lateral en tablet/desktop
- **Microinteracciones:** Feedback háptico/visual al voltear tarjetas, loaders contextuales, transiciones suaves entre vistas

### Estructura de Carpetas (Propuesta)
```
lib/
├── core/          # Constantes, temas, utilidades, enrutamiento, errores
├── features/      # Autenticación, Dashboards, Mazos, Estudio, Estadísticas
├── shared/        # Widgets reutilizables, modelos base, servicios comunes
├── main.dart      # Punto de entrada, configuración global de Provider
```

---

## 📦 3. Dependencias Clave (Conceptual para `pubspec.yaml`)
| Paquete | Función |
|---------|---------|
| `firebase_core` | Inicialización del ecosistema Firebase |
| `firebase_auth` | Autenticación con email/contraseña, gestión de sesión |
| `cloud_firestore` | Base de datos NoSQL, sincronización en tiempo real, CRUD |
| `provider` | Gestión de estado, inyección de dependencias, notificación de cambios |
| `flutter_riverpod` *(opcional)* | Alternativa moderna si se migra en el futuro |
| `go_router` o `auto_route` | Enrutamiento declarativo y protección de rutas |
| `intl` | Formato de fechas, números, localización |
| `shared_preferences` o `hive` | Caché local ligero para preferencias de usuario |
| `flutter_localizations` | Soporte multilingüe (español por defecto) |
| `lottie` o `rive` *(opcional)* | Animaciones ligeras para onboarding/feedback |
| `image_picker` / `file_picker` *(opcional)* | Importación de imágenes o CSV a mazos |

> ✅ Todas se gestionarán mediante `flutter pub get` y se versionarán con restricciones semánticas estables.

---

## 🗺️ 4. Plan de Implementación Paso a Paso

### 🔹 Fase 1: Preparación del Entorno
1. Instalar Flutter SDK y configurar variables de entorno (`PATH`)
2. Instalar VS Code y añadir extensiones oficiales de Flutter/Dart
3. Verificar instalación: `flutter doctor`
4. Configurar emuladores Android/iOS y/o navegador web
5. Inicializar repositorio Git, definir ramas (`main`, `dev`, `feature/*`)
6. Crear estructura base del proyecto: `flutter create flashcards_estudio --platforms android,ios,web`

### 🔹 Fase 2: Configuración de Firebase
1. Crear proyecto en Firebase Console
2. Registrar cada plataforma (Android, iOS, Web) y descargar archivos de configuración
3. Colocar archivos en carpetas correspondientes (`android/app/`, `ios/Runner/`, `web/`)
4. Habilitar **Authentication** → Método Email/Password
5. Habilitar **Cloud Firestore** → Iniciar en modo prueba, definir reglas básicas por usuario
6. Configurar Firebase CLI local: `firebase login`, `firebase init` (si se usa emulación)
7. Verificar conexión inicial en la app (sin lógica aún)

### 🔹 Fase 3: Arquitectura y Gestión de Estado
1. Definir estructura de carpetas según guía UI/UX
2. Configurar `main.dart` con `MultiProvider` vacío (auth, decks, cards, uiState)
3. Crear clases base para `ChangeNotifier` (contratos de interfaz)
4. Implementar enrutamiento base con protección de rutas (solo usuarios autenticados acceden al dashboard)
5. Definir constantes globales: colores, tipografías, espaciado, strings de error

### 🔹 Fase 4: Autenticación (Login/Registro)
1. Diseñar formularios UI: email, contraseña, confirmación, toggle visibilidad
2. Implementar validación en tiempo real (formato, longitud, coincidencia)
3. Crear servicio de autenticación: registro, inicio de sesión, cierre, recuperación de contraseña
4. Conectar UI con `AuthNotifier` mediante Provider
5. Manejar estados: carga, éxito, errores específicos (Firebase exceptions)
6. Implementar persistencia de sesión y redirección automática al dashboard
7. Proteger rutas: si no hay usuario activo, redirigir a login

### 🔹 Fase 5: Modelo de Datos y Firestore
1. Definir colecciones:
   - `users/{uid}`: perfil, preferencias, fecha creación
   - `decks/{deckId}`: título, descripción, propietario, fecha, tags, contador de tarjetas
   - `cards/{cardId}`: frente, reverso, deckId, dificultad, última revisión, intervalo
   - `sessions/{sessionId}`: userId, deckId, fecha, aciertos, errores, duración
2. Establecer relaciones y restricciones de integridad (solo el propietario modifica/borra)
3. Implementar repositorios/servicios para CRUD asíncrono
4. Configurar listeners en tiempo real para listas de mazos y tarjetas
5. Definir reglas de seguridad en Firestore (lectura/escritura por `request.auth.uid`)

### 🔹 Fase 6: Integración de Estado con Provider
1. Crear `AuthNotifier`, `DecksNotifier`, `CardsNotifier`, `StudyNotifier`
2. Implementar métodos: `fetchDecks()`, `addDeck()`, `updateCard()`, `startSession()`, `endSession()`
3. Conectar notificaciones de cambio con `notifyListeners()`
4. Optimizar rebuilds: usar `Consumer` solo donde cambie el estado, evitar `Provider.of` innecesarios
5. Añadir manejo de errores centralizado y estados de carga por operación
6. Implementar caché local ligero para offline básico (opcional en esta fase)

### 🔹 Fase 7: Desarrollo de Vistas y Navegación
1. Implementar vistas principales:
   - Login / Registro / Recuperación
   - Dashboard (grid/lista de mazos, botón crear, búsqueda, filtros)
   - Editor de Mazo (formulario, lista de tarjetas, drag & drop básico)
   - Modo Estudio (tarjeta central, botones voltear/marcar, barra de progreso)
   - Resultados (gráfico simple, resumen, botón repetir/guardar)
2. Construir widgets reutilizables: `PrimaryButton`, `InputField`, `FlashcardWidget`, `LoaderOverlay`, `EmptyState`
3. Configurar transiciones y animaciones (volteo de tarjeta, fade entre vistas)
4. Ajustar layout responsive para tablet y escritorio
5. Conectar cada vista con sus respectivos `Provider` y servicios

### 🔹 Fase 8: Pruebas, Optimización y Despliegue
1. **Pruebas Unitarias:** Servicios de auth, repositorios Firestore, lógica de estudio
2. **Pruebas de Widgets:** Formularios, navegación, estados de carga/error, componentes UI
3. **Pruebas de Integración:** Flujo completo: registro → crear mazo → estudiar → guardar resultados
4. **Optimización:** 
   - Lazy loading de listas
   - Evitar rebuilds globales
   - Compresión de assets
   - Análisis con `flutter devtools`
5. **Seguridad:** Revisar reglas de Firestore, validar entradas, sanitizar datos, limitar tasa de peticiones
6. **Preparación para Tiendas:** Iconos adaptativos, splash screen, metadatos, versionado semántico, builds firmados
7. **Despliegue:** 
   - Web: Firebase Hosting
   - Android: Play Console (APK/AAB)
   - iOS: App Store Connect (TestFlight → producción)
   - Documentación técnica y manual de usuario

---

## ✅ Entregables por Fase
| Fase | Entregable |
|------|------------|
| 1 | Entorno listo, proyecto creado, `flutter doctor` limpio |
| 2 | Firebase configurado, auth y firestore habilitados, archivos de config integrados |
| 3 | Estructura de carpetas, `MultiProvider` base, enrutamiento protegido |
| 4 | Auth funcional, validación, manejo de errores, protección de rutas |
| 5 | Modelo de datos definido, servicios CRUD, reglas de seguridad básicas |
| 6 | Notifiers implementados, optimización de rebuilds, estados centralizados |
| 7 | Todas las vistas construidas, navegación fluida, responsive, animaciones |
| 8 | Pruebas superadas, rendimiento optimizado, builds listos para despliegue |

---

## 📌 Próximos Pasos
1. Validar y aprobar este plan de implementación
2. Definir paleta de colores y tipografía final (o usar Material 3 por defecto)
3. Confirmar alcance de la versión 1.0 (MVP) vs. características futuras (sincronización offline, spaced repetition avanzado, exportación CSV, multiidioma completo)
4. Una vez aprobado, procederé a generar el código estructurado por fases, comenzando por `pubspec.yaml`, configuración de Firebase, y arquitectura base con Provider.

¿Deseas ajustar algún alcance, añadir funcionalidades específicas o proceder a la fase de codificación?


## Prompt 

## Antigravity
## Flutter para Android / web / Windows / iOS
## Usar estándar, no utilizar la opción de producción en A, no utilizar analíticas

# Actuación como ingeniero de software

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
