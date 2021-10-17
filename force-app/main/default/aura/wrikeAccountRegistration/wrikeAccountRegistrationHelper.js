({
    findExistingAccounts: function (cmp) {
        cmp.set("v.preloader", true);
        const action = cmp.get("c.findAccounts");
        action.setParams({
            email: cmp.get("v.email")
        });
        action.setCallback(this, function (response) {
            if (response.getState() === "SUCCESS") {
                const accountsResponse = response.getReturnValue();
                if (accountsResponse.success) {
                    if (accountsResponse.wrikeAccounts.length > 0) {
                        cmp.set("v.existingAccounts", accountsResponse.wrikeAccounts);
                        cmp.set("v.selectedAccount", accountsResponse.wrikeAccounts[0].id);
                        cmp.set("v.step", "SelectAccount");
                    } else {
                        cmp.set("v.step", "SendInvite");
                    }
                } else {
                    cmp.set("v.errorMessage", accountsResponse.message);
                }
            } else {
                cmp.set("v.errorMessage", JSON.stringify(response.getError()[0]));
            }
            cmp.set("v.preloader", false);
        });
        $A.enqueueAction(action);
    },

    createNewAccount: function (cmp) {
        cmp.set("v.preloader", true);
        const action = cmp.get("c.registerNewAccount");
        const email = cmp.get("v.sendInviteDecision") === "now"
            ? cmp.get("v.email")
            : cmp.get("v.outboundEmail");
        action.setParams({
            quoteId: cmp.get("v.quoteId"),
            email: email
        });
        action.setCallback(this, function (response) {
            if (response.getState() === "SUCCESS") {
                const registrationResponse = response.getReturnValue();
                if (!registrationResponse.success) {
                    cmp.set("v.errorMessage", registrationResponse.message);
                } else {
                    cmp.find("overlayLib").notifyClose();
                    $A.get('e.force:refreshView').fire();
                }
            } else {
                cmp.set("v.errorMessage", JSON.stringify(response.getError()[0]));
            }
            cmp.set("v.preloader", false);
        });
        $A.enqueueAction(action);
    },

    updateQuoteWrikeAccount: function (cmp) {
        cmp.set("v.preloader", true);
        const action = cmp.get("c.updateQuoteWrikeAccountId");
        action.setParams({
            quoteId: cmp.get("v.quoteId"),
            wrikeAccountId: cmp.get("v.selectedAccount")
        });
        action.setCallback(this, function (response) {
            if (response.getState() === "SUCCESS") {
                cmp.find("overlayLib").notifyClose();
                $A.get('e.force:refreshView').fire();
            } else {
                cmp.set("v.errorMessage", JSON.stringify(response.getError()[0]));
            }
            cmp.set("v.preloader", false);
        });
        $A.enqueueAction(action);
    },

    validateEmail: function (cmp) {
        const emailInput = cmp.find("email");
        emailInput.showHelpMessageIfInvalid();
        return emailInput.get("v.validity").valid;
    }
})