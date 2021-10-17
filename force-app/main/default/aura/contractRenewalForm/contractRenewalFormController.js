({
    init: function (component, event, helper) {
        component.set("v.preloader", true);
        helper.setRenewalData(component);
    },

    expireContractAction: function (component, event, helper) {
        component.set("v.preloader", true);
        const action = component.get("c.expireContract");
        action.setParams({contractId: component.get("v.contractId")});
        action.setCallback(this, function (response) {
            if (response.getState() === "SUCCESS") {
                helper.setRenewalData(component);
            }
        });
        $A.enqueueAction(action);
    },

    setGracePeriodAction: function (component, event, helper) {
        component.set("v.preloader", true);
        const action = component.get("c.keepGracePeriod");
        action.setParams({contractId: component.get("v.contractId")});
        action.setCallback(this, function (response) {
            if (response.getState() === "SUCCESS") {
                helper.setRenewalData(component);
            }
        });
        $A.enqueueAction(action);
    },

    createRenewalQuoteAction: function (component, event, helper) {
        component.set("v.preloader", true);
        const action = component.get("c.createRenewalQuote");
        action.setParams({contractId: component.get("v.contractId")});
        action.setCallback(this, function (response) {
            if (response.getState() === "SUCCESS") {
                helper.setRenewalData(component);
            }
        });
        $A.enqueueAction(action);
    }
});