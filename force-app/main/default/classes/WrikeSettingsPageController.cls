global class WrikeSettingsPageController {
    private Map<String, Object> demoAccountData;
    private Boolean resetInProgress;

    public WrikeSettingsPageController() {
        refresh();
    }
    
    public void refresh() {
        this.demoAccountData = WrikeUtil.checkDemoAccount();
        this.resetInProgress = this.demoAccountData != null && ((Integer)this.demoAccountData.get('shardId')) < 0;
    }
    
    public Map<String, Object> getDemoAccountData() {
        return this.demoAccountData;
    }
    
    public List<String> getInfo() {
        final String info = this.demoAccountData != null ? (String)this.demoAccountData.get('info') : null;
        return (info != null ? info : '').split('\n', 0);
    }
    
    public Boolean getResetInProgress() {
        return this.resetInProgress;
    }
    
    public void resetDemoAccount() {
        this.resetInProgress = true;
        WrikeUtil.resetDemoAccount();
    }
    
    @RemoteAction
    global static Boolean checkResetCompleted() {
        final Map<String, Object> accountData = WrikeUtil.checkDemoAccount();
        return ((Integer)accountData.get('shardId')) > 0;                     
    }

}