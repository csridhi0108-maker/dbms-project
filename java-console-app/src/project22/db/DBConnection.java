package project22.db;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

/**
 * Single source of truth for how we connect to Oracle.
 *
 * WHY a separate class for this (and not just calling DriverManager
 * everywhere we need a connection)?
 *   1. If the password, host, or port ever changes, there is exactly
 *      ONE line to edit, not twenty scattered across the codebase.
 *   2. It keeps the credential out of your business logic and UI code
 *      entirely — PlacementService doesn't need to know HOW we connect,
 *      only that getConnection() gives it a working Connection.
 */
public class DBConnection {

    // jdbc:oracle:thin:@<host>:<port>/<service_name>
    // "thin" = Oracle's pure-Java driver (no native Oracle client needed)
    private static final String URL = "jdbc:oracle:thin:@localhost:1521/ORCLPDB";
    private static final String USER = "system";
    private static final String PASSWORD = "YOUR_DB_PASSWORD";

    public static Connection getConnection() throws SQLException {
        return DriverManager.getConnection(URL, USER, PASSWORD);
    }
}
