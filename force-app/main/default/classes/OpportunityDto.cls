public class OpportunityDto {

    public String id;
    public String name;
    public String currencyCode;
    public Integer wrikeAccountId;
    public String accountId;
    public String accountName;
    public String billingCountryCode;
    public String vat;
    public String vatValidStatus;
    public String opportunityDataId;
    public String recordTypeDeveloperName;
    public String verticalSegment;
    public String billingContact;
    public String competitorLostTo;
    public String reasonsLostTo;
    public String subReason;
    public String lostReasonDetail;
    public String otherCompetitorsWonLostTo;
    public String otherWonLostReasons;

    public  OpportunityDto() {}

    public OpportunityDto(final String id,
                          final String name,
                          final String currencyCode,
                          final Decimal wrikeAccountId,
                          final String accountId,
                          final String company,
                          final String verticalSegment,
                          final String billingContact,
                          final String competitorLostTo,
                          final String reasonsLostTo,
                          final String subReason,
                          final String lostReasonDetail,
                          final String otherCompetitorsWonLostTo,
                          final String otherWonLostReasons) {
        this.id = id;
        this.name = name;
        this.currencyCode = currencyCode;
        this.wrikeAccountId = Integer.valueOf(wrikeAccountId);
        this.accountId = accountId;
        this.accountName = company;
        this.verticalSegment = verticalSegment;
        this.billingContact = billingContact;
        this.competitorLostTo = competitorLostTo;
        this.reasonsLostTo = reasonsLostTo;
        this.subReason = subReason;
        this.lostReasonDetail = lostReasonDetail;
        this.otherCompetitorsWonLostTo = otherCompetitorsWonLostTo;
        this.otherWonLostReasons = otherWonLostReasons;
    }
}