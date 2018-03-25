public class ZZWorkflowInstance {
    public static final String multiModelAndNameErr = 'Fatal Error! Database contains more ' +
            'than 1 ZZWorkflowInstance__c with the same Model__c and Name. ';

    public static final String Status_New = 'New';
    public static final String Status_In_Progress = 'In Progress';
    public static final String Status_Completed = 'Completed';
    public static final String Status_Aborted = 'Aborted';
    public static final String Status_Failed = 'Failed';
    private static final Map<String, ZZWorkflowInstance> cacheMap =
        new Map<String, ZZWorkflowInstance>();

    public static void cleanUpCache() {
        cacheMap.clear();
    }

    /**
     * Update all workflow instances to remove the phase from cache
     * @param pmodel
     */
    public static void updateWorkflowInstancesRemovePhase(ZZPhaseModel pmodel){
        for (String key : cacheMap.keySet()){
            if (ZZParser.isValidId(key)){
                cacheMap.get(key).updateRemovePhaseModel(pmodel);
            }
        }
    }

    /**
     * Get the workfow instance with given workflow instance id
     * If its in cache, return the cache
     * Else build a new ZZWorkflowInstance and update cache
     * @param  wfinstanceId 
     * @return Workflow Instance
     */
    public static ZZWorkflowInstance getWorkflow(Id wfinstanceId) {
        if (!cacheMap.containsKey(wfinstanceId)) {
            ZZWorkflowInstance wfinstance = new ZZWorkflowInstance(wfinstanceId);
            cacheMap.put(wfinstanceId, wfinstance);
            cacheMap.put(((String)wfinstance.getModel().getId()) + wfinstance.getName(), wfinstance);
        }
        return cacheMap.get(wfinstanceId);
    }

    /**
     * Get hte workflow instance with given Workflow Model and Name
     * If its in cache, return the cache
     * Else build a new ZZWorkflowInstance and update cache
     * @param  model
     * @param  name 
     * @return Workflow Instance
     */
    public static ZZWorkflowInstance getWorkflow(ZZWorkflowModel model, String name) {
        String key = ((String)model.getId()) + name;
        if (!cacheMap.containsKey(key)) {
            ZZWorkflowInstance wfinstance = new ZZWorkflowInstance(model, name);
            cacheMap.put(wfinstance.getId(), wfinstance);
            cacheMap.put(key, wfinstance);
        }
        return cacheMap.get(key);
    }

    private ZZWorkflowInstance__c self;
    private Map<String, Object> paramMap = Null;

    /**
     * Constructore for ZZWorkflowInstnace, Load ZZWorkfInstance__c self with Workflow Instance Id
     * @param  wfinstanceId 
     * @return
     */
    private ZZWorkflowInstance(Id wfinstanceId) {
        loadSelf(wfinstanceId);
    }

    /**
     * Constructor for ZZWorkflowInstnace, try fetch the record in the database
     * If it is in the database, populate ZZWorkflowInstance__c self with the data
     * Else create a new record
     * @param  wfmodel
     * @param  name
     * @return
     */
    private ZZWorkflowInstance(ZZWorkflowModel wfmodel, String name) {
        List<ZZWorkflowInstance__c> wfinstanceObjList = [SELECT Id, Name, Current_Phases__c,
                                    Model__c, Parameters__c, Status__c FROM
                                    ZZWorkflowInstance__c WHERE Model__c = :wfmodel.getId() AND
                                            Name = :name];
        if (wfinstanceObjList.size() > 0) {
            self = wfinstanceObjList[0];
            if (wfinstanceObjList.size() > 1) {
                String errMsg = multiModelAndNameErr + 'ZZWorkflowInstance(' +
                                'ZZWorkflowModel, String)';
                ZZParser.addErrMsg(errMsg);
            }
        } else {
            self = new ZZWorkflowInstance__c(Name = name, Model__c = wfmodel.getId(), Parameters__c=wfmodel.getParams());
            insert self;
            loadSelf(self.Id);
            List<ZZPhaseModel> pmodelList = wfmodel.getPhaseList();
            ZZPhaseInstance.loadPhaseList(this, pmodelList);
        }
    }

    private void loadSelf(Id wfinstanceId) {
        self = [SELECT Id, Name, Current_Phases__c, Model__c, Parameters__c, Status__c
                FROM ZZWorkflowInstance__c WHERE Id = :wfinstanceId];
    }

    public void updateRemovePhaseModel(ZZPhaseModel pmodel){
        List<ZZPhaseInstance> phaseList = getPhaseList();
        for(Integer i = 0; i < phaseList.size(); i++) {
            if (phaseList[i].getModel() === pmodel){
                ZZPhaseInstance.updateRemovePhaseModel(this, pmodel);
            }
        }
    }

    public ZZPhaseInstance getPhase(ZZPhaseModel pmodel) {
        return ZZPhaseInstance.getPhase(this, pmodel);
    }

    public ZZPhaseInstance getPhase(String name){
        ZZPhaseModel pmodel = getModel().getPhase(name);
        return ZZPhaseInstance.getPhase(this, pmodel);
    }

    public String getParams(){
        return self.Parameters__c;
    }

    public void setParams(String params){
        if (self.Parameters__c != params){
            self.Parameters__c = params;
            update self;
        }
    }

    public void updateDefaults(List<Map<String, String>> defaults){
        if (defaults == null || defaults.size() == 0) return;
        List<ZZPhaseInstance__c> pinstanceObjList = new List<ZZPhaseInstance__c>();
        for (Map<String, String> default_value : defaults){
            String phaseName = default_value.get('name');
            ZZPhaseInstance pinstance = getPhase(phaseName);
            if (default_value.containsKey('status')){
                String status = default_value.get('status');
                pinstance.updateStatus(status);
            }
            if (default_value.containsKey('params')){
                String params = default_value.get('params');
                pinstance.updateParams(params);
            }
            pinstanceObjList.add(pinstance.getObj());
        }
        update pinstanceObjList;
    }

    /**
     * Get all Phase Instances of the Workflow Instance.
     * @return List of Phase Instance
     */
    public List<ZZPhaseInstance> getPhaseList() {
        List<ZZPhaseInstance> phaseList = new List<ZZPhaseInstance>();
        List<ZZPhaseModel> pmodelList = getModel().getPhaseList();
        for (ZZPhaseModel pmodel : pmodelList)
            phaseList.add(getPhase(pmodel));
        return phaseList;
    }

    /**
     * Add the list of Phase Instance into Current_Phases__c
     * @param phaseList List of Phase Instance
     */
    public void addCurrentPhaseList(List<ZZPhaseInstance> phaseList) {
        phaseList.addAll(getCurrentPhaseList());
        resetCurrentPhases(phaseList);
    }

    /**
     * Reset current phases, store it into database
     * @param currentPhaseList
     */
    private void resetCurrentPhases(List<ZZPhaseInstance> currentPhaseList) {
        List<String> currentPhaseIdList = new List<String>();
        for (ZZPhaseInstance phase : currentPhaseList)
            currentPhaseIdList.add(phase.getId());
        self.Current_Phases__c = String.join(currentPhaseIdList, ',');
        update self;
    }

    /**
     * NOTICE: get the map of phases status. Mapping from PHASE MODEL ID to 
     * PHASE INSTANCE STATUS
     * @return Map
     */
    public Map<String, String> getStatusMap() {
        Map<String, String> statusMap = new Map<String, String>();
        List<ZZPhaseInstance> phaseList = getPhaseList();
        for (ZZPhaseInstance phase : phaseList) {
            statusMap.put(phase.getModel().getId(), phase.getStatus());
        }
        return statusMap;
    }

    /**
     * Add the phase to current active phase list of this workflow instance
     * If it exists, do nothing
     * @param phase
     */
    public void addPhaseToCurrent(ZZPhaseInstance phase) {
        List<ZZPhaseInstance> currentList = getCurrentPhaseList();
        for (ZZPhaseInstance currPhase : currentList)
            if (currPhase.getId() == phase.getId()) return;
        currentList.add(phase);
        resetCurrentPhases(currentList);
    }

    /**
     * Remove the phase to current active phase list of this workflow instance
     * If it does not exists, do nothing
     * @param phase
     */
    public void removePhaseFromCurrent(ZZPhaseInstance phase) {
        List<ZZPhaseInstance> currentList = getCurrentPhaseList();
        Integer i = 0;
        for (i = 0; i < currentList.size(); i++)
            if (currentList[i].getId() == phase.getId()) break;
        if (i < currentList.size()) {
            currentList.remove(i);
            resetCurrentPhases(currentList);
        }
    }

    /**
     * Get current pahse list
     * @return
     */
    public List<ZZPhaseInstance> getCurrentPhaseList() {
        return ZZParser.parsePInstanceList(self.Current_Phases__c);
    }

    /**
     * Kick off the Workflow Instance
     */
    public void kickOff() {
        self.Current_Phases__c = Null;
        self.Status__c = Status_In_Progress;
        List<ZZPhaseInstance> startPhaseList = getStartPhaseList();
        for (ZZPhaseInstance startPhase : startPhaseList) {
            startPhase.kickOff();
        }
        resetCurrentPhases(startPhaseList);
    }

    /**
     * Check whether the Workflow Instance is completed
     * @return
     */
    public Boolean checkCompleted() {
        String status = getStatus();
        if (status == Status_Completed) return True;
        else if (status == Status_In_Progress) {
            List<ZZPhaseInstance> phaseList = getPhaseList();
            for (ZZPhaseInstance phase : phaseList) {
                if (phase.getStatus().toLowerCase() != 'completed') {
                    return False;
                }
            }
            self.Status__c = Status_Completed;
            update self;
            return True;
        }
        return False;
    }

    /**
     * Get List of Phase Instances which are initial phases.
     * @return List of Phase Instances
     */
    public List<ZZPhaseInstance> getStartPhaseList() {
        List<ZZPhaseInstance> startPhaseList = new List<ZZPhaseInstance>();
        List<ZZPhaseModel> startPhaseModelList = getModel().getStartPhaseList();
        for (ZZPhaseModel model : startPhaseModelList)
            startPhaseList.add(getPhase(model));
        return startPhaseList;
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

    public ZZWorkflowModel getModel() {
        return ZZWorkflowModel.getWorkflow(self.Model__c);
    }

    public String getStatus() {
        return self.Status__c;
    }
}