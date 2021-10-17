public class OpportunityUpdateJob implements Database.Batchable<SObject>, Schedulable {
    
    public void execute(final SchedulableContext sc) {
        Database.executeBatch(this);
    }
    
    public Database.QueryLocator start(final Database.BatchableContext context) {
        return Database.getQueryLocator([
            SELECT Id, Opportunity__c
            FROM Quote__c
            WHERE Status__c = 'SENT'
            AND Opportunity__r.StageName = 'Closed Won - Pending'
        ]);
    }
    
    public void execute(final Database.BatchableContext context, final List<Quote__c> quotes) {
        final List<Opportunity> updateOppList = new List<Opportunity>();
        if(!quotes.isEmpty()){
            for(Quote__c newQuote : quotes){
                Opportunity newOpp = new Opportunity(
                    Id = newQuote.Opportunity__c,
                    StageName = 'Closed Won'
                );
                updateOppList.add(newOpp);
            }
            if(!updateOppList.isEmpty()){
                update updateOppList;
            }
        }
    }
    
    public void finish(final Database.BatchableContext context) {
    }
}