({
    setTableColumns : function(component) {    
        component.set('v.columns', [
            { label: 'Name', fieldName: 'DeploymentName', sortable: true, type: 'url',
            typeAttributes: {
                label: { fieldName: 'Name' },
                target : '_blank'
            }},
            { label: 'Owner', fieldName: 'OwnerName', sortable: true},
            { label: 'Consultant', fieldName: 'Consultant_Selected__c', sortable: true},
            { label: 'Package', fieldName: 'Deployment_Package2__c', sortable: true},
            { label: 'Add-On', fieldName: 'AddOns__c', sortable: true},
            { label: 'Status', fieldName: 'Status__c', sortable: true},
            { label: 'Delivery Deadline', fieldName: 'Master_Delivery_Deadline__c', sortable: true},
        ]);
    },
    
    getDeploymentRecords : function(component, event) { 
    	const action = component.get('c.getDeployments');
        action.setParams({
            recordId : component.get('v.recordId')
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                response.getReturnValue().forEach(function(record){
                    if(component.get('v.Source') == "Internal"){
                        record.DeploymentName = '/'+record.Id;
                    } else{
                        record.DeploymentName = '/profsvcs/s/detail/'+record.Id;
                    }
                    record.OwnerName = record.Owner.Name;
                });
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