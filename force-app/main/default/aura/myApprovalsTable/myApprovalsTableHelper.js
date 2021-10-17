({
    getMyApprovals: function (cmp) {
        cmp.set("v.preloader", true);
        const action = cmp.get("c.findMyApprovals");
        action.setCallback(this, function (response) {
            if (response.getState() === "SUCCESS") {
                cmp.set("v.myApprovals", response.getReturnValue());
            } else {
                cmp.set("v.errorMessage", JSON.stringify(response.getError()[0]));
            }
            cmp.set("v.preloader", false);
        });
        $A.enqueueAction(action);
    },

    navigateToDecision: function (cmp, pageName, quoteId) {
        cmp.set("v.preloader", true);
        const action = cmp.get("c.getRequestedApprovalId");
        action.setParams({quoteId: quoteId});
        action.setCallback(this, function (response) {
            if (response.getState() === "SUCCESS") {
                const approvalId = response.getReturnValue();
                if (approvalId != null) {
                    const url = "/apex/" + pageName + "?id=" + approvalId;
                    this.navigate(cmp, url);
                } else {
                    $A.get('e.force:refreshView').fire();
                }
            } else {
                cmp.set("v.errorMessage", JSON.stringify(response.getError()[0]));
            }
            cmp.set("v.preloader", false);
        });
        $A.enqueueAction(action);
    },

    navigate: function (cmp, url) {
        cmp.find("navService").navigate({
            "type": "standard__webPage",
            "attributes": {
                "url": url
            }
        });
    }
})