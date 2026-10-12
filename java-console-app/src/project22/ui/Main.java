package project22.ui;

import project22.service.PlacementService;
import java.sql.SQLException;
import java.util.Scanner;

/**
 * The menu loop. Notice this class never writes a single line of SQL —
 * that's deliberate. Its only job is: read what the user typed, hand it
 * to PlacementService, print whatever comes back. If you ever swapped
 * this console menu for a GUI (Swing) or a web page later, NONE of
 * PlacementService or DBConnection would need to change.
 */
public class Main {

    public static void main(String[] args) {

        // Loads the Oracle JDBC driver into memory so DriverManager
        // knows how to handle "jdbc:oracle:thin:..." URLs.
        // (Modern JDBC drivers often auto-register, but calling this
        // explicitly avoids surprises on older setups.)
        try {
            Class.forName("oracle.jdbc.OracleDriver");
        } catch (ClassNotFoundException e) {
            System.out.println("Oracle JDBC driver not found on the classpath.");
            System.out.println("Make sure ojdbc8.jar (or ojdbc11.jar) is included — see README.");
            return;
        }

        PlacementService service = new PlacementService();
        Scanner sc = new Scanner(System.in);
        boolean running = true;

        while (running) {
            System.out.println("\n===== Campus Placement Management System =====");
            System.out.println("1. View eligible students for a drive");
            System.out.println("2. Apply a student to a drive");
            System.out.println("3. Enter a round result");
            System.out.println("4. Issue an offer");
            System.out.println("5. Department-wise placement report");
            System.out.println("6. Company-wise offer report");
            System.out.println("7. Exit");
            System.out.print("Choose an option: ");

            String choice = sc.nextLine().trim();

            try {
                switch (choice) {
                    case "1" -> {
                        int driveId = readInt(sc, "Enter drive ID: ");
                        service.showEligibleStudents(driveId);
                    }
                    case "2" -> {
                        int appId = readInt(sc, "Enter new application ID: ");
                        int studentId = readInt(sc, "Enter student ID: ");
                        int driveId = readInt(sc, "Enter drive ID: ");
                        service.applyToDrive(appId, studentId, driveId);
                    }
                    case "3" -> {
                        int appId = readInt(sc, "Enter application ID: ");
                        int roundId = readInt(sc, "Enter round ID: ");
                        System.out.print("Enter status (Pass/Fail): ");
                        String status = sc.nextLine().trim();
                        service.enterRoundResult(appId, roundId, status);
                    }
                    case "4" -> {
                        int offerId = readInt(sc, "Enter new offer ID: ");
                        int appId = readInt(sc, "Enter application ID: ");
                        System.out.print("Enter status (Pending/Accepted/Rejected): ");
                        String status = sc.nextLine().trim();
                        service.issueOffer(offerId, appId, status);
                    }
                    case "5" -> service.showDepartmentWiseReport();
                    case "6" -> service.showCompanyWiseReport();
                    case "7" -> {
                        running = false;
                        System.out.println("Goodbye!");
                    }
                    default -> System.out.println("Invalid option, try again.");
                }
            } catch (SQLException e) {
                System.out.println("Unexpected database error: " + e.getMessage());
            }
        }

        sc.close();
    }

    private static int readInt(Scanner sc, String prompt) {
        System.out.print(prompt);
        return Integer.parseInt(sc.nextLine().trim());
    }
}
