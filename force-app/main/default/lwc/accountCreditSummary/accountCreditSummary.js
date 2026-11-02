import { LightningElement, api, wire } from "lwc";
import getCreditSummary from "@salesforce/apex/AccountCreditController.getCreditSummary";

export default class AccountCreditSummary extends LightningElement {
    @api recordId;

    summary;
    error;

    @wire(getCreditSummary, { accountId: "$recordId" })
    wiredSummary({ data, error }) {
        if (data) {
            this.summary = data;
            this.error = undefined;
        } else if (error) {
            this.summary = undefined;
            this.error = error.body?.message ?? "Unable to load credit summary.";
        }
    }

    get hasLimit() {
        return this.summary?.creditLimit != null;
    }

    get statusLabel() {
        return this.summary?.onHold ? "Credit Hold" : "In Good Standing";
    }

    get statusClass() {
        return this.summary?.onHold ? "slds-badge slds-theme_error" : "slds-badge slds-theme_success";
    }
}
