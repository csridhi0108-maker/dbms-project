# Project 22 — Campus Placement Management System (Java front-end)

## 1. Folder structure

```
project22-app/
├── src/
│   └── project22/
│       ├── db/
│       │   └── DBConnection.java      <- JDBC URL + credentials, one place
│       ├── service/
│       │   └── PlacementService.java  <- business logic, SQL, transactions
│       └── ui/
│           └── Main.java              <- console menu
└── README.md
```

## 2. One thing you need to download: the Oracle JDBC driver

Your Java code talks to Oracle through a **driver** — a .jar file that
translates `java.sql` calls into Oracle's actual network protocol. It's
not bundled with Java, and I can't download it for you (your Oracle
install already includes it locally).

It's already sitting on your machine inside the Oracle installation.
Look for a file named **ojdbc8.jar** or **ojdbc11.jar** here (adjust for
your actual install path):

```
C:\app\<your-username>\product\19.0.0\dbhome_1\jdbc\lib\ojdbc8.jar
```

If you can't find it, download it from Oracle's official site:
https://www.oracle.com/database/technologies/appdev/jdbc-downloads.html
(pick the version matching your Oracle 19c install — ojdbc8.jar works
for Java 8+).

Copy that jar into your `project22-app` folder so it's easy to reference.

## 3. Compile

From inside `project22-app`, open Command Prompt and run:

```
javac -cp ojdbc8.jar -d out src\project22\db\DBConnection.java src\project22\service\PlacementService.java src\project22\ui\Main.java
```

This should finish with no output (no errors = success). It creates an
`out` folder with the compiled `.class` files.

## 4. Run

```
java -cp "out;ojdbc8.jar" project22.ui.Main
```

(Windows uses `;` to separate classpath entries; Mac/Linux would use `:`
instead — but you're on Windows based on our terminal sessions, so use `;`.)

You should see the menu:

```
===== Campus Placement Management System =====
1. View eligible students for a drive
2. Apply a student to a drive
3. Enter a round result
4. Issue an offer
5. Department-wise placement report
6. Company-wise offer report
7. Exit
Choose an option:
```

## 5. Things to try that double as a demo for Review 3

- **Option 1**, drive ID `3` → shows only students meeting FinEdge
  Analytics' strict criteria (CGPA ≥ 8.0, 0 backlogs) — a clean way to
  show eligibility logic live.
- **Option 2**, try applying student `104` to drive `3` again (app ID
  can be anything new, e.g. `99`) → you'll see the app catch the
  trigger's rejection with a clean message instead of a crash. This is
  the single best thing to demo — it proves the Java layer and the
  database layer are both doing their job.
- **Option 5** and **Option 6** → pull straight from the views you
  built in Review 2, so this is a nice bridge showing continuity between
  reviews.

## 6. If you get "No suitable driver found"

That means the classpath isn't pointing at the jar correctly — double
check the jar's exact filename and that you're in the same folder when
running the `java` command, or use the jar's full path instead of just
`ojdbc8.jar`.
