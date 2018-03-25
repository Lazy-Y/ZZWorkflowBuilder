@isTest
public class ZZPhaseInstanceTest {
    public static String Status_New = 'New';
    public static String Status_In_Progress = 'In Progress';
    public static String Status_Completed = 'Completed';

    @testSetup
    public static void setup() {
        ZZWorkflowModelTest.setup();
    }


    public static void assertPhaseInstanceEquals(ZZPhaseInstance__c pinstanceObj, ZZPhaseInstance pinstance) {
        System.assertEquals(pinstanceObj.Id, pinstance.getId());
        System.assertEquals(pinstanceObj.Name, pinstance.getName());
        System.assertEquals(pinstanceObj.Workflow__c, pinstance.getWorkflow().getId());
        System.assertEquals(pinstanceObj.Model__c, pinstance.getModel().getId());
        System.assertEquals(pinstanceObj.Status__c, pinstance.getStatus());
    }

    public static ZZPhaseInstance__c getObj(Id pinstanceId) {
        return [SELECT Id, Name, Model__c, Status__c, Workflow__c
                FROM ZZPhaseInstance__c WHERE Id = :pinstanceId];
    }

    public static ZZWorkflowInstance memorySetup() {
        ZZWorkflowModel__c wfmodelObj = [SELECT Id, Name, Auto_Kick_Off__c FROM ZZWorkflowModel__c][0];
        ZZWorkflowModel wfmodel = ZZWorkflowModel.getWorkflow(wfmodelObj.Id);
        ZZWorkflowInstance wfinstance = wfmodel.buildInstance('Test Workflow Instance');
        wfinstance.getPhaseList();
        ZZPhaseInstance.cleanUpCache();
        return wfinstance;
    }

    @isTest
    public static void testLoadPhaseList(){
        ZZWorkflowModel wfmodel = ZZWorkflowModel.getWorkflow('Sample Workflow');
        ZZWorkflowInstance wfinstance = wfmodel.buildInstance('Sample Workflow Instance');
        List<ZZPhaseModel> pmodelList = wfmodel.getPhaseList();
        Test.startTest();
        ZZPhaseInstance.loadPhaseList(wfinstance, pmodelList);
        System.assertEquals(1, LIMITS.getQueries());
        System.assertEquals(1, LIMITS.getDMLStatements());
        Test.stopTest();
    }

    @isTest
    public static void testGetParents(){
        ZZWorkflowModel wfmodel = ZZWorkflowModel.getWorkflow('Sample Workflow');
        ZZPhaseModel pmodel1 = wfmodel.getPhase('Sample Phase 1');
        ZZPhaseModel pmodel2 = wfmodel.getPhase('Sample Phase 2');
        ZZPhaseModel pmodel4 = wfmodel.getPhase('Sample Phase 4');
        ZZWorkflowInstance wfinstance = wfmodel.buildInstance('Sample Workflow Instance');
        ZZPhaseInstance p1 = wfinstance.getPhase(pmodel1);
        ZZPhaseInstance p2 = wfinstance.getPhase(pmodel2);
        ZZPhaseInstance p4 = wfinstance.getPhase(pmodel4);
        Test.startTest();
        List<ZZPhaseInstance> parents = p4.getParents();
        System.assertEquals(0, LIMITS.getQueries());
        Test.stopTest();
        System.assertEquals(2, parents.size());
        System.assert(ZZParser.listContains(parents, p1));
        System.assert(ZZParser.listContains(parents, p2));
    }

    @isTest
    public static void testUpdateRemovePhaseModel(){
        ZZWorkflowModel wfmodel = ZZWorkflowModel.getWorkflow('Sample Workflow');
        ZZPhaseModel pmodel0 = wfmodel.getPhase('Sample Phase 0');
        ZZWorkflowInstance wfinstance = wfmodel.buildInstance('Sample Workflow Instance');
        pmodel0.destruct();
        ZZPhaseInstance pinstance0 = wfinstance.getPhase(pmodel0);
        System.assertEquals(Null, wfinstance.getPhase(pmodel0));
    }

    @isTest
    public static void testGetNoParent(){
        ZZWorkflowModel wfmodel = ZZWorkflowModel.getWorkflow('Sample Workflow');
        ZZPhaseModel pmodel0 = wfmodel.getPhase('Sample Phase 0');
        ZZWorkflowInstance wfinstance = wfmodel.buildInstance('Sample Workflow Instance');
        ZZPhaseInstance p0 = wfinstance.getPhase(pmodel0);
        Test.startTest();
        List<ZZPhaseInstance> parents = p0.getParents();
        System.assertEquals(0, LIMITS.getQueries());
        Test.stopTest();
        System.assertEquals(0, parents.size());
    }


    @isTest
    public static void testGetChildren(){
        ZZWorkflowModel wfmodel = ZZWorkflowModel.getWorkflow('Sample Workflow');
        ZZPhaseModel pmodel0 = wfmodel.getPhase('Sample Phase 0');
        ZZPhaseModel pmodel1 = wfmodel.getPhase('Sample Phase 1');
        ZZPhaseModel pmodel2 = wfmodel.getPhase('Sample Phase 2');
        ZZWorkflowInstance wfinstance = wfmodel.buildInstance('Sample Workflow Instance');
        ZZPhaseInstance p0 = wfinstance.getPhase(pmodel0);
        ZZPhaseInstance p1 = wfinstance.getPhase(pmodel1);
        ZZPhaseInstance p2 = wfinstance.getPhase(pmodel2);
        Test.startTest();
        List<ZZPhaseInstance> children = p0.getChildren();
        System.assertEquals(0, LIMITS.getQueries());
        Test.stopTest();
        System.assertEquals(2, children.size());
        System.assert(ZZParser.listContains(children, p1));
        System.assert(ZZParser.listContains(children, p2));
    }

    @isTest
    public static void testGetNoChildren(){
        ZZWorkflowModel wfmodel = ZZWorkflowModel.getWorkflow('Sample Workflow');
        ZZPhaseModel pmodel5 = wfmodel.getPhase('Sample Phase 5');
        ZZWorkflowInstance wfinstance = wfmodel.buildInstance('Sample Workflow Instance');
        ZZPhaseInstance p5 = wfinstance.getPhase(pmodel5);
        Test.startTest();
        List<ZZPhaseInstance> children = p5.getChildren();
        System.assertEquals(0, LIMITS.getQueries());
        Test.stopTest();
        System.assertEquals(0, children.size());
    }

    @isTest
    public static void testGetPhaseWithId() {
        ZZWorkflowInstance wfinstance = memorySetup();
        List<ZZPhaseInstance__c> pinstanceObjList = [SELECT Id, Name, Workflow__c, Model__c, Status__c FROM
                ZZPhaseInstance__c];
        System.assertEquals(6, pinstanceObjList.size());
        Map<Id, ZZPhaseInstance__c> pinstanceObjMap = new Map<Id, ZZPhaseInstance__c>();
        for (ZZPhaseInstance__c pinstanceObj : pinstanceObjList)
            pinstanceObjMap.put(pinstanceObj.Id, pinstanceObj);
        Test.startTest();
        for (ZZPhaseInstance__c pinstanceObj : pinstanceObjList) {
            ZZPhaseInstance pinstance = ZZPhaseInstance.getPhase(pinstanceObj.Id);
            assertPhaseInstanceEquals(pinstanceObj, pinstance);
        }
        System.assertEquals(0, LIMITS.getDMLStatements());
        System.assertEquals(6, LIMITS.getQueries());
        for (ZZPhaseInstance__c pinstanceObj : pinstanceObjList) {
            ZZPhaseInstance pinstance = ZZPhaseInstance.getPhase(pinstanceObj.Id);
            assertPhaseInstanceEquals(pinstanceObj, pinstance);
        }
        System.assertEquals(0, LIMITS.getDMLStatements());
        System.assertEquals(6, LIMITS.getQueries());
        List<ZZPhaseModel> pmodelList = wfinstance.getModel().getPhaseList();
        for (ZZPhaseModel pmodel : pmodelList) {
            ZZPhaseInstance pinstance = wfinstance.getPhase(pmodel);
            ZZPhaseInstance__c pinstanceObj = pinstanceObjMap.get(pinstance.getId());
            assertPhaseInstanceEquals(pinstanceObj, pinstance);
        }
        System.assertEquals(0, LIMITS.getDMLStatements());
        System.assertEquals(6, LIMITS.getQueries());
        Test.stopTest();
        System.assertEquals(0, ZZParser.getErrMsgList().size());
    }

    @isTest
    public static void testGetNoneExisitingPhaseWithWorkflowAndModel() {
        ZZWorkflowInstance wfinstance = memorySetup();
        ZZWorkflowModel wfmodel = wfinstance.getModel();
        ZZPhaseModel newPModel = wfmodel.getPhase('New Phase');
        Test.startTest();
        ZZPhaseInstance newPInstance = wfinstance.getPhase(newPModel);
        System.assertEquals(2, LIMITS.getQueries());
        System.assertEquals(1, LIMITS.getDMLStatements());
        Test.stopTest();
        ZZPhaseInstance__c newPInstanceObj = getObj(newPInstance.getId());
        assertPhaseInstanceEquals(newPInstanceObj, newPInstance);
        System.assertEquals(0, ZZParser.getErrMsgList().size());
    }

    @isTest
    public static void testGetPhaseWithError() {
        ZZWorkflowInstance wfinstance = memorySetup();
        ZZPhaseModel pmodel = wfinstance.getModel().getPhase('Test Phase Model');
        ZZPhaseInstance__c pinstance1 = new ZZPhaseInstance__c(Name = 'Test 1', Workflow__c = wfinstance.getId(), Model__c = pmodel.getId());
        ZZPhaseInstance__c pinstance2 = new ZZPhaseInstance__c(Name = 'Test 2', Workflow__c = wfinstance.getId(), Model__c = pmodel.getId());
        insert pinstance1;
        insert pinstance2;
        ZZPhaseInstance pinstance = wfinstance.getPhase(pmodel);
        System.assertEquals(pinstance1.Id, pinstance.getId());
        System.assertEquals(1, ZZParser.getErrMsgList().size());
        System.assert(ZZParser.getErrMsgList()[0].startsWith(ZZPhaseInstance.multiWorkflowAndModelErr));
    }

    @isTest
    public static void testGetPhaseWithWorkflowAndModel() {
        ZZWorkflowInstance wfinstance = memorySetup();
        ZZWorkflowModel wfmodel = wfinstance.getModel();
        List<ZZPhaseModel> pmodelList = wfmodel.getPhaseList();
        List<ZZPhaseInstance__c> pinstanceObjList = [SELECT Id, Name, Workflow__c, Model__c, Status__c FROM
                ZZPhaseInstance__c];
        Map<Id, ZZPhaseInstance__c> pinstanceObjMap = new Map<Id, ZZPhaseInstance__c>();
        for (ZZPhaseInstance__c pinstanceObj : pinstanceObjList)
            pinstanceObjMap.put(pinstanceObj.Id, pinstanceObj);
        System.assertEquals(6, pmodelList.size());
        Test.startTest();
        for (ZZPhaseModel pmodel : pmodelList) {
            ZZPhaseInstance pinstance = wfinstance.getPhase(pmodel);
            ZZPhaseInstance__c pinstanceObj = pinstanceObjMap.get(pinstance.getId());
            assertPhaseInstanceEquals(pinstanceObj, pinstance);
        }
        System.assertEquals(0, LIMITS.getDMLStatements());
        System.assertEquals(6, LIMITS.getQueries());
        for (ZZPhaseModel pmodel : pmodelList) {
            ZZPhaseInstance pinstance = wfinstance.getPhase(pmodel);
            ZZPhaseInstance__c pinstanceObj = pinstanceObjMap.get(pinstance.getId());
            assertPhaseInstanceEquals(pinstanceObj, pinstance);
        }
        System.assertEquals(0, LIMITS.getDMLStatements());
        System.assertEquals(6, LIMITS.getQueries());
        for (ZZPhaseInstance__c pinstanceObj : pinstanceObjList) {
            ZZPhaseInstance pinstance = ZZPhaseInstance.getPhase(pinstanceObj.Id);
            assertPhaseInstanceEquals(pinstanceObj, pinstance);
        }
        System.assertEquals(6, LIMITS.getQueries());
        System.assertEquals(0, LIMITS.getDMLStatements());
        Test.stopTest();
        System.assertEquals(0, ZZParser.getErrMsgList().size());
    }

    @isTest
    public static void testCheckReady(){
        ZZWorkflowModel wfmodel = ZZWorkflowModel.getWorkflow('Sample Workflow');
        ZZPhaseModel pmodel0 = wfmodel.getPhase('Sample Phase 0');
        ZZPhaseModel pmodel1 = wfmodel.getPhase('Sample Phase 1');
        ZZPhaseModel pmodel2 = wfmodel.getPhase('Sample Phase 2');
        ZZWorkflowInstance wfinstance = wfmodel.buildInstance('Sample Workflow Instance');
        ZZPhaseInstance p0 = wfinstance.getPhase(pmodel0);
        ZZPhaseInstance p1 = wfinstance.getPhase(pmodel1);
        ZZPhaseInstance p2 = wfinstance.getPhase(pmodel2);
        Test.startTest();
        System.assert(p0.checkReady());
        System.assert(!p1.checkReady());
        System.assert(!p2.checkReady());
        System.assertEquals(0, LIMITS.getQueries());
        Integer currQueries = LIMITS.getQueries();
        p0.kickOff();
        p0.executeAction('complete');
        System.assertEquals(0, currQueries);

        currQueries = LIMITS.getQueries();
        System.assertEquals(Status_In_Progress, p1.getStatus());
        System.assertEquals(Status_In_Progress, p2.getStatus());
        System.assert(!p1.checkReady());
        System.assert(!p2.checkReady());
        System.assertEquals(0, LIMITS.getQueries());

        p1.setStatus(Status_New);
        p2.setStatus(Status_New);
        currQueries = LIMITS.getQueries();
        System.assertEquals(Status_New, p1.getStatus());
        System.assertEquals(Status_New, p2.getStatus());
        System.assert(p1.checkReady());
        System.assert(p2.checkReady());
        System.assertEquals(0, LIMITS.getQueries());
        Test.stopTest();
    }

    @isTest
    public static void testKickOffNewStatus() {
        ZZWorkflowInstance wfinstance = memorySetup();
        ZZPhaseInstance pinstance = wfinstance.getPhaseList()[0];
        System.assertEquals(Status_New, pinstance.getStatus());
        Test.startTest();
        System.assertEquals(0, LIMITS.getDMLStatements());
        pinstance.kickOff();
        System.assertEquals(1, LIMITS.getDMLStatements());
        System.assertEquals(0, LIMITS.getQueries());
        Test.stopTest();
        System.assertEquals(0, ZZParser.getErrMsgList().size());
    }

    @isTest
    public static void testKickOffInProgressStatus() {
        ZZWorkflowInstance wfinstance = memorySetup();
        ZZPhaseInstance pinstance = wfinstance.getPhaseList()[0];
        pinstance.kickOff();
        System.assertEquals(Status_In_Progress, pinstance.getStatus());
        Test.startTest();
        pinstance.kickOff();
        System.assertEquals(0, LIMITS.getDMLStatements());
        System.assertEquals(0, LIMITS.getQueries());
        Test.stopTest();
        System.assertEquals(0, ZZParser.getErrMsgList().size());
    }

    @isTest
    public static void testSetStatusCompleted() {
        ZZWorkflowInstance wfinstance = memorySetup();
        ZZPhaseModel pmodel = wfinstance.getModel().getPhase('Test Phase');
        ZZPhaseInstance pinstance = wfinstance.getPhase(pmodel);
        Test.startTest();
        pinstance.setStatus(Status_Completed);
        System.assertEquals(1, LIMITS.getDMLStatements());
        Test.stopTest();
        System.assertEquals(Status_Completed, pinstance.getStatus());
        ZZPhaseInstance__c pinstanceObj = [SELECT Status__c FROM ZZPhaseInstance__c WHERE
                                           Id = :pinstance.getId()];
        System.assertEquals(pinstanceObj.Status__c, pinstance.getStatus());
    }

    @isTest
    public static void testKickOffCompletedStatus() {
        ZZWorkflowInstance wfinstance = memorySetup();
        ZZPhaseInstance pinstance = wfinstance.getPhaseList()[0];
        pinstance.setStatus(Status_Completed);
        List<ZZPhaseInstance> children = pinstance.getChildren();
        for (ZZPhaseInstance child : children) {
            child.setStatus(Status_New);
        }
        System.assert(wfinstance === pinstance.getWorkflow());
        System.assertEquals(Status_Completed, pinstance.getStatus());
        Test.startTest();
        pinstance.kickOff();
        System.assertEquals(children.size() + 1, LIMITS.getDMLStatements());
        System.assertEquals(0, LIMITS.getQueries());
        Test.stopTest();
        System.assertEquals(0, ZZParser.getErrMsgList().size());
    }
}