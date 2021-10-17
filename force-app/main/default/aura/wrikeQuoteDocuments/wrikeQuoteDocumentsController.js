({
    init: function (cmp, event, helper) {
        helper.getDocuments(cmp);
    },

    handleUploadFinished: function (cmp, event, helper) {
        const files = event.getParam("files");
        if (files.length > 0) {
            helper.createDocuments(cmp, files);
        }
    },

    handleTableItemSelect: function (cmp, event, helper) {
        const itemId = event.getParam("value").split(',')[0];
        const action = event.getParam("value").split(',')[1];
        if (action === "Delete") {
            helper.deleteItem(cmp, itemId);
        }
    },

    previewFile: function (cmp, event, helper) {
        const fileId = event.target.id;
        cmp.find("navService").navigate({
            "type": "standard__namedPage",
            "attributes": {
                "pageName": "filePreview"
            },
            "state": {
                "recordIds": fileId
            }
        });
    }
})