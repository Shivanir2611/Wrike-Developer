({
    doInit : function(component, event, helper) {
        var checkEditAccessAction = component.get("c.getAccess");         
        checkEditAccessAction.setParams({
            recordId: component.get("v.recordId")         
        });         
        checkEditAccessAction.setCallback(this, function(response){
            var retResponse = response.getReturnValue();             
            component.set("v.access", retResponse);
        });         
        $A.enqueueAction(checkEditAccessAction);
        var action = component.get("c.getFields");
        action.setParams({
            typeName: component.get("v.objectApiName"),
            fsName: component.get("v.fieldSetName")
        });
        action.setCallback(this, function(a) {
            var fields = a.getReturnValue();
            var columns = component.get('v.columns');
            if (columns === '1') {
                component.set("v.fields", fields);
            } else if (columns === '2') {
                var fields2 = [];
                var lastIndex = fields.length - 1;
                for (var i = 0; i < fields.length; i += 2) {
                    var elem = {};
                    elem['field1'] = fields[i].fieldPath;
                    if (i < lastIndex) {
                        elem['field2'] = fields[i + 1].fieldPath;
                    }
                    fields2.push(elem);
                }
                component.set("v.fields", fields2);
            }
        });
        $A.enqueueAction(action);  
    },
    fireRefreshView : function(component, event, helper) {
        $A.get('e.force:refreshView').fire();
    },
    handleToggle : function(component, event, helper) {
        $A.get('e.force:refreshView').fire();
        var inputModeBool = component.get("v.inputModeBool");
        component.set("v.inputModeBool", !inputModeBool);
    }
})