({
    updateQuote: function(cmp) {
        this.enablePreloader(cmp);
        const action = cmp.get("c.updateQuotePartnerAccount");
        action.setParams({
            quoteId: cmp.get("v.quoteId"),
            partnerAccountId: cmp.get("v.selectedItem").id
        });
        action.setCallback(this, function (response) {
            this.disablePreloader(cmp);
            if (response.getState() === "SUCCESS") {
                const errorMessage = response.getReturnValue();
                if (errorMessage) {
                    cmp.set("v.errorMessage", errorMessage);
                } else {
                   this.recalculate(cmp);
                }
            } else {
                cmp.set("v.errorMessage", JSON.stringify(response.getError()[0]));
            }
        });
        $A.enqueueAction(action);
    },

    recalculate: function(cmp) {
        this.enablePreloader(cmp);
        const action = cmp.get("c.recalculateQuote");
        action.setParams({quoteId: cmp.get("v.quoteId")});
        action.setCallback(this, function (response) {
            this.disablePreloader(cmp);
            if (response.getState() === "SUCCESS") {
                this.closeForm(cmp);
                $A.get('e.force:refreshView').fire();
            } else {
                cmp.set("v.errorMessage", JSON.stringify(response.getError()[0]));
            }
        });
        $A.enqueueAction(action);
    },

    enablePreloader: function(cmp) {
        cmp.set("v.preloader", true);
    },

    disablePreloader: function(cmp) {
        cmp.set("v.preloader", false);
    },

    closeForm: function (cmp) {
        cmp.find("overlayLib").notifyClose();
    }
})