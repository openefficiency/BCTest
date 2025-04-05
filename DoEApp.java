package org.whistleblower.doe;

import org.whistleblower.client.WhistleblowerClient;
import org.whistleblower.WhistleblowerReport;

import java.util.List;
import java.util.Scanner;

public class DoEApplication {

    private static WhistleblowerClient client;

    public static void main(String[] args) {
        try {
            // Initialize the client for DoE
            client = new WhistleblowerClient(
                "wallets/doe", 
                "connection-profiles/doe-connection.json", 
                "doeUser", 
                "whistleblowerchannel", 
                "whistleblower"
            );
            
            // Start the application
            startApplication();
            
        } catch (Exception e) {
            System.err.println("Error starting DoE application: " + e.getMessage());
            e.printStackTrace();
        }
    }

    private static void startApplication() {
        Scanner scanner = new Scanner(System.in);
        boolean exit = false;
        
        while (!exit) {
            System.out.println("\nDepartment of Education - Whistleblower System");
            System.out.println("1. Submit new whistleblower report");
            System.out.println("2. View all reports");
            System.out.println("3. View reports by status");
            System.out.println("4. View specific report");
            System.out.println("5. Submit leadership review");
            System.out.println("0. Exit");
            System.out.print("Select an option: ");
            
            int choice = scanner.nextInt();
            scanner.nextLine(); // Consume newline
            
            switch (choice) {
                case 1:
                    submitReport(scanner);
                    break;
                case 2:
                    viewAllReports();
                    break;
                case 3:
                    viewReportsByStatus(scanner);
                    break;
                case 4:
                    viewSpecificReport(scanner);
                    break;
                case 5:
                    submitLeadershipReview(scanner);
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

    private static void submitReport(Scanner scanner) {
        try {
            System.out.println("\nSubmit New Whistleblower Report");
            
            System.out.print("Enter report ID: ");
            String id = scanner.nextLine();
            
            System.out.print("Enter description: ");
            String description = scanner.nextLine();
            
            System.out.print("Enter affected department: ");
            String department = scanner.nextLine();
            
            System.out.print("Enter whistleblower ID (anonymous): ");
            String submittedBy = scanner.nextLine();
            
            WhistleblowerReport report = client.submitReport(id, description, department, submittedBy);
            System.out.println("Report submitted successfully: " + report.getId());
            
        } catch (Exception e) {
            System.err.println("Error submitting report: " + e.getMessage());
        }
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
            System.out.println("Investigator: " + report.getInvestigatorId());
            System.out.println("Findings: " + report.getFindings());
            System.out.println("Leadership Decision: " + report.getLeadershipDecision());
            
        } catch (Exception e) {
            System.err.println("Error retrieving report: " + e.getMessage());
        }
    }

    private static void submitLeadershipReview(Scanner scanner) {
        try {
            System.out.print("Enter report ID: ");
            String id = scanner.nextLine();
            
            // First verify the report is in PENDING_REVIEW status
            WhistleblowerReport report = client.getReport(id);
            if (!report.getStatus().toString().equals("PENDING_REVIEW")) {
                System.out.println("Report is not in PENDING_REVIEW status. Cannot submit leadership review.");
                return;
            }
            
            System.out.print("Enter leadership decision: ");
            String decision = scanner.nextLine();
            
            WhistleblowerReport updatedReport = client.submitLeadershipReview(id, decision);
            System.out.println("Leadership review submitted successfully for report: " + updatedReport.getId());
            
        } catch (Exception e) {
            System.err.println("Error submitting leadership review: " + e.getMessage());
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
