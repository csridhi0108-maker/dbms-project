<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%
    String q = request.getParameter("q") == null ? "" : request.getParameter("q");
    String msg;
    String type;
    Connection conn = null;
    try {
        int studentId = Integer.parseInt(request.getParameter("student_id"));
        double cgpa = Double.parseDouble(request.getParameter("cgpa"));
        int backlogs = Integer.parseInt(request.getParameter("backlogs"));

        // Validation in the application layer (the CHECK constraints are the second line of defence)
        if (cgpa < 0 || cgpa > 10) throw new IllegalArgumentException("CGPA must be between 0 and 10.");
        if (backlogs < 0) throw new IllegalArgumentException("Backlogs cannot be negative.");

        Class.forName("oracle.jdbc.OracleDriver");
        conn = DriverManager.getConnection(
            "jdbc:oracle:thin:@localhost:1521/ORCLPDB", "system", "YOUR_DB_PASSWORD");
        conn.setAutoCommit(false);
        PreparedStatement ps = conn.prepareStatement(
            "UPDATE Academic_Record SET cgpa = ?, backlogs = ? WHERE student_id = ?");
        ps.setDouble(1, cgpa);
        ps.setInt(2, backlogs);
        ps.setInt(3, studentId);
        int rows = ps.executeUpdate();
        ps.close();
        conn.commit();
        msg = rows == 1 ? "Academic record updated for student " + studentId + "." : "No such student.";
        type = rows == 1 ? "success" : "error";
    } catch (NumberFormatException e) {
        msg = "Please enter valid numbers for CGPA and backlogs.";
        type = "error";
    } catch (IllegalArgumentException e) {
        msg = e.getMessage();
        type = "error";
    } catch (SQLException e) {
        if (conn != null) conn.rollback();
        msg = e.getMessage().contains("ORA-02290") ? "Update rejected by a database CHECK constraint." : "Could not update: " + e.getMessage();
        type = "error";
    } finally {
        if (conn != null) conn.close();
    }
    response.sendRedirect("students.jsp?q=" + java.net.URLEncoder.encode(q, "UTF-8")
        + "&msg=" + java.net.URLEncoder.encode(msg, "UTF-8") + "&type=" + type);
%>
