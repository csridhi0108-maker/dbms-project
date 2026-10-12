-- =====================================================================
-- PROJECT 22 — Campus Placement & Recruitment Drive Management System
-- Oracle 19c DDL — run as SYSTEM, connected to ORCLPDB
-- Run top to bottom: parent tables are created before the tables that
-- reference them via foreign keys.
-- =====================================================================

-- 1. DEPARTMENT -------------------------------------------------------
CREATE TABLE Department (
    dept_id     NUMBER PRIMARY KEY,
    dept_name   VARCHAR2(50) NOT NULL,
    dept_code   VARCHAR2(10) UNIQUE
);

-- 2. STUDENT ------------------------------------------------------------
CREATE TABLE Student (
    student_id  NUMBER PRIMARY KEY,
    name        VARCHAR2(60) NOT NULL,
    dept_id     NUMBER NOT NULL,
    email       VARCHAR2(80) UNIQUE,
    CONSTRAINT fk_student_dept FOREIGN KEY (dept_id)
        REFERENCES Department(dept_id)
);

-- 3. ACADEMIC_RECORD ----------------------------------------------------
CREATE TABLE Academic_Record (
    record_id   NUMBER PRIMARY KEY,
    student_id  NUMBER NOT NULL UNIQUE,          -- 1:1 with Student
    cgpa        NUMBER(3,2) NOT NULL,
    backlogs    NUMBER(2) DEFAULT 0 NOT NULL,
    CONSTRAINT fk_record_student FOREIGN KEY (student_id)
        REFERENCES Student(student_id),
    CONSTRAINT chk_cgpa CHECK (cgpa BETWEEN 0 AND 10),
    CONSTRAINT chk_backlogs CHECK (backlogs >= 0)
);

-- 4. SKILL ----------------------------------------------------------------
CREATE TABLE Skill (
    skill_id    NUMBER PRIMARY KEY,
    skill_name  VARCHAR2(50) NOT NULL UNIQUE
);

-- 5. STUDENT_SKILL (junction, M:N) ----------------------------------------
CREATE TABLE Student_Skill (
    student_id  NUMBER NOT NULL,
    skill_id    NUMBER NOT NULL,
    CONSTRAINT pk_student_skill PRIMARY KEY (student_id, skill_id),
    CONSTRAINT fk_ss_student FOREIGN KEY (student_id)
        REFERENCES Student(student_id),
    CONSTRAINT fk_ss_skill FOREIGN KEY (skill_id)
        REFERENCES Skill(skill_id)
);

-- 6. COMPANY ----------------------------------------------------------------
CREATE TABLE Company (
    company_id  NUMBER PRIMARY KEY,
    name        VARCHAR2(80) NOT NULL,
    sector      VARCHAR2(50)
);

-- 7. JOB_PROFILE --------------------------------------------------------------
CREATE TABLE Job_Profile (
    profile_id  NUMBER PRIMARY KEY,
    company_id  NUMBER NOT NULL,
    role        VARCHAR2(60) NOT NULL,
    package_lpa NUMBER(5,2),
    CONSTRAINT fk_profile_company FOREIGN KEY (company_id)
        REFERENCES Company(company_id)
);

-- 8. DRIVE ----------------------------------------------------------------------
CREATE TABLE Drive (
    drive_id    NUMBER PRIMARY KEY,
    profile_id  NUMBER NOT NULL,
    drive_date  DATE NOT NULL,
    CONSTRAINT fk_drive_profile FOREIGN KEY (profile_id)
        REFERENCES Job_Profile(profile_id)
);

-- 9. ELIGIBILITY_CRITERIA (1:1 with Drive) ---------------------------------------
CREATE TABLE Eligibility_Criteria (
    drive_id        NUMBER PRIMARY KEY,
    min_cgpa        NUMBER(3,2) NOT NULL,
    max_backlogs    NUMBER(2) DEFAULT 0,
    CONSTRAINT fk_elig_drive FOREIGN KEY (drive_id)
        REFERENCES Drive(drive_id),
    CONSTRAINT chk_min_cgpa CHECK (min_cgpa BETWEEN 0 AND 10)
);

-- 10. APPLICATION -------------------------------------------------------------------
CREATE TABLE Application (
    app_id      NUMBER PRIMARY KEY,
    student_id  NUMBER NOT NULL,
    drive_id    NUMBER NOT NULL,
    applied_on  DATE DEFAULT SYSDATE,
    CONSTRAINT fk_app_student FOREIGN KEY (student_id)
        REFERENCES Student(student_id),
    CONSTRAINT fk_app_drive FOREIGN KEY (drive_id)
        REFERENCES Drive(drive_id),
    CONSTRAINT uq_student_drive UNIQUE (student_id, drive_id)   -- one application per student per drive
);

-- 11. PLACEMENT_ROUND -----------------------------------------------------------------------
CREATE TABLE Placement_Round (
    round_id    NUMBER PRIMARY KEY,
    drive_id    NUMBER NOT NULL,
    round_no    NUMBER(2) NOT NULL,
    round_type  VARCHAR2(30) NOT NULL,     -- e.g. 'Aptitude', 'GD', 'Technical', 'HR'
    CONSTRAINT fk_round_drive FOREIGN KEY (drive_id)
        REFERENCES Drive(drive_id),
    CONSTRAINT uq_drive_roundno UNIQUE (drive_id, round_no)
);

-- 12. RESULT ------------------------------------------------------------------------
CREATE TABLE Result (
    app_id      NUMBER NOT NULL,
    round_id    NUMBER NOT NULL,
    status      VARCHAR2(10) NOT NULL,     -- 'Pass' / 'Fail'
    CONSTRAINT pk_result PRIMARY KEY (app_id, round_id),
    CONSTRAINT fk_result_app FOREIGN KEY (app_id)
        REFERENCES Application(app_id),
    CONSTRAINT fk_result_round FOREIGN KEY (round_id)
        REFERENCES Placement_Round(round_id),
    CONSTRAINT chk_status CHECK (status IN ('Pass', 'Fail'))
);

-- 13. OFFER -------------------------------------------------------------------------
CREATE TABLE Offer (
    offer_id    NUMBER PRIMARY KEY,
    app_id      NUMBER NOT NULL UNIQUE,     -- at most one offer per application
    offer_date  DATE DEFAULT SYSDATE,
    status      VARCHAR2(10) DEFAULT 'Pending',
    CONSTRAINT fk_offer_app FOREIGN KEY (app_id)
        REFERENCES Application(app_id),
    CONSTRAINT chk_offer_status CHECK (status IN ('Pending', 'Accepted', 'Rejected'))
);

-- =====================================================================
-- TRIGGER 1: enforce eligibility at the moment a student applies
-- =====================================================================
CREATE OR REPLACE TRIGGER trg_check_eligibility
BEFORE INSERT ON Application
FOR EACH ROW
DECLARE
    v_cgpa      Academic_Record.cgpa%TYPE;
    v_backlogs  Academic_Record.backlogs%TYPE;
    v_min_cgpa  Eligibility_Criteria.min_cgpa%TYPE;
    v_max_back  Eligibility_Criteria.max_backlogs%TYPE;
BEGIN
    SELECT cgpa, backlogs INTO v_cgpa, v_backlogs
    FROM Academic_Record WHERE student_id = :NEW.student_id;

    SELECT min_cgpa, max_backlogs INTO v_min_cgpa, v_max_back
    FROM Eligibility_Criteria WHERE drive_id = :NEW.drive_id;

    IF v_cgpa < v_min_cgpa OR v_backlogs > v_max_back THEN
        RAISE_APPLICATION_ERROR(-20001, 'Student does not meet eligibility criteria for this drive.');
    END IF;
END;
/

-- =====================================================================
-- TRIGGER 2: enforce that a student can only enter a round after
-- passing the previous round of the same drive
-- =====================================================================
CREATE OR REPLACE TRIGGER trg_check_round_sequence
BEFORE INSERT ON Result
FOR EACH ROW
DECLARE
    v_round_no      Placement_Round.round_no%TYPE;
    v_drive_id      Drive.drive_id%TYPE;
    v_prev_round_id Placement_Round.round_id%TYPE;
    v_prev_status   Result.status%TYPE;
BEGIN
    SELECT round_no, drive_id INTO v_round_no, v_drive_id
    FROM Placement_Round WHERE round_id = :NEW.round_id;

    IF v_round_no > 1 THEN
        SELECT round_id INTO v_prev_round_id
        FROM Placement_Round WHERE drive_id = v_drive_id AND round_no = v_round_no - 1;

        SELECT status INTO v_prev_status
        FROM Result WHERE app_id = :NEW.app_id AND round_id = v_prev_round_id;

        IF v_prev_status != 'Pass' THEN
            RAISE_APPLICATION_ERROR(-20002, 'Cannot enter this round without passing the previous round.');
        END IF;
    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20003, 'Previous round result not found — student has not cleared the prior stage.');
END;
/

-- Quick sanity check after running everything above:
-- SELECT table_name FROM user_tables ORDER BY table_name;
