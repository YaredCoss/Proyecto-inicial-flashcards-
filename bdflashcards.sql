-- ============================================================
--  bdflashcards.sql
--  Base de datos para sistema de estudio con flashcards
--  Motor: PostgreSQL 15+
--  Algoritmo de repetición espaciada: SM-2
-- ============================================================

-- ────────────────────────────────────────────────────────────
--  EXTENSIONES
-- ────────────────────────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS "pgcrypto";   -- gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS "pg_trgm";    -- búsqueda por similitud de texto


-- ============================================================
--  1. USUARIO
-- ============================================================
CREATE TABLE usuario (
    id               UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre           VARCHAR(100)  NOT NULL,
    email            VARCHAR(255)  NOT NULL,
    password_hash    TEXT          NOT NULL,
    fecha_registro   TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    idioma           CHAR(5)       NOT NULL DEFAULT 'es',
    activo           BOOLEAN       NOT NULL DEFAULT TRUE,

    CONSTRAINT uq_usuario_email UNIQUE (email),
    CONSTRAINT chk_usuario_email CHECK (email ~* '^[^@]+@[^@]+\.[^@]+$')
);

COMMENT ON TABLE  usuario              IS 'Usuarios registrados en la plataforma.';
COMMENT ON COLUMN usuario.password_hash IS 'Hash bcrypt de la contraseña, nunca texto plano.';
COMMENT ON COLUMN usuario.idioma        IS 'Código BCP-47, ej: es, en-US.';


-- ============================================================
--  2. CATEGORÍA (auto-referenciada para jerarquía)
-- ============================================================
CREATE TABLE categoria (
    id          UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre      VARCHAR(100)  NOT NULL,
    descripcion TEXT,
    id_padre    UUID          REFERENCES categoria(id) ON DELETE SET NULL,
    icono       VARCHAR(50),
    orden       SMALLINT      NOT NULL DEFAULT 0
);

COMMENT ON TABLE  categoria         IS 'Clasificación jerárquica de mazos (ej: Idiomas > Inglés > Vocabulario).';
COMMENT ON COLUMN categoria.id_padre IS 'NULL = categoría raíz. Self-join para subcategorías.';


-- ============================================================
--  3. MAZO
-- ============================================================
CREATE TABLE mazo (
    id                  UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    id_usuario          UUID          NOT NULL REFERENCES usuario(id)   ON DELETE CASCADE,
    id_categoria        UUID          REFERENCES categoria(id)           ON DELETE SET NULL,
    nombre              VARCHAR(150)  NOT NULL,
    descripcion         TEXT,
    es_publico          BOOLEAN       NOT NULL DEFAULT FALSE,
    idioma              CHAR(5),
    fecha_creacion      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    fecha_actualizacion TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE  mazo           IS 'Colección temática de flashcards creada por un usuario.';
COMMENT ON COLUMN mazo.es_publico IS 'TRUE permite que otros usuarios vean y clonen el mazo.';


-- ============================================================
--  4. FLASHCARD
-- ============================================================
CREATE TABLE flashcard (
    id                UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    id_mazo           UUID         NOT NULL REFERENCES mazo(id) ON DELETE CASCADE,
    frente            TEXT         NOT NULL,
    reverso           TEXT         NOT NULL,
    pista             TEXT,
    imagen_frente_url TEXT,
    imagen_reverso_url TEXT,
    tipo              VARCHAR(20)  NOT NULL DEFAULT 'basica'
                        CHECK (tipo IN ('basica', 'cloze', 'imagen', 'opcion_multiple')),
    activa            BOOLEAN      NOT NULL DEFAULT TRUE,
    fecha_creacion    TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE  flashcard       IS 'Tarjeta individual de estudio con pregunta y respuesta.';
COMMENT ON COLUMN flashcard.tipo   IS 'basica=Q&A simple | cloze=texto con huecos | imagen | opcion_multiple.';
COMMENT ON COLUMN flashcard.activa IS 'FALSE suspende la tarjeta sin eliminarla.';


-- ============================================================
--  5. ETIQUETA
-- ============================================================
CREATE TABLE etiqueta (
    id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre     VARCHAR(60) NOT NULL,
    color_hex  CHAR(7)     CHECK (color_hex ~ '^#[0-9A-Fa-f]{6}$'),

    CONSTRAINT uq_etiqueta_nombre UNIQUE (nombre)
);

COMMENT ON TABLE etiqueta IS 'Etiquetas libres para clasificar flashcards de forma transversal.';


-- ============================================================
--  6. FLASHCARD_ETIQUETA  (pivote M:N)
-- ============================================================
CREATE TABLE flashcard_etiqueta (
    id_flashcard  UUID  NOT NULL REFERENCES flashcard(id) ON DELETE CASCADE,
    id_etiqueta   UUID  NOT NULL REFERENCES etiqueta(id)  ON DELETE CASCADE,

    CONSTRAINT pk_flashcard_etiqueta PRIMARY KEY (id_flashcard, id_etiqueta)
);

COMMENT ON TABLE flashcard_etiqueta IS 'Asociación M:N entre flashcards y etiquetas.';


-- ============================================================
--  7. SESIÓN DE ESTUDIO
-- ============================================================
CREATE TABLE sesion_estudio (
    id              UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    id_usuario      UUID         NOT NULL REFERENCES usuario(id) ON DELETE CASCADE,
    id_mazo         UUID         NOT NULL REFERENCES mazo(id)    ON DELETE CASCADE,
    fecha_inicio    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    fecha_fin       TIMESTAMPTZ,
    total_tarjetas  SMALLINT     NOT NULL DEFAULT 0,
    modo            VARCHAR(20)  NOT NULL DEFAULT 'normal'
                        CHECK (modo IN ('normal', 'examen', 'repaso')),

    CONSTRAINT chk_sesion_fechas CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio)
);

COMMENT ON TABLE  sesion_estudio       IS 'Registro de cada sesión de estudio iniciada por un usuario.';
COMMENT ON COLUMN sesion_estudio.modo   IS 'normal=retroalimentación inmediata | examen=sin pistas | repaso=solo vencidas.';


-- ============================================================
--  8. REVISIÓN DE TARJETA  (historial inmutable)
-- ============================================================
CREATE TABLE revision_tarjeta (
    id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    id_sesion           UUID        NOT NULL REFERENCES sesion_estudio(id) ON DELETE CASCADE,
    id_flashcard        UUID        NOT NULL REFERENCES flashcard(id)       ON DELETE CASCADE,
    calificacion        SMALLINT    NOT NULL CHECK (calificacion BETWEEN 1 AND 5),
    tiempo_respuesta_ms INTEGER     CHECK (tiempo_respuesta_ms >= 0),
    fue_correcto        BOOLEAN     NOT NULL,
    revisado_en         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE  revision_tarjeta              IS 'Historial inmutable: una fila por cada tarjeta respondida en una sesión.';
COMMENT ON COLUMN revision_tarjeta.calificacion  IS '1=olvidé, 2=difícil, 3=regular, 4=bien, 5=perfecto (escala SM-2).';


-- ============================================================
--  9. PROGRESO DE TARJETA  (estado SM-2 mutable por usuario)
-- ============================================================
CREATE TABLE progreso_tarjeta (
    id                     UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    id_usuario             UUID          NOT NULL REFERENCES usuario(id)   ON DELETE CASCADE,
    id_flashcard           UUID          NOT NULL REFERENCES flashcard(id) ON DELETE CASCADE,
    nivel_dominio          SMALLINT      NOT NULL DEFAULT 0
                               CHECK (nivel_dominio BETWEEN 0 AND 5),
    factor_facilidad       NUMERIC(4,2)  NOT NULL DEFAULT 2.50
                               CHECK (factor_facilidad >= 1.30),
    intervalo_dias         SMALLINT      NOT NULL DEFAULT 1
                               CHECK (intervalo_dias >= 1),
    repeticiones           SMALLINT      NOT NULL DEFAULT 0,
    fecha_ultima_revision  TIMESTAMPTZ,
    fecha_proxima_revision DATE          NOT NULL DEFAULT CURRENT_DATE,

    CONSTRAINT uq_progreso_usuario_tarjeta UNIQUE (id_usuario, id_flashcard)
);

COMMENT ON TABLE  progreso_tarjeta                      IS 'Estado SM-2 acumulado por usuario/tarjeta. Un solo registro por par.';
COMMENT ON COLUMN progreso_tarjeta.nivel_dominio         IS '0=nueva | 1-4=aprendiendo | 5=dominada.';
COMMENT ON COLUMN progreso_tarjeta.factor_facilidad      IS 'E-Factor SM-2. Inicia en 2.50, mínimo 1.30.';
COMMENT ON COLUMN progreso_tarjeta.intervalo_dias        IS 'Días hasta la próxima revisión calculada por SM-2.';
COMMENT ON COLUMN progreso_tarjeta.repeticiones          IS 'Respuestas correctas consecutivas acumuladas.';
COMMENT ON COLUMN progreso_tarjeta.fecha_proxima_revision IS 'Columna clave para construir la cola de estudio diaria.';


-- ============================================================
--  10. ESTADÍSTICA DE MAZO  (caché / vista materializada)
-- ============================================================
CREATE TABLE estadistica_mazo (
    id_mazo           UUID          NOT NULL REFERENCES mazo(id)    ON DELETE CASCADE,
    id_usuario        UUID          NOT NULL REFERENCES usuario(id) ON DELETE CASCADE,
    total_tarjetas    SMALLINT      NOT NULL DEFAULT 0,
    tarjetas_dominadas SMALLINT     NOT NULL DEFAULT 0,
    porcentaje_dominio NUMERIC(5,2) NOT NULL DEFAULT 0.00,
    racha_dias        SMALLINT      NOT NULL DEFAULT 0,
    ultima_sesion     TIMESTAMPTZ,
    actualizado_en    TIMESTAMPTZ   NOT NULL DEFAULT NOW(),

    CONSTRAINT pk_estadistica_mazo PRIMARY KEY (id_mazo, id_usuario),
    CONSTRAINT chk_porcentaje CHECK (porcentaje_dominio BETWEEN 0 AND 100)
);

COMMENT ON TABLE estadistica_mazo IS 'Caché de métricas por mazo/usuario. Refrescar tras cada sesión o via vista materializada.';


-- ============================================================
--  ÍNDICES
-- ============================================================

-- usuario
CREATE INDEX idx_usuario_email        ON usuario(email);

-- mazo
CREATE INDEX idx_mazo_usuario         ON mazo(id_usuario);
CREATE INDEX idx_mazo_categoria       ON mazo(id_categoria);
CREATE INDEX idx_mazo_publico         ON mazo(es_publico) WHERE es_publico = TRUE;

-- flashcard
CREATE INDEX idx_flashcard_mazo       ON flashcard(id_mazo);
CREATE INDEX idx_flashcard_activa     ON flashcard(id_mazo, activa) WHERE activa = TRUE;
CREATE INDEX idx_flashcard_frente_trgm ON flashcard USING gin(frente gin_trgm_ops);

-- sesion_estudio
CREATE INDEX idx_sesion_usuario       ON sesion_estudio(id_usuario);
CREATE INDEX idx_sesion_mazo          ON sesion_estudio(id_mazo);
CREATE INDEX idx_sesion_fecha         ON sesion_estudio(fecha_inicio DESC);

-- revision_tarjeta
CREATE INDEX idx_revision_sesion      ON revision_tarjeta(id_sesion);
CREATE INDEX idx_revision_flashcard   ON revision_tarjeta(id_flashcard);

-- progreso_tarjeta  (columna clave para la cola diaria)
CREATE INDEX idx_progreso_usuario          ON progreso_tarjeta(id_usuario);
CREATE INDEX idx_progreso_proxima_revision ON progreso_tarjeta(id_usuario, fecha_proxima_revision);

-- categoria
CREATE INDEX idx_categoria_padre      ON categoria(id_padre);


-- ============================================================
--  TRIGGER: actualizar fecha_actualizacion en mazo
-- ============================================================
CREATE OR REPLACE FUNCTION fn_actualizar_fecha_mazo()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    NEW.fecha_actualizacion := NOW();
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_mazo_fecha_actualizacion
    BEFORE UPDATE ON mazo
    FOR EACH ROW
    EXECUTE FUNCTION fn_actualizar_fecha_mazo();


-- ============================================================
--  TRIGGER: crear registro progreso_tarjeta al insertar flashcard
-- ============================================================
--  Crea automáticamente un progreso inicial para el dueño del mazo.
-- ============================================================
CREATE OR REPLACE FUNCTION fn_init_progreso_tarjeta()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
    v_id_usuario UUID;
BEGIN
    SELECT id_usuario INTO v_id_usuario FROM mazo WHERE id = NEW.id_mazo;

    INSERT INTO progreso_tarjeta (id_usuario, id_flashcard)
    VALUES (v_id_usuario, NEW.id)
    ON CONFLICT (id_usuario, id_flashcard) DO NOTHING;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_init_progreso
    AFTER INSERT ON flashcard
    FOR EACH ROW
    EXECUTE FUNCTION fn_init_progreso_tarjeta();


-- ============================================================
--  VISTA: cola_estudio_hoy
--  Tarjetas pendientes de revisión para hoy por usuario
-- ============================================================
CREATE OR REPLACE VIEW cola_estudio_hoy AS
SELECT
    pt.id_usuario,
    pt.id_flashcard,
    f.frente,
    f.reverso,
    f.pista,
    f.tipo,
    pt.nivel_dominio,
    pt.factor_facilidad,
    pt.intervalo_dias,
    pt.fecha_proxima_revision,
    m.id       AS id_mazo,
    m.nombre   AS nombre_mazo
FROM progreso_tarjeta pt
JOIN flashcard f ON f.id = pt.id_flashcard AND f.activa = TRUE
JOIN mazo      m ON m.id = f.id_mazo
WHERE pt.fecha_proxima_revision <= CURRENT_DATE;

COMMENT ON VIEW cola_estudio_hoy IS 'Tarjetas cuya fecha_proxima_revision ya venció. Usar para construir la sesión diaria.';


-- ============================================================
--  VISTA: resumen_usuario
--  Métricas globales por usuario
-- ============================================================
CREATE OR REPLACE VIEW resumen_usuario AS
SELECT
    u.id,
    u.nombre,
    u.email,
    COUNT(DISTINCT m.id)                                        AS total_mazos,
    COUNT(DISTINCT f.id)                                        AS total_flashcards,
    COUNT(DISTINCT pt.id) FILTER (WHERE pt.nivel_dominio = 5)  AS tarjetas_dominadas,
    COUNT(DISTINCT s.id)                                        AS total_sesiones,
    MAX(s.fecha_inicio)                                         AS ultima_sesion
FROM usuario u
LEFT JOIN mazo           m  ON m.id_usuario  = u.id
LEFT JOIN flashcard      f  ON f.id_mazo     = m.id
LEFT JOIN progreso_tarjeta pt ON pt.id_usuario = u.id AND pt.id_flashcard = f.id
LEFT JOIN sesion_estudio s  ON s.id_usuario  = u.id
GROUP BY u.id, u.nombre, u.email;

COMMENT ON VIEW resumen_usuario IS 'Métricas agregadas por usuario. Útil para dashboards.';


-- ============================================================
--  DATOS DE EJEMPLO (semilla mínima)
-- ============================================================

-- Categorías raíz
INSERT INTO categoria (id, nombre, descripcion) VALUES
    ('11111111-0000-0000-0000-000000000001', 'Idiomas',    'Estudio de lenguas extranjeras'),
    ('11111111-0000-0000-0000-000000000002', 'Ciencias',   'Biología, química, física'),
    ('11111111-0000-0000-0000-000000000003', 'Tecnología', 'Programación y sistemas');

-- Subcategorías
INSERT INTO categoria (id, nombre, id_padre) VALUES
    ('22222222-0000-0000-0000-000000000001', 'Inglés',      '11111111-0000-0000-0000-000000000001'),
    ('22222222-0000-0000-0000-000000000002', 'Bases de datos', '11111111-0000-0000-0000-000000000003');

-- Usuario demo
INSERT INTO usuario (id, nombre, email, password_hash) VALUES
    ('aaaaaaaa-0000-0000-0000-000000000001',
     'Demo User',
     'demo@flashcards.app',
     '$2b$12$demohashplaceholder000000000000000000000000000000000000');

-- Mazo demo
INSERT INTO mazo (id, id_usuario, id_categoria, nombre, descripcion) VALUES
    ('bbbbbbbb-0000-0000-0000-000000000001',
     'aaaaaaaa-0000-0000-0000-000000000001',
     '22222222-0000-0000-0000-000000000002',
     'SQL Básico',
     'Conceptos fundamentales de SQL y bases de datos relacionales');

-- Etiquetas
INSERT INTO etiqueta (nombre, color_hex) VALUES
    ('ddl',    '#534AB7'),
    ('dml',    '#0F6E56'),
    ('repaso', '#854F0B');

-- ============================================================
--  FIN DEL SCRIPT
-- ============================================================
