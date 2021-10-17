public with sharing class CPQDocumentPreviewController {

    public Id quoteId {get; set;}
    public String jobId {get; set;}
    public String pdfBase64 {get; set;}

    public PageReference initiatePreviewGeneration() {
        this.quoteId = ApexPages.currentPage().getParameters().get('quoteId');
        this.jobId = SBQQ.QuoteDocumentController.generateDocument(
                'en_US',
                quoteId,
                CPQSettings__c.getOrgDefaults().QuoteDocumentTemplateId__c,
                'Document Preview',
                'PDF',
                'Default',
                new List<String>{quoteId}
        );
        return null;
    }

    public PageReference checkPreviewGenerated() {
        final String pdfBase64 = (String)SBQQ.QueueableJobCheckerExt.getJobStatus(
                quoteId,
                'QuoteDocumentService',
                jobId
        ).get('payload');
        if (pdfBase64 != null) {
            this.pdfBase64 = pdfBase64.removeStart('"').removeEnd('"');
        }
        return null;
    }
}