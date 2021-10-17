({
    onConfirm: function(cmp, event, helper) {
        cmp.getEvent('onConfirm').fire();
    },

    onCancel: function(cmp, event, helper) {
        cmp.getEvent('onCancel').fire();
    }
})