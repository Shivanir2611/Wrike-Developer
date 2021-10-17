({
    init: function (cmp, event, helper) {
        helper.getMyApprovals(cmp);
    },

    onApprovalMenuSelect: function(cmp, event, helper) {
        const values = event.getParam("value").split(';');
        const selectedMenuItemValue = values[0];
        const quoteId = values[1];
        if (selectedMenuItemValue === "approve") {
            helper.navigateToDecision(cmp, "sbaa__Approve", quoteId);
        }
        if (selectedMenuItemValue === "reject") {
            helper.navigateToDecision(cmp, "sbaa__Reject", quoteId);
        }
    }
})