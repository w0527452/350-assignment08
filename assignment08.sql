BEGIN
    BEGIN
        EXECUTE IMMEDIATE 'DROP TABLE BC_EMPLOYEES CASCADE CONSTRAINTS';
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END;

    BEGIN
        EXECUTE IMMEDIATE 'DROP TABLE BC_PAYROLL CASCADE CONSTRAINTS';
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END;

    BEGIN
        EXECUTE IMMEDIATE 'DROP SEQUENCE employee_id_seq';
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END;
END;
/

create sequence employee_id_seq start with 1;

create table BC_EMPLOYEES
(
    EMPLOYEE_ID    NUMBER default employee_id_seq.nextval not null,
    LAST_NAME      VARCHAR2(30),
    FIRST_NAME     VARCHAR2(30),
    HOURS          NUMBER(9, 2),
    HOURLY_RATE    NUMBER(9, 2),
    TRANSPORT_CODE CHAR,
    constraint BC_EMPLOYEES_PK
        primary key (EMPLOYEE_ID),
    constraint VALID_HOURLY_RATE
        check (hourly_rate between 0 and 99.99),
    constraint VALID_HOURS
        check (hours between 0 and 99.99),
    constraint VALID_TRANSPORT
        check (transport_code IN ('P', 'T', 'L', 'N'))
);

create table BC_PAYROLL
(
    EMPLOYEE_ID   NUMBER,
    REG_HOURS     NUMBER(9, 2),
    OVT_HOURS     NUMBER(9, 2),
    GROSS_PAY     NUMBER(9, 2),
    TAXES         NUMBER(9, 2),
    TRANSPORT_FEE NUMBER(9, 2),
    NET_PAY       NUMBER(9, 2),
    constraint PAYROLL_EMPLOYEES_EMP_ID_FK
        foreign key (EMPLOYEE_ID) references BC_EMPLOYEES,
    constraint PAYROLL_GROSS_PAY_CHECK
        check (gross_pay between 0 and 9999.99),
    constraint PAYROLL_HOURS_CHECK
        check (reg_hours between 0 and 99.99),
    constraint PAYROLL_NET_PAY_CHECK
        check (net_pay between 0 and 9999.99),
    constraint PAYROLL_OVT_CHECK
        check (ovt_hours between 0 and 99.99),
    constraint PAYROLL_TAXES_CHECK
        check (taxes between 0 and 9999.99),
    constraint PAYROLL_TRANSPORT_CHECK
        check (transport_fee between 0 and 99.99)
);

INSERT INTO BC_EMPLOYEES (LAST_NAME, FIRST_NAME, HOURS, HOURLY_RATE, TRANSPORT_CODE)
VALUES ('Horsecollar', 'Horace', 38, 12.5, 'P');
INSERT INTO BC_EMPLOYEES (LAST_NAME, FIRST_NAME, HOURS, HOURLY_RATE, TRANSPORT_CODE)
VALUES ('Reins', 'Rachel', 46.5, 14.4, 'T');
INSERT INTO BC_EMPLOYEES (LAST_NAME, FIRST_NAME, HOURS, HOURLY_RATE, TRANSPORT_CODE)
VALUES ('Saddle', 'Samuel', 51, 40, 'N');


DECLARE
    dynamic_sql   VARCHAR2(1000);
    tax_rate      FLOAT := .28;
    regular_hours BC_EMPLOYEES.hours%TYPE;
    ot_hours      BC_EMPLOYEES.hours%TYPE;
    gross_pay     BC_EMPLOYEES.hourly_rate%TYPE;
    net_pay       BC_EMPLOYEES.hourly_rate%TYPE;
    transport_fee BC_EMPLOYEES.hourly_rate%TYPE;
    taxes         BC_EMPLOYEES.hourly_rate%TYPE;
    CURSOR employees_cursor IS select *
                               from BC_EMPLOYEES
                               order by FIRST_NAME ASC;
    employee_row  BC_EMPLOYEES%rowtype;
BEGIN
    FOR employee_row in employees_cursor
        LOOP
        --             if employee_row.hours > 40 then
--                 regular_hours := 40;
--                 ot_hours := employee_row.hours - 40;
--             else
--                 regular_hours := employee_row.hours;
--                 ot_hours := 0;
--             end if;

            regular_hours := case when employee_row.hours > 40 then 40 else employee_row.hours end;
            ot_hours := case when employee_row.hours > 40 then employee_row.hours - 40 else 0 end;

            transport_fee :=
                    CASE
                        WHEN employee_row.TRANSPORT_CODE = 'P' THEN 7.5
                        WHEN employee_row.TRANSPORT_CODE = 'T' THEN 5
                        WHEN employee_row.TRANSPORT_CODE = 'L' THEN 1
                        WHEN employee_row.TRANSPORT_CODE = 'N' THEN 0
                        END;

            gross_pay := regular_hours * employee_row.HOURLY_RATE + ot_hours * employee_row.HOURLY_RATE * 1.5;
            taxes := gross_pay * tax_rate;
            net_pay := gross_pay - taxes - transport_fee;
            --             DBMS_OUTPUT.PUT_LINE( employee_row.EMPLOYEE_ID || ' ' || employee_row.FIRST_NAME || ' ' || 'gross: ' || gross_pay || ' net: ' || net_pay ||
--                                  ' taxes: ' || taxes || ' transport: ' || transport_fee);

            dynamic_sql :=
                        'INSERT INTO BC_PAYROLL VALUES(' || employee_row.EMPLOYEE_ID || ', ' || regular_hours || ', ' ||
                        ot_hours || ', ' || gross_pay || ', ' || taxes || ', ' || transport_fee || ', ' || net_pay || ')';
            EXECUTE IMMEDIATE dynamic_sql;
        end loop;
END;
/