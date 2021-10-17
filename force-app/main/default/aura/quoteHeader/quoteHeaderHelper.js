({
    doAction: function (cmp, actionName, cb) {
        cmp.set("v.errorMessage", null);
        this.enablePreloader(cmp);
        const action = cmp.get("c." + actionName);
        action.setParams({quoteId: cmp.get("v.recordId")});
        action.setCallback(this, cb);
        $A.enqueueAction(action);
    },

    doActionAndSetQuote: function (cmp, actionName) {
        this.doAction(cmp, actionName, (response) => {
            if (response.getState() === "SUCCESS") {
                const quote = response.getReturnValue();
                cmp.set("v.quote", quote);
                if (quote.status !== "PendingDocument") {
                    this.disablePreloader(cmp);
                }
            } else {
                cmp.set("v.preloader", false);
                cmp.set("v.errorMessage", JSON.stringify(response.getError()[0]));
            }
        });
    },

    doActionAndRefresh: function (cmp, actionName) {
        this.doAction(cmp, actionName, function (response) {
            if (response.getState() === "SUCCESS") {
                $A.get('e.force:refreshView').fire();
            } else {
                cmp.set("v.preloader", false);
                cmp.set("v.errorMessage", JSON.stringify(response.getError()[0]));
            }
        });
    },

    getUrlAndOpenNewTab: function (cmp, actionName) {
        this.doAction(cmp, actionName, function (response) {
            cmp.set("v.preloader", false);
            if (response.getState() === "SUCCESS") {
                const url = response.getReturnValue();
                if (url) {
                    let a = document.getElementById("redirect");
                    a.href = url;
                    a.click();
                } else {
                    $A.get('e.force:refreshView').fire();
                }
            } else {
                cmp.set("v.errorMessage", JSON.stringify(response.getError()[0]));
            }
        });
    },

    getUrlAndNavigate: function (cmp, actionName) {
        this.doAction(cmp, actionName, function (response) {
            cmp.set("v.preloader", false);
            if (response.getState() === "SUCCESS") {
                const url = response.getReturnValue();
                if (url) {
                    cmp.find("navService").navigate({
                        "type": "standard__webPage",
                        "attributes": {
                            "url": url
                        }
                    });
                } else {
                    $A.get('e.force:refreshView').fire();
                }
            } else {
                cmp.set("v.errorMessage", JSON.stringify(response.getError()[0]));
            }
        });
    },

    enablePreloader: function(cmp) {
        cmp.set("v.preloader", true);
    },

    disablePreloader: function(cmp) {
        cmp.set("v.preloader", false);
    },

    subscribeQuoteStatusUpdate: function(cmp) {
        console.log("subscribeQuoteStatusUpdate...");
        const empApi = cmp.find("empApi");
        empApi.subscribe("/topic/UpdateQuoteStatus", -1, $A.getCallback(event => {
            console.log(event);
            if (event.data.sobject.Id === cmp.get("v.recordId")) {
                empApi.unsubscribe(cmp.get("v.subscription"), () => {});
                $A.get('e.force:refreshView').fire();
            }
        })).then(subscription => {
            cmp.set("v.subscription", subscription);
        });
    }
})