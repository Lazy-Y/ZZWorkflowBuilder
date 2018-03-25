public class ZZPhaseModel {
    public static final String multiWorkflowAndNameErr = 'Fatal Error! Database contains more '
            + 'than 1 ZZPhaseModel__c with the same Workflow__c and Model__c. ';
    public static final String phaseModelNotExistException = 'Exception! Phase Model does not exist.';

    private ZZPhaseModel__c self;
    private ZZWorkflowModel workflow = Null;
    private static Map<String, ZZPhaseModel> cacheMap = new Map<String, ZZPhaseModel>();

    public class ZZPhaseModelException extends Exception {}

    /**
     * Clean up cache
     */
    public static void cleanUpCache() {
        cacheMap.clear();
    }

    /**
     * Get list of Phase Models using give list of Phase Model Ids
     * If a Phase Model Id no longer exists, remove it from the Phase Model Id list
     * @param  pmodelIdList Phase Model Id list
     * @return List of Phase Models
     */
    public static List<ZZPhaseModel> getPhaseList(List<String> pmodelIdList) {
        List<ZZPhaseModel> pmodelList = new List<ZZPhaseModel>();
        Integer i = pmodelIdList.size() - 1;
        while (i >= 0) {
            Id pmodelId = (Id) pmodelIdList[i];
            ZZPhaseModel pmodel = ZZPhaseModel.getPhase(pmodelId);
            if (pmodel == Null) {
                pmodelIdList.remove(i);
            } else {
                pmodelList.add(pmodel);
            }
            i--;
        }
        return pmodelList;
    }

    /**
     * Constructor for get Phase Model using Phase Model Object
     * @param  pmodelObj
     * @return
     */
    public static ZZPhaseModel getPhase(ZZPhaseModel__c pmodelObj) {
        if (!cacheMap.containsKey(pmodelObj.Id)) {
            ZZPhaseModel pmodel = new ZZPhaseModel(pmodelObj);
            cacheMap.put(pmodel.getId(), pmodel);
            cacheMap.put(pmodel.getWorkflow().getId() + pmodel.getName(), pmodel);
        }
        return cacheMap.get(pmodelObj.Id);
    }

    /**
     * Get Phase Model using Phase Modle Id
     * @param  pmodelId
     * @return
     */
    public static ZZPhaseModel getPhase(Id pmodelId) {
        if (!cacheMap.containsKey(pmodelId)) {
            try {
                ZZPhaseModel phase = new ZZPhaseModel(pmodelId);
                cacheMap.put(pmodelId, phase);
                cacheMap.put(phase.getWorkflow().getId() + phase.getName(), phase);
            } catch (ZZPhaseModelException e) {
                return Null;
            }
        }
        return cacheMap.get(pmodelId);
    }

    /**
     * Get Phase Model using Workflow Model and Phase Model Name
     * @param  wfmodel
     * @param  name
     * @return
     */
    public static ZZPhaseModel getPhase(ZZWorkflowModel wfmodel, String name) {
        String key = ((String)wfmodel.getId()) + name;
        if (!cacheMap.containsKey(key)) {
            ZZPhaseModel phase = new ZZPhaseModel(wfmodel, name);
            cacheMap.put(key, phase);
            cacheMap.put(phase.getId(), phase);
        }
        return cacheMap.get(key);
    }

    /**
     * Load new phase model list with workflow model and name list, update the database
     * @param wfmodel
     * @param nameList
     */
    public static void loadNewPhaseModelList(ZZWorkflowModel wfmodel, List<String> nameList) {
        Set<String> existingPModelNameSet = new Set<String>();
        List<ZZPhaseModel> pmodelList = wfmodel.getPhaseList();
        for (ZZPhaseModel pmodel : pmodelList) {
            existingPModelNameSet.add(pmodel.getName());
        }
        List<ZZPhaseModel__c> pmodelObjList = new List<ZZPhaseModel__c>();
        for (String name : nameList) {
            if (!existingPModelNameSet.contains(name)) {
                ZZPhaseModel__c pmodelObj = new ZZPhaseModel__c(Name = name, Workflow__c = wfmodel.getId());
                pmodelObjList.add(pmodelObj);
            }
        }
        if (pmodelObjList.size() > 0) {
            insert pmodelObjList;
            for (ZZPhaseModel__c pmodelObj : pmodelObjList) {
                ZZPhaseModel pmodel = new ZZPhaseModel(pmodelObj);
                cacheMap.put(pmodel.getId(), pmodel);
                cacheMap.put(pmodel.getWorkflow().getId() + pmodel.getName(), pmodel);
            }
        }
    }

    /**
     * Constructor for ZZPhaseModel uisng Workflow Model and Phase Model Name
     * Firstly check it there is a record in database
     * If not create a new one
     * @param  wfmodel
     * @param  name
     * @return
     */
    private ZZPhaseModel(ZZWorkflowModel wfmodel, String name) {
        List<ZZPhaseModel__c> plist = [SELECT Id, Name, Parents__c, Children__c, Kick_Off_Function__c,
                                       Phase_Controller_Class__c, Workflow__c, Phase_Controller__c, Actions__c,
                                       Statuses__c, Default_Status__c, Parameters__c, Position_X__c, Position_Y__c
                                       FROM ZZPhaseModel__c WHERE Name = :name AND Workflow__c = :wfmodel.getId()];
        if (plist.size() > 0) {
            self = plist[0];
            if (plist.size() > 1) {
                String errMsg = multiWorkflowAndNameErr + 'ZZPhaseModel(' +
                                'ZZWorkflowModel, String)';
                ZZParser.addErrMsg(errMsg);
            }
        } else {
            self = new ZZPhaseModel__c(Name = name, Workflow__c = wfmodel.getId());
            insert self;
            loadSelf(self.Id);
            wfmodel.updateAddNewPhase(this);
            wfmodel.updateAddToStartPhaseList(this);
        }
    }

    /**
     * Constructor for ZZPhaseModle uisng Phase Model Object
     * @param  pmodelObj
     * @return
     */
    public ZZPhaseModel(ZZPhaseModel__c pmodelObj) {
        self = pmodelObj;
    }


    /**
     * Constructor for ZZPhaseModel using Phase Model Id
     * @param  pmodelId
     * @return
     */
    private ZZPhaseModel(Id pmodelId) {
        loadSelf(pmodelId);
    }

    /**
     * Populate self with data from database
     * @param pmodelId
     */
    private void loadSelf(Id pmodelId) {
        List<ZZPhaseModel__c> plist = [SELECT Id, Name, Parents__c, Children__c, Kick_Off_Function__c,
                                       Phase_Controller_Class__c, Workflow__c, Phase_Controller__c, Actions__c,
                                       Statuses__c, Default_Status__c, Parameters__c, Position_X__c, Position_Y__c
                                       FROM ZZPhaseModel__c WHERE Id = :pmodelId];
        if (plist.size() > 0) {
            self = plist[0];
        } else {
            throw new ZZPhaseModelException(phaseModelNotExistException);
        }
    }

    /**
     * Update the data of the Phase Model, also update its Workflow Model
     * DO NOT UPDATE DATABASE
     * @param data = {
     *             label:$phaseName(String),
     *             Parents__c:$Parents__c(String),
     *             Children__c:$Children__c(String),
     *             Phase_Controller_Class__c:$Phase_Controller_Class__c(String),
     *             Kick_Off_Function__c:$Kick_Off_Function__c(String)
     * }
     */
    public ZZPhaseModel__c updateData(Map<String, Object> data) {
        String newName = (String) data.get('label');
        if (newName != self.Name) {
            cacheMap.remove(getWorkflow().getId() + self.Name);
            self.Name = newName;
            cacheMap.put(getWorkflow().getId() + newName, this);
        }
        String parents = (String) data.get('Parents__c');
        if (parents == '') parents = Null;
        if (parents != self.Parents__c) {
            if (parents == Null) {
                // Add this Phase Model to Workflow Model start phase list
                getWorkflow().updateAddToStartPhaseList(this);
            } else if (self.Parents__c == Null) {
                // Remove this Phase Model to Workflow Model start phase list
                getWorkflow().updateRemoveFromStartPhaseList(this);
            }
            self.Parents__c = parents;
        }
        String children = (String) data.get('Children__c');
        if (children == '') children = Null;
        self.Children__c = children;
        if (data.containsKey('x'))
            self.Position_X__c = (Integer) data.get('x');
        if (data.containsKey('y'))
            self.Position_Y__c = (Integer) data.get('y');
        if (data.containsKey('Phase_Controller_Class__c'))
            self.Phase_Controller_Class__c = (String) data.get('Phase_Controller_Class__c');
        if (data.containsKey('Kick_Off_Function__c'))
            self.Kick_Off_Function__c = (String) data.get('Kick_Off_Function__c');
        if (data.containsKey('Phase_Controller__c'))
            self.Phase_Controller__c = (String) data.get('Phase_Controller__c');
        if (data.containsKey('Default_Status__c'))
            self.Default_Status__c = (String) data.get('Default_Status__c');
        if (data.containsKey('actions')) {
            List<Object> actionList = (List<Object>) data.get('actions');
            List<String> actions = new List<String>();
            for (Object action : actionList) {
                Map<String, Object> actionMap = (Map<String, Object>) action;
                String name = '';
                String next = '';
                String hook = '';
                if (actionMap.containsKey('name'))
                    name = (String)actionMap.get('name');
                if (actionMap.containsKey('next'))
                    next = (String)actionMap.get('next');
                if (actionMap.containsKey('hook'))
                    hook = (String)actionMap.get('hook');
                actions.add(name + ',' + next + ',' + hook);
            }
            self.Actions__c = String.join(actions, '\n');
        }
        if (data.containsKey('statuses')) {
            List<Object> statuses = (List<Object>) data.get('statuses');
            self.Statuses__c = String.join(statuses, ',');
        }
        if (data.containsKey('Parameters__c')){
            self.Parameters__c = (String)data.get('Parameters__c');
        }
        return self;
    }

    /**
     * Get action Map
     * @param  actionName 
     * @return actionMap
     */
    public Map<String, String> getActionMap(String actionName){
        if (self.Actions__c != null && self.Actions__c != ''){
            List<String> actionList = self.Actions__c.split('\n');
            for (String action : actionList){
                List<String> actionCmp = action.split(',');
                if (actionCmp.size() > 0){
                    if (actionName == null || actionCmp[0] == actionName){
                        Map<String, String> actionMap = new Map<String, String>();
                        if (actionCmp.size() > 1){
                            actionMap.put('next', actionCmp[1]);
                        }
                        if (actionCmp.size() > 2){
                            actionMap.put('hook', actionCmp[2]);
                        }
                        return actionMap;
                    }
                }
            }
        }
        return new Map<String, String>();
    }

    public String getPhaseControllerClass() {
        return self.Phase_Controller_Class__c;
    }

    public String getController() {
        return self.Phase_Controller__c;
    }

    public String getKickOffFunction() {
        return self.Kick_Off_Function__c;
    }

    /**
     * Destruct this Phase Model entirely. Remove it from database, cache map
     * and Workflow Model's cache. Update database.
     */
    public void destruct() {
        List<ZZPhaseModel__c> pmodelObjList = updateDestruct();
        if (pmodelObjList.size() > 0) {
            update pmodelObjList;
        }
        delete self;
    }

    public List<ZZPhaseModel__c> updateDestruct() {
        ZZWorkflowInstance.updateWorkflowInstancesRemovePhase(this);
        List<ZZPhaseModel> parents = getParents();
        List<ZZPhaseModel> children = getChildren();
        List<ZZPhaseModel__c> pmodelObjList = new List<ZZPhaseModel__c>();
        for (ZZPhaseModel parent : parents) {
            parent.updateRemoveChild(this);
            pmodelObjList.add(parent.self);
        }
        for (ZZPhaseModel child : children) {
            child.updateRemoveParent(this);
            pmodelObjList.add(child.self);
        }
        getWorkflow().updateRemovePhase(this);
        cacheMap.remove(getId());
        cacheMap.remove(getWorkflow().getId() + getName());
        return pmodelObjList;
    }

    public ZZPhaseModel__c getSelf() {
        return self;
    }

    public String getParams(){
        return self.Parameters__c;
    }

    public String getDefaultStatus() {
        return self.Default_Status__c;
    }

    /**
     * Only remove the Phase Model from its Children__c, NOT update it in database.
     * @param childModel
     */
    private void updateRemoveChild(ZZPhaseModel childModel) {
        List<String> childrenIdList = self.Children__c.split(',');
        Integer i = 0;
        for (i = 0; i < childrenIdList.size(); i++) {
            if (childModel.getId() == childrenIdList[i]) {
                childrenIdList.remove(i);
                self.Children__c = String.join(childrenIdList, ',');
                break;
            }
        }
    }

    /**
     * Only remove the Phase Model from its Parents__c and NOT update it in database.
     * @param parentModel
     */
    private void updateRemoveParent(ZZPhaseModel parentModel) {
        List<String> parentIdList = self.Parents__c.split(',');
        Integer i = 0;
        for (i = 0; i < parentIdList.size(); i++) {
            if (parentModel.getId() == parentIdList[i]) {
                parentIdList.remove(i);
                self.Parents__c = String.join(parentIdList, ',');
                break;
            }
        }
    }

    /**
     * Add child to this Phase Model, also update database
     * @param childModel [description]
     */
    public void addChild(ZZPhaseModel childModel) {
        String childId = childModel.getId();
        if (!cacheMap.containsKey(childModel.getId())) return;
        if (self.Children__c == Null || self.Children__c == '') self.Children__c = childId;
        else self.Children__c += ',' + childId;
        childModel.addParent(this);
        update new List<ZZPhaseModel__c> {this.self, childModel.self};
    }

    /**
     * Add parent to this Phase Model, DO NOT update database, the public function
     * addChild does it
     * @param parentModel
     */
    private void addParent(ZZPhaseModel parentModel) {
        String parentId = parentModel.getId();
        if (!cacheMap.containsKey(parentModel.getId())) return;
        if (self.Parents__c == Null || self.Parents__c == '') {
            self.Parents__c = parentId;
        } else self.Parents__c += ',' + parentId;
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
    
    public ZZWorkflowModel getWorkflow() {
        return ZZWorkflowModel.getWorkflow(self.Workflow__c);
    }

    /**
     * Get child phase models of this phase model
     * @return List of child phase models
     */
    public List<ZZPhaseModel> getChildren() {
        List<ZZPhaseModel> childList = new List<ZZPhaseModel>();
        if (self.Children__c == Null) return childList;
        List<String> pmodelIdList = self.Children__c.split(',');
        childList = getPhaseList(pmodelIdList);
        return childList;
    }

    /**
     * Get parent phase models of this phase model
     * @return List of parent phase models
     */
    public List<ZZPhaseModel> getParents() {
        List<ZZPhaseModel> parentList = new List<ZZPhaseModel>();
        if (self.Parents__c == Null || self.Parents__c == '') return parentList;
        List<String> pmodelIdList = self.Parents__c.split(',');
        parentList = getPhaseList(pmodelIdList);
        return parentList;
    }

    /**
     * Get node information in order to create a vis node
     * @return Map of the information of the node
     */
    public Map<String, Object> getNode() {
        Map<String, Object> node = new Map<String, Object>();
        node.put('id', getId());
        node.put('label', getName());
        node.put('x', self.Position_X__c);
        node.put('y', self.Position_Y__c);
        node.put('Statuses__c', self.Statuses__c);
        node.put('Actions__c', self.Actions__c);
        node.put('Default_Status__c', self.Default_Status__c);
        node.put('Phase_Controller__c', self.Phase_Controller__c);
        node.put('Parameters__c', self.Parameters__c);

        node.put('statuses', self.Statuses__c.split(','));
        List<String> actions = new List<String>();
        if (self.Actions__c != null && self.Actions__c != '')
            actions = self.Actions__c.split('\n');
        List<Object> actionList = new List<Object>();
        for (String action : actions) {
            List<String> actionDetail = action.split(',');
            Map<String, String> actionMap = new Map<String, String> {};
            if (actionDetail.size() >= 1)
                actionMap.put('name', actionDetail[0]);
            if (actionDetail.size() >= 2)
                actionMap.put('next', actionDetail[1]);
            if (actionDetail.size() == 3)
                actionMap.put('hook', actionDetail[2]);
            actionList.add(actionMap);
        }
        node.put('actions', actionList);
        //node.put('Kick_Off_Function__c', getKickOffFunction());
        //node.put('Phase_Controller_Class__c', getPhaseControllerClass());
        return node;
    }

    /**
     * Get edge information in order to create a vis node
     * @param  child Child Phase Model it is connecting to
     * @return Map of the information of the edge
     */
    public Map<String, Object> getEdge(ZZPhaseModel child) {
        Map<String, Object> edge = new Map<String, Object>();
        edge.put('from', getId());
        edge.put('to', child.getId());
        edge.put('arrows', 'to');
        return edge;
    }
}