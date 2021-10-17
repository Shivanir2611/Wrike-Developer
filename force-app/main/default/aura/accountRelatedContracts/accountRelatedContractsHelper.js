({
    setTableColumns : function(component) {    
        component.set('v.columns', [
            { label: 'Contract', fieldName: 'ContractName', sortable: true, type: 'url', fixedWidth: 120,
            typeAttributes: {
                label: { fieldName: 'ContractNumber' },
                target : '_blank'  
            }},
            { label: 'Term', fieldName: 'ContractTerm', sortable: true, fixedWidth: 100},
            { label: 'Agreement Type', fieldName: 'Agreement_Type__c', sortable: true},
            { label: 'Contract Status', fieldName: 'Status', sortable: true, fixedWidth: 140},
            { label: 'Contract Notes', fieldName: 'Catch_All_Notes__c', sortable: true, wrapText: true},
        ]);
    },
    
    getContracts : function(component, event, helper) { 
    	const action = component.get('c.getContracts');
        action.setParams({
            recordId : component.get('v.recordId')
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                response.getReturnValue().forEach(function(record){
                    record.ContractName = '/'+record.Id;
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