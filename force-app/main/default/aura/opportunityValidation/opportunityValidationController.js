({
    init: function (cmp, event, helper) {
        const action = cmp.get("c.validate");
        action.setParams({opportunityId: cmp.get("v.recordId")});
        action.setCallback(this, function (response) {
            if (response.getState() === "SUCCESS") {
                cmp.set("v.validationResult", response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
    },

    goToNewAmendmentPage: function (cmp, event, helper) {
        helper.goToQuotePage(cmp, 'AmendmentQuote');
    },

    goToNewRenewalPage: function (cmp, event, helper) {
        helper.goToQuotePage(cmp, 'RenewalQuote');
    },

    goToNewQuotePage: function (cmp, event, helper) {
        helper.goToQuotePage(cmp, 'SubscriptionQuote');
    },
})