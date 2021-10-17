({
    setRenewalData: function (component) {
        const action = component.get("c.findRenewalData");
        action.setParams({contractId: component.get("v.contractId")});
        action.setCallback(this, function (response) {
            if (response.getState() === "SUCCESS") {
                component.set("v.renewalData", response.getReturnValue());
            }
            component.set("v.preloader", false);
        });
        $A.enqueueAction(action);
    }
});