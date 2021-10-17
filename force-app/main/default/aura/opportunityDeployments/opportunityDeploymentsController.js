({
    doInit: function(component, event, helper) {
        helper.setTableColumns(component);
        helper.getDeploymentRecords(component, event);
    },
    
    handleSort: function(component, event, helper) {
        helper.handleSort(component, event);
    }
})