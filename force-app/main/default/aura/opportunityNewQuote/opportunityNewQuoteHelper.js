({
    navigateToQuoteLines: function (component, quoteId) {
        component.find("navigationService").navigate({
            "type": "standard__webPage",
            "attributes": {
                "url": "/apex/SBQQ__sb?id=" + quoteId
            }
        });
    }
});