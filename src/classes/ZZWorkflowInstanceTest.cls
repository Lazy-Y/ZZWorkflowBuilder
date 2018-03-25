@isTest
public class ZZWorkflowInstanceTest {
    @testSetup
    public static void setup() {
        ZZWorkflowModelTest.setup();
    }

    @isTest
    public static void testGetWorkflowInstance() {
        ZZWorkflowModel wfmodel = ZZWorkflowModel.getWorkflow('Sample Workflow');
        String wfinstanceName = 'Sample Workflow Instance';
        ZZWorkflowInstance wfinstance = wfmodel.buildInstance(wfinstanceName);
        ZZWorkflowInstance.cleanUpCache();
        Test.startTest();
        ZZWorkflowInstance wfinstance1 = wfmodel.getInstance(wfinstanceName);
        System.assert(wfinstance !== wfinstance1);
        System.assertEquals(wfinstance.getId(), wfinstance1.getId());
        System.assertEquals(1, LIMITS.getQueries());
        System.assertEquals(0, LIMITS.getDMLStatements());

        ZZWorkflowInstance wfinstance2 = wfmodel.getInstance(wfinstanceName);
        System.assert(wfinstance1 === wfinstance2);
        System.assertEquals(1, LIMITS.getQueries());
        System.assertEquals(0, LIMITS.getDMLStatements());

        ZZWorkflowInstance wfinstance3 = wfmodel.getInstance(wfinstance1.getId());
        System.assert(wfinstance1 === wfinstance3);
        System.assertEquals(1, LIMITS.getQueries());
        System.assertEquals(0, LIMITS.getDMLStatements());

        ZZWorkflowInstance.cleanUpCache();

        ZZWorkflowInstance wfinstance4 = wfmodel.getInstance(wfinstance2.getId());
        System.assert(wfinstance2 != wfinstance4);
        System.assertEquals(wfinstance2.getId(), wfinstance4.getId());
        System.assertEquals(2, LIMITS.getQueries());
        System.assertEquals(0, LIMITS.getDMLStatements());

        ZZWorkflowInstance wfinstance5 = wfmodel.getInstance(wfinstance2.getId());
        System.assert(wfinstance4 === wfinstance5);
        System.assertEquals(2, LIMITS.getQueries());
        System.assertEquals(0, LIMITS.getDMLStatements());

        ZZWorkflowInstance wfinstance6 = wfmodel.getInstance(wfinstanceName);
        System.assert(wfinstance4 === wfinstance6);
        System.assertEquals(2, LIMITS.getQueries());
        System.assertEquals(0, LIMITS.getDMLStatements());

        Test.stopTest();
    }

    @isTest
    public static void testGetPhaseList() {
        ZZWorkflowModel wfmodel = ZZWorkflowModel.getWorkflow('Sample Workflow');
        String wfinstanceName = 'Sample Workflow Instance';
        ZZWorkflowInstance wfinstance = wfmodel.buildInstance(wfinstanceName);
        Test.startTest();
        List<ZZPhaseInstance> phaseList = wfinstance.getPhaseList();
        System.assertEquals(0, LIMITS.getQueries());
        System.assertEquals(0, LIMITS.getDMLStatements());
        Test.stopTest();
        List<ZZPhaseInstance__c> phaseObjList = [SELECT Id FROM ZZPhaseInstance__c];
        System.assertEquals(phaseObjList.size(), phaseList.size());
        List<Id> phaseIdList = new List<Id>();
        for (ZZPhaseInstance phase : phaseList) {
            phaseIdList.add(phase.getId());
        }
        for (ZZPhaseInstance__c phaseObj : phaseObjList) {
            System.assert(ZZParser.listContainsCopy(phaseIdList, phaseObj.Id));
        }
    }

    @isTest
    public static void testGetPhaseStatus() {
        ZZWorkflowModel wfmodel = ZZWorkflowModel.getWorkflow('Sample Workflow');
        String wfinstanceName = 'Sample Workflow Instance';
        ZZWorkflowInstance wfinstance = wfmodel.buildInstance(wfinstanceName);
        List<ZZPhaseModel> pmodelList = wfmodel.getPhaseList();
        Test.startTest();
        List<ZZPhaseInstance> pinstanceList = wfinstance.getPhaseList();
        System.assertEquals(0, LIMITS.getQueries());
        System.assertEquals(0, LIMITS.getDMLStatements());
        Test.stopTest();
        Map<String, String> statusMap = wfinstance.getStatusMap();
        System.assertEquals(pmodelList.size(), statusMap.size());
        for (ZZPhaseModel pmodel : pmodelList) {
            System.assertEquals(ZZPhaseInstanceTest.Status_New, statusMap.get(pmodel.getId()));
        }

        List<String> statusList = new List<String> {ZZPhaseInstanceTest.Status_Completed,
                ZZPhaseInstanceTest.Status_In_Progress,
                ZZPhaseInstanceTest.Status_In_Progress,
                ZZPhaseInstanceTest.Status_New,
                ZZPhaseInstanceTest.Status_New,
                ZZPhaseInstanceTest.Status_New
                                                   };

        wfinstance.kickOff();
        wfinstance.getCurrentPhaseList()[0].executeAction('complete');
        statusMap = wfinstance.getStatusMap();

        for (Integer i = 0; i < pmodelList.size(); i++){
            System.assertEquals(statusList[i], statusMap.get(pmodelList[i].getId()));
        }
        System.assertEquals(pmodelList.size(), statusMap.size());
    }

    @isTest
    public static void testKickOff(){
        ZZWorkflowModel wfmodel = ZZWorkflowModel.getWorkflow('Sample Workflow');
        String wfinstanceName = 'Sample Workflow Instance';
        ZZWorkflowInstance wfinstance = wfmodel.buildInstance(wfinstanceName);
        Test.startTest();
        wfinstance.kickOff();
        System.assertEquals(2, LIMITS.getDMLStatements());
        System.assertEquals(0, LIMITS.getQueries());
        Test.stopTest();
        System.assertEquals(ZZPhaseInstanceTest.Status_In_Progress, wfinstance.getStartPhaseList()[0].getStatus());
        System.assertEquals(ZZWorkflowInstance.Status_In_Progress, wfinstance.getStatus());
        ZZWorkflowInstance__c wfinstanceObj = [SELECT Id, Status__c FROM ZZWorkflowInstance__c WHERE Id = :wfinstance.getId()];
        System.assertEquals(ZZWorkflowInstance.Status_In_Progress, wfinstanceObj.Status__c);
    }

    @isTest
    public static void testCheckCompleted(){
        ZZWorkflowModel wfmodel = ZZWorkflowModel.getWorkflow('Sample Workflow');
        String wfinstanceName = 'Sample Workflow Instance';
        ZZWorkflowInstance wfinstance = wfmodel.buildInstance(wfinstanceName);
        Test.startTest();
        System.assertEquals(ZZWorkflowInstance.Status_New, wfinstance.getStatus());
        System.assertEquals(0, LIMITS.getQueries());
        Test.stopTest();
        wfinstance.kickOff();
        List<ZZPhaseInstance> currentPhaseList = wfinstance.getCurrentPhaseList();
        while (currentPhaseList.size() > 0) {
            System.assertEquals(ZZWorkflowInstance.Status_In_Progress, wfinstance.getStatus());
            ZZPhaseInstance phase = currentPhaseList[0];
            phase.executeAction('complete');
            currentPhaseList = wfinstance.getCurrentPhaseList();
        }
        System.assertEquals(ZZWorkflowInstance.Status_Completed, wfinstance.getStatus());
    }

    @isTest
    public static void testGetStartPhaseList(){
        ZZWorkflowModel wfmodel = ZZWorkflowModel.getWorkflow('Sample Workflow');
        String wfinstanceName = 'Sample Workflow Instance';
        ZZWorkflowInstance wfinstance = wfmodel.buildInstance(wfinstanceName);
        Test.startTest();
        List<ZZPhaseInstance> pinstanceList = wfinstance.getStartPhaseList();
        System.assertEquals(0, LIMITS.getQueries());
        System.assertEquals(0, LIMITS.getDMLStatements());
        System.assertEquals(1, pinstanceList.size());
        wfmodel.getPhase('New Phase');
        System.assertEquals(2, LIMITS.getQueries());
        System.assertEquals(1, LIMITS.getDMLStatements());
        pinstanceList = wfinstance.getStartPhaseList();
        System.assertEquals(2, pinstanceList.size());
        System.assertEquals(4, LIMITS.getQueries());
        System.assertEquals(2, LIMITS.getDMLStatements());
        Test.stopTest();
    }

    @isTest
    public static void testAddPhaseToCurrent() {
        ZZWorkflowModel__c wfmodelObj = [SELECT Id, Name, Auto_Kick_Off__c
                                         FROM ZZWorkflowModel__c][0];
        ZZWorkflowModel wfmodel = ZZWorkflowModel.getWorkflow(wfmodelObj.Id);
        ZZWorkflowInstance workflow = wfmodel.buildInstance('My First Workflow');
        ZZPhaseInstance pinstance = workflow.getStartPhaseList()[0];
        Test.startTest();
        workflow.addPhaseToCurrent(pinstance);
        System.assertEquals(1, LIMITS.getDMLStatements());
        Test.stopTest();
    }

    @isTest
    public static void testWorkflowSimulation() {
        Test.startTest();
        ZZWorkflowModel__c wfmodelObj = [SELECT Id, Name, Auto_Kick_Off__c
                                         FROM ZZWorkflowModel__c][0];
        ZZWorkflowModel wfmodel = ZZWorkflowModel.getWorkflow(wfmodelObj.Id);
        ZZWorkflowInstance workflow = wfmodel.buildInstance('My First Workflow');

        System.assertEquals(0, workflow.getCurrentPhaseList().size());
        System.assertEquals(ZZWorkflowInstance.Status_New, workflow.getStatus());
        ZZPhaseInstance p0 = workflow.getStartPhaseList()[0];
        System.assertEquals(ZZPhaseInstanceTest.Status_New, p0.getStatus());

        List<ZZPhaseModel> pmodelList = wfmodel.getPhaseList();

        List<ZZPhaseInstance> p0children = p0.getChildren();

        workflow.kickOff();
        System.assertEquals(1, workflow.getCurrentPhaseList().size());
        System.assertEquals(ZZWorkflowInstance.Status_In_Progress, workflow.getStatus());
        System.assertEquals(ZZPhaseInstanceTest.Status_In_Progress, p0.getStatus());
        assertPhaseListStatus(p0children, ZZPhaseInstanceTest.Status_New);

        p0.executeAction('complete');
        System.assertEquals(2, workflow.getCurrentPhaseList().size());
        System.assertEquals(ZZWorkflowInstance.Status_In_Progress, workflow.getStatus());
        System.assertEquals(ZZPhaseInstanceTest.Status_Completed, p0.getStatus());
        assertPhaseListStatus(p0children, ZZPhaseInstanceTest.Status_In_Progress);

        ZZPhaseInstance p1 = workflow.getPhase(pmodelList[1]);
        ZZPhaseInstance p2 = workflow.getPhase(pmodelList[2]);
        List<ZZPhaseInstance> p1children = p1.getChildren();
        List<ZZPhaseInstance> p2children = p2.getChildren();
        assertPhaseListStatus(p1children, ZZPhaseInstanceTest.Status_New);
        assertPhaseListStatus(p2children, ZZPhaseInstanceTest.Status_New);

        ZZPhaseInstance p3 = workflow.getPhase(pmodelList[3]);
        ZZPhaseInstance p4 = workflow.getPhase(pmodelList[4]);
        System.assertEquals(p4.getId(), p2.getChildren()[0].getId());

        p1.executeAction('complete');
        System.assertEquals(2, workflow.getCurrentPhaseList().size());
        System.assertEquals(ZZWorkflowInstance.Status_In_Progress, workflow.getStatus());
        System.assertEquals(ZZPhaseInstanceTest.Status_Completed, p1.getStatus());
        System.assertEquals(ZZPhaseInstanceTest.Status_In_Progress, p2.getStatus());
        System.assertEquals(ZZPhaseInstanceTest.Status_In_Progress, p3.getStatus());
        System.assertEquals(ZZPhaseInstanceTest.Status_New, p4.getStatus());

        List<ZZPhaseInstance> p3children = p3.getChildren();
        List<ZZPhaseInstance> p4children = p4.getChildren();
        System.assertEquals(1, p3children.size());
        System.assertEquals(1, p4children.size());
        System.assert(p4children[0] === p3children[0]);
        ZZPhaseInstance p5 = workflow.getPhase(pmodelList[5]);

        p2.executeAction('complete');
        System.assertEquals(2, workflow.getCurrentPhaseList().size());
        System.assertEquals(ZZWorkflowInstance.Status_In_Progress, workflow.getStatus());
        System.assertEquals(ZZPhaseInstanceTest.Status_Completed, p2.getStatus());
        System.assertEquals(ZZPhaseInstanceTest.Status_In_Progress, p3.getStatus());
        System.assertEquals(ZZPhaseInstanceTest.Status_In_Progress, p4.getStatus());
        System.assertEquals(ZZPhaseInstanceTest.Status_New, p5.getStatus());

        p3.executeAction('complete');
        System.assertEquals(1, workflow.getCurrentPhaseList().size());
        System.assertEquals(ZZWorkflowInstance.Status_In_Progress, workflow.getStatus());
        System.assertEquals(ZZPhaseInstanceTest.Status_Completed, p3.getStatus());
        System.assertEquals(ZZPhaseInstanceTest.Status_In_Progress, p4.getStatus());
        System.assertEquals(ZZPhaseInstanceTest.Status_New, p5.getStatus());

        p4.executeAction('complete');
        System.assertEquals(1, workflow.getCurrentPhaseList().size());
        System.assertEquals(ZZWorkflowInstance.Status_In_Progress, workflow.getStatus());
        System.assertEquals(ZZPhaseInstanceTest.Status_Completed, p4.getStatus());
        System.assertEquals(ZZPhaseInstanceTest.Status_In_Progress, p5.getStatus());

        p5.executeAction('complete');
        System.assertEquals(0, workflow.getCurrentPhaseList().size());
        System.assertEquals(ZZWorkflowInstance.Status_Completed, workflow.getStatus());
        System.assertEquals(ZZPhaseInstanceTest.Status_Completed, p0.getStatus());
        System.assertEquals(ZZPhaseInstanceTest.Status_Completed, p1.getStatus());
        System.assertEquals(ZZPhaseInstanceTest.Status_Completed, p2.getStatus());
        System.assertEquals(ZZPhaseInstanceTest.Status_Completed, p3.getStatus());
        System.assertEquals(ZZPhaseInstanceTest.Status_Completed, p4.getStatus());
        System.assertEquals(ZZPhaseInstanceTest.Status_Completed, p5.getStatus());

        //Kick off a completed workflow
        workflow.kickOff();
        System.assertEquals(ZZWorkflowInstance.Status_Completed, workflow.getStatus());
        System.assertEquals(ZZPhaseInstanceTest.Status_Completed, p0.getStatus());
        System.assertEquals(ZZPhaseInstanceTest.Status_Completed, p1.getStatus());
        System.assertEquals(ZZPhaseInstanceTest.Status_Completed, p2.getStatus());
        System.assertEquals(ZZPhaseInstanceTest.Status_Completed, p3.getStatus());
        System.assertEquals(ZZPhaseInstanceTest.Status_Completed, p4.getStatus());
        System.assertEquals(ZZPhaseInstanceTest.Status_Completed, p5.getStatus());

        Test.stopTest();
    }

    public static void assertPhaseListStatus(List<ZZPhaseInstance> plist, String status) {
        for (ZZPhaseInstance phase : plist)
            System.assertEquals(status, phase.getStatus());
    }

    @isTest
    public static void testAddAndRemoveCurrentPhase() {
        ZZWorkflowModel wfmodel = ZZWorkflowModel.getWorkflow('Sample Workflow');
        ZZWorkflowInstance workflow = wfmodel.buildInstance('Sample Workflow Instance');
        System.assertEquals(0, workflow.getCurrentPhaseList().size());
        ZZPhaseInstance phase0 = workflow.getStartPhaseList()[0];

        List<ZZPhaseInstance> phaseList = phase0.getChildren();
        ZZPhaseInstance phase1 = phaseList.get(0);
        ZZPhaseInstance phase2 = phaseList.get(1);

        System.assertEquals(2, phaseList.size());

        Test.startTest();
        workflow.addPhaseToCurrent(phase0);
        System.assertEquals(1, workflow.getCurrentPhaseList().size());
        System.assertEquals(workflow.getCurrentPhaseList()[0].getId(), phase0.getId());
        System.assertEquals(1, LIMITS.getDMLStatements());
        System.assertEquals(0, LIMITS.getQueries());

        workflow.addPhaseToCurrent(phase0);
        System.assertEquals(1, workflow.getCurrentPhaseList().size());
        System.assertEquals(workflow.getCurrentPhaseList()[0].getId(), phase0.getId());
        System.assertEquals(1, LIMITS.getDMLStatements());
        System.assertEquals(0, LIMITS.getQueries());

        workflow.addPhaseToCurrent(phase1);
        System.assertEquals(2, workflow.getCurrentPhaseList().size());
        System.assertEquals(workflow.getCurrentPhaseList()[1].getId(), phase1.getId());
        System.assertEquals(2, LIMITS.getDMLStatements());
        System.assertEquals(0, LIMITS.getQueries());

        workflow.addPhaseToCurrent(phase2);
        System.assertEquals(3, workflow.getCurrentPhaseList().size());
        System.assertEquals(workflow.getCurrentPhaseList()[2].getId(), phase2.getId());
        System.assertEquals(3, LIMITS.getDMLStatements());
        System.assertEquals(0, LIMITS.getQueries());

        workflow = ZZWorkflowInstance.getWorkflow(workflow.getId());
        System.assertEquals(3, workflow.getCurrentPhaseList().size());

        workflow.removePhaseFromCurrent(phase1);
        System.assertEquals(2, workflow.getCurrentPhaseList().size());
        System.assertEquals(workflow.getCurrentPhaseList()[0].getId(), phase0.getId());
        System.assertEquals(workflow.getCurrentPhaseList()[1].getId(), phase2.getId());
        System.assertEquals(4, LIMITS.getDMLStatements());
        System.assertEquals(0, LIMITS.getQueries());

        workflow.removePhaseFromCurrent(phase1);
        System.assertEquals(2, workflow.getCurrentPhaseList().size());
        System.assertEquals(workflow.getCurrentPhaseList()[0].getId(), phase0.getId());
        System.assertEquals(workflow.getCurrentPhaseList()[1].getId(), phase2.getId());
        System.assertEquals(4, LIMITS.getDMLStatements());
        System.assertEquals(0, LIMITS.getQueries());

        workflow.removePhaseFromCurrent(phase0);
        System.assertEquals(1, workflow.getCurrentPhaseList().size());
        System.assertEquals(workflow.getCurrentPhaseList()[0].getId(), phase2.getId());
        System.assertEquals(5, LIMITS.getDMLStatements());
        System.assertEquals(0, LIMITS.getQueries());

        workflow.removePhaseFromCurrent(phase2);
        System.assertEquals(0, workflow.getCurrentPhaseList().size());
        System.assertEquals(6, LIMITS.getDMLStatements());
        System.assertEquals(0, LIMITS.getQueries());

        Test.stopTest();
    }
}