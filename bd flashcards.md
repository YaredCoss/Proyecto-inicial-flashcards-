actúa como un administrador de base de datos: proyecto flashcards para estudio, que entidades se necesitan para su gestión 

## Entidades para un Sistema de Flashcards
<img width="751" height="163" alt="image" src="https://github.com/user-attachments/assets/9443c3c2-7819-4475-a461-fe58632ae766" />


Aquí están las entidades principales y sus relaciones:

---

### Entidades Core

**Usuario** — quien usa la app
- id, nombre, email, contraseña, fecha_registro, configuración

**Mazo (Deck)** — colección temática de tarjetas
- id, nombre, descripción, id_usuario, id_categoria, fecha_creación, es_público

**Flashcard** — la tarjeta en sí
- id, id_mazo, frente (pregunta), reverso (respuesta), pista, imagen_frente, imagen_reverso, fecha_creación

**Categoría** — para organizar mazos
- id, nombre, descripción, id_padre *(para subcategorías)*

---

### Entidades de Estudio

**Sesión\_Estudio** — cada vez que el usuario estudia
- id, id_usuario, id_mazo, fecha_inicio, fecha_fin, total_tarjetas_vistas

**Revisión\_Tarjeta** — registro por tarjeta en cada sesión
- id, id_sesión, id_flashcard, calificación *(1-5 o Bien/Mal)*, tiempo_respuesta_ms

**Progreso\_Tarjeta** — estado acumulado por tarjeta/usuario
- id, id_usuario, id_flashcard, nivel_dominio, fecha_última_revisión, **fecha_próxima_revisión**, intervalo_días, factor_facilidad

> Esta última entidad implementa el algoritmo de **repetición espaciada (SM-2)**.

---

### Entidades Auxiliares (opcionales pero útiles)

**Etiqueta (Tag)** — clasificación flexible
- id, nombre

**Flashcard\_Etiqueta** — tabla pivote M:N
- id_flashcard, id_etiqueta

**Estadística\_Mazo** — métricas por mazo
- id_mazo, id_usuario, porcentaje_dominio, racha_días, última_sesión

---

### Diagrama de relaciones clave

```
Usuario ──< Mazo >── Categoría
           │
           └──< Flashcard >──< Revisión_Tarjeta >── Sesión_Estudio
                    │
                    └── Progreso_Tarjeta (por usuario)
```

---

### Puntos de diseño importantes

- **Separar `Revisión_Tarjeta` de `Progreso_Tarjeta`**: una es el historial inmutable, la otra es el estado actual mutable (crucial para SM-2).
- **`Mazo` puede ser público o privado**: permite funcionalidad de compartir/clonar mazos.
- **`Categoría` auto-referenciada**: permite jerarquías como *Idiomas → Inglés → Vocabulario*.
- **`factor_facilidad` en Progreso\_Tarjeta**: parámetro central del algoritmo SM-2 que ajusta los intervalos según el desempeño histórico.

¿Quieres que profundice en alguna entidad, diseñe el DDL (CREATE TABLE), o modelemos el algoritmo de repetición espaciada? 

las entidades con sus atributos y tipo en forma de forma de tabla para cada una de las entidades

## tablas 
<img width="738" height="356" alt="image" src="https://github.com/user-attachments/assets/5a935dc9-add2-4660-87d8-45dce822760d" />
<img width="693" height="702" alt="image" src="https://github.com/user-attachments/assets/973dc347-f4be-4a53-80e7-6afc93a2a2ec" />
<img width="678" height="554" alt="image" src="https://github.com/user-attachments/assets/b328d9cc-62bf-4d65-97fb-6c412b27b760" />
<img width="683" height="295" alt="image" src="https://github.com/user-attachments/assets/bfc5041d-4127-4a36-97a2-64ebac05f7e9" />

## de acuerdo a tu respuesta anterior puedes generar un script en sql para descargar con el nombre de bdflashcards.sql  para las entidades con sus relaciones 
