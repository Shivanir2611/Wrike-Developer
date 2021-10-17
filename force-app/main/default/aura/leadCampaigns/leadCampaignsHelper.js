({
    setTableColumns : function(component) {    
        component.set('v.columns', [
            { label: 'Campaign Member', fieldName: 'CampaignMemberName', sortable: true, type: 'url',
            typeAttributes: {
                label: { fieldName: 'Name' },
                target : '_blank'  
            }},
            { label: 'Status', fieldName: 'Status', sortable: true},
            { label: 'Campaign Name', fieldName: 'CampaignID', sortable: true, type: 'url',
            typeAttributes: {
                label: { fieldName: 'CampaignName' },
                target : '_blank'  
            }},
            { label: 'Lead / Contact', fieldName: 'LeadOrContactName', sortable: true, type: 'url',
             typeAttributes: {
                 label: { fieldName: 'Name' },
                 target : '_blank'
            }},
        ]);
    },
    
    getCampaignMembers : function(component, event) { 
    	const action = component.get('c.getCampaignMembers');
        action.setParams({
            recordId : component.get('v.recordId')
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                response.getReturnValue().forEach(function(record){
                    record.CampaignMemberName = '/'+record.Id;
                    record.CampaignID = '/'+record.CampaignId;
                    record.CampaignName = record.Campaign.Name;
                    record.LeadOrContactName = '/'+record.LeadOrContactId;
            	})
            	component.set('v.data', response.getReturnValue());
            }
        });
        $A.enqueueAction(action);	    
    },
    
    sortBy: function(field, reverse, primer) {
        var key = primer
            ? function(x) {
                  return primer(x[field]);
              }
            : function(x) {
                  return x[field];
              };

        return function(a, b) {
            a = key(a);
            b = key(b);
            return reverse * ((a > b) - (b > a));
        };
    },

    handleSort: function(component, event) {
        const sortedBy = event.getParam('fieldName');
        const sortDirection = event.getParam('sortDirection');

        const cloneData = component.get('v.data').slice(0);
        cloneData.sort((this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1)));
        
        component.set('v.data', cloneData);
        component.set('v.sortDirection', sortDirection);
        component.set('v.sortedBy', sortedBy);
    }
})