public class ZZWorkflowModel {
    private ZZWorkflowModel__c self;
    private Map<String, String> paramMap = Null;
    private List<ZZPhaseModel> startPhaseList = Null;
    private List<ZZPhaseModel> phaseList = Null;
    private static Map<String, ZZWorkflowModel> cacheMap = new Map<String, ZZWorkflowModel>();

    /**
     * Get Workflow instance using Workflow Instance Id
     * @param  wfmodelId
     * @return ZZWorkflowModel
     */
    public static ZZWorkflowModel getWorkflow(Id wfmodelId) {
        if (!cacheMap.containsKey(wfmodelId)) {
            ZZWorkflowModel wfmodel = new ZZWorkflowModel(wfmodelId);
            cacheMap.put(wfmodel.getName(), wfmodel);
            cacheMap.put(wfmodelId, wfmodel);
        }
        return cacheMap.get(wfmodelId);
    }

    /**
     * Get Workflow Modle using given name, if not exist, create one.
     * @param  name
     * @return
     */
    public static ZZWorkflowModel getWorkflow(String name) {
        return getWorkflow(name, False);
    }

    /**
     * Get Workflow Modle using given name, if not exist, create one, specify if
     * it is automatically kicked off when created
     * @param  name
     * @param  autoKickOff
     * @return
     */
    public static ZZWorkflowModel getWorkflow(String name, Boolean autoKickOff) {
        if (!cacheMap.containsKey(name)) {
            ZZWorkflowModel wfmodel = new ZZWorkflowModel(name, autoKickOff);
            cacheMap.put(name, wfmodel);
            cacheMap.put(wfmodel.getId(), wfmodel);
        }
        return cacheMap.get(name);
    }

    /**
     * Constructor for Workflow Model
     * @param  name
     * @param  autoKickOff
     * @return
     */
    private ZZWorkflowModel(String name, Boolean autoKickOff) {
        List<ZZWorkflowModel__c> wflist = [SELECT Id, Name, Auto_Kick_Off__c, Parameters__c FROM
                                           ZZWorkflowModel__c WHERE Name = :name];
        if (wflist.size() > 0) self = wflist[0];
        else {
            self = new ZZWorkflowModel__c(Name = name, Auto_Kick_Off__c = autoKickOff);
            insert self;
            loadSelf(self.Id);
        }
    }

    private ZZWorkflowModel(Id wfmodelId) {
        loadSelf(wfmodelId);
    }

    private void loadSelf(Id wfmodelId) {
        self = [SELECT Id, Name, Auto_Kick_Off__c, Parameters__c FROM ZZWorkflowModel__c WHERE Id = :wfmodelId];
    }

    public ZZPhaseModel getPhase(String name) {
        return ZZPhaseModel.getPhase(this, name);
    }

    public ZZWorkflowInstance getInstance(String name) {
        return ZZWorkflowInstance.getWorkflow(this, name);
    }

    public ZZWorkflowInstance getInstance(Id wfinstanceId) {
        return ZZWorkflowInstance.getWorkflow(wfinstanceId);
    }

    private void setParams(String params){
        if (params != self.Parameters__c){
            self.Parameters__c = params;
            update self;
        }
    }

    public String getParams(){
        return self.Parameters__c;
    }

    /**
     * Save network structur
     * @param  data = {
     *                  nodes: {
     *                      $nodeId: {
     *                          id: $nodeId,
     *                          label: $name,
     *                          statuses: [$status],
     *                          actions: [{"name": $name, "next": $next, "hook": $hook}]
     *                      }
     *                  },
     *                  edges:{
     *                      $edgeId: {
     *                          id: $edgeId,
     *                          from: $fromId,
     *                          to: $childId,
     *                          arrows: to
     *                      }
     *                  }
     *                }
     * @return Description of messages. If success, return 'Success!'.
     */
    public String saveStructure(Map<String, Object> data) {
        List<ZZPhaseModel> phaseList = getPhaseList();
        List<ZZPhaseModel> newPhaseList = new List<ZZPhaseModel>();
        Set<String> phaseToDeleteSet = new Set<String>();
        // Mapping from node id which was created by Vis to phase id which is
        // sObject id
        Map<String, String> idMap = new Map<String, String>();

        // Build phase to delete set, if a phase is no longer in nodes map,
        // delete it
        for (ZZPhaseModel phase : phaseList)
            phaseToDeleteSet.add(phase.getId());

        Map<String, Object> nodes = (Map<String, Object>)data.get('nodes');
        Map<String, Object> edges = (Map<String, Object>)data.get('edges');
        String params = (String)data.get('Parameters__c');
        setParams(params);

        Map<String, Object> phaseMap = new Map<String, Object>();

        // Mapping from id to a list of parents id
        Map<String, List<String>> parentsMap = new Map<String, List<String>>();
        // Mapping from id to a list of children id
        Map<String, List<String>> childrenMap = new Map<String, List<String>>();

        List<String> nameList = new List<String>();
        for (String nodeId : nodes.keySet()) {
            if (!phaseToDeleteSet.contains(nodeId)) {
                Map<String, Object> nodeMap = (Map<String, Object>)nodes.get(nodeId);
                nameList.add((String)nodeMap.get('label'));
            }
        }
        ZZPhaseModel.loadNewPhaseModelList(this, nameList);

        // Build idMap, new phase list
        // Initialize parents map, children map
        for (String nodeId : nodes.keySet()) {
            Map<String, Object> nodeMap = (Map<String, Object>)nodes.get(nodeId);
            ZZPhaseModel phase = Null;
            if (phaseToDeleteSet.contains(nodeId)) {
                phase = ZZPhaseModel.getPhase(nodeId);
            } else {
                phase = getPhase((String)nodeMap.get('label'));
            }
            parentsMap.put(phase.getId(), new List<String>());
            childrenMap.put(phase.getId(), new List<String>());
            idMap.put(nodeId, phase.getId());
            newPhaseList.add(phase);
            phaseToDeleteSet.remove(phase.getId());
        }

        // Populate parents map and children map
        for (String edgeId : edges.KeySet()) {
            Map<String, Object> edgeMap = (Map<String, Object>)edges.get(edgeId);
            String parentId = idMap.get((String) edgeMap.get('from'));
            String childId = idMap.get((String) edgeMap.get('to'));
            List<String> parentsList = parentsMap.get(childId);
            parentsList.add(parentId);
            List<String> childrenList = childrenMap.get(parentId);
            childrenList.add(childId);
        }

        Map<Id, ZZPhaseModel__c> updatePhaseObjMap = new Map<Id, ZZPhaseModel__c>();
        // Update all phases
        for (String nodeId : nodes.KeySet()) {
            String phaseId = idMap.get(nodeId);
            Map<String, Object> nodeMap = (Map<String, Object>)nodes.get(nodeId);
            nodeMap.put('Children__c', String.join(childrenMap.get(phaseId), ','));
            nodeMap.put('Parents__c', String.join(parentsMap.get(phaseId), ','));
            ZZPhaseModel phase = ZZPhaseModel.getPhase(phaseId);
            updatePhaseObjMap.put(phase.getId(), phase.updateData(nodeMap));
        }

        List<ZZPhaseModel__c> pmodelObjToDestructList = new List<ZZPhaseModel__c>();
        // Delete extra phases
        for (Id phaseId : phaseToDeleteSet) {
            ZZPhaseModel pmodel = ZZPhaseModel.getPhase(phaseId);
            List<ZZPhaseModel__c> updatePModelObjList = pmodel.updateDestruct();
            for (ZZPhaseModel__c pmodelObj : updatePModelObjList) {
                updatePhaseObjMap.put(pmodelObj.Id, pmodelObj);
            }
            pmodelObjToDestructList.add(pmodel.getSelf());
        }
        if (updatePhaseObjMap.size() > 0) {
            update updatePhaseObjMap.values();
        }
        this.phaseList.clear();
        for (ZZPhaseModel phase : newPhaseList) {
            this.phaseList.add(phase);
        }
        if (pmodelObjToDestructList.size() > 0) {
            delete pmodelObjToDestructList;
        }
        return 'Success!';
    }

    /**
     * Get graph structure
     * @return structure = {
     *                       nodes:[
     *                           {
     *                               id: $id,
     *                               label: $name,
     *                               statuses: [
     *                                   $status
     *                               ]
     *                           }
     *                       ],
     *                       edges:[
     *                           {
     *                               from: $parentId,
     *                               to: $childId,
     *                               arrows: to
     *                           }
     *                       ]
     *                     }
     */
    public Map<String, Object> getStructure() {
        Map<String, Object> structure = new Map<String, Object>();
        List<Object> nodes = new List<Object>();
        List<Object> edges = new List<Object>();
        structure.put('nodes', nodes);
        structure.put('edges', edges);
        structure.put('Parameters__c', self.Parameters__c);
        List<ZZPhaseModel> phaseList = getPhaseList();
        for (ZZPhaseModel phase : phaseList) {
            nodes.add(phase.getNode());
            List<ZZPhaseModel> children = phase.getChildren();
            for (ZZPhaseModel child : children)
                edges.add(phase.getEdge(child));
        }
        return structure;
    }

    /**
     * Build a Workflow Instance of this Workflow Model using given name
     * @param  name
     * @return Workflow Instance
     */
    public ZZWorkflowInstance buildInstance(String name) {
        ZZWorkflowInstance wfinstance = getInstance(name);
        return wfinstance;
    }

    public Id getId() {
        return self.Id;
    }

    public String getName() {
        return self.Name;
    }

    public Map<String, Object> toMap(){
        return (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(self));
    }
    
    /**
     * Get add new phase to phase list and check if to add the phase to start phase list
     * @param pmodel [description]
     */
    public void updateAddNewPhase(ZZPhaseModel pmodel) {
        if (phaseList != Null && !ZZParser.listContains(phaseList, pmodel)) {
            phaseList.add(pmodel);
        }

        if (pmodel.getParents().size() == 0) {
            updateAddToStartPhaseList(pmodel);
        }
    }

    /**
     * Update Workflow Model to remove the Phase Model
     * @param pmodel
     */
    public void updateRemovePhase(ZZPhaseModel pmodel) {
        if (phaseList != Null) {
            Integer i = 0;
            for (i = 0; i < phaseList.size(); i++) {
                if (pmodel == phaseList[i]) break;
            }
            if (i < phaseList.size()) {
                phaseList.remove(i);
            }
            updateRemoveFromStartPhaseList(pmodel);
        }
    }

    /**
     * Update, add the Phase Model into start phase list.
     * DO NOT UPDATE DATABASE FOR ANY FUNCTION START WITH UPDATE
     * @param pmodel
     */
    public void updateAddToStartPhaseList(ZZPhaseModel pmodel) {
        if (startPhaseList != Null && !ZZParser.listContains(startPhaseList, pmodel)) {
            startPhaseList.add(pmodel);
        }
    }

    /**
     * Update, remove the Phase Model from start phase list.
     * DO NOT UPDATE DATABASE FOR ANY FUNCTION START WITH UPDATE
     * @param pmodel [description]
     */
    public void updateRemoveFromStartPhaseList(ZZPhaseModel pmodel) {
        if (startPhaseList != Null) {
            Integer i = 0;
            while (i < startPhaseList.size()) {
                if (startPhaseList[i] == pmodel) {
                    startPhaseList.remove(i);
                    break;
                }
            }
        }
    }

    /**
     * Get reference of all Phase Models which belongs to this Workflow Model
     * @return List of Phase Model
     */
    public List<ZZPhaseModel> getPhaseList() {
        if (phaseList == Null) {
            List<ZZPhaseModel__c> pmodelObjList = [SELECT Id, Name, Parents__c, Children__c, 
                                                   Kick_Off_Function__c, Phase_Controller_Class__c, 
                                                   Workflow__c, Phase_Controller__c, 
                                                   Actions__c, Statuses__c, Default_Status__c, Parameters__c, Position_X__c, 
                                                   Position_Y__c FROM ZZPhaseModel__c WHERE Workflow__c = :getId()];
            phaseList = new List<ZZPhaseModel>();
            for (ZZPhaseModel__c pmodelObj : pmodelObjList) {
                phaseList.add(ZZPhaseModel.getPhase(pmodelObj));
            }
        }
        return phaseList;
    }

    /**
     * Get the reference of the start phase list
     * @return [description]
     */
    public List<ZZPhaseModel> getStartPhaseList() {
        if (startPhaseList == Null) {
            List<ZZPhaseModel> phaseList = getPhaseList();
            startPhaseList = new List<ZZPhaseModel>();
            for (ZZPhaseModel phase : phaseList) {
                if (phase.getParents().size() == 0) {
                    startPhaseList.add(phase);
                }
            }
        }
        return startPhaseList;
    }

    public Boolean isAutoKickOff() {
        return self.Auto_Kick_Off__c;
    }
}