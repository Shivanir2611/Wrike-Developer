({
    fireChangeEvent: function (cmp, event, helper) {
        if (cmp.get("v.contact").QS_Bill_To__c) {
            cmp.getEvent("onBillToChange").fire();
        }
    },

    handleEventCountryCodeChanged: function (cmp, event, helper) {
        if (!cmp.get("v.disabled")) {
            const usStateOptions = cmp.get("v.usStateOptions");
            const canadaStateOptions = cmp.get("v.canadaStateOptions");
            if (usStateOptions != null && canadaStateOptions != null) {
                const contact = cmp.get("v.contact");
                const countryCode = contact.QS_Country_Code__c;
                const isCountryWithStates = countryCode === "US" || countryCode === "CA";
                cmp.set("v.isCountryWithStates", isCountryWithStates);
                cmp.set("v.showVatNumber", helper.isVatNumberCountryCode(countryCode) && contact.QS_Bill_To__c);
                if (isCountryWithStates) {
                    if (countryCode === "US") {
                        cmp.set("v.stateOptions", usStateOptions);
                    }
                    if (countryCode === "CA") {
                        cmp.set("v.stateOptions", canadaStateOptions);
                    }
                }
            }
        }
    },

    handleCountrySelectorChanged: function (cmp, event, helper) {
        const contact = cmp.get("v.contact");
        contact.QS_State_Code__c = null;
        contact.RegionState__c = null;
        cmp.set("v.contact", contact);
    },

    validate: function (cmp, event, helper) {
        return cmp.find("inputField").reduce(function (validSoFar, inputField) {
            const label = inputField.get("v.label");
            if (label === 'Additional Emails') {
                const emailRe = /[a-zA-Z0-9._|\\%#~`=?&amp;/$^*!}{+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,10}/g;
                const value = cmp.get("v.contact").QS_Secondary_Email__c;
                const notValid = value !== undefined
                    && value !== ""
                    && value.split(",")
                    .some(email => email.match(emailRe) == null);
                inputField.setCustomValidity(notValid ? "Only multiple email addresses separated by comma are allowed." : "");
                inputField.reportValidity();
            }
            inputField.showHelpMessageIfInvalid();
            return validSoFar && inputField.get("v.validity").valid;
        }, true);
    }
})