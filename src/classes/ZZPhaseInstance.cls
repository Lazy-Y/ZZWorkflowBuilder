public class ZZPhaseInstance {
    public static final String multiWorkflowAndModelErr = 'Fatal Error! Database contains more '
            + 'than 1 ZZPhaseInstance__c with the same Workflow__c and Model__c. ';

    private static Map<String, ZZPhaseInstance> cacheMap = new Map<String, ZZPhaseInstance>();
    public static final String Status_New = 'new';
    public static final String Status_Completed = 'completed';
    public static final String Status_Skipped = 'skipped';
    public static final String Status_deferred = 'deferred';

    /**
     * Clean local cache map which stores all instance of ZZPhaseInstance
     */
    public static void cleanUpCache() {
        cacheMap.clear();
    }

    /**
     * Get phase instance with phase instance Id
     * Firstly try to load phase instance from the cache map
     * If cache map does not contain the id, load it using SOQL
     * @param  phaseId Phase Instance Id
     * @return         Phase Instance
     */
    public static ZZPhaseInstance getPhase(Id phaseId) {
        if (!cacheMap.containsKey(phaseId)) {
            ZZPhaseInstance pinstance = new ZZPhaseInstance(phaseId);
            cacheMap.put(phaseId, pinstance);
            String wfinstanceId = pinstance.getWorkflow().getId();
            String pmodelId = pinstance.getModel().getId();
            cacheMap.put(wfinstanceId + pmodelId, pinstance);
        }
        return cacheMap.get(phaseId);
    }

    /**
     * Get phase using workflow instance and phase model
     * Firstly try to load it from the cache map
     * If no record in cache map, load it from database
     * If no such a record in database, create one
     * @param  workflow Workflow Instance
     * @param  model    Phase Model
     * @return          Phase Instance
     */
    public static ZZPhaseInstance getPhase(ZZWorkflowInstance workflow, ZZPhaseModel model) {
        String wfinstanceId = workflow.getId();
        String pmodelId = model.getId();
        String cacheMapKey = wfinstanceId + pmodelId;
        if (!cacheMap.containsKey(cacheMapKey)) {
            List<ZZPhaseModel> pmodelList = workflow.getModel().getPhaseList();
            if (ZZParser.listContains(pmodelList, model)) {
                ZZPhaseInstance pinstance = new ZZPhaseInstance(workflow, model);
                cacheMap.put(pinstance.getId(), pinstance);
                cacheMap.put(cacheMapKey, pinstance);
            } else {
                return Null;
            }
        }
        return cacheMap.get(cacheMapKey);
    }

    /**
     * Load list of Phase Instance using list of Phase Instance Ids (Use only for ZZWorkflowModel.buildInstance)
     * @param  pinstanceIdList
     * @return
     */
    public static void loadPhaseList(ZZWorkflowInstance wfinstance, List<ZZPhaseModel> pmodelList) {
        List<ZZPhaseInstance__c> pinstanceObjList = new List<ZZPhaseInstance__c>();
        List<Id> pinstanceIdList = new List<Id>();
        for (ZZPhaseModel pmodel : pmodelList) {
            pinstanceObjList.add(new ZZPhaseInstance__c(Name = wfinstance.getName() + ' - ' + pmodel.getName(),
                                 Workflow__c = wfinstance.getId(), Model__c = pmodel.getId(),
                                 Status__c = pmodel.getDefaultStatus()));
        }
        insert pinstanceObjList;
        for (ZZPhaseInstance__c pinstanceObj : pinstanceObjList) {
            pinstanceIdList.add(pinstanceObj.Id);
        }
        pinstanceObjList = [SELECT Id, Name, Workflow__c, Model__c, Status__c, On_Going_Action__c, Parameters__c FROM ZZPhaseInstance__c WHERE Id IN :pinstanceIdList];
        for (ZZPhaseInstance__c pinstanceObj : pinstanceObjList) {
            ZZPhaseInstance pinstance = new ZZPhaseInstance(pinstanceObj);
            cacheMap.put(pinstance.getId(), pinstance);
            String cacheMapKey = ((String)wfinstance.getId()) + ((String)pinstance.getModel().getId());
            cacheMap.put(cacheMapKey, pinstance);
        }
    }

    private ZZPhaseInstance__c self;
    private ZZPhaseModel model = Null;
    private ZZWorkflowInstance workflow = Null;

    /**
     * Constructor for ZZPhaseInstance using workflow instance and phase model
     * @param  wfinstance Workflow Instance
     * @param  pmodel     Phase Model
     * @return
     */
    private ZZPhaseInstance(ZZWorkflowInstance wfinstance, ZZPhaseModel pmodel) {
        // TODO: check if the phase model is in workflow model
        List<ZZPhaseInstance__c> pinstanceObjList = [SELECT Id, Name, Workflow__c, Model__c, Parameters__c,
                                 Status__c, On_Going_Action__c FROM ZZPhaseInstance__c WHERE Workflow__c =
                                     :wfinstance.getId() AND Model__c = :pmodel.getId()];
        if (pinstanceObjList.size() > 0) {
            self = pinstanceObjList[0];
            if (pinstanceObjList.size() > 1) {
                String errMsg = multiWorkflowAndModelErr + 'ZZPhaseInstance.getPhase(' +
                                'ZZWorkflowInstance, ZZPhaseModel)';
                ZZParser.addErrMsg(errMsg);
            }
        } else {
            self = new ZZPhaseInstance__c(Name = wfinstance.getName() + ' - ' + pmodel.getName(), Model__c = pmodel.getId(), 
                Workflow__c = wfinstance.getId(), Status__c = pmodel.getDefaultStatus(), Parameters__c = pmodel.getParams());
            insert self;
            loadSelf(self.Id);
        }
    }

    /**
     * Constructor for ZZPhaseInstance using ZZPhaseInstance__c Object
     * @param  pinstanceObj
     * @return
     */
    private ZZPhaseInstance(ZZPhaseInstance__c pinstanceObj) {
        self = pinstanceObj;
    }

    /**
     * Constructor for ZZPhaseInstance using phase instance id
     * @param  pinstanceId Phase Instance Id
     * @return
     */
    private ZZPhaseInstance(Id pinstanceId) {
        loadSelf(pinstanceId);
    }

    /**
     * Populate Phase Instance self with Phase Instance Id, load data from database
     * @param pinstanceId Phase Instance Id
     */
    private void loadSelf(Id pinstanceId) {
        self = [SELECT Id, Name, Model__c, Status__c, Workflow__c, On_Going_Action__c, Parameters__c
                FROM ZZPhaseInstance__c WHERE Id = :pinstanceId];
    }

    public static void updateRemovePhaseModel(ZZWorkflowInstance wfinstance, ZZPhaseModel pmodel) {
        ZZPhaseInstance pinstance = getPhase(wfinstance, pmodel);
        cacheMap.remove(pinstance.getId());
        cacheMap.remove((String)wfinstance.getId() + (String)pmodel.getId());
    }

    public Id getId() {
        return self.Id;
    }

    public String getName() {
        return self.Name;
    }

    public ZZPhaseInstance__c getObj(){
        return self;
    }

    public Map<String, Object> toMap(){
        return (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(self));
    }

    public void setParams(String params){
        if (params != self.Parameters__c){
            self.Parameters__c = params;
            update self;
        }
    }

    public void updateParams(String params){
        self.Parameters__c = params;
    }

    public Map<String, Object> getNode(){
        Map<String, Object> node = new Map<String, Object>();
        String onGoingAction = '';
        if (self.On_Going_Action__c != null){
            onGoingAction = self.On_Going_Action__c;
        }
        node.put('On_Going_Action__c', onGoingAction);
        node.put('Status__c', self.Status__c);
        node.put('Parameters__c', self.Parameters__c);
        return node;
    }

    /**
     * Only update status, need to manually add the phase instance to the workflow instance's
     * current phase list. If status is completed, send the completed signal to it child phases
     */
    public void kickOff() {
        if (canPassThrough()){
            nextStep();
        }
        else if (getStatus().toLowerCase() == 'new'){
            executeAction(null);
        }
    }

    public Boolean canPassThrough(){
        String status = getStatus().toLowerCase();
        return status == 'completed' || status == 'skipped' || status == 'deferred';
    }

    /**
     * This function is IMPORTANT for this situation
     * Completed (Triger) ------
     *                          \
     * In Progress - Deferred -- New
     * It should recursively check if it can be 
     * @return [description]
     */
    private Boolean checkAllParentsCompleted(){
        List<ZZPhaseInstance> parents = getParents();
        for (ZZPhaseInstance parent : parents) {
            String status = parent.getStatus().toLowerCase();
            if (status == 'skipped' || status == 'deferred'){
                if (!parent.checkAllParentsCompleted()){
                    return False;
                }
            }
            else if (status != 'completed'){
                return False;
            }
        }
        return True;
    }

    /**
     * Check if the phases status is ready
     * If its new, check its all parents' status are Completed
     * Else return True
     * @return [description]
     */
    public Boolean checkReady() {
        if (getStatus().toLowerCase() == Status_New) {
            return checkAllParentsCompleted();
        }
        else{
            return False;
        }
    }

    /**
     * After this phase instance's status gets completed, check if its children are ready
     * If any on them are ready, kick off them and add them into Current_Phase__c
     */
    public void nextStep() {
        ZZWorkflowInstance wfinstance = getWorkflow();
        wfinstance.removePhaseFromCurrent(this);
        List<ZZPhaseInstance> children = getChildren();
        List<ZZPhaseInstance> currentPhaseList = new List<ZZPhaseInstance>();
        for (ZZPhaseInstance child : children) {
            if (child.checkReady()) {
                child.kickOff();
                currentPhaseList.add(child);
            }
        }
        if (currentPhaseList.size() > 0) {
            wfinstance.addCurrentPhaseList(currentPhaseList);
        }
        wfinstance.checkCompleted();
    }

    /**
     * Get child phase instances
     * @return List of Phase Instance
     */
    public List<ZZPhaseInstance> getChildren() {
        List<ZZPhaseInstance> children = new List<ZZPhaseInstance>();
        ZZPhaseModel model = getModel();
        List<ZZPhaseModel> childModelList = model.getChildren();
        for (ZZPhaseModel childModel : childModelList)
            children.add(getWorkflow().getPhase(childModel));
        return children;
    }

    /**
     * Get parent phase instances
     * @return List of Phase Instance
     */
    public List<ZZPhaseInstance> getParents() {
        List<ZZPhaseInstance> parents = new List<ZZPhaseInstance>();
        ZZPhaseModel model = getModel();
        List<ZZPhaseModel> parentModelList = model.getParents();
        for (ZZPhaseModel parentModel : parentModelList)
            parents.add(getWorkflow().getPhase(parentModel));
        return parents;
    }

    /**
     * Execute action with the give action name
     * @param action
     */
    public void executeAction(String action) {
        Map<String, String> actionMap = getModel().getActionMap(action);
        String next = null;
        if (actionMap.containsKey('next')){
            next = actionMap.get('next');
            if (next != null && next != ''){
                setStatus(next);
                if (next.toLowerCase() == 'completed'){
                    nextStep();
                }
            }
        }
        if (actionMap.containsKey('hook')){
            String hook = actionMap.get('hook');
            String controller = getModel().getController();
            if (controller != null && controller != ''){
                Map<String, Object> params = new Map<String, Object>();
                params.put('pinstance', toMap());
                params.put('pmodel', getModel().toMap());
                params.put('wfinstance', getWorkflow().toMap());
                params.put('wfmodel', getWorkflow().getModel().toMap());
                params.put('hook', hook);
                Type t = Type.forName(controller);
                if (t == null) {
                    System.debug('ZZExecution error: Unable to find controller class');
                    return;
                }
                if (next == null || next == ''){
                    self.On_Going_Action__c = hook;
                }
                else{
                    updateStatus(next);
                }
                update self;
                ZZExecutable x = (ZZExecutable) t.newInstance();
                x.execute(hook, toMap(), getModel().toMap(), getWorkflow().toMap(), getWorkflow().getModel().toMap());
            }
        }
    }

    /**
     * Only udate the status in cache
     * @param newStatus
     */
    public void updateStatus(String newStatus) {
        self.Status__c = newStatus;
        self.On_Going_Action__c = '';
    }

    /**
     * Set status and update datebase
     * @param newStatus
     */
    public void setStatus(String newStatus) {
        if (self.Status__c != newStatus){
            updateStatus(newStatus);
            update self;
        }
    }

    public String getStatus() {
        return self.Status__c;
    }

    public ZZPhaseModel getModel() {
        return ZZPhaseModel.getPhase(self.Model__c);
    }

    public ZZWorkflowInstance getWorkflow() {
        return ZZWorkflowInstance.getWorkflow(self.Workflow__c);
    }
}