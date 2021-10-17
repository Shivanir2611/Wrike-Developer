({
    update: function(cmp, event, helper) {
        helper.updateQuote(cmp);
    },

    lookupSearch: function(cmp, event, helper) {
        const lookupComponent = event.getSource();
        const serverSearchAction = cmp.get("c.searchForPartnerAccounts");
        lookupComponent.search(serverSearchAction);
    },

    close: function (cmp, event, helper) {
        helper.closeForm(cmp);
    }
})