<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%
    int studentId = Integer.parseInt(request.getParameter("student_id"));
    int driveId = Integer.parseInt(request.getParameter("drive_id"));

    Class.forName("oracle.jdbc.OracleDriver");
    Connection conn = DriverManager.getConnection(
        "jdbc:oracle:thin:@localhost:1521/ORCLPDB", "system", "YOUR_DB_PASSWORD");

    String msg;
    String type;

    try {
        conn.setAutoCommit(false);

        // Generate the next app_id ourselves (simple approach: max + 1).
        // A production system would use a SEQUENCE for this.
        int newAppId = 1;
        PreparedStatement psMax = conn.prepareStatement("SELECT NVL(MAX(app_id), 0) + 1 FROM Application");
        ResultSet rsMax = psMax.executeQuery();
        if (rsMax.next()) newAppId = rsMax.getInt(1);
        rsMax.close(); psMax.close();

        PreparedStatement ps = conn.prepareStatement(
            "INSERT INTO Application (app_id, student_id, drive_id, applied_on) VALUES (?, ?, ?, SYSDATE)");
        ps.setInt(1, newAppId);
        ps.setInt(2, studentId);
        ps.setInt(3, driveId);
        ps.executeUpdate();
        ps.close();

        conn.commit();
        msg = "Application submitted successfully!";
        type = "success";

    } catch (SQLException e) {
        conn.rollback();
        if (e.getMessage().contains("ORA-20001")) {
            msg = "Could not apply: you do not meet the eligibility criteria for this drive.";
        } else if (e.getErrorCode() == 1) {
            msg = "Could not apply: you have already applied to this drive.";
        } else {
            msg = "Could not apply: " + e.getMessage();
        }
        type = "error";
    } finally {
        conn.close();
    }

    response.sendRedirect("dashboard.jsp?student_id=" + studentId
        + "&msg=" + java.net.URLEncoder.encode(msg, "UTF-8") + "&type=" + type);
%>
