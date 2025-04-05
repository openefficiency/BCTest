package org.whistleblower;

import com.owlike.genson.annotation.JsonValue;

public enum ReportStatus {
    SUBMITTED("SUBMITTED"),
    UNDER_INVESTIGATION("UNDER_INVESTIGATION"),
    PENDING_REVIEW("PENDING_REVIEW"),
    CLOSED("CLOSED");

    private final String status;

    ReportStatus(final String status) {
        this.status = status;
    }

    @JsonValue
    public String toString() {
        return this.status;
    }
}
