({
    fetchValues : function(component, event, helper) {
        var action = component.get("c.getVBPSPicklist");
        action.setCallback(this, function(response){
            var state = response.getState();
            component.set("v.showSpinner", false);
            if(state === "SUCCESS") {
                var vbps = response.getReturnValue();
                if(vbps != null) {
                    component.set("v.verticalList", vbps.verticalValuesList);
                    component.set("v.keyToLOVMap", vbps.keyToLOVMap);
                    let record = component.get("v.record");
                    if(record) {
                        let vertical = record.Vertical2__c;
                        let businessArea = record.Business_Area__c;
                        let primaryUseCase = record.Primary_Use_Case__c;
                        let secondaryUseCase = record.Secondary_Use_Case__c;
                        if(vertical) {
                            let keyToLOVMap = component.get("v.keyToLOVMap");
                            let businessAreaList = keyToLOVMap[vertical];
                            component.set("v.businessAreaList", businessAreaList);
                            component.set("v.primaryUseCaseList", []);
                            component.set("v.secondaryUseCaseList", []);
                            if(businessArea){
                                let key2 = vertical + '~' + businessArea;
                                let primaryUseCaseList = keyToLOVMap[key2];
                                component.set("v.primaryUseCaseList", primaryUseCaseList);
                                component.set("v.secondaryUseCaseList", []);
                                if(primaryUseCase){
                                    let key3 = vertical + '~' + businessArea + '~' + primaryUseCase;
                                    let secondaryUseCaseList = keyToLOVMap[key3];
                                    component.set("v.secondaryUseCaseList", secondaryUseCaseList);
                                }
                            }
                        }
                        window.setTimeout(
                            $A.getCallback( function() {
                                component.set("v.vertical", vertical);
                                component.set("v.businessArea", businessArea);
                                component.set("v.primaryUseCase", primaryUseCase);
                                component.set("v.secondaryUseCase", secondaryUseCase); 
                                component.find("vertical").set("v.value", vertical);
                                component.find("businessArea").set("v.value", businessArea);
                                component.find("primaryUseCase").set("v.value", primaryUseCase);
                                component.find("secondaryUseCase").set("v.value", secondaryUseCase);
                            })
                        );   
                    }
                }
            }else if(state === "ERROR") {
                $A.get("e.force:closeQuickAction").fire();
		        $A.get("e.force:showToast").setParams({ "title": "Error", "type": "error","mode": "dismissible", "message": "Something went wrong." }).fire();
            }
            
        });
        $A.enqueueAction(action);
    },

    onVerticalChanged : function(component, event, helper) {
        let vertical = component.get("v.vertical");
        let keyToLOVMap = component.get("v.keyToLOVMap");
        let businessAreaList = keyToLOVMap[vertical];
        component.set("v.businessAreaList", businessAreaList);
        component.set("v.primaryUseCaseList", []);
        component.set("v.secondaryUseCaseList", []);
    },
    onBusinessAreaChanged : function(component, event, helper) {
        let vertical = component.get("v.vertical");
        let businessArea = component.get("v.businessArea");
        let key = vertical + '~' + businessArea;
        let keyToLOVMap = component.get("v.keyToLOVMap");
        let primaryUseCaseList = keyToLOVMap[key];
        component.set("v.primaryUseCaseList", primaryUseCaseList);
        component.set("v.secondaryUseCaseList", []);
    },
    onPrimaryUseCaseChanged : function(component, event, helper) {
        let vertical = component.get("v.vertical");
        let businessArea = component.get("v.businessArea");
        let primaryUseCase = component.get("v.primaryUseCase");
        let key = vertical + '~' + businessArea + '~' + primaryUseCase;
        let keyToLOVMap = component.get("v.keyToLOVMap");
        let secondaryUseCaseList = keyToLOVMap[key];
        component.set("v.secondaryUseCaseList", secondaryUseCaseList);
    },
    save : function(component, event, helper){
        let recordId = component.get("v.recordId")
        let vertical = component.get("v.vertical");
        let businessArea = component.get("v.businessArea");
        let primaryUseCase = component.get("v.primaryUseCase");
        let secondaryUseCase = component.get("v.secondaryUseCase"); 
        var action = component.get("c.saveUseCaseRecord");
        component.set("v.showSpinner", true);
        action.setParams({
            "recordId" : recordId,
            "vertical" : vertical,
            "businessArea" : businessArea,
            "primaryUseCase" : primaryUseCase,
            "secondaryUseCase" : secondaryUseCase
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            component.set("v.showSpinner", false);
            if(state === "SUCCESS"){
                $A.get("e.force:closeQuickAction").fire();
                $A.get('e.force:refreshView').fire();
            }else if(state === "ERROR"){
                $A.get("e.force:closeQuickAction").fire();
		        $A.get("e.force:showToast").setParams({ "title": "Error", "type": "error","mode": "dismissible", "message": response.getError()[0].message}).fire();
            }
        });
        $A.enqueueAction(action);
    }
})