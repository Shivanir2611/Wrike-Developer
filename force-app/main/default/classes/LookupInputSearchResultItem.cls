public class LookupInputSearchResultItem {
    @AuraEnabled
    public Id id {get; set;}
    @AuraEnabled
    public String icon {get; set;}
    @AuraEnabled
    public String title {get; set;}
    @AuraEnabled
    public String subtitle {get; set;}

    public LookupInputSearchResultItem(final Id id,
                                       final String icon,
                                       final String title,
                                       final String subtitle) {
        this.id = id;
        this.icon = icon;
        this.title = title;
        this.subtitle = subtitle;
    }
}