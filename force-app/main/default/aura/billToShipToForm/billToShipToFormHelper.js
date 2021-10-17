({
    getBillToShipToForm: function (cmp) {
        this.enablePreloader(cmp);
        const accountId = cmp.get("v.recordId");
        let action;
        if (accountId !== undefined) {
            action = cmp.get("c.getFormByAccountId");
            action.setParams({accountId: accountId});
        } else {
            action = cmp.get("c.getFormByQuoteId");
            action.setParams({quoteId: cmp.get("v.quoteId")});
        }
        action.setCallback(this, function (response) {
            if (response.getState() === "SUCCESS") {
                const billToShipToForm = response.getReturnValue();
                cmp.set("v.countryMap", billToShipToForm.countryMap);
                cmp.set("v.usStateMap", billToShipToForm.usStateMap);
                cmp.set("v.canadaStateMap", billToShipToForm.canadaStateMap);
                cmp.set("v.usStateOptions", this.getOptionsFromMap(billToShipToForm.usStateMap));
                cmp.set("v.canadaStateOptions", this.getOptionsFromMap(billToShipToForm.canadaStateMap));
                cmp.set("v.countryOptions", this.getOptionsFromMap(billToShipToForm.countryMap));
                cmp.set("v.billTo", billToShipToForm.billTo);
                cmp.set("v.shipTo", billToShipToForm.shipTo);
                cmp.set("v.endCustomer", billToShipToForm.endCustomer);
                this.disablePreloader(cmp);
            }
        });
        $A.enqueueAction(action);
    },

    save: function (cmp) {
        this.enablePreloader(cmp);
        const action = cmp.get("c.saveContacts");
        action.setParams({
            quoteId: cmp.get("v.quoteId"),
            billTo: cmp.get("v.billTo"),
            shipTo: cmp.get("v.shipTo"),
            endCustomer: cmp.get("v.endCustomer")
        });
        action.setCallback(this, function (response) {
            if (response.getState() === "SUCCESS") {
                cmp.find("overlayLib").notifyClose();
                $A.get('e.force:refreshView').fire();
            }
        });
        $A.enqueueAction(action);
    },

    setCountryStateNames: function (cmp) {
        cmp.set("v.billTo", this.setContactCountryStateNames(cmp, cmp.get("v.billTo")));
        cmp.set("v.shipTo", this.setContactCountryStateNames(cmp, cmp.get("v.shipTo")));
        if (cmp.get("v.hasEndCustomer")) {
            cmp.set("v.endCustomer", this.setContactCountryStateNames(cmp, cmp.get("v.endCustomer")));
        }
    },

    setContactCountryStateNames: function (cmp, contact) {
        const countryMap = cmp.get("v.countryMap");
        const usStateMap = cmp.get("v.usStateMap");
        const canadaStateMap = cmp.get("v.canadaStateMap");

        contact.QS_Country__c = countryMap[contact.QS_Country_Code__c];
        if (contact.QS_Country_Code__c === "US") {
            contact.RegionState__c = usStateMap[contact.QS_State_Code__c];
        }
        if (contact.QS_Country_Code__c === "CA") {
            contact.RegionState__c = canadaStateMap[contact.QS_State_Code__c];
        }
        return contact;
    },

    enablePreloader: function(cmp) {
        cmp.set("v.preloader", true);
    },

    disablePreloader: function(cmp) {
        cmp.set("v.preloader", false);
    },

    getOptionsFromMap: function(map) {
        return Object.entries(map).map(entry => ({ value: entry[0], label: entry[1] }))
    }
})