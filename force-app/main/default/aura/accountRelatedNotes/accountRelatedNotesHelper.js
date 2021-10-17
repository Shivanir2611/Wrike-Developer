({
    setTableColumns : function(component) {        
        component.set('v.columns', [
            { label: 'Title', fieldName: 'titleName', sortable: true, type: 'url',  
             typeAttributes: {
                 label: { fieldName: 'title' },
                 target : '_blank'  
            }},
            { label: 'Description', fieldName: 'description', sortable: true},
            { label: 'Related To', fieldName: 'relatedToName', sortable: true, type: 'url',
            typeAttributes: {
                label: { fieldName: 'relatedTo' },
                target : '_blank'  
            }},
            { label: 'Related Type', fieldName: 'relatedType', sortable: true},
            { label: 'Owner Name', fieldName: 'ownerName', sortable: true},
            { label: 'Created Date', fieldName: 'createdDate', sortable: true}, 
        ]);
    },

    getNotesData : function(component, event, helper) {
    	const action = component.get('c.getRelatedNotes');
            action.setParams({
                recordId : component.get('v.recordId')
            });
            action.setCallback(this,function(response){
                const state = response.getState();
                if (state === "SUCCESS") {
                    response.getReturnValue().forEach(function(record){
                        record.titleName = '/'+record.titleId;
                        record.relatedToName = '/'+ record.relatedToId;
                    });
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