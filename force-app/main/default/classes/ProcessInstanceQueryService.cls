public with sharing class ProcessInstanceQueryService {

    public static ProcessInstanceQueryService getInstance() {
        return (ProcessInstanceQueryService)ServiceLocator.getInstance(ProcessInstanceQueryService.class);
    }

    public List<ProcessInstance> findByTargetObjectId(String targetObjectId) {
        return [
            SELECT Id, Status, CompletedDate,
            (
                SELECT Id, StepStatus, OriginalActor.Id, OriginalActor.Name
                FROM StepsAndWorkitems
            )
            FROM ProcessInstance
            WHERE TargetObjectId = :targetObjectId
            ORDER BY CreatedDate DESC
        ];
    }

    public List<ProcessInstanceWorkitem> findWorkItemsByTargetObjectId(String targetObjectId) {
        return [
            SELECT Id, ProcessInstanceId
            From ProcessInstanceWorkitem
            Where ProcessInstance.TargetObjectId = :targetObjectId
        ];
    }
}