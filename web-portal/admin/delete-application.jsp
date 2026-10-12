<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%
    int appId = Integer.parseInt(request.getParameter("app_id"));
    int driveId = Integer.parseInt(request.getParameter("drive_id"));
    String msg;
    String type;
    Class.forName("oracle.jdbc.OracleDriver");
    Connection conn = DriverManager.getConnection(
        "jdbc:oracle:thin:@localhost:1521/ORCLPDB", "system", "YOUR_DB_PASSWORD");
    try {
        // One transaction: child rows (Result, Offer) must go before the parent Application row,
        // otherwise the foreign keys would raise ORA-02292.
        conn.setAutoCommit(false);
        String[] sqls = {
            "DELETE FROM Result WHERE app_id = ?",
            "DELETE FROM Offer WHERE app_id = ?",
            "DELETE FROM Application WHERE app_id = ?" };
        int appRows = 0;
        for (int i = 0; i < sqls.length; i++) {
            PreparedStatement ps = conn.prepareStatement(sqls[i]);
            ps.setInt(1, appId);
            int r = ps.executeUpdate();
            if (i == 2) appRows = r;
            ps.close();
        }
        conn.commit();
        msg = appRows == 1 ? "Application deleted (with its results and offer)." : "Application not found.";
        type = appRows == 1 ? "success" : "error";
    } catch (SQLException e) {
        conn.rollback();
        msg = "Could not delete: " + e.getMessage();
        type = "error";
    } finally {
        conn.close();
    }
    response.sendRedirect("drive-detail.jsp?drive_id=" + driveId
        + "&msg=" + java.net.URLEncoder.encode(msg, "UTF-8") + "&type=" + type);
%>
