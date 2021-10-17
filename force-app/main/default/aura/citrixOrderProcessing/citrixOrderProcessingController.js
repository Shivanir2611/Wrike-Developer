({
    process: function (cmp, event, helper) {
        cmp.set("v.preloader", true);
        const action = cmp.get("c.createOpportunityAndQuote");
        action.setParams({
            accountId: cmp.get("v.recordId"),
            orderType: cmp.get("v.orderType")
        });
        action.setCallback(this, function (response) {
            if (response.getState() === "SUCCESS") {
                cmp.find("navService").navigate({
                    "type": "standard__recordPage",
                    "attributes": {
                        "recordId": response.getReturnValue(),
                        "objectApiName": "SBQQ__Quote__c",
                        "actionName": "view"
                    }
                });
            } else {
                cmp.set("v.preloader", false);
                cmp.set("v.errorMessage", JSON.stringify(response.getError()[0]));
            }
        });
        $A.enqueueAction(action);
    },

    close: function (cmp, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    }
})