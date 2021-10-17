({
    getCurrentAccountStatus: function (cmp) {
        const action = cmp.get("c.getAccountStatus");
        action.setParams({opportunityId: cmp.get("v.recordId")});
        action.setCallback(this, function (response) {
            if (response.getState() === "SUCCESS") {
                const accountStatusResponse = response.getReturnValue();
                cmp.set("v.contracts", accountStatusResponse.contracts);
                cmp.set("v.subscriptionProducts", accountStatusResponse.subscriptionProducts);
                cmp.set("v.currencyCode", accountStatusResponse.currencyCode);
                cmp.set("v.displayRenewalPrice",
                    accountStatusResponse.subscriptionProducts
                        .some(product => product.avgEffectivePrice !== product.avgRenewalPrice));
            } else {
                cmp.set("v.errorMessage", JSON.stringify(response.getError()[0]));
            }
        });
        $A.enqueueAction(action);
    }
})