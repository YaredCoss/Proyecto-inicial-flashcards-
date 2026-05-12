Actúa como un ingeniero de software especializado en desarrollo multiplataforma. Deseo construir una aplicación robusta y escalable utilizando Flutter (con Dart) como framework frontend y Firebase como backend. La aplicación debe ser compatible con Android, web, Windows e iOS, y su gestión de navegación deberá implementarse mediante rutas nombradas definidas desde el archivo main.dart, asegurando una arquitectura clara y mantenible.

La interfaz de usuario incluirá inicialmente una pantalla de autenticación (login) y otra de registro. El lenguaje visual deberá apoyarse en una paleta de colores sobria y contemporánea: fondo y barras en gris oscuro, tarjetas y texto principal en blanco, y acentos (botones, elementos interactivos) en naranja vibrante. Se valorará una tipografía limpia, una disposición elegante y un diseño cuidado que transmita profesionalismo y confianza.

La lógica de datos se estructurará en torno a las siguientes tablas (colecciones en Firestore), organizadas por dominios funcionales:

Entidades Core

Usuario: almacena la información base del usuario (id, nombre, email, contraseña, configuración).

Mazo (Deck): representa colecciones temáticas de tarjetas (id, nombre, descripción, id_usuario, id_categoria, fecha_creación, es_público).

Flashcard: cada tarjeta de estudio (id, id_mazo, frente (pregunta), reverso (respuesta), pista, imagen_frente, imagen_reverso, fecha_creación).

Categoría: estructura jerarquizable para organizar mazos (id, nombre, descripción, id_padre — permite subcategorías).

Entidades de Estudio

Sesión_Estudio: registra cada bloque de estudio (id, id_usuario, id_mazo, fecha_inicio, fecha_fin, total_tarjetas_vistas).

Revisión_Tarjeta: historial inmutable de cada interacción con una tarjeta durante una sesión (id, id_sesión, id_flashcard, calificación (1–5 o Bien/Mal), tiempo_respuesta_ms).

Progreso_Tarjeta: estado acumulado por usuario y tarjeta (id, id_usuario, id_flashcard, nivel_dominio, fecha_última_revisión, fecha_próxima_revisión, intervalo_días, factor_facilidad). Esta entidad implementa el algoritmo de repetición espaciada SM-2.

Entidades Auxiliares (opcionales, pero altamente recomendadas)

Etiqueta (id, nombre) y tabla pivote Flashcard_Etiqueta (id_flashcard, id_etiqueta) para clasificación flexible M:N.

Estadística_Mazo: métricas consolidadas por mazo y usuario (id_mazo, id_usuario, porcentaje_dominio, racha_días, última_sesión).

Relaciones clave:
Usuario → Mazo → Categoría
Mazo → Flashcard → Revisión_Tarjeta → Sesión_Estudio
Flashcard → Progreso_Tarjeta (por usuario)

Consideraciones de diseño adicionales

Diferenciar claramente Revisión_Tarjeta (historial inmutable) de Progreso_Tarjeta (estado mutable), siendo esta última fundamental para la lógica SM-2.

Los mazos pueden ser públicos o privados, lo que permitirá en el futuro funcionalidades de compartir o clonar contenido.

La tabla Categoría es auto-referenciada para sustentar jerarquías complejas (ej. Idiomas → Inglés → Vocabulario).

El campo factor_facilidad en Progreso_Tarjeta es neurálgico para el algoritmo SM-2, ya que ajusta dinámicamente los intervalos de repaso según el desempeño histórico.

Por favor, genera la estructura inicial del proyecto Flutter (carpetas, pantallas, servicios y modelos) que refleje fielmente este diseño, priorizando buenas prácticas, separación de responsabilidades y escalabilidad futura.
