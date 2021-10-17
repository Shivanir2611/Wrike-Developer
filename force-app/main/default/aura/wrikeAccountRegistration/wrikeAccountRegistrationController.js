({
    onCancel: function(cmp, event, helper) {
        cmp.find("overlayLib").notifyClose();
    },

    checkEmail: function(cmp, event, helper) {
        if (helper.validateEmail(cmp)) {
            helper.findExistingAccounts(cmp);
        }
    },

    backToEnterEmail: function(cmp, event, helper) {
        cmp.set("v.step", "EnterEmail");
    },

    backToSendInvite: function(cmp, event, helper) {
        cmp.set("v.step", "SendInvite");
    },

    setExistingAccountId: function(cmp, event, helper) {
        helper.updateQuoteWrikeAccount(cmp);
    },

    showCreationConfirmation: function(cmp, event, helper) {
        const email = cmp.get("v.email");
        if (cmp.get("v.sendInviteDecision") === "later") {
            const username = email.split("@")[0];
            const domain = email.split("@")[1];
            cmp.set("v.outboundEmail", username + "-" + domain + "@outbound.deal.wrike.com");
        }
        cmp.set("v.step", "CreateAccount");
    },

    createAccount: function(cmp, event, helper) {
        helper.createNewAccount(cmp);
    },

    selectExistingAccount: function(cmp, event, helper) {
        cmp.set("v.selectedAccount", event.getSource().get("v.text"));
    }
})