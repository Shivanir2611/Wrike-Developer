({
    getApprovals: function (cmp) {
        cmp.set("v.preloader", true);
        const userInfoAction = cmp.get("c.getUserInfo");
        userInfoAction.setCallback(this, function (userInfoResponse) {
            if (userInfoResponse.getState() === "SUCCESS") {
                const userInfo = userInfoResponse.getReturnValue();
                cmp.set("v.userInfo", userInfo);
                const approvalsAction = cmp.get("c.findQuoteApprovals");
                approvalsAction.setParams({quoteId: cmp.get("v.recordId")});
                approvalsAction.setCallback(this, function (approvalsResponse) {
                    if (approvalsResponse.getState() === "SUCCESS") {
                        const allApprovals = approvalsResponse.getReturnValue();
                        cmp.set("v.allApprovals", allApprovals);
                        if (allApprovals.length > 0) {
                            const userApprovals = allApprovals.filter(approval =>
                                approval.approverUserId === userInfo.userId
                                || approval.assignedToId === userInfo.userId
                                || userInfo.userGroupIds.includes(approval.approverGroupId));
                            cmp.set("v.userApprovals", userApprovals);
                            if (userApprovals.length > 0) {
                                this.viewUserApprovals(cmp);
                                cmp.set("v.hasApprovals", userApprovals.some(approval =>
                                    approval.status === "Assigned" || approval.status === "Requested"));
                            } else {
                                this.viewAllApprovals(cmp);
                            }
                        }
                    } else {
                        cmp.set("v.errorMessage", JSON.stringify(approvalsResponse.getError()[0]));
                    }
                    cmp.set("v.preloader", false);
                });
                $A.enqueueAction(approvalsAction);
            } else {
                cmp.set("v.errorMessage", JSON.stringify(userInfoResponse.getError()[0]));
            }
            cmp.set("v.preloader", false);
        });
        $A.enqueueAction(userInfoAction);
    },

    navigate: function (cmp, url) {
        cmp.find("navService").navigate({
            "type": "standard__webPage",
            "attributes": {
                "url": url
            }
        });
    },

    needToReassign: function (cmp) {
        const userInfo = cmp.get("v.userInfo");
        return cmp.get("v.userApprovals").some(approval =>
            (approval.approverUserId === userInfo.userId
            || userInfo.userGroupIds.includes(approval.approverGroupId))
            && approval.assignedTo !== userInfo.userId);
    },

    navigateToDecision: function (cmp, pageName) {
        cmp.set("v.preloader", true);
        const action = cmp.get("c.prepareApprovals");
        action.setParams({quoteId: cmp.get("v.recordId")});
        action.setCallback(this, function (response) {
            if (response.getState() === "SUCCESS") {
                if (response.getReturnValue()) {
                    const url = "/apex/" + pageName + "?id=" + response.getReturnValue();
                    this.navigate(cmp, url);
                } else {
                    cmp.set("v.errorMessage", "There is nothing to approve.");
                }
            } else {
                cmp.set("v.errorMessage", JSON.stringify(response.getError()[0]));
            }
            cmp.set("v.preloader", false);
        });
        $A.enqueueAction(action);
    },

    viewAllApprovals: function (cmp) {
        cmp.set("v.approvals", cmp.get("v.allApprovals"));
        cmp.set("v.showOnlyUserApprovals", false);
    },

    viewUserApprovals: function (cmp) {
        cmp.set("v.approvals", cmp.get("v.userApprovals"));
        cmp.set("v.showOnlyUserApprovals", true);
    }
})