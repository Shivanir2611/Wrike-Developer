({
    init: function (cmp, event, helper) {
        helper.getApprovals(cmp);
    },

    approve: function (cmp, event, helper) {
        helper.navigateToDecision(cmp, "sbaa__Approve");
    },

    reject: function (cmp, event, helper) {
        helper.navigateToDecision(cmp, "sbaa__Reject");
    },

    viewAllApprovals: function (cmp, event, helper) {
        helper.viewAllApprovals(cmp);
    },

    viewUserApprovals: function (cmp, event, helper) {
        helper.viewUserApprovals(cmp);
    },

    onApprovalMenuSelect: function(cmp, event, helper) {
        const selectedMenuItemValue = event.getParam("value");
        if (selectedMenuItemValue === "reject") {
            helper.navigateToDecision(cmp, "sbaa__Reject");
        }
        if (selectedMenuItemValue === "viewAllApprovals") {
            helper.viewAllApprovals(cmp);
        }
        if (selectedMenuItemValue === "viewUserApprovals") {
            helper.viewUserApprovals(cmp);
        }
    }
})