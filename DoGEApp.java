package org.whistleblower.doge;

import org.whistleblower.client.WhistleblowerClient;
import org.whistleblower.WhistleblowerReport;

import java.util.List;
import java.util.Scanner;

public class DoGEApplication {

    private static WhistleblowerClient client;

    public static void main(String[] args) {
        try {
            // Initialize the client for DoGE
            client = new WhistleblowerClient(
                "wallets/doge", 
                "connection-profiles/doge-connection.json", 
                "dogeUser", 
                "whistleblowerchannel", 
                "whistleblower"
            );
            
            // Start the application
            startApplication();
            
        } catch (Exception e) {
            System.err.println("Error starting DoGE application: " + e.getMessage());
            e.printStackTrace();
        }
    }

    private static void startApplication() {
        Scanner scanner = new Scanner(System.in);
        boolean exit = false;
        
        while (!exit) {
            System.out.println("\nDepartment of Government Efficiency - Whistleblower System");
            System.out.println("1. View all reports");
            System.out.println("2. View reports by status");
            System.out.println("3. View reports assigned to me");
            System.out.println("4. View specific report");
            System.out.println("5. Assign investigator to report");
            System.out.println("6. Submit investigation findings");
            System.out.println("0. Exit");
            System.out.print("Select an option: ");
            
            int choice = scanner.nextInt();
            scanner.nextLine(); // Consume newline
            
            switch (choice) {
                case 1:
                    viewAllReports();
                    break;
                case 2:
                    viewReportsByStatus(scanner);
                    break;
                case 3:
                    viewReportsAssignedToMe(scanner);
                    break;
                case 4:
                    viewSpecificReport(scanner);
                    break;
                case 5:
                    assignInvestigator(scanner);
                    break;
                case 6:
                    submitFindings(scanner);
                    break;
                case 0:
                    exit = true;
                    break;
                default:
                    System.out.println("Invalid option. Please try again.");
            }
        }
        
        scanner.close();
    }

    private static void viewAllReports() {
        try {
            List<WhistleblowerReport> reports = client.getAllReports();
            displayReports(reports);
        } catch (Exception e) {
            System.err.println("Error retrieving reports: " + e.getMessage());
        }
    }

    private static void viewReportsByStatus(Scanner scanner) {
        try {
            System.out.print("Enter status (SUBMITTED, UNDER_INVESTIGATION, PENDING_REVIEW, CLOSED): ");
            String status = scanner.nextLine();
            
            List<WhistleblowerReport> reports = client.getReportsByStatus(status);
            displayReports(reports);
        } catch (Exception e) {
            System.err.println("Error retrieving reports: " + e.getMessage());
        }
    }

    private static void viewReportsAssignedToMe(Scanner scanner) {
        try {
            System.out.print("Enter your investigator ID: ");
            String investigatorId = scanner.nextLine();
            
            List<WhistleblowerReport> reports = client.getReportsByInvestigator(investigatorId);
            displayReports(reports);
        } catch (Exception e) {
            System.err.println("Error retrieving reports: " + e.getMessage());
        }
    }

    private static void viewSpecificReport(Scanner scanner) {
        try {
            System.out.print("Enter report ID: ");
            String id = scanner.nextLine();
            
            WhistleblowerReport report = client.getReport(id);
            System.out.println("\nReport Details:");
            System.out.println("ID: " + report.getId());
            System.out.println("Description: " + report.getDescription());
            System.out.println("Department: " + report.getDepartment());
            System.out.println("Submitted By: " + report.getSubmittedBy());
            System.out.println("Status: " + report.getStatus());
            System.out.println("Investigator: " + (report.getInvestigatorId().isEmpty() ? "Unassigned" : report.getInvestigatorId()));
            System.out.println("Findings: " + report.getFindings());
            System.out.println("Leadership Decision: " + report.getLeadershipDecision());
            
        } catch (Exception e) {
            System.err.println("Error retrieving report: " + e.getMessage());
        }
    }

    private static void assignInvestigator(Scanner scanner) {
        try {
            System.out.print("Enter report ID: ");
            String id = scanner.nextLine();
            
            // First verify the report is in SUBMITTED status
            WhistleblowerReport report = client.getReport(id);
            if (!report.getStatus().toString().equals("SUBMITTED")) {
                System.out.println("Report is not in SUBMITTED status. Cannot assign investigator.");
                return;
            }
            
            System.out.print("Enter investigator ID: ");
            String investigatorId = scanner.nextLine();
            
            WhistleblowerReport updatedReport = client.assignInvestigator(id, investigatorId);
            System.out.println("Investigator assigned successfully to report: " + updatedReport.getId());
            
        } catch (Exception e) {
            System.err.println("Error assigning investigator: " + e.getMessage());
        }
    }

    private static void submitFindings(Scanner scanner) {
        try {
            System.out.print("Enter report ID: ");
            String id = scanner.nextLine();
            
            // First verify the report is in UNDER_INVESTIGATION status
            WhistleblowerReport report = client.getReport(id);
            if (!report.getStatus().toString().equals("UNDER_INVESTIGATION")) {
                System.out.println("Report is not in UNDER_INVESTIGATION status. Cannot submit findings.");
                return;
            }
            
            // Verify the investigator is assigned to this report
            System.out.print("Enter your investigator ID: ");
            String investigatorId = scanner.nextLine();
            if (!report.getInvestigatorId().equals(investigatorId)) {
                System.out.println("You are not assigned to this report. Cannot submit findings.");
                return;
            }
            
            System.out.println("Enter investigation findings (press Enter twice to finish):");
            StringBuilder findings = new StringBuilder();
            String line;
            while (!(line = scanner.nextLine()).isEmpty()) {
                findings.append(line).append("\n");
            }
            
            WhistleblowerReport updatedReport = client.submitFindings(id, findings.toString());
            System.out.println("Findings submitted successfully for report: " + updatedReport.getId());
            
        } catch (Exception e) {
            System.err.println("Error submitting findings: " + e.getMessage());
        }
    }

    private static void displayReports(List<WhistleblowerReport> reports) {
        System.out.println("\nReports:");
        System.out.println("---------------------------------------------------------------------------------");
        System.out.printf("%-10s %-15s %-20s %-15s %-15s%n", "ID", "Department", "Status", "Investigator", "Decision");
        System.out.println("---------------------------------------------------------------------------------");
        
        for (WhistleblowerReport report : reports) {
            System.out.printf("%-10s %-15s %-20s %-15s %-15s%n", 
                report.getId(), 
                report.getDepartment(), 
                report.getStatus(),
                report.getInvestigatorId().isEmpty() ? "Unassigned" : report.getInvestigatorId(),
                report.getLeadershipDecision().isEmpty() ? "Pending" : report.getLeadershipDecision()
            );
        }
        System.out.println("---------------------------------------------------------------------------------");
    }
}
