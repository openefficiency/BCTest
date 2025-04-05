package org.whistleblower.client;

import org.hyperledger.fabric.gateway.Contract;
import org.hyperledger.fabric.gateway.Gateway;
import org.hyperledger.fabric.gateway.Network;
import org.hyperledger.fabric.gateway.Wallet;
import org.hyperledger.fabric.gateway.Wallets;
import org.whistleblower.WhistleblowerReport;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.google.gson.reflect.TypeToken;

import java.io.IOException;
import java.lang.reflect.Type;
import java.nio.charset.StandardCharsets;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.TimeoutException;

public class WhistleblowerClient {

    private final Contract contract;
    private static final Gson gson = new GsonBuilder().create();

    public WhistleblowerClient(String walletPath, String connectionProfilePath, String userId, String channelName, String contractName) throws Exception {
        // Load a wallet containing user credentials
        Path walletDirectory = Paths.get(walletPath);
        Wallet wallet = Wallets.newFileSystemWallet(walletDirectory);

        // Load connection profile
        Path networkConfigPath = Paths.get(connectionProfilePath);

        // Configure the gateway connection
        Gateway.Builder builder = Gateway.createBuilder()
                .identity(wallet, userId)
                .networkConfig(networkConfigPath);

        // Create a gateway connection
        Gateway gateway = builder.connect();
        
        // Access the network
        Network network = gateway.getNetwork(channelName);
        
        // Get the contract
        this.contract = network.getContract(contractName);
    }

    /**
     * Submit a new whistleblower report
     */
    public WhistleblowerReport submitReport(String id, String description, String department, String submittedBy) throws Exception {
        byte[] result = contract.submitTransaction("submitReport", id, description, department, submittedBy);
        return deserializeReport(result);
    }

    /**
     * Assign an investigator to a report (DoGE only)
     */
    public WhistleblowerReport assignInvestigator(String reportId, String investigatorId) throws Exception {
        byte[] result = contract.submitTransaction("assignInvestigator", reportId, investigatorId);
        return deserializeReport(result);
    }

    /**
     * Submit investigation findings (DoGE only)
     */
    public WhistleblowerReport submitFindings(String reportId, String findings) throws Exception {
        byte[] result = contract.submitTransaction("submitFindings", reportId, findings);
        return deserializeReport(result);
    }

    /**
     * Submit leadership review decision (DoE only)
     */
    public WhistleblowerReport submitLeadershipReview(String reportId, String decision) throws Exception {
        byte[] result = contract.submitTransaction("submitLeadershipReview", reportId, decision);
        return deserializeReport(result);
    }

    /**
     * Get a specific report by ID
     */
    public WhistleblowerReport getReport(String reportId) throws Exception {
        byte[] result = contract.evaluateTransaction("getReport", reportId);
        return deserializeReport(result);
    }

    /**
     * Get all reports
     */
    public List<WhistleblowerReport> getAllReports() throws Exception {
        byte[] result = contract.evaluateTransaction("getAllReports");
        return deserializeReportList(result);
    }

    /**
     * Get reports by status
     */
    public List<WhistleblowerReport> getReportsByStatus(String status) throws Exception {
        byte[] result = contract.evaluateTransaction("getReportsByStatus", status);
        return deserializeReportList(result);
    }

    /**
     * Get reports by investigator
     */
    public List<WhistleblowerReport> getReportsByInvestigator(String investigatorId) throws Exception {
        byte[] result = contract.evaluateTransaction("getReportsByInvestigator", investigatorId);
        return deserializeReportList(result);
    }

    // Helper methods for deserialization
    private WhistleblowerReport deserializeReport(byte[] bytes) {
        String json = new String(bytes, StandardCharsets.UTF_8);
        return gson.fromJson(json, WhistleblowerReport.class);
    }

    private List<WhistleblowerReport> deserializeReportList(byte[] bytes) {
        String json = new String(bytes, StandardCharsets.UTF_8);
        Type listType = new TypeToken<ArrayList<WhistleblowerReport>>(){}.getType();
        return gson.fromJson(json, listType);
    }
}
