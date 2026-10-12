package project22.service;

import project22.db.DBConnection;
import java.sql.*;

/**
 * All the placement-drive business operations live here.
 *
 * WHY PreparedStatement everywhere instead of building SQL strings
 * with +concatenation?
 *   If we wrote:  "SELECT * FROM Student WHERE name = '" + userInput + "'"
 *   a user typing  ' OR '1'='1  as their name would rewrite our query's
 *   logic entirely (classic SQL injection). PreparedStatement sends the
 *   SQL and the data as two SEPARATE things to Oracle, so user input is
 *   always treated as a literal value, never as part of the query.
 */
public class PlacementService {

    // ---------------------------------------------------------------
    // 1. ELIGIBILITY CHECK (read-only — just a SELECT, no transaction
    //    needed, since we aren't changing any data)
    // ---------------------------------------------------------------
    public void showEligibleStudents(int driveId) throws SQLException {
        String sql =
            "SELECT s.student_id, s.name, ar.cgpa, ar.backlogs " +
            "FROM Student s " +
            "JOIN Academic_Record ar ON s.student_id = ar.student_id " +
            "JOIN Eligibility_Criteria ec ON ec.drive_id = ?            " +
            "WHERE ar.cgpa >= ec.min_cgpa AND ar.backlogs <= ec.max_backlogs";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, driveId);

            try (ResultSet rs = ps.executeQuery()) {
                System.out.printf("%-6s %-20s %-6s %-8s%n", "ID", "Name", "CGPA", "Backlogs");
                boolean any = false;
                while (rs.next()) {
                    any = true;
                    System.out.printf("%-6d %-20s %-6.2f %-8d%n",
                        rs.getInt("student_id"),
                        rs.getString("name"),
                        rs.getDouble("cgpa"),
                        rs.getInt("backlogs"));
                }
                if (!any) System.out.println("No eligible students found for this drive.");
            }
        }
    }

    // ---------------------------------------------------------------
    // 2. APPLY TO A DRIVE
    //
    // WHY wrap this in a transaction (setAutoCommit(false) ... commit)
    // even though it's a single INSERT?
    //   Right now it IS just one statement. But in a real system this
    //   is exactly the kind of operation that grows — e.g. "insert the
    //   application AND log an audit record AND send a notification."
    //   If step 2 failed after step 1 succeeded, auto-commit mode would
    //   leave you with a half-done, inconsistent state. Wrapping it now
    //   means the pattern is already correct when the operation grows.
    //
    // WHY the try/catch around a SQLException specifically?
    //   Your trg_check_eligibility trigger in Oracle calls
    //   RAISE_APPLICATION_ERROR(-20001, ...) when a student doesn't
    //   qualify. JDBC surfaces that as a SQLException whose getMessage()
    //   contains "ORA-20001". We catch it here and show a clean message
    //   instead of letting a raw stack trace reach the user.
    // ---------------------------------------------------------------
    public void applyToDrive(int appId, int studentId, int driveId) {
        String sql = "INSERT INTO Application (app_id, student_id, drive_id, applied_on) " +
                     "VALUES (?, ?, ?, SYSDATE)";

        try (Connection conn = DBConnection.getConnection()) {
            conn.setAutoCommit(false);  // start transaction

            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setInt(1, appId);
                ps.setInt(2, studentId);
                ps.setInt(3, driveId);
                ps.executeUpdate();

                conn.commit();  // all good — make it permanent
                System.out.println("Application submitted successfully.");

            } catch (SQLException e) {
                conn.rollback();  // undo the transaction — nothing is saved

                if (e.getMessage().contains("ORA-20001")) {
                    System.out.println("Rejected: student does not meet the eligibility "
                        + "criteria for this drive.");
                } else if (e.getErrorCode() == 1) { // ORA-00001 unique constraint violated
                    System.out.println("Rejected: this student has already applied to this drive.");
                } else {
                    System.out.println("Could not submit application: " + e.getMessage());
                }
            }
        } catch (SQLException connEx) {
            System.out.println("Database connection error: " + connEx.getMessage());
        }
    }

    // ---------------------------------------------------------------
    // 3. ENTER A ROUND RESULT
    //
    // Same pattern as applyToDrive: transaction wrapper, and a catch
    // specifically for trg_check_round_sequence (ORA-20002 / ORA-20003).
    // ---------------------------------------------------------------
    public void enterRoundResult(int appId, int roundId, String status) {
        String sql = "INSERT INTO Result (app_id, round_id, status) VALUES (?, ?, ?)";

        try (Connection conn = DBConnection.getConnection()) {
            conn.setAutoCommit(false);

            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setInt(1, appId);
                ps.setInt(2, roundId);
                ps.setString(3, status);
                ps.executeUpdate();

                conn.commit();
                System.out.println("Result recorded successfully.");

            } catch (SQLException e) {
                conn.rollback();

                if (e.getMessage().contains("ORA-20002") || e.getMessage().contains("ORA-20003")) {
                    System.out.println("Rejected: this student has not passed the "
                        + "previous round yet, so this round cannot be entered.");
                } else {
                    System.out.println("Could not record result: " + e.getMessage());
                }
            }
        } catch (SQLException connEx) {
            System.out.println("Database connection error: " + connEx.getMessage());
        }
    }

    // ---------------------------------------------------------------
    // 4. ISSUE AN OFFER
    // ---------------------------------------------------------------
    public void issueOffer(int offerId, int appId, String status) {
        String sql = "INSERT INTO Offer (offer_id, app_id, offer_date, status) " +
                     "VALUES (?, ?, SYSDATE, ?)";

        try (Connection conn = DBConnection.getConnection()) {
            conn.setAutoCommit(false);

            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setInt(1, offerId);
                ps.setInt(2, appId);
                ps.setString(3, status);
                ps.executeUpdate();

                conn.commit();
                System.out.println("Offer issued successfully.");

            } catch (SQLException e) {
                conn.rollback();
                if (e.getErrorCode() == 1) {
                    System.out.println("Rejected: this application already has an offer.");
                } else {
                    System.out.println("Could not issue offer: " + e.getMessage());
                }
            }
        } catch (SQLException connEx) {
            System.out.println("Database connection error: " + connEx.getMessage());
        }
    }

    // ---------------------------------------------------------------
    // 5. REPORTS — reading from the views you already created in Review 2
    //
    // WHY query the VIEW instead of repeating the big JOIN here?
    //   The view already encapsulates the join/aggregation logic in the
    //   database. The Java code just asks for the answer, which keeps
    //   this class focused on "how to talk to the app," not "how to
    //   compute placement stats" (that logic lives in one place: the view).
    // ---------------------------------------------------------------
    public void showDepartmentWiseReport() throws SQLException {
        String sql = "SELECT * FROM vw_department_placement_stats";
        printTwoColumnReport(sql, "Department", "Offers Made");
    }

    public void showCompanyWiseReport() throws SQLException {
        String sql = "SELECT company_name, role, offers_made FROM vw_company_offer_stats";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            System.out.printf("%-25s %-25s %-12s%n", "Company", "Role", "Offers Made");
            while (rs.next()) {
                System.out.printf("%-25s %-25s %-12d%n",
                    rs.getString("company_name"),
                    rs.getString("role"),
                    rs.getInt("offers_made"));
            }
        }
    }

    private void printTwoColumnReport(String sql, String col1Label, String col2Label) throws SQLException {
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            System.out.printf("%-25s %-12s%n", col1Label, col2Label);
            while (rs.next()) {
                System.out.printf("%-25s %-12d%n", rs.getString(1), rs.getInt(2));
            }
        }
    }
}
