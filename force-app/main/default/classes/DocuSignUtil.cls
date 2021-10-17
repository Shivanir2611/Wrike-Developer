public class DocuSignUtil {
    
    public static String findCompletedDocuSign(final String attachmentId) {
        if(String.isBlank(attachmentId)) {
            return null;
        }
        final List<dsfs__DocuSign_Envelope_Document__c> docs = 
            [SELECT dsfs__DocuSign_EnvelopeID__r.dsfs__DocuSign_Envelope_ID__c
             FROM dsfs__DocuSign_Envelope_Document__c
             WHERE (dsfs__Attachment_ID__c = :attachmentId OR dsfs__External_Document_Id__c = :attachmentId )
               AND dsfs__DocuSign_EnvelopeID__r.dsfs__DocuSign_Envelope_ID__c != NULL];
        if(docs.isEmpty()) {
            return null;
        }
        final Set<String> envelopIds = new Set<String>();
        for(dsfs__DocuSign_Envelope_Document__c doc : docs) {
            envelopIds.add(doc.dsfs__DocuSign_EnvelopeID__r.dsfs__DocuSign_Envelope_ID__c.toUpperCase());
        }
        final List<dsfs__DocuSign_Status__c> statuses = 
            [SELECT Id 
             FROM dsfs__DocuSign_Status__c 
             WHERE dsfs__DocuSign_Envelope_ID__c IN :envelopIds 
             AND dsfs__Envelope_Status__c = 'Completed'];
        return statuses.isEmpty() ? null : statuses[0].Id;
    }

    public class Recipient {
        private Integer routingOrder;
        private String firstName;
        private String lastName;
        private String email;
        private String role;

        public Recipient(final Integer routingOrder,
                         final String firstName,
                         final String lastName,
                         final String email,
                         final String role) {
            this.routingOrder = routingOrder;
            this.firstName = firstName;
            this.lastName = lastName;
            this.email = email;
            this.role = role;
        }

        public override String toString() {
            return StringUtils.format('RoutingOrder~{0};FirstName~{1};LastName~{2};Email~{3};Role~{4}', routingOrder,
                            firstName, lastName, email, role);
        }
    }
}