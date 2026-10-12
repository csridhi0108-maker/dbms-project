<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%
    int appId = Integer.parseInt(request.getParameter("app_id"));
    int driveId = Integer.parseInt(request.getParameter("drive_id"));
    int roundId = Integer.parseInt(request.getParameter("round_id"));
    String status = request.getParameter("status");

    Class.forName("oracle.jdbc.OracleDriver");
    Connection conn = DriverManager.getConnection(
        "jdbc:oracle:thin:@localhost:1521/ORCLPDB", "system", "YOUR_DB_PASSWORD");

    String msg;
    String type;

    try {
        conn.setAutoCommit(false);
        PreparedStatement ps = conn.prepareStatement(
            "INSERT INTO Result (app_id, round_id, status) VALUES (?, ?, ?)");
        ps.setInt(1, appId);
        ps.setInt(2, roundId);
        ps.setString(3, status);
        ps.executeUpdate();
        ps.close();

        conn.commit();
        msg = "Result recorded successfully.";
        type = "success";

    } catch (SQLException e) {
        conn.rollback();
        if (e.getMessage().contains("ORA-20002") || e.getMessage().contains("ORA-20003")) {
            msg = "Could not record result: this student has not passed the previous round yet.";
        } else if (e.getErrorCode() == 1) {
            msg = "A result for this round has already been recorded.";
        } else {
            msg = "Could not record result: " + e.getMessage();
        }
        type = "error";
    } finally {
        conn.close();
    }

    response.sendRedirect("drive-detail.jsp?drive_id=" + driveId
        + "&msg=" + java.net.URLEncoder.encode(msg, "UTF-8") + "&type=" + type);
%>
