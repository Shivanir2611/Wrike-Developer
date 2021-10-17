({
    doInit: function(component, event, helper) {
        helper.setTableColumns(component);
        helper.getCampaignMembers(component, event);
    },
    
    handleSort: function(component, event, helper) {
        helper.handleSort(component, event);
    }
})