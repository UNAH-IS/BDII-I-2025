-- Crear una función llamada F_REGISTRAR_ARTISTA, que reciba como parámetros toda la información
-- relacionada. Debe verificar si el artista existe en base al nombre, en caso de no existir que lo cree, 
-- de lo contrario
-- que actualice la información relacionada al artista. Retornar el código del artista y un 
-- parámetro de salida con el mensaje de resultado.


CREATE SEQUENCE SEQ_CODIGO_ARTISTA;

CREATE OR REPLACE FUNCTION F_REGISTRAR_ARTISTA
(
    P_NOMBRE ARTISTAS.NOMBRE%TYPE, 
    P_NACIONALIDAD ARTISTAS.NACIONALIDAD%TYPE, 
    P_FECHA_NACIMIENTO ARTISTAS.FECHA_NACIMIENTO%TYPE,
    P_MENSAJE OUT VARCHAR2,
    P_CODIGO_RESULTADO OUT NUMBER
) RETURN NUMBER IS
    V_CODIGO_ARTISTA NUMBER;
BEGIN
    BEGIN
        SELECT ID_ARTISTA 
        INTO V_CODIGO_ARTISTA
        FROM ARTISTAS
        WHERE NOMBRE = P_NOMBRE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            V_CODIGO_ARTISTA := NULL;
    END;


    IF (V_CODIGO_ARTISTA IS NULL) THEN
        V_CODIGO_ARTISTA := SEQ_CODIGO_ARTISTA.NEXTVAL;

        INSERT INTO ARTISTAS
        (
            ID_ARTISTA,
            NOMBRE,
            NACIONALIDAD,
            FECHA_NACIMIENTO
        ) VALUES (
            V_CODIGO_ARTISTA,
            P_NOMBRE,
            P_NACIONALIDAD,
            P_FECHA_NACIMIENTO
        );
        P_CODIGO_RESULTADO := 1;
        P_MENSAJE := 'Artista registrado correctamente';
    ELSE 
        UPDATE ARTISTAS
        SET
            NACIONALIDAD = P_NACIONALIDAD,
            FECHA_NACIMIENTO = P_FECHA_NACIMIENTO
        WHERE ID_ARTISTA = V_CODIGO_ARTISTA;

        P_CODIGO_RESULTADO := 2;
        P_MENSAJE := 'Artista ACTUALIZADO correctamente';
    END IF;

    
    RETURN V_CODIGO_ARTISTA;
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        P_MENSAJE := 'Error al registrar el artista';
        P_CODIGO_RESULTADO := 0;
        RETURN 0;
END;

--PROBAR FUNCION
DECLARE
    V_MENSAJE VARCHAR2(100);
    V_CODIGO_RESULTADO NUMBER;
    V_CODIGO_ARTISTA NUMBER;
BEGIN
    V_CODIGO_ARTISTA := F_REGISTRAR_ARTISTA('Juan Gabriel', 'Hondure~no', '07/01/1950', V_MENSAJE, V_CODIGO_RESULTADO);
    DBMS_OUTPUT.PUT_LINE('CODIGO ARTISTA: ' || V_CODIGO_ARTISTA);
    DBMS_OUTPUT.PUT_LINE(V_MENSAJE);
    DBMS_OUTPUT.PUT_LINE(V_CODIGO_RESULTADO);
END;

SELECT * FROM ARTISTAS;

SELECT SEQ_CODIGO_ARTISTA.CURRVAL FROM DUAL;


-- 2. Crear un procedimiento almacenado llamado P_AGREGAR_REPRODUCCION que reciba como parámetro el
-- correo electrónico del usuario el id de la canción y la duración de la reproducción. 
-- Deberá obtener el id del
-- usuario en base al correo electrónico, en caso de no existir lanzar una excepción personalizada. Crear la
-- secuencia correspondiente para el identificador de la reproducción. Por cada nueva reproducción se debe
-- incrementar en uno el campo de cantidad de reproducciones de la tabla canciones y de la tabla estadísticas(esta
-- tabla guarda las estadísticas por usuario, por lo cual se debe incrementar solo las estadísticas de ese usuario).
-- Verificar que la canción exista, de lo contrario lanzar una excepción personalizada. Enviar dos parámetros de
-- salida, el primero sería el código de la reproducción y el segundo un mensaje del resultado de la ejecución del
-- procedimiento (ya sea exitoso o fallido).

DROP SEQUENCE SEQ_CODIGO_REPRODUCCION;
CREATE SEQUENCE SEQ_CODIGO_REPRODUCCION START WITH 16;

CREATE OR REPLACE PROCEDURE P_AGREGAR_REPRODUCCION
(
    P_CORREO_USUARIO USUARIOS.CORREO%TYPE,
    P_ID_CANCION CANCIONES.ID_CANCION%TYPE,
    P_DURACION_REPRODUCCION CANCIONES.DURACION_SEGUNDOS%TYPE,
    P_ID_REPRODUCCION OUT NUMBER,
    P_MENSAJE OUT VARCHAR2
) IS
    V_ID_USUARIO USUARIOS.ID_USUARIO%TYPE;
    V_ID_CANCION CANCIONES.ID_CANCION%TYPE;
    V_CANTIDAD_ESTADISTICAS NUMBER;
    V_USUARIO_NO_EXISTE EXCEPTION;
    V_CANCION_NO_EXISTE EXCEPTION;
BEGIN
    BEGIN
        SELECT ID_USUARIO
        INTO V_ID_USUARIO
        FROM USUARIOS
        WHERE CORREO = P_CORREO_USUARIO;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE V_USUARIO_NO_EXISTE;
    END;

    BEGIN
        SELECT ID_CANCION
        INTO V_ID_CANCION
        FROM CANCIONES
        WHERE ID_CANCION = P_ID_CANCION;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE V_CANCION_NO_EXISTE;
    END;    

    P_ID_REPRODUCCION := SEQ_CODIGO_REPRODUCCION.NEXTVAL;

    INSERT INTO REPRODUCCIONES(
        ID_REPRODUCCION,
        ID_USUARIO,
        ID_CANCION,
        FECHA_REPRODUCCION,
        DURACION_REPRODUCCION_SEGUNDOS
    ) VALUES (
        P_ID_REPRODUCCION,
        V_ID_USUARIO,
        P_ID_CANCION,
        SYSDATE,
        P_DURACION_REPRODUCCION
    );

    UPDATE CANCIONES
    SET
        CANTIDAD_REPRODUCCIONES = CANTIDAD_REPRODUCCIONES + 1
    WHERE ID_CANCION = P_ID_CANCION;

    SELECT COUNT(*)
    INTO V_CANTIDAD_ESTADISTICAS
    FROM ESTADISTICAS
    WHERE ID_USUARIO = V_ID_USUARIO;

    IF (V_CANTIDAD_ESTADISTICAS = 0) THEN
        INSERT INTO ESTADISTICAS(
            ID_USUARIO,
            ID_CANCION,
            CANTIDAD_REPRODUCCIONES,
            CANTIDAD_MINUTOS_REPRODUCCION,
            FECHA_ULTIMA_REPRODUCCION
        ) VALUES (
            V_ID_USUARIO,
            P_ID_CANCION,
            1,
            P_DURACION_REPRODUCCION / 60,
            SYSDATE
        );
    ELSE 
        UPDATE ESTADISTICAS
        SET
            CANTIDAD_REPRODUCCIONES = CANTIDAD_REPRODUCCIONES + 1,
            CANTIDAD_MINUTOS_REPRODUCCION = CANTIDAD_MINUTOS_REPRODUCCION + (P_DURACION_REPRODUCCION / 60),
            FECHA_ULTIMA_REPRODUCCION = SYSDATE
        WHERE ID_USUARIO = V_ID_USUARIO
        AND ID_CANCION = P_ID_CANCION;
    END IF;
    P_MENSAJE := 'Reproducción agregada correctamente';
    COMMIT;

EXCEPTION
    WHEN V_USUARIO_NO_EXISTE THEN
        P_MENSAJE := 'Usuario no encontrado';
        P_ID_REPRODUCCION := 0;
        ROLLBACK;
    WHEN V_CANCION_NO_EXISTE THEN
        P_MENSAJE := 'Canción no encontrada';
        P_ID_REPRODUCCION := 0;
        ROLLBACK;
    WHEN OTHERS THEN
        P_MENSAJE := 'Error al agregar la reproducción ' || SQLERRM;
        P_ID_REPRODUCCION := 0;    
        ROLLBACK;
END;


SET SERVEROUTPUT ON;    
--PROBAR PROCEDIMIENTO
DECLARE
    V_MENSAJE VARCHAR2(100);
    V_CODIGO_REPRODUCCION NUMBER;
BEGIN
    P_AGREGAR_REPRODUCCION(
        P_CORREO_USUARIO => 'alex@example.com', --3
        P_ID_CANCION => 1,
        P_DURACION_REPRODUCCION => 120, 
        P_ID_REPRODUCCION => V_CODIGO_REPRODUCCION,
        P_MENSAJE => V_MENSAJE
    );
    DBMS_OUTPUT.PUT_LINE('MENSAJE:  ' || V_MENSAJE);
    DBMS_OUTPUT.PUT_LINE('CODIGO REPRODUCCION' || V_CODIGO_REPRODUCCION);
END;


SELECT * FROM REPRODUCCIONES;
SELECT * FROM USUARIOS;
SELECT * FROM CANCIONES
WHERE ID_CANCION = 1; --5


SELECT * FROM ESTADISTICAS
WHERE ID_USUARIO = 3;

