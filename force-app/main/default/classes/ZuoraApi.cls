public virtual class ZuoraApi {

    private Zuora.zApi zApi;

    public static ZuoraApi getInstance() {
        return (ZuoraApi)ServiceLocator.getInstance(ZuoraApi.class);
    }

    public virtual Zuora.zApi getZApiAndLogin() {
        if (this.zApi != null) {
            return this.zApi;
        }
        this.zApi = new Zuora.zApi();
        this.zApi.zlogin();
        return this.zApi;
    }

    public virtual List<Zuora.zObject> executeZQuery(String zoql) {
        return (List<Zuora.zObject>)getZApiAndLogin().zquery(zoql);
    }

    public virtual Zuora.zApi.QueryResult executeZQuery(Zuora.zApi.QueryRequest zQueryRequest) {
        return ZuoraApi.getInstance().getZApiAndLogin().zquery(zQueryRequest);
    }

    public virtual Zuora.zApi.QueryResult executeZQueryMore(Zuora.zApi.QueryMoreRequest zQueryMoreRequest) {
        return ZuoraApi.getInstance().getZApiAndLogin().zqueryMore(zQueryMoreRequest);
    }

    public virtual List<Zuora.zApi.SaveResult> zcreate(List<Zuora.zObject> zobjects) {
        return getZApiAndLogin().zcreate(zobjects);
    }

    public virtual List<Zuora.zApi.SaveResult> zupdate(List<Zuora.zObject> zobjects) {
        return getZApiAndLogin().zupdate(zobjects);
    }

    public virtual List<Zuora.zApi.SaveResult> zgenerate(List<Zuora.zObject> invoiceList) {
        return getZApiAndLogin().zgenerate(invoiceList);
    }
}