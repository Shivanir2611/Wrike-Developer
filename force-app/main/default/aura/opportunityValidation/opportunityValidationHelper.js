({
    goToQuotePage: function (cmp, pageName) {
        let opportunityId = cmp.get('v.recordId');
        let zuoraAccount = cmp.get('v.validationResult').zuoraAccount;

        let urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": '/one/one.app#/alohaRedirect/apex/' + pageName
                + '?opportunityId=' + opportunityId
                + (zuoraAccount != null ? '&zuoraAccountId=' + zuoraAccount.id : '')
        });
        urlEvent.fire();
    },
})