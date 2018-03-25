public with sharing class ZZWorkflowController {
	/**
	 * Get workflow model map
	 * @return Mapping name -> id
	 */
	@AuraEnabled
	public static Map<String, String> getWorkflowModelMap(){
		Map<String, String> workflowModelMap = new Map<String, String>();
		List<ZZWorkflowModel__c> workflowModelList = [SELECT Id, Name FROM ZZWorkflowModel__c];
		for (ZZWorkflowModel__c model : workflowModelList){
			workflowModelMap.put(model.Name, model.Id);
		}
		return workflowModelMap;
	}

	@AuraEnabled
	public static String saveParams(String wfinstanceId, String params){
		if (!ZZParser.isValidId(wfinstanceId)) return 'Save Parameters__c failed! Id is not valid.';
		if (((Id)wfinstanceId).getSobjectType() != Schema.ZZWorkflowInstance__c.SObjectType) 
			return 'Save params failed! Id is not ZZWorkflowInstance__c.';
		ZZWorkflowInstance wfinstance = ZZWorkflowInstance.getWorkflow((Id)wfinstanceId);
		wfinstance.setParams(params);
		return 'SUCCESS';
	}

	@AuraEnabled
	public static String savePhaseParams(String wfinstanceId, String pmodelId, String params){
		if (!ZZParser.isValidId(wfinstanceId)) return 'Save Parameters__c failed! wfinstanceId is not valid.';
		if (((Id)wfinstanceId).getSobjectType() != Schema.ZZWorkflowInstance__c.SObjectType) 
			return 'Save params failed! wfinstanceId is not ZZWorkflowInstance__c.';
		if (!ZZParser.isValidId(pmodelId)) return 'Save Parameters__c failed! pmodelId is not valid.';
		if (((Id)pmodelId).getSobjectType() != Schema.ZZPhaseModel__c.SObjectType) 
			return 'Save params failed! pmodelId is not ZZPhaseModel__c.';
		ZZWorkflowInstance wfinstance = ZZWorkflowInstance.getWorkflow((Id)wfinstanceId);
		ZZPhaseModel pmodel = ZZPhaseModel.getPhase(pmodelId);
		ZZPhaseInstance pinstance = wfinstance.getPhase(pmodel);
		pinstance.setParams(params);
		return 'SUCCESS';
	}

	/**
	 * Kick off a Workflow Instance using valid Workflow Instance Id
	 * @param  wfinstanceId Workflow Instance Id
	 * @return Status Description
	 */
	@AuraEnabled
	public static String kickOff(String wfinstanceId){
		if (!ZZParser.isValidId(wfinstanceId)) return 'Kick off failed! Id is not valid.';
		if (((Id)wfinstanceId).getSobjectType() != Schema.ZZWorkflowInstance__c.SObjectType) 
			return 'Kick off failed! Id is not ZZWorkflowInstance__c.';
		ZZWorkflowInstance wfinstance = ZZWorkflowInstance.getWorkflow((Id)wfinstanceId);
		wfinstance.kickOff();
		return 'Success!';
	}

	/**
	 * Get workflow instance map
	 * @return Mapping name -> id
	 */
	@AuraEnabled
	public static Map<String, String> getWorkflowInstanceMap(String wfmodelId){
		Map<String, String> workflowInstanceMap = new Map<String, String>();
		if (!ZZParser.isValidId(wfmodelId) || 
			((Id)wfmodelId).getSobjectType() != Schema.ZZWorkflowModel__c.SObjectType) 
			return workflowInstanceMap;
		List<ZZWorkflowInstance__c> workflowInstanceList = [SELECT Id, Name FROM ZZWorkflowInstance__c WHERE Model__c = :wfmodelId];
		for (ZZWorkflowInstance__c instance : workflowInstanceList)
			workflowInstanceMap.put(instance.Name, instance.Id);
		return workflowInstanceMap;
	}

	/**
	 * Build a Workflow Model using given name
	 * @param  name
	 * @return
	 */
	@AuraEnabled
	public static String buildWorkflowModel(String name){
		List<ZZWorkflowModel__c> pmodelList = [SELECT Id FROM ZZWorkflowModel__c WHERE Name = :name];
		if (pmodelList.size() > 0) return 'Name Duplicated';
		ZZWorkflowModel model = ZZWorkflowModel.getWorkflow(name);
		return model.getId();
	}

	/**
	 * Get the structure of the workflow using workflow id
	 * If it is a Workflow Model Id, simply return the structure
	 * If it is a Workflow Instanec Id, add the phase status to the structure map
	 * @param  workflowId 
	 * @return
	 */
	@AuraEnabled
	public static Map<String, Object> getStructure(String workflowId){
		Map<String, Object> structure = new Map<String, Object>();
		List<Object> nodes = new List<Object>();
		List<Object> edges = new List<Object>();
		structure.put('nodes', nodes);
		structure.put('edges', edges);
		if (!ZZParser.isValidId(workflowId)) return structure;
		if (((Id)workflowId).getSobjectType() == Schema.ZZWorkflowModel__c.SObjectType){
			Id wfmodelId = (Id) workflowId;
			ZZWorkflowModel workflow = ZZWorkflowModel.getWorkflow(wfmodelId);
			if (workflow == Null){
				ZZParser.addErrMsg('Unable to find the Workflow Model with given Id. ZZWorkflowController.getStructure(String) ' + wfmodelId);
				return structure;
			}
			structure = workflow.getStructure();
		}
		else if (((Id)workflowId).getSobjectType() == Schema.ZZWorkflowInstance__c.SObjectType){
			Id wfinstanceId = (Id)workflowId;
			ZZWorkflowInstance workflow = ZZWorkflowInstance.getWorkflow(wfinstanceId);
			if (workflow == Null){
				ZZParser.addErrMsg('Unable to find the Workflow Instance with given Id. ZZWorkflowController.getStructure(String) ' + wfinstanceId);
				return structure;
			}
			structure = workflow.getModel().getStructure();
			Map<String, String> statusMap = workflow.getStatusMap();
			nodes = (List<Object>) structure.get('nodes');
			for (Object nodeObj : nodes){
				Map<String, Object> node = (Map<String, Object>)nodeObj;
				String nodeId = (String)node.get('id');
				ZZPhaseInstance pinstance = ZZPhaseInstance.getPhase(workflow, ZZPhaseModel.getPhase(nodeId));
				node.putAll(pinstance.getNode());
			}
			Map<String, String> wfinstanceMap = new Map<String, String>();
			wfinstanceMap.put('Status__c', workflow.getStatus());
			structure.put('wfinstance', wfinstanceMap);
			structure.put('Parameters__c', workflow.getParams());
		}
		return structure;
	}

	/**
	 * Build Workflow Instance using Workflow Model Id and new Name
	 * @param  wfmodelId 
	 * @param  name      
	 * @return Workflow Instanec Id
	 */
	@AuraEnabled
	public static String buildWorkflowInstance(String wfmodelId, String name){
		if (!ZZParser.isValidId(wfmodelId) || ((Id)wfmodelId).getSobjectType() != Schema.ZZWorkflowModel__c.SObjectType) return 'Invalid Workflow Model Id';
		ZZWorkflowModel model = ZZWorkflowModel.getWorkflow((Id)wfmodelId);
		List<ZZWorkflowInstance__c> wfinstanceObjList = [SELECT Id FROM ZZWorkflowInstance__c WHERE Name = :name AND Model__c = :model.getId()];
		if (wfinstanceObjList.size() > 0) return 'Name Duplicated';
		ZZWorkflowInstance instance = model.buildInstance(name);
		return instance.getId();
	}

	/**
	 * Save the Workflow Model Structure
	 * @param  workflowId Workflow Model Id
	 * @param  structure
	 * @return
	 */
	@AuraEnabled
	public static String saveStructure(String workflowId, String structure){
		if (!ZZParser.isValidId(workflowId)) return 'Save structure failed. Bad workflow Id format.';
		if (((Id)workflowId).getSobjectType() != Schema.ZZWorkflowModel__c.SObjectType) return 'Save structure failed. Id type is not ZZWorkflowModel__c.';
		ZZWorkflowModel wfmodel = ZZWorkflowModel.getWorkflow((Id)workflowId);
		if (wfmodel == Null){
			String errMsg = 'Save structure failed. Unable to find ZZWorkflowModel__c using given Id.';
			ZZParser.addErrMsg(errMsg + ' ZZWorkflowController.saveStructure(String, String)');
			return errMsg;
		}
		Map<String, Object> newStructure = (Map<String, Object>)JSON.deserializeUntyped(structure);
		String msg = wfmodel.saveStructure(newStructure);
		return msg;
	}

	/**
	 * Execute the phase action
	 * @param  wfinstanceId
	 * @param  pmodelId  
	 * @param  actionName
	 * @return Error message or Success!
	 */
	@AuraEnabled
	public static String executeAction(String wfinstanceId, String pmodelId, String action){
		if (!ZZParser.isValidId(wfinstanceId) || !ZZParser.isValidId(pmodelId)) 
			return 'Set phase status failed, id is not in correct format.';
		if (((Id)wfinstanceId).getSobjectType() != Schema.ZZWorkflowInstance__c.SObjectType)
			return 'Set phase status failed, wfinstanceId is not ZZWorkflowInstance__c.';
		if (((Id)pmodelId).getSobjectType() != Schema.ZZPhaseModel__c.SObjectType)
			return 'Set phase status failed, pmodelId is not ZZPhaseModel__c.';
		ZZWorkflowInstance wfinstance = ZZWorkflowInstance.getWorkflow((Id) wfinstanceId);
		ZZPhaseModel pmodel = ZZPhaseModel.getPhase((Id) pmodelId);
		ZZPhaseInstance pinstance = wfinstance.getPhase(pmodel);
		pinstance.executeAction(action);
		return 'Success!';
	}

	/**
	 * Set the Status__c of the Phase Instance
	 * @param  wfinstanceId 
	 * @param  pmodelId    
	 * @param  status       
	 * @return
	 */
	@AuraEnabled
	public static String setPhaseStatus(String wfinstanceId, String pmodelId, String status){
		if (!ZZParser.isValidId(wfinstanceId) || !ZZParser.isValidId(pmodelId)) 
			return 'Set phase status failed, id is not in correct format.';
		if (((Id)wfinstanceId).getSobjectType() != Schema.ZZWorkflowInstance__c.SObjectType)
			return 'Set phase status failed, wfinstanceId is not ZZWorkflowInstance__c.';
		if (((Id)pmodelId).getSobjectType() != Schema.ZZPhaseModel__c.SObjectType)
			return 'Set phase status failed, pmodelId is not ZZPhaseModel__c.';
		//getPhase(ZZWorkflowInstance workflow, ZZPhaseModel model)
		ZZWorkflowInstance wfinstance = ZZWorkflowInstance.getWorkflow((Id) wfinstanceId);
		ZZPhaseModel pmodel = ZZPhaseModel.getPhase((Id) pmodelId);
		ZZPhaseInstance pinstance = wfinstance.getPhase(pmodel);
		pinstance.setStatus(status);
		return 'Success!';
	}
}