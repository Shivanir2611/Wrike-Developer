({
    init: function (cmp, event, helper) {
        helper.doAction(cmp, "findQuoteById", function (response) {
            if (response.getState() === "SUCCESS") {
                const quote = response.getReturnValue();
                console.log(quote);
                cmp.set("v.quote", quote);
                if (cmp.get("v.subscription") == null && quote.status === "PendingDocument") {
                    helper.subscribeQuoteStatusUpdate(cmp);
                } else {
                    helper.disablePreloader(cmp);
                }
            } else {
                cmp.set("v.preloader", false);
                cmp.set("v.errorMessage", JSON.stringify(response.getError()[0]));
            }
        });
    },

    changeStatusToDraft: function(cmp, event, helper) {
        cmp.set("v.draftConfirmation", false);
        helper.doActionAndRefresh(cmp, "changeQuoteStatusToDraft");
    },

    generateDocument: function(cmp, event, helper) {
        helper.doAction(cmp, "validateAddress", function (response) {
            helper.disablePreloader(cmp);
            if (response.getState() === "SUCCESS") {
                if (response.getReturnValue()) {
                    helper.subscribeQuoteStatusUpdate(cmp);
                    helper.doActionAndSetQuote(cmp, "initiateDocumentGeneration");
                } else {
                    const toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "message": "Please provide a valid postal code for the selected state.",
                        "type": "error"
                    });
                    toastEvent.fire();
                }
            } else {
                cmp.set("v.errorMessage", JSON.stringify(response.getError()[0]));
            }
        });
    },

    deleteDocument: function(cmp, event, helper) {
        helper.doActionAndSetQuote(cmp, "deleteQuoteDocument");
    },

    openLineEditor: function(cmp, event, helper) {
        helper.getUrlAndNavigate(cmp, "getQuoteLineEditorUrl");
    },

    createOrder: function (cmp, event, helper) {
        helper.doActionAndSetQuote(cmp, "generateOrderAndContract");
    },

    sendViaDocuSign: function (cmp, event, helper) {
        helper.getUrlAndOpenNewTab(cmp,"getDocuSignUrl");
    },

    cancelDocuSign: function (cmp, event, helper) {
        helper.doActionAndSetQuote(cmp,"cancelDocuSignEnvelope");
    },

    backToDocumentGeneratedStep: function (cmp, event, helper) {
        helper.doActionAndSetQuote(cmp, "setDocumentGeneratedStatus");
    },

    editCustomBilling: function (cmp, event, helper) {
        cmp.find("navService").navigate({
            "type": "standard__component",
            "attributes": {
                "componentName": "c__customBillingSchedule"
            },
            "state": {
                "c__quoteId": cmp.get("v.recordId")
            }
        });
    },

    generatePreview: function(cmp, event, helper) {
        if (!cmp.get("v.quote").previewMessage) {
            helper.getUrlAndOpenNewTab(cmp,"getPreviewUrl");
        }
    },

    delete: function (cmp, event, helper) {
        helper.doAction(cmp, "beforeDeleteQuote", function (response) {
            if (response.getState() === "SUCCESS") {
                if (response.getReturnValue()) {
                    cmp.find("recordHandler").deleteRecord($A.getCallback(function(deleteResult) {
                        cmp.find("navService").navigate({
                            "type" : "standard__recordPage",
                            "attributes": {
                                "recordId": cmp.get("v.quote").opportunityId,
                                "actionName": "view"
                            }
                        }, true);
                    }));
                } else {
                    $A.get('e.force:refreshView').fire();
                }
            } else {
                cmp.set("v.preloader", false);
                cmp.set("v.errorMessage", JSON.stringify(response.getError()[0]));
            }
        });
    },

    enableDraftConfirmation: function(cmp, event, helper) {
        cmp.set("v.draftConfirmation", true);
    },

    disableDraftConfirmation: function(cmp, event, helper) {
        cmp.set("v.draftConfirmation", false);
    },

    enableDeleteConfirmation: function(cmp, event, helper) {
        cmp.set("v.deleteConfirmation", true);
    },

    disableDeleteConfirmation: function(cmp, event, helper) {
        cmp.set("v.deleteConfirmation", false);
    },

    enableCancelQuoteConfirmation: function(cmp, event, helper) {
        cmp.set("v.cancelQuoteConfirmation", true);
    },

    disableCancelQuoteConfirmation: function(cmp, event, helper) {
        cmp.set("v.cancelQuoteConfirmation", false);
    },

    cancelQuote: function (cmp, event, helper) {
        $A.enqueueAction(cmp.get("c.disableCancelQuoteConfirmation"));
        helper.doActionAndRefresh(cmp,"changeQuoteStatusToCancelled");
    },

    startApproval: function(cmp, event, helper) {
        if (!cmp.get("v.quote").startApprovalMessage) {
            helper.doActionAndRefresh(cmp, "activateQuote");
        }
    },

    makePrimary: function(cmp, event, helper) {
        $A.enqueueAction(cmp.get("c.disableMakePrimaryConfirmation"));
        helper.doActionAndRefresh(cmp, "makeQuotePrimary");
    },

    showMakePrimaryConfirmation: function(cmp, event, helper) {
        if (!cmp.get("v.quote").makePrimaryMessage) {
            helper.doAction(cmp, "getExistingPrimaryQuoteId", function (response) {
                cmp.set("v.preloader", false);
                if (response.getState() === "SUCCESS") {
                    const existingPrimaryQuoteId = response.getReturnValue();
                    if (existingPrimaryQuoteId) {
                        cmp.set("v.existingPrimaryQuoteId", existingPrimaryQuoteId);
                        cmp.set("v.makePrimaryConfirmation", true);
                    } else {
                        $A.enqueueAction(cmp.get("c.makePrimary"));
                    }
                } else {
                    cmp.set("v.errorMessage", JSON.stringify(response.getError()[0]));
                }
            });
        }
    },

    disableMakePrimaryConfirmation: function(cmp, event, helper) {
        cmp.set("v.makePrimaryConfirmation", false);
    },

    openBillToShipToForm: function(cmp, event, helper) {
        helper.enablePreloader(cmp);
        helper.doAction(cmp, "getDocumentIsNotGeneratedYet", (response) => {
            if (response.getState() === "SUCCESS") {
                if (response.getReturnValue()) {
                    $A.createComponent("c:billToShipToForm", {
                            quoteId: cmp.get("v.recordId"),
                            hasEndCustomer: cmp.get("v.quote").hasPartnerAccount
                        },
                        function(content, status) {
                            if (status === "SUCCESS") {
                                helper.disablePreloader(cmp);
                                cmp.find("overlayLib").showCustomModal({
                                    body: content,
                                    showCloseButton: true,
                                    cssClass: "slds-modal_medium cQuoteHeader overlay-modal"
                                })
                            }
                        });
                } else {
                    $A.get('e.force:refreshView').fire();
                }
            } else {
                cmp.set("v.preloader", false);
                cmp.set("v.errorMessage", JSON.stringify(response.getError()[0]));
            }
        });
    },

    openPartnerSelection: function(cmp, event, helper) {
        helper.enablePreloader(cmp);
        helper.doAction(cmp, "getPartnerUpdateAllowed", (response) => {
            if (response.getState() === "SUCCESS") {
                if (response.getReturnValue()) {
                    $A.createComponent("c:quotePartnerSelection", {quoteId: cmp.get("v.recordId")},
                        function(content, status) {
                            if (status === "SUCCESS") {
                                helper.disablePreloader(cmp);
                                cmp.find("overlayLib").showCustomModal({
                                    body: content,
                                    showCloseButton: false,
                                    cssClass: "cQuoteHeader overlay-modal"
                                })
                            }
                        });
                } else {
                    $A.get('e.force:refreshView').fire();
                }
            } else {
                cmp.set("v.preloader", false);
                cmp.set("v.errorMessage", JSON.stringify(response.getError()[0]));
            }
        });
    },

    openWrikeAccountRegistration: function(cmp, event, helper) {
        helper.enablePreloader(cmp);
        helper.doAction(cmp, "getDocumentIsNotGeneratedYet", (response) => {
            if (response.getState() === "SUCCESS") {
                if (response.getReturnValue()) {
                    $A.createComponent("c:wrikeAccountRegistration", {quoteId: cmp.get("v.recordId")},
                        function(content, status) {
                            if (status === "SUCCESS") {
                                helper.disablePreloader(cmp);
                                cmp.find("overlayLib").showCustomModal({
                                    body: content,
                                    showCloseButton: true,
                                    cssClass: "cQuoteHeader btst"
                                })
                            }
                        });
                } else {
                    $A.get('e.force:refreshView').fire();
                }
            } else {
                cmp.set("v.preloader", false);
                cmp.set("v.errorMessage", JSON.stringify(response.getError()[0]));
            }
        });
    },

    onApprovalMenuSelect: function(cmp, event, helper) {
        const selectedMenuItemValue = event.getParam("value");
        if (selectedMenuItemValue === "previewApproval") {
            helper.getUrlAndOpenNewTab(cmp, "getApprovalPreviewUrl");
        }
    },

    cloneQuote: function(cmp, event, helper) {
        helper.getUrlAndOpenNewTab(cmp, "getCloneUrl");
    }
});