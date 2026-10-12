# Campus Placement Portal — Web App (JSP + JDBC)

Same deployment style as your Green Mobility project — this drops straight
into your existing XAMPP Tomcat.

## 1. Folder structure (already correct, don't rearrange)

```
PlacementPortal/
├── index.jsp                 <- landing page
├── css/style.css
├── student/
│   ├── login.jsp
│   ├── dashboard.jsp
│   └── apply.jsp
├── admin/
│   ├── login.jsp
│   ├── dashboard.jsp
│   ├── drive-detail.jsp
│   ├── enter-result.jsp
│   └── issue-offer.jsp
└── WEB-INF/
    └── lib/                  <- put ojdbc8.jar here
```

## 2. Deploy — 3 steps

**Step 1.** Copy the whole `PlacementPortal` folder into your Tomcat
webapps directory — the same place Green Mobility lives:

```
C:\xampp\tomcat\webapps\PlacementPortal
```

**Step 2.** Copy your Oracle driver jar into `WEB-INF\lib`:

```
copy "C:\Users\csrid\Downloads\WINDOWS.X64_193000_db_home\jdbc\lib\ojdbc8.jar" "C:\xampp\tomcat\webapps\PlacementPortal\WEB-INF\lib\"
```

**Step 3.** Restart Tomcat (via the XAMPP control panel — stop then start
the Tomcat service), then visit:

```
http://localhost:8080/PlacementPortal/
```

## 3. Login details

- **Student:** just enter a student ID — try `101`, `103`, or `105`
  (these have academic records and existing applications already).
- **Admin:** username `admin`, password `admin123` (hardcoded in
  `admin/login.jsp` for simplicity — a real system would store this in
  a table with a hashed password instead).

## 4. What to demo for Review 3

1. **Student 104** logging in and trying to apply to Drive 3 (FinEdge
   Analytics) — the eligibility badge will already show "Not Eligible,"
   and even if they try, the Apply button won't show since the page
   pre-checks eligibility. This demonstrates the UI respecting the same
   rule your database trigger enforces.
2. **Admin → Manage a drive → Enter Result** — try entering a result for
   a round the student hasn't reached yet (skip ahead) to show the
   round-sequence trigger rejecting it with a clean message on the page,
   not a raw Oracle error.
3. **Admin dashboard** — show the two report tables, and mention they're
   reading directly from the `vw_department_placement_stats` and
   `vw_company_offer_stats` views you built in Review 2. This is a great
   way to show continuity between Review 2 (DB-side work) and Review 3
   (application-side work) in your presentation.

## 5. If a page shows a raw Java error

Nearly always one of these:
- `ojdbc8.jar` isn't actually in `WEB-INF\lib` — double check the copy
  from Step 2 above.
- The Oracle pluggable database isn't open — same `ALTER PLUGGABLE
  DATABASE ORCLPDB OPEN;` fix we used in SQL*Plus applies here too, since
  it's the same database.
- Tomcat wasn't restarted after copying the jar — Tomcat only loads jars
  from `WEB-INF/lib` at startup.

Screenshot the error and send it over — same troubleshooting approach as
our SQL*Plus sessions.
