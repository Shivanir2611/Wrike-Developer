({
    onInput: function (cmp, event, helper) {
        let searchTimeout = cmp.get('v.searchThrottlingTimeout');
        if (searchTimeout) {
            clearTimeout(searchTimeout);
        }
        searchTimeout = window.setTimeout($A.getCallback(function() {
            const searchText = event.target.value;
            cmp.set("v.searchText", searchText);
            if (searchText.length >= 2) {
                const searchEvent = cmp.getEvent("onSearch");
                searchEvent.fire();
            } else {
                cmp.set("v.searchResultItems", []);
            }
        }), 300);
        cmp.set("v.searchThrottlingTimeout", searchTimeout);
    },

    onFocus: function (cmp, event, helper) {
        cmp.set("v.hasFocus", true);
    },

    onBlur: function (cmp, event, helper) {
        cmp.set("v.hasFocus", false);
    },

    onResultItemClick: function (cmp, event, helper) {
        const recordId = event.currentTarget.id;
        const searchResultItems = cmp.get("v.searchResultItems");
        cmp.set("v.selectedItem", searchResultItems.find(item => item.id === recordId));
        cmp.set("v.searchText", "");
        cmp.set("v.searchResultItems", []);
    },

    search: function (cmp, event, helper) {
        const action = event.getParam("arguments").serverAction;
        helper.enablePreloader(cmp);
        action.setParams({searchText: cmp.get("v.searchText")});
        action.setCallback(this, function(response) {
            helper.disablePreloader(cmp);
            if (response.getState() === "SUCCESS") {
                cmp.set("v.searchResultItems", response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
    },

    clearSelection: function (cmp, event, helper) {
        cmp.set("v.selectedItem", null);
    }
})