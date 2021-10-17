({
    init: function (cmp, event, helper) {
        const cb = function (response) {
            if (response.getState() === "SUCCESS") {
                const quote = response.getReturnValue();
                cmp.set("v.quote", quote);
                if (quote.billingSchedules.length === 0) {
                    cmp.set("v.unallocatedSubscriptionAmount", quote.subscriptionTotal);
                    cmp.set("v.unallocatedOneTimeFeeAmount", quote.oneTimeTotal);
                    $A.enqueueAction(cmp.get("c.addRow"));
                } else {
                    $A.enqueueAction(cmp.get("c.updateUnallocatedAmountAndValidate"));
                }
                helper.setCurrencySymbol(cmp, quote.currencyCode);
            }
        };
        const action = cmp.get("c.getQuote");
        action.setParams({quoteId: cmp.get("v.pageReference").state.c__quoteId});
        action.setCallback(this, cb);
        $A.enqueueAction(action);
    },

    reInit: function(cmp, event, helper) {
        $A.get('e.force:refreshView').fire();
    },

    updateUnallocatedAmountAndValidate: function (cmp, event, helper) {
        const quote = cmp.get("v.quote");
        let hasPositiveItem = false;
        let hasNegativeItem = false;
        let subscriptionAmount = quote.subscriptionTotal;
        let oneTimeFeeAmount = quote.oneTimeTotal;
        quote.billingSchedules.forEach(item => {
            subscriptionAmount = Number(subscriptionAmount).toFixed(2) - Number(item.subscriptionAmount).toFixed(2);
            oneTimeFeeAmount = Number(oneTimeFeeAmount).toFixed(2) - Number(item.oneTimeFeeAmount).toFixed(2);
            if (Number(item.subscriptionAmount).toFixed(2) > 0) {
                hasPositiveItem = true;
            }
            if (Number(item.subscriptionAmount).toFixed(2) < 0) {
                hasNegativeItem = true;
            }
        });
        cmp.set("v.unallocatedSubscriptionAmount", subscriptionAmount);
        cmp.set("v.unallocatedOneTimeFeeAmount", oneTimeFeeAmount);
        let blockSaveMessage = "";
        if (subscriptionAmount !== 0 || oneTimeFeeAmount !== 0) {
            blockSaveMessage = "Unallocated amount should be $0.";
        } else if (quote.subscriptionTotal > 0 && hasNegativeItem) {
            blockSaveMessage = "Only positive lines are allowed.";
        } else if (quote.subscriptionTotal < 0 && hasPositiveItem) {
            blockSaveMessage = "Only negative lines are allowed.";
        } else if (quote.subscriptionTotal === 0 && (hasNegativeItem || hasPositiveItem)) {
            blockSaveMessage = "Only zero lines are allowed.";
        }
        cmp.set("v.blockSaveMessage", blockSaveMessage);
    },

    addRow: function (cmp, event, helper) {
        const quote = cmp.get("v.quote");
        quote.billingSchedules.push({
            "invoiceNumber": quote.billingSchedules.length + 1,
            "invoiceDate": "",
            "subscriptionAmount": 0,
            "oneTimeFeeAmount": 0,
            "quoteId": quote.id,
            "currencyCode": quote.currencyCode
        });
        cmp.set("v.quote", quote);
    },

    removeRow: function (cmp, event, helper) {
        const rowIndex = event.getSource().get('v.value');
        const quote = cmp.get("v.quote");
        quote.billingSchedules.splice(rowIndex, 1);
        cmp.set("v.quote", quote);
        $A.enqueueAction(cmp.get("c.updateUnallocatedAmountAndValidate"));
    },

    save: function (cmp, event, helper) {
        if(helper.validateDateInputs(cmp)) {
            helper.save(cmp);
        }
    },

    navigateToQuote: function (cmp, event, helper) {
        cmp.find("navService").navigate({
            "type": "standard__recordPage",
            "attributes": {
                "recordId": cmp.get("v.quote").id,
                "objectApiName": "SBQQ__Quote__c",
                "actionName": "view"
            }
        });
    }
})