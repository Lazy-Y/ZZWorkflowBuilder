public abstract class ZZExecutable {
    public abstract void execute(String hook,
                 Map<String, Object> phaseInstance, 
                 Map<String, Object> phaseModel,
                 Map<String, Object> workflowInstance,
                 Map<String, Object> workflowModel);

    public String executeAction(String piid, String action){
        if (!ZZParser.isValidId(piid)){
            return 'Phase instance id is not valid.';
        }
        if (((Id)piid).getSobjectType() != Schema.ZZPhaseInstance__c.SObjectType){
            return 'Id is not phase instance id';
        }
        ZZPhaseInstance pinstsance = ZZPhaseInstance.getPhase((Id)piid);
        pinstsance.executeAction(action);
        return 'SUCCESS';
    }

    public String updateStatus(String piid, String newStatus){
        if (!ZZParser.isValidId(piid)){
            return 'Phase instance id is not valid.';
        }
        if (((Id)piid).getSobjectType() != Schema.ZZPhaseInstance__c.SObjectType){
            return 'Id is not phase instance id';
        }
        ZZPhaseInstance pinstsance = ZZPhaseInstance.getPhase((Id)piid);
        pinstsance.setStatus(newStatus);
        return 'SUCCESS';
    }
}