<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%
    int appId = Integer.parseInt(request.getParameter("app_id"));
    int driveId = Integer.parseInt(request.getParameter("drive_id"));

    Class.forName("oracle.jdbc.OracleDriver");
    Connection conn = DriverManager.getConnection(
        "jdbc:oracle:thin:@localhost:1521/ORCLPDB", "system", "YOUR_DB_PASSWORD");

    String msg;
    String type;

    try {
        conn.setAutoCommit(false);

        int newOfferId = 1;
        PreparedStatement psMax = conn.prepareStatement("SELECT NVL(MAX(offer_id), 0) + 1 FROM Offer");
        ResultSet rsMax = psMax.executeQuery();
        if (rsMax.next()) newOfferId = rsMax.getInt(1);
        rsMax.close(); psMax.close();

        PreparedStatement ps = conn.prepareStatement(
            "INSERT INTO Offer (offer_id, app_id, offer_date, status) VALUES (?, ?, SYSDATE, 'Pending')");
        ps.setInt(1, newOfferId);
        ps.setInt(2, appId);
        ps.executeUpdate();
        ps.close();

        conn.commit();
        msg = "Offer issued successfully.";
        type = "success";

    } catch (SQLException e) {
        conn.rollback();
        if (e.getErrorCode() == 1) {
            msg = "This application already has an offer.";
        } else {
            msg = "Could not issue offer: " + e.getMessage();
        }
        type = "error";
    } finally {
        conn.close();
    }

    response.sendRedirect("drive-detail.jsp?drive_id=" + driveId
        + "&msg=" + java.net.URLEncoder.encode(msg, "UTF-8") + "&type=" + type);
%>
