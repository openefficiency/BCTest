package org.whistleblower;

import org.hyperledger.fabric.contract.annotation.DataType;
import org.hyperledger.fabric.contract.annotation.Property;

import com.owlike.genson.annotation.JsonProperty;

@DataType()en
public class WhistleblowerReport {

    @Property()
    private String id;

    @Property()
    private String description;

    @Property()
    private String department;

    @Property()
    private String submittedBy;

    @Property()
    private long submittedAt;

    @Property()
    private ReportStatus status;

    @Property()
    private String investigatorId;

    @Property()
    private String findings;

    @Property()
    private String leadershipDecision;

    @Property()
    private long lastUpdated;

    public WhistleblowerReport() {
        // Empty constructor required for deserialization
    }

    public WhistleblowerReport(
            @JsonProperty("id") final String id,
            @JsonProperty("description") final String description,
            @JsonProperty("department") final String department,
            @JsonProperty("submittedBy") final String submittedBy,
            @JsonProperty("submittedAt") final long submittedAt,
            @JsonProperty("status") final ReportStatus status,
            @JsonProperty("investigatorId") final String investigatorId,
            @JsonProperty("findings") final String findings,
            @JsonProperty("leadershipDecision") final String leadershipDecision) {
        this.id = id;
        this.description = description;
        this.department = department;
        this.submittedBy = submittedBy;
        this.submittedAt = submittedAt;
        this.status = status;
        this.investigatorId = investigatorId;
        this.findings = findings;
        this.leadershipDecision = leadershipDecision;
        this.lastUpdated = submittedAt;
    }

    public String getId() {
        return id;
    }

    public void setId(final String id) {
        this.id = id;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(final String description) {
        this.description = description;
    }

    public String getDepartment() {
        return department;
    }

    public void setDepartment(final String department) {
        this.department = department;
    }

    public String getSubmittedBy() {
        return submittedBy;
    }

    public void setSubmittedBy(final String submittedBy) {
        this.submittedBy = submittedBy;
    }

    public long getSubmittedAt() {
        return submittedAt;
    }

    public void setSubmittedAt(final long submittedAt) {
        this.submittedAt = submittedAt;
    }

    public ReportStatus getStatus() {
        return status;
    }

    public void setStatus(final ReportStatus status) {
        this.status = status;
    }

    public String getInvestigatorId() {
        return investigatorId;
    }

    public void setInvestigatorId(final String investigatorId) {
        this.investigatorId = investigatorId;
    }

    public String getFindings() {
        return findings;
    }

    public void setFindings(final String findings) {
        this.findings = findings;
    }

    public String getLeadershipDecision() {
        return leadershipDecision;
    }

    public void setLeadershipDecision(final String leadershipDecision) {
        this.leadershipDecision = leadershipDecision;
    }

    public long getLastUpdated() {
        return lastUpdated;
    }

    public void setLastUpdated(final long lastUpdated) {
        this.lastUpdated = lastUpdated;
    }
}
