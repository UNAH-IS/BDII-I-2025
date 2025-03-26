CREATE OR REPLACE PROCEDURE


begin
    dbms_scheduler.create_job (
        job_name => 'JOB_TEST',
        job_type => 'PLSQL_BLOCK',
        job_action => 'begin P_ETL_CAMPUS; end;',
        number_of_arguments => 0,
        start_date => sysdate + 2/24/59, -- sysdate + 10 minutos
        job_class => 'DEFAULT_JOB_CLASS', -- Priority Group
        enabled => TRUE,
        auto_drop => TRUE,
        comments => 'JOB de prueba'
    );
end;



SELECT * 
FROM  ALL_SCHEDULER_JOBS;

SELECT * FROM TBL_LOG_ETL;

SELECT * 
FROM ALL_TABLES
WHERE OWNER = 'C##HR';

SELECT *
FROM ALL_PROCEDURES;

SELECT TO_CHAR(SYSDATE, 'HH24:MI:SS')  FROM DUAL;


--INTERVALO DIARIO
begin
    dbms_scheduler.create_schedule
    (
        schedule_name => 'INTERVALO_DIARIO',
        start_date=> trunc(sysdate)+18/24, --CUANDO SE VA A HABILITAR POR PRIMER VEZ
        repeat_interval=> 'FREQ=DAILY; BYDAY=MON,TUE,WED,THU,FRI,SAT,SUN;BYHOUR=20;',
        comments=>'Ejecucion: Todos los dias a las 20:00'
    );
end;
/

-- intervalo cada hora
begin
    dbms_scheduler.create_schedule(
        schedule_name => 'INTERVALO_CADA_HORA',
        start_date => trunc(sysdate)+18/24, --CUANDO SE VA A HABILITAR POR PRIMER VEZ
        repeat_interval => 'freq=HOURLY;interval=1',
        comments => 'Ejecucion: cada hora'
    );
end;
/

-- intervalo cada 10 minutos
begin
    dbms_scheduler.create_schedule(
        schedule_name => 'INTERVALO_CADA_10_MINUTOS',
        start_date => trunc(sysdate)+18/24,
        repeat_interval => 'freq=MINUTELY;interval=10',
        comments => 'Ejecucion: cada 10 minutos'
    );
end;
/

-- todos los viernes a las 14:00
begin
    dbms_scheduler.create_schedule (
        schedule_name => 'INTERVALO_VIERNES_1400',
        start_date=> trunc(sysdate)+18/24,
        repeat_interval=> 'FREQ=DAILY; BYDAY=FRI; BYHOUR=14;',
        comments=>'Ejecucion: Cada viernes a las 14:00'
    );
end;


begin
    dbms_scheduler.create_schedule(
        schedule_name => 'INTERVALO_CADA_1_MINUTOS',
        start_date => sysdate,
        repeat_interval => 'freq=MINUTELY;interval=1',
        comments => 'Ejecucion: cada 1 minutos'
    );
end;


SELECT *
FROM ALL_SCHEDULER_SCHEDULES;



begin
    dbms_scheduler.create_program
    (
        program_name=> 'PROG_ETL_CAMPUS',
        program_type=> 'PLSQL_BLOCK',
        program_action=> 'begin P_ETL_CAMPUS; end;',
        enabled=>true,
        comments=>'Programa de ETL de CAMPUS'
    );
end;

SELECT *
FROM ALL_SCHEDULER_PROGRAMS;


begin
    dbms_scheduler.create_job(
        job_name => 'JOB_ETL_CAMPUS',
        program_name=> 'PROG_ETL_CAMPUS',
        schedule_name=>'INTERVALO_CADA_1_MINUTOS',
        enabled=>true,
        auto_drop=>false,
        comments=>'Job que ejecuta el procedimiento P_ETL_CAMPUS cada minuto'
    );
end;


SELECT *
FROM TBL_LOG_ETL
ORDER BY FECHA_HORA_INICIO DESC;