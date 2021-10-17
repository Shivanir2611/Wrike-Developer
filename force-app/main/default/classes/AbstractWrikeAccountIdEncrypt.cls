public abstract class AbstractWrikeAccountIdEncrypt {
    
    public abstract Decimal getWrikeAccountId();
    
    public String getEncryptedWrikeAccountId() {
        return WrikeUtil.getEncryptedData(getWrikeAccountId(), null);
    }
    
    public String getWrikeURL() {
        return SettingsProvider.getWrikeSupportappURL();
    }
}