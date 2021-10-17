({
    setTableColumns : function(component) {    
        component.set('v.columns', [
            { label: 'Opportunity Name', fieldName: 'OpportunityName', sortable: true, type: 'url',
            typeAttributes: {
                label: { fieldName: 'Name' },
                target : '_blank'  
            }},
            { label: 'Stage', fieldName: 'StageName', sortable: true, fixedWidth: 100},
            { label: 'Primary Contact', fieldName: 'PrimaryContactId', sortable: true, type: 'url',
            typeAttributes: {
                label: { fieldName: 'PrimaryContactName' },
                target : '_blank'  
            }},
            { label: 'Reasons Won', fieldName: 'Reasons_Lost__c', sortable: true},
            { label: 'Customer Goals', fieldName: 'Customer_Goals__c', sortable: true, wrapText: true},
        ]);
    },
    
    getOpportunities : function(component, event, helper) { 
    	const action = component.get('c.getOpportunities');
        action.setParams({
            recordId : component.get('v.recordId')
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                response.getReturnValue().forEach(function(record){
                    record.OpportunityName = '/'+record.Id;
                    if (record.Billing_Contact__c) {
                        record.PrimaryContactId = '/'+record.Billing_Contact__c;
                        record.PrimaryContactName = record.Billing_Contact__r.Name; 
                    }
            	})
            	component.set('v.returnData', response.getReturnValue());
                component.set("v.maxPage", Math.floor((response.getReturnValue().length+9)/10));
                helper.renderPageData(component);
            }
        });
        $A.enqueueAction(action);	    
    },
    
    handleSort: function(component, event, helper) {
        helper.handleSortData(component,event, event.getParam('fieldName'), event.getParam('sortDirection'));
    },
})