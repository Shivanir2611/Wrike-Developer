({
    getDocuments: function (cmp) {
        cmp.set("v.preloader", true);
        const action = cmp.get("c.findDocuments");
        action.setParams({quoteId: cmp.get("v.recordId")});
        action.setCallback(this, function (response) {
            if (response.getState() === "SUCCESS") {
                cmp.set("v.documents", response.getReturnValue());
            } else {
                cmp.set("v.errorMessage", JSON.stringify(action.getError()[0]));
            }
            cmp.set("v.preloader", false);
        });
        $A.enqueueAction(action);
    },

    createDocuments: function (cmp, files) {
        cmp.set("v.preloader", true);
        const action = cmp.get("c.createWrikeQuoteDocuments");
        action.setParams({
            quoteId: cmp.get("v.recordId"),
            files: files
        });
        action.setCallback(this, function (response) {
            if (response.getState() === "SUCCESS") {
                cmp.set("v.documents", response.getReturnValue());
            } else {
                cmp.set("v.errorMessage", JSON.stringify(action.getError()[0]));
            }
            cmp.set("v.preloader", false);
        });
        $A.enqueueAction(action);
    },

    deleteItem: function (cmp, id) {
        cmp.set("v.preloader", true);
        const action = cmp.get("c.deleteWrikeQuoteDocument");
        action.setParams({wrikeQuoteDocumentId: id});
        action.setCallback(this, function (response) {
            if (response.getState() === "SUCCESS") {
                const documents = cmp.get("v.documents").filter(document => document.id !== id);
                cmp.set("v.documents", documents);
            } else {
                cmp.set("v.errorMessage", JSON.stringify(action.getError()[0]));
            }
            cmp.set("v.preloader", false);
        });
        $A.enqueueAction(action);
    }
})