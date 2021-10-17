({
    init: function (cmp, event, helper) {
        helper.getBillToShipToForm(cmp);
    },

    cloneShipToFromBillTo: function (cmp, event, helper) {
        if (cmp.get("v.shipToSameAsBillTo")) {
            const billTo = cmp.get("v.billTo");
            cmp.set("v.shipTo", {
                'sobjectType': 'QS_Bill_To_Ship_To__c',
                'Id': cmp.get("v.shipTo").Id,
                'QS_Country_Code__c': billTo.QS_Country_Code__c,
                'QS_State_Code__c': billTo.QS_State_Code__c,
                'QS_City__c': billTo.QS_City__c,
                'QS_Attention_To__c': billTo.QS_Attention_To__c,
                'QS_Company_Name__c': billTo.QS_Company_Name__c,
                'QS_Email__c': billTo.QS_Email__c,
                'QS_Zip_Postal_Code__c': billTo.QS_Zip_Postal_Code__c,
                'QS_Phone__c': billTo.QS_Phone__c,
                'QS_Street_1__c': billTo.QS_Street_1__c,
                'QS_Street_2__c': billTo.QS_Street_2__c,
                'QS_Secondary_Email__c': billTo.QS_Secondary_Email__c,
                'RegionState__c': billTo.RegionState__c,
                'QS_Ship_To__c': true,
                'QS_Account__c': billTo.QS_Account__c,
                'Wrike_Account_ID__c': billTo.Wrike_Account_ID__c
            });
        }
    },

    closeForm: function (cmp, event, helper) {
        cmp.find("overlayLib").notifyClose();
    },

    save: function (cmp, event, helper) {
        helper.setCountryStateNames(cmp);

        const billTo = cmp.get("v.billTo");
        const shipTo = cmp.get("v.shipTo");

        console.log("bill to: " + JSON.stringify(billTo));
        console.log("ship to: " +  JSON.stringify(shipTo));

        const isBillToValid = cmp.find("billToFields").validate();
        const isShipToValid = cmp.find("shipToFields").validate();
        const isEndCustomerValid = !cmp.get("v.hasEndCustomer") || cmp.find("endCustomerFields").validate();

        if (isBillToValid && isShipToValid && isEndCustomerValid) {
            console.log('validation...ok');
            helper.save(cmp);
        }
    }
})