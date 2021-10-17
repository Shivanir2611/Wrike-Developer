public class ZuoraApiMock extends ZuoraApi {

    private String zoql;

    public override Zuora.zApi getZApiAndLogin() {
        return new Zuora.zApi();
    }

    public override List<Zuora.zObject> executeZQuery(String zoql) {

        Integer startIndex = zoql.indexOf('FROM ');
        Integer endIndex = zoql.indexOf(' ', startIndex + 5);
        if (endIndex == -1) {
            endIndex = zoql.length();
        }
        String zType = zoql.substring(startIndex + 5, endIndex);

        Zuora.zObject zObject = new Zuora.zObject(zType);
        zObject.setValue('Id', '1');
        if (zType == 'ProductRatePlan') {
            zObject.setValue('ProductId', '1');
        } else if (zType == 'ProductRatePlanCharge') {
            zObject.setValue('ProductRatePlanId', '1');
            zObject.setValue('ProductRatePlanId', '1');
            zObject.setValue('ListPriceBase', 'Per Billing Period');
        } else if (zType == 'ProductRatePlanChargeTier') {
            zObject.setValue('ProductRatePlanChargeId', '1');
            zObject.setValue('Tier', 0);
        } else if (zType == 'PaymentMethod') {
            zObject.setValue('CreditCardHolderName', 'TestF TestL');
            zObject.setValue('Country', 'United States');
            zObject.setValue('State', 'CA');
        } else if (zType == 'Contact') {
            zObject.setValue('Country', 'United States');
            zObject.setValue('State', 'AB');
        }
        return new List<Zuora.zObject>{zObject};
    }

    public override Zuora.zApi.QueryResult executeZQuery(Zuora.zApi.QueryRequest zQueryRequest) {
        this.zoql = zQueryRequest.zoql;
        Zuora.zApi.QueryResult zQueryResult = new Zuora.zApi.QueryResult();
        zQueryResult.done = false;
        zQueryResult.records = executeZQuery(this.zoql);
        return zQueryResult;
    }

    public override Zuora.zApi.QueryResult executeZQueryMore(Zuora.zApi.QueryMoreRequest zQueryMoreRequest) {
        Zuora.zApi.QueryResult zQueryResult = new Zuora.zApi.QueryResult();
        zQueryResult.done = true;
        zQueryResult.records = executeZQuery(this.zoql);
        return zQueryResult;
    }

    public override List<Zuora.zApi.SaveResult> zcreate(List<Zuora.zObject> zobjects) {
        return new List<Zuora.zApi.SaveResult>{createSaveResult()};
    }

    public override List<Zuora.zApi.SaveResult> zupdate(List<Zuora.zObject> zobjects) {
        return new List<Zuora.zApi.SaveResult>{createSaveResult()};
    }

    public override List<Zuora.zApi.SaveResult> zgenerate(List<Zuora.zObject> invoiceList) {
        return new List<Zuora.zApi.SaveResult>{createSaveResult()};
    }

    private Zuora.zApi.SaveResult createSaveResult() {
        Zuora.zApi.SaveResult saveResult = new Zuora.zApi.SaveResult();
        saveResult.Id = 'Id';
        saveResult.Success = true;
        return saveResult;
    }
}