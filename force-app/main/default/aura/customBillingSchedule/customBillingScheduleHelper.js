({
    enablePreloader: function(cmp) {
        cmp.set("v.preloader", true);
    },

    disablePreloader: function(cmp) {
        cmp.set("v.preloader", false);
    },

    save: function(cmp) {
        this.enablePreloader(cmp);
        if (!cmp.get("v.blockSaveMessage")) {
            const action = cmp.get("c.saveBillingSchedule");
            const billingSchedules = cmp.get("v.quote").billingSchedules
                .map(item => {
                    item.subscriptionAmount = Number(item.subscriptionAmount).toFixed(2);
                    item.oneTimeFeeAmount = Number(item.oneTimeFeeAmount).toFixed(2);
                    return item;
                });
            action.setParams({
                quoteId: cmp.get("v.quote").id,
                billingSchedules: billingSchedules
            });
            action.setCallback(this, function (response) {
                if (response.getState() === "SUCCESS") {
                    this.disablePreloader(cmp);
                    $A.enqueueAction(cmp.get("c.navigateToQuote"));
                }
            });
            $A.enqueueAction(action);
        }
    },

    validateDateInputs: function(cmp) {
        if (cmp.find("dateInput").length > 0) {
            return cmp.find("dateInput").reduce(function (validSoFar, dateInput) {
                return validSoFar && dateInput.get('v.validity').valid;
            }, true);
        }
        return true;
    },

    setCurrencySymbol: function(cmp, currencyCode) {
        let currencySymbol = "";
        switch (currencyCode) {
            case "USD": currencySymbol = "$"; break;
            case "EUR": currencySymbol = "€"; break;
            case "JPY": currencySymbol = "¥"; break;
        }
        cmp.set("v.currencySymbol", currencySymbol);
    }
})