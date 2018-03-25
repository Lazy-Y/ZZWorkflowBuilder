@RestResource(urlMapping='/ZZWebService/ExecuteAction')
global with sharing class ZZWSExecuteAction {

    @HttpPost
    global static String actions(String piid, String action){
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
}