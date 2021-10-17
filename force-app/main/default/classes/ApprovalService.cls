public without sharing class ApprovalService {

    public static ApprovalService getInstance() {
        return (ApprovalService)ServiceLocator.getInstance(ApprovalService.class);
    }

    private final ProcessInstanceQueryService processInstanceQuerySrv;

    public ApprovalService() {
        this.processInstanceQuerySrv = ProcessInstanceQueryService.getInstance();
    }

    public Boolean submitForApproval(String targetObjectId, String comment) {
        final Approval.ProcessSubmitRequest request = new Approval.ProcessSubmitRequest();
        request.setObjectId(targetObjectId);
        request.setComments(comment);
        Approval.ProcessResult startApprovallResult = Approval.process(request);
        return startApprovallResult.isSuccess();
    }

    public Boolean cancelRequest(String targetObjectId) {
        List<ProcessInstanceWorkitem> workItems = processInstanceQuerySrv.findWorkItemsByTargetObjectId(targetObjectId);
        if (workItems.isEmpty()) {
            return false;
        }
        Approval.ProcessWorkitemRequest request = new Approval.ProcessWorkitemRequest();
        request.setWorkitemId(workItems[0].Id);
        request.setAction('Removed');
        request.setComments('Cancelled');
        Approval.ProcessResult result =  Approval.process(request);
        return result.isSuccess();
    }
}