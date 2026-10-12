# Campus Placement and Recruitment Drive Management System

DBMS PBL Project 22 - C. Sai Ridhi (25WU0102055), Woxsen University.

An Oracle 19c database (13 tables in 3NF, two triggers, two views) with a Java JDBC console app and a JSP web portal (student and admin dashboards).

## Folders
- `database/project22_ddl.sql` - tables, constraints and both triggers (run as SYSTEM in ORCLPDB)
- `web-portal/` - JSP portal (copy to Tomcat `webapps`, add `ojdbc8.jar` to `WEB-INF/lib`)
- `java-console-app/` - Java JDBC console application
- `docs/` - project report (PDF)

## Run the portal
1. Run the DDL script, then load your sample data.
2. Replace `YOUR_DB_PASSWORD` in the JSP files (search for it) with your Oracle password.
3. Put `ojdbc8.jar` in `web-portal/WEB-INF/lib`, copy `web-portal` to Tomcat as `PlacementPortal`, start Tomcat.
4. Open http://localhost:8080/PlacementPortal/

Demo logins: student ID 101 to 105; admin / admin123 (hard-coded demo credentials).
