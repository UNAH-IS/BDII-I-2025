-- 1. Desarrollar un procedimiento almacenado llamado P_ACTUALIZAR_SUSCRIPTORES. Este procedimiento
-- almacenado actualizará la cantidad de suscriptores de un canal de YouTube específico. Tomará como entrada el
-- código del canal y el código del usuario que se agregará. El procedimiento verificará si el canal y el usuario existe
-- y luego insertará el suscriptor en la tabla de usuarios por canal y luego actualizará la cantidad de suscriptores
-- sumando uno . Además, si la cantidad de suscriptores supera a 10, enviará una notificación al usuario dueño del
-- canal felicitandolo por su logro. Para el envío de notificaciones crear un procedimiento llamado
-- P_GUARDAR_NOTIFICACION que reciba como parametros los campos de la tabla y los use para insertar un nuevo
-- registro en la tabla tbl_notificaciones.
-- Para verificar si los registros indicados existen utilizar excepciones personalizadas y enviar un mensaje de salida
-- indicando cual es el error.

 CREATE OR REPLACE PROCEDURE P_ACTUALIZAR_SUSCRIPTORES (
        V_CODIGO_CANAL TBL_CANALES.CODIGO_CANAL%TYPE, 
        V_CODIGO_USUARIO TBL_USUARIOS.CODIGO_USUARIO%TYPE,
        V_MENSAJE_RESULTADO OUT VARCHAR2
) AS
    V_CANTIDAD_CANALES NUMBER;
    V_CANTIDAD_USUARIOS NUMBER;
    E_CANAL_NO_EXISTE EXCEPTION;
    E_USUARIO_NO_EXISTE EXCEPTION;

    V_CODIGO_USUARIO_DESTINO TBL_USUARIOS.CODIGO_USUARIO%TYPE;
    V_CANTIDAD_SUSCRIPTORES NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO V_CANTIDAD_CANALES 
    FROM TBL_CANALES
    WHERE CODIGO_CANAL = V_CODIGO_CANAL;

    IF V_CANTIDAD_CANALES = 0 THEN
        RAISE E_CANAL_NO_EXISTE;
    END IF;

    SELECT COUNT(*)
    INTO V_CANTIDAD_USUARIOS
    FROM TBL_USUARIOS
    WHERE CODIGO_USUARIO = V_CODIGO_USUARIO;

    IF V_CANTIDAD_USUARIOS = 0 THEN
        RAISE E_USUARIO_NO_EXISTE;
    END IF;

    INSERT INTO TBL_USUARIOS_X_CANAL (CODIGO_CANAL, CODIGO_USUARIO, FECHA_SUSCRIPCION)
    VALUES (V_CODIGO_CANAL, V_CODIGO_USUARIO, SYSDATE);


    UPDATE TBL_CANALES
    SET CANTIDAD_SUSCRIPTORES = CANTIDAD_SUSCRIPTORES + 1
    WHERE CODIGO_CANAL = V_CODIGO_CANAL;

    SELECT CODIGO_USUARIO, CANTIDAD_SUSCRIPTORES
    INTO V_CODIGO_USUARIO_DESTINO, V_CANTIDAD_SUSCRIPTORES 
    FROM TBL_CANALES
    WHERE CODIGO_CANAL = V_CODIGO_CANAL;

    IF V_CANTIDAD_SUSCRIPTORES = 10 THEN
        P_GUARDAR_NOTIFICACION(
            V_CODIGO_USUARIO_ORIGEN => V_CODIGO_USUARIO,
            V_CODIGO_USUARIO_DESTINO => V_CODIGO_USUARIO_DESTINO,
            V_TEXTO_NOTIFICACION => 'Felicitaciones, has superado los 10 suscriptores',
            V_CODIGO_VIDEO => NULL
        );
    END IF;

    COMMIT;


EXCEPTION
    WHEN E_CANAL_NO_EXISTE THEN
        V_MENSAJE_RESULTADO := 'El canal no existe';
    WHEN E_USUARIO_NO_EXISTE THEN
        V_MENSAJE_RESULTADO := 'El usuario no existe';

END;

SELECT * FROM TBL_NOTIFICACIONES;

CREATE OR REPLACE PROCEDURE P_GUARDAR_NOTIFICACION (
    V_CODIGO_USUARIO_ORIGEN TBL_USUARIOS.CODIGO_USUARIO%TYPE,
    V_CODIGO_USUARIO_DESTINO TBL_USUARIOS.CODIGO_USUARIO%TYPE,
    V_TEXTO_NOTIFICACION TBL_NOTIFICACIONES.TEXTO_NOTIFICACION%TYPE,
    V_CODIGO_VIDEO TBL_NOTIFICACIONES.CODIGO_VIDEO%TYPE
) AS
BEGIN
    INSERT INTO TBL_NOTIFICACIONES (
        CODIGO_NOTIFICACION, 
        CODIGO_USUARIO_ORIGEN,
        CODIGO_USUARIO_DESTINO, 
        FECHA_HORA_ENVIO,
        TEXTO_NOTIFICACION,
        CODIGO_VIDEO
    )
    VALUES (
        SEQ_NOTIFICACIONES.NEXTVAL,
        V_CODIGO_USUARIO_ORIGEN,
        V_CODIGO_USUARIO_DESTINO, 
        SYSDATE,
        V_TEXTO_NOTIFICACION,
        V_CODIGO_VIDEO
    );

    COMMIT;
END;

CREATE SEQUENCE SEQ_NOTIFICACIONES;

SELECT * FROM TBL_NOTIFICACIONES;


SELECT * FROM TBL_CANALES; --77689  => 77690
SELECT * FROM TBL_USUARIOS;
SELECT COUNT(*) --NO ES LO M'AS OPTIMO
FROM TBL_USUARIOS_X_CANAL
WHERE CODIGO_CANAL = 9;


DECLARE
    V_MENSAJE VARCHAR2(100);
BEGIN
    P_ACTUALIZAR_SUSCRIPTORES(
        V_CODIGO_CANAL => 9,
        V_CODIGO_USUARIO => 1,
        V_MENSAJE_RESULTADO => V_MENSAJE
    );

    DBMS_OUTPUT.PUT_LINE(V_MENSAJE);
END;


-- Usar el procedimieto P_GUARDAR_NOTIFICACION para el envío de notificaciones desde los siguientes
-- procedimientos:
-- a. Crear un procedimiento llamado P_GUARDAR_VIDEO para guardar un video usando los parametros de
-- entrada del procedimiento y luego de ello verificar cual es el canal correspondiente para luego obtener
-- la lista de los usuarios suscritos a dicho canal. Por ultimo, enviar una notificacion a cada usuario suscrito
-- indicando que se ha subido un nuevo video al canal al cual está suscrito. Gestionar exceptiones
-- personalizadas para verificar la existencia del usuario y el canal.
-- b. Crear un procedimiento llamado P_GUARDAR_COMENTARIO para guardar un comentario usando los
-- parametros de entrada del procedimiento y luego de ello enviar una notificación al usuario dueño del
-- video que se cometó, indicando en la notificación el contenido del comentario. Gestionar exceptiones
-- personalizadas para verificar la existencia del usuario y el video.


SELECT * FROM TBL_VIDEOS;
SELECT * FROM TBL_CANALES;
SELECT * FROM TBL_USUARIOS_X_CANAL;
-- MICHIS SATANICOS (ROCK, HEAVY METAL)


CREATE OR REPLACE PROCEDURE P_GUARDAR_VIDEO (
    P_CODIGO_USUARIO TBL_VIDEOS.CODIGO_USUARIO%TYPE,
    P_CODIGO_ESTADO_VIDEO TBL_VIDEOS.CODIGO_ESTADO_VIDEO%TYPE,
    P_CODIGO_IDIOMA TBL_VIDEOS.CODIGO_IDIOMA%TYPE,
    P_CODIGO_CANAL TBL_VIDEOS.CODIGO_CANAL%TYPE,
    P_NOMBRE_VIDEO TBL_VIDEOS.NOMBRE_VIDEO%TYPE,
    P_RESOLUCION TBL_VIDEOS.RESOLUCION%TYPE,
    P_DURACION_SEGUNDOS TBL_VIDEOS.DURACION_SEGUNDOS%TYPE,
    P_DESCRIPCION TBL_VIDEOS.DESCRIPCION%TYPE,
    P_URL TBL_VIDEOS.URL%TYPE,
    P_MENSAJE_RESULTADO OUT VARCHAR2
) AS
    V_CODIGO_VIDEO TBL_VIDEOS.CODIGO_VIDEO%TYPE;

    V_CANTIDAD_CANALES NUMBER;
    V_CANTIDAD_USUARIOS NUMBER;
    E_CANAL_NO_EXISTE EXCEPTION;
    E_USUARIO_NO_EXISTE EXCEPTION;
BEGIN 
    SELECT COUNT(*)
    INTO V_CANTIDAD_CANALES 
    FROM TBL_CANALES
    WHERE CODIGO_CANAL = P_CODIGO_CANAL;

    IF V_CANTIDAD_CANALES = 0 THEN
        RAISE E_CANAL_NO_EXISTE;
    END IF;

    SELECT COUNT(*)
    INTO V_CANTIDAD_USUARIOS
    FROM TBL_USUARIOS
    WHERE CODIGO_USUARIO = P_CODIGO_USUARIO;

    IF V_CANTIDAD_USUARIOS = 0 THEN
        RAISE E_USUARIO_NO_EXISTE;
    END IF;

    V_CODIGO_VIDEO := SEQ_CODIGO_VIDEO.NEXTVAL;
    INSERT INTO TBL_VIDEOS (
            CODIGO_VIDEO,
            CODIGO_USUARIO,
            CODIGO_ESTADO_VIDEO,
            CODIGO_IDIOMA,
            CODIGO_CANAL,
            NOMBRE_VIDEO,
            RESOLUCION,
            DURACION_SEGUNDOS,
            CANTIDAD_LIKES,
            CANTIDAD_DISLIKES,
            CANTIDAD_VISUALIZACIONES,
            FECHA_SUBIDA,
            DESCRIPCION,
            CANTIDAD_SHARES,
            URL
        ) VALUES (
            V_CODIGO_VIDEO,
            P_CODIGO_USUARIO,
            P_CODIGO_ESTADO_VIDEO,
            P_CODIGO_IDIOMA,
            P_CODIGO_CANAL,
            P_NOMBRE_VIDEO,
            P_RESOLUCION,
            P_DURACION_SEGUNDOS,
            0,
            0,
            0,
            SYSDATE,
            P_DESCRIPCION,
            0,
            P_URL
        );

        FOR V_USUARIO IN (
                            SELECT * 
                            FROM TBL_USUARIOS_X_CANAL
                            WHERE CODIGO_CANAL = P_CODIGO_CANAL
        ) LOOP
            P_GUARDAR_NOTIFICACION(
                V_CODIGO_USUARIO_ORIGEN => P_CODIGO_USUARIO,
                V_CODIGO_USUARIO_DESTINO => V_USUARIO.CODIGO_USUARIO,
                V_TEXTO_NOTIFICACION => 'Se ha subido un nuevo video titulado "'||
                                        P_NOMBRE_VIDEO || '" al canal',
                V_CODIGO_VIDEO => V_CODIGO_VIDEO
            );
        END LOOP;

        COMMIT;
EXCEPTION
    WHEN E_CANAL_NO_EXISTE THEN
        P_MENSAJE_RESULTADO := 'El canal no existe';
    WHEN E_USUARIO_NO_EXISTE THEN
        P_MENSAJE_RESULTADO := 'El usuario no existe';
END;


CREATE SEQUENCE SEQ_CODIGO_VIDEO;

SELECT * FROM TBL_VIDEOS;


--PROBAR P_GUARDAR_VIDEO

DECLARE
    V_MENSAJE VARCHAR2(100);
BEGIN
    P_GUARDAR_VIDEO(
        P_CODIGO_USUARIO => 1,
        P_CODIGO_ESTADO_VIDEO => 1,
        P_CODIGO_IDIOMA => 1,
        P_CODIGO_CANAL => 2,
        P_NOMBRE_VIDEO => 'Michis Satánicos',
        P_RESOLUCION => 1080,
        P_DURACION_SEGUNDOS => 120,
        P_DESCRIPCION => 'Descripcion del video',
        P_URL => 'https://www.youtube.com/watch?v=123',
        P_MENSAJE_RESULTADO => V_MENSAJE
    );

    DBMS_OUTPUT.PUT_LINE(V_MENSAJE);
END;


SELECT * FROM TBL_NOTIFICACIONES;
SELECT * FROM TBL_USUARIOS_X_CANAL;


SELECT * FROM TBL_VIDEOS;


SELECT * FROM TBL_COMENTARIOS;







CREATE OR REPLACE PROCEDURE P_GUARDAR_COMENTARIO(
        P_CODIGO_COMENTARIO_PADRE TBL_COMENTARIOS.CODIGO_COMENTARIO_PADRE%TYPE,
        P_CODIGO_USUARIO TBL_COMENTARIOS.CODIGO_USUARIO%TYPE,
        P_CODIGO_VIDEO TBL_COMENTARIOS.CODIGO_VIDEO%TYPE,
        P_COMENTARIO TBL_COMENTARIOS.COMENTARIO%TYPE
) AS
    V_CODIGO_COMENTARIO NUMBER;
    V_CODIGO_USUARIO_DESTINO NUMBER;
BEGIN
    V_CODIGO_COMENTARIO := SEQ_CODIGO_COMENTARIO.NEXTVAL;
    INSERT INTO TBL_COMENTARIOS(
        CODIGO_COMENTARIO,
        CODIGO_COMENTARIO_PADRE,
        CODIGO_USUARIO,
        CODIGO_VIDEO,
        COMENTARIO,
        FECHA_PUBLICACION,
        CANTIDAD_LIKES
    ) VALUES (
        V_CODIGO_COMENTARIO,
        P_CODIGO_COMENTARIO_PADRE,
        P_CODIGO_USUARIO,
        P_CODIGO_VIDEO,
        P_COMENTARIO,
        SYSDATE,
        0
    );

    SELECT CODIGO_USUARIO
    INTO V_CODIGO_USUARIO_DESTINO 
    FROM TBL_VIDEOS
    WHERE CODIGO_VIDEO = P_CODIGO_VIDEO;

     P_GUARDAR_NOTIFICACION(
        V_CODIGO_USUARIO_ORIGEN => P_CODIGO_USUARIO,
        V_CODIGO_USUARIO_DESTINO => V_CODIGO_USUARIO_DESTINO,
        V_TEXTO_NOTIFICACION => 'Nuevo comentario: "'||
                                P_COMENTARIO || '"',
        V_CODIGO_VIDEO => P_CODIGO_VIDEO
    );

    COMMIT;
END;

CREATE SEQUENCE SEQ_CODIGO_COMENTARIO 
START WITH 8;

SELECT * FROM TBL_COMENTARIOS;

--PROBAR P_GUARDAR_COMENTARIO
BEGIN
    P_GUARDAR_COMENTARIO(
        P_CODIGO_COMENTARIO_PADRE => NULL,
        P_CODIGO_USUARIO => 2,
        P_CODIGO_VIDEO => 22,
        P_COMENTARIO => 'Que bonitos michis'
    );
END;

SELECT * FROM TBL_VIDEOS;

SELECT * FROM TBL_NOTIFICACIONES;



-- Generar lista de videos recomendados para un usuario específico: desarrolle una función que retorne una
-- cadena con el html necesario para generar una tabla con la lista de videos recomedados para un usuario. La
-- tabla debe ser como el siguiete html:

-- <table>
--     <thead>
--          <tr>
    --         <th>Id video</th>
    --         <th>Nombre video</th>
--     </thead>
--     <tbody>
--         <td>1</td>
--         <td>Video recomendado 1</td>
--     </tbody>
-- </table>

-- En la base de datos no existe una tabla de recomendados, deberá calcular la información resultante basado en
-- los siguietes criterios, mostrar como recomedado si cumple con lo siguiente:
-- • Si está dentro de los últimos 3 videos que el usuario ha visto (segun el historial)
-- • Si el usuario le ha dado like o ha cometado un video
-- • Incluir los videos de los canales a los que está suscrito un usuario
-- Todos los videos que cumplan con los criterios anteriores deberán ser anexados al valor de retorno
-- de la función y despues desde un bloque anónimo capturar el valor e imprimirlo en la terminal.



CREATE OR REPLACE FUNCTION F_LISTA_VIDEOS_RECOMENDADOS(
    P_CODIGO_USUARIO TBL_USUARIOS.CODIGO_USUARIO%TYPE
) RETURN VARCHAR2 AS
    V_HTML VARCHAR2(4000);
BEGIN
    V_HTML := '<table><thead><th>Id video</th><th>Nombre video</th></thead><tbody>';

    FOR V_VIDEO IN (
        SELECT *
        FROM TBL_VIDEOS
        WHERE CODIGO_VIDEO IN ( 
            SELECT CODIGO_VIDEO
            FROM (
                SELECT *
                FROM TBL_HISTORIAL_VIDEOS A
                WHERE CODIGO_USUARIO = P_CODIGO_USUARIO
                ORDER BY FECHA_HORA_VISUALIZACION DESC
            ) A
            WHERE ROWNUM <= 3
        ) 
        AND (
            CODIGO_VIDEO IN (
                SELECT CODIGO_VIDEO FROM TBL_LIKES
                WHERE CODIGO_USUARIO = P_CODIGO_USUARIO
            ) OR CODIGO_VIDEO IN (
                SELECT CODIGO_VIDEO FROM TBL_COMENTARIOS
                WHERE CODIGO_USUARIO = P_CODIGO_USUARIO
            )
        )
        OR CODIGO_VIDEO IN (
            SELECT B.CODIGO_VIDEO
            FROM TBL_USUARIOS_X_CANAL A
            INNER JOIN TBL_VIDEOS B
            ON A.CODIGO_CANAL = B.CODIGO_CANAL
            WHERE A.CODIGO_USUARIO = P_CODIGO_USUARIO
        )
    ) LOOP
        V_HTML := V_HTML || '<tr><td>' || V_VIDEO.CODIGO_VIDEO || '</td><td>' || V_VIDEO.NOMBRE_VIDEO || '</td></tr>';
        -- V_HTML := V_HTML || '<tr>';
        -- V_HTML := V_HTML || '<td>' || V_VIDEO.CODIGO_VIDEO || '</td>';
        -- V_HTML := V_HTML || '<td>' || V_VIDEO.NOMBRE_VIDEO || '</td>';
        -- V_HTML := V_HTML || '</tr>';
    END LOOP;

    V_HTML := V_HTML || '</tbody>';
    V_HTML := V_HTML || '</table>';

    RETURN V_HTML;
END;


SELECT B.CODIGO_VIDEO, B.NOMBRE_VIDEO, B.CODIGO_CANAL
FROM TBL_USUARIOS_X_CANAL A
INNER JOIN TBL_VIDEOS B
ON A.CODIGO_CANAL = B.CODIGO_CANAL
WHERE A.CODIGO_USUARIO = 1;


DECLARE
    V_HTML VARCHAR2(4000);
BEGIN
    V_HTML := F_LISTA_VIDEOS_RECOMENDADOS(1);
    DBMS_OUTPUT.PUT_LINE(V_HTML);
END;



-- Desarrollar un procedimiento almacenado para guardar denuncias de videos P_DENUNCIAR_VIDEO, el
-- procedimiento debe recibir el video que se denunciará y toda la información relacionada. Se debe verificar si el
-- video existe y gestionarlo con excepciones personalizadas, enviar un parametro de salida con el estatus de la
-- ejecución del procedimiento.
-- Verificar si la cantidad de denuncias del video exceden las 5 denuncias, en caso de ser así se deberá cambiar el
-- estado del video a bloqueado, además se deberá enviar una notificación al dueño del video de que su video ha
-- sido denunciado y bloqueado.

SELECT * 
FROM TBL_DENUNCIAS;

SELECT * 
FROM TBL_TIPOS_DENUNCIAS;

SELECT *
FROM TBL_ESTADOS_DENUNCIAS;


CREATE SEQUENCE SEQ_CODIGO_DENUNCIA;

CREATE OR REPLACE PROCEDURE P_DENUNCIAR_VIDEO (
        P_CODIGO_TIPO_DENUNCIA TBL_DENUNCIAS.CODIGO_TIPO_DENUNCIA%TYPE,
        P_CODIGO_USUARIO TBL_DENUNCIAS.CODIGO_USUARIO%TYPE,
        P_CODIGO_VIDEO TBL_DENUNCIAS.CODIGO_VIDEO%TYPE,
        P_DESCRIPCION TBL_DENUNCIAS.DESCRIPCION%TYPE,
        P_ESTATUS_EJECICION OUT VARCHAR2
) IS
    V_CODIGO_DENUNCIA NUMBER;
    V_CANTIDAD_VIDEOS NUMBER;
    V_CANTIDAD_DENUNCIAS NUMBER;
    E_VIDEO_NO_EXISTE EXCEPTION;
BEGIN

    SELECT COUNT(*)
    INTO V_CANTIDAD_VIDEOS 
    FROM TBL_VIDEOS
    WHERE CODIGO_VIDEO = P_CODIGO_VIDEO;

    IF V_CANTIDAD_VIDEOS = 0 THEN
        RAISE E_VIDEO_NO_EXISTE;
    END IF;

    V_CODIGO_DENUNCIA := SEQ_CODIGO_DENUNCIA.NEXTVAL;
    INSERT INTO TBL_DENUNCIAS
    (   
        CODIGO_DENUNCIA,
        CODIGO_TIPO_DENUNCIA,
        CODIGO_ESTADO_DENUNCIA,
        CODIGO_USUARIO,
        CODIGO_VIDEO,
        DESCRIPCION,
        FECHA_DENUNCIA
    ) VALUES (
        V_CODIGO_DENUNCIA,
        P_CODIGO_TIPO_DENUNCIA,
        1,
        P_CODIGO_USUARIO,
        P_CODIGO_VIDEO,
        P_DESCRIPCION,
        SYSDATE
    );

    SELECT COUNT(*)
    INTO V_CANTIDAD_DENUNCIAS
    FROM TBL_DENUNCIAS
    WHERE CODIGO_VIDEO = P_CODIGO_VIDEO;

    IF V_CANTIDAD_DENUNCIAS >= 5 THEN
        UPDATE TBL_VIDEOS
        SET CODIGO_ESTADO_VIDEO = 2
        WHERE CODIGO_VIDEO = P_CODIGO_VIDEO;
    END IF;

    P_ESTATUS_EJECICION := 'DENUNCIA AGREGADA CON EXITO';
    COMMIT;

EXCEPTION
    WHEN E_VIDEO_NO_EXISTE THEN 
        P_ESTATUS_EJECICION := 'VIDEO NO EXISTE';
    WHEN OTHERS THEN 
        DBMS_OUTPUT.PUT_LINE ('OCURRIO UN ERROR: ' || SQLERRM || ' - ' || SQLCODE);
        P_ESTATUS_EJECICION := 'OCURRIO UN ERROR: ' || SQLERRM || ' - ' || SQLCODE;
END;

SELECT * FROM TBL_DENUNCIAS;
SELECT * FROM TBL_VIDEOS 
WHERE CODIGO_VIDEO = 1;


DECLARE
    V_ESTATUS_EJECICION VARCHAR2(1000);
BEGIN
    P_DENUNCIAR_VIDEO(
        P_CODIGO_TIPO_DENUNCIA => 1,
        P_CODIGO_USUARIO => 1,
        P_CODIGO_VIDEO => 1,
        P_DESCRIPCION => 'dIOMIO ESE VIDEO TIENE COSAS INDEVBBIDAS',
        P_ESTATUS_EJECICION => V_ESTATUS_EJECICION
    );

    DBMS_OUTPUT.PUT_LINE(V_ESTATUS_EJECICION);
END;