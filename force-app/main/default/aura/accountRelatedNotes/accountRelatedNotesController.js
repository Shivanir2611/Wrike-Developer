({
    doInit: function(component, event, helper) {
        helper.setTableColumns(component);
        helper.getNotesData(component, event, helper);
    },

    handleSort: function(component, event, helper) {
        helper.handleSort(component, event, helper);
    },
})