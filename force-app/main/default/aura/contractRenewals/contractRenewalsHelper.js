({
    refreshContracts: function (component) {
        component.set("v.preloader", true);
        const queryContractsAction = component.get("c.listRenewalContracts");
        queryContractsAction.setCallback(this, function (response) {
            if (response.getState() === "SUCCESS") {
                component.set("v.contracts", response.getReturnValue());
            }
            component.set("v.preloader", false);
        });
        $A.enqueueAction(queryContractsAction);
    }
});