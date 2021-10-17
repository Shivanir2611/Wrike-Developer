({

    doInit: function (component, event, helper) {
        component.set("v.loading", true);
        const action = component.get("c.queryOpportunityData");
        action.setParams({ opportunityId: component.get("v.recordId") });
        action.setCallback(this, function (response) {
            if (response.getState() === "SUCCESS") {
                const opportunityData = response.getReturnValue();
                component.set("v.opportunityData", opportunityData);
                if(opportunityData.opportunityType === 'Renewal') {
                    component.set("v.workflowType", 'renew');
                    component.set("v.numberOfTeams", '0');
                } else {
                    component.set("v.errorMessage", JSON.stringify(response.getError()[0]));
                }
            } else {
                component.set("v.errorMessage", JSON.stringify(response.getError()[0]));
            }
            component.set("v.loading", false);
        });
        $A.enqueueAction(action);
        const getNumberOfTeamOptions = component.get("c.getNumberOfTeamsOptions");
        getNumberOfTeamOptions.setCallback(this, function (response) {
            if (response.getState() === "SUCCESS") {
                component.set("v.numberOfTeamsOptions", response.getReturnValue());
            } else {
                component.set("v.errorMessage", JSON.stringify(response.getError()[0]));
            }
        });
        $A.enqueueAction(getNumberOfTeamOptions);
    },

    workflowTypeOnChange: function (component, event, helper) {
        component.set("v.selectedContractId", null);
        component.set("v.quoteType", null);
        component.set("v.quoteSubType", null);
        const workflowType = event.getSource().get("v.value");
        if(workflowType === 'existing' || workflowType === 'amendAndRenew') {
            component.set("v.loading", true);
            const action = component.get("c.listAccountContracts");
            action.setParams({ opportunityId: component.get("v.recordId") });
            action.setCallback(this, function (response) {
                if (response.getState() === "SUCCESS") {
                    component.set("v.contracts", response.getReturnValue());
                } else {
                    component.set("v.errorMessage", JSON.stringify(response.getError()[0]));
                }
                component.set("v.loading", false);
            });
            $A.enqueueAction(action);
        }
    },

    quoteTypeOnChange: function (component, event, helper) {
        component.set("v.quoteSubType", null);
    },

    selectContract: function (component, event, helper) {
        const contractId = event.currentTarget.value;
        component.set("v.loading", true);
        component.set("v.selectedContractId", contractId);
        const action = component.get("c.findAmendmentStartDate");
        action.setParams({ contractId: contractId });
        action.setCallback(this, function (response) {
            if (response.getState() === "SUCCESS") {
                component.set("v.amendmentStartDate", response.getReturnValue());
            } else {
                component.set("v.errorMessage", JSON.stringify(response.getError()[0]));
            }
            component.set("v.loading", false);
        });
        $A.enqueueAction(action);
    },

    newSubscription: function (component, event, helper) {
        component.set("v.loading", true);
        const action = component.get("c.createdNewSubscriptionQuote");
        action.setParams({
            opportunityId: component.get("v.recordId"),
            quoteType: "New Subscription",
            quoteSubType: component.get("v.quoteSubType"),
            numberOfTeams: component.get("v.numberOfTeams")
        });
        action.setCallback(this, function (response) {
            if (response.getState() === "SUCCESS") {
                helper.navigateToQuoteLines(component, response.getReturnValue());
            } else {
                component.set("v.errorMessage", JSON.stringify(response.getError()[0]));
            }
            component.set("v.loading", false);
        });
        $A.enqueueAction(action);
    },

    amendContract: function (component, event, helper) {
        component.set("v.loading", true);
        const action = component.get("c.createAmendmentQuote");
        action.setParams({
            opportunityId: component.get("v.recordId"),
            contractId: component.get("v.selectedContractId"),
            quoteType: component.get("v.quoteType"),
            quoteSubType: component.get("v.quoteSubType"),
            numberOfTeams: component.get("v.numberOfTeams")
        });
        action.setCallback(this, function (response) {
            if (response.getState() === "SUCCESS") {
                const amendResponse = response.getReturnValue();
                if (amendResponse.errorMessage) {
                    component.set("v.errorMessage", amendResponse.errorMessage);
                } else {
                    helper.navigateToQuoteLines(component, amendResponse.quoteId);
                }
            } else {
                component.set("v.errorMessage", JSON.stringify(response.getError()[0]));
            }
            component.set("v.loading", false);
        });
        $A.enqueueAction(action);
    },

    renewContract: function (component, event, helper) {
        component.set("v.loading", true);
        const action = component.get("c.createRenewalQuote");
        action.setParams({
            opportunityId: component.get("v.recordId"),
            numberOfTeams: component.get("v.numberOfTeams"),
            selectedContractId: component.get("v.selectedContractId")
        });
        action.setCallback(this, function (response) {
            if (response.getState() === "SUCCESS") {
                helper.navigateToQuoteLines(component, response.getReturnValue());
            } else {
                component.set("v.errorMessage", JSON.stringify(response.getError()[0]));
            }
            component.set("v.loading", false);
        });
        $A.enqueueAction(action);
    },

    cancelLegacyQuote: function (component, event, helper) {
        component.set("v.loading", true);
        component.set("v.errorMessage", null);
        const action = component.get("c.cancelZuoraQuote");
        action.setParams({
            opportunityId: component.get("v.recordId"),
            zuoraQuoteId: component.get("v.opportunityData.existingZuoraQuoteId")
        });
        action.setCallback(this, function (response) {
            if (response.getState() === "SUCCESS") {
                component.set("v.opportunityData", response.getReturnValue());
            } else {
                component.set("v.errorMessage", JSON.stringify(response.getError()[0]));
            }
            component.set("v.loading", false);
        });
        $A.enqueueAction(action);
    }
});