({
    executeMode : function(component, event, helper) {
        var action = component.get("c.runOwnerRules");
        action.setParams({
            "recordId":component.get('v.recordId'),
            "mode":component.get('v.SelectedMode')
        });
        action.setCallback(component,function(response) {
            var state = response.getState();
            if (state === 'SUCCESS'){
                var toastEvent = $A.get("e.force:showToast");
                $A.get("e.force:closeQuickAction").fire();
                toastEvent.setParams({
                    mode: 'pester',
                    message: 'The records have been updated successfully.',
                });
                toastEvent.fire();
            }
        }
                          );
        $A.enqueueAction(action);
    }
})