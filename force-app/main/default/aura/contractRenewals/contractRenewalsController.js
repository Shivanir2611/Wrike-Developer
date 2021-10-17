({
    init: function (component, event, helper) {
        helper.refreshContracts(component);
    },

    handleShowModal: function(component, event, helper) {
        $A.createComponent("c:contractRenewalForm", {contractId: event.getSource().get('v.value')},
            function(content, status) {
                if (status === "SUCCESS") {
                    component.find('overlayLib').showCustomModal({
                        header: "Contract Renewal",
                        body: content,
                        showCloseButton: true,
                        cssClass: "renewal-form",
                        closeCallback: function() {
                            helper.refreshContracts(component);
                        }
                    })
                }
            });
    }
});