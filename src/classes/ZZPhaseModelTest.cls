@isTest
public class ZZPhaseModelTest {
    @testSetup
    public static void setup() {
        ZZWorkflowModelTest.setup();
    }

    @isTest
    public static void testGetPhaseModel() {
        ZZWorkflowModel wfmodel = ZZWorkflowModel.getWorkflow('Sample Workflow');
        ZZPhaseModel pt = wfmodel.getPhase('Sample Phase 1');
        ZZPhaseModel.cleanUpCache();
        Test.startTest();
        ZZPhaseModel p0 = wfmodel.getPhase('Sample Phase 0');
        System.assertEquals(1, LIMITS.getQueries());

        ZZPhaseModel p1 = wfmodel.getPhase('Sample Phase 0');
        System.assertEquals(1, LIMITS.getQueries());
        System.assert(p0 === p1);

        ZZPhaseModel p2 = ZZPhaseModel.getPhase(p0.getId());
        System.assertEquals(1, LIMITS.getQueries());
        System.assert(p0 === p2);


        ZZPhaseModel p3 = ZZPhaseModel.getPhase(pt.getId());
        System.assertEquals(2, LIMITS.getQueries());

        ZZPhaseModel p4 = ZZPhaseModel.getPhase(pt.getId());
        System.assertEquals(2, LIMITS.getQueries());
        System.assert(p3 === p4);

        ZZPhaseModel p5 = wfmodel.getPhase('Sample Phase 1');
        System.assertEquals(2, LIMITS.getQueries());
        System.assert(p3 === p5);
        System.assertEquals(pt.getId(), p5.getId());

        Test.stopTest();
    }

    @isTest
    public static void testUpdateData() {
        ZZWorkflowModel wfmodel = ZZWorkflowModel.getWorkflow('Sample Workflow');
        ZZPhaseModel p0 = wfmodel.getPhase('Sample Phase 0');
        ZZPhaseModel p1 = wfmodel.getPhase('Sample Phase 1');
        ZZPhaseModel p2 = wfmodel.getPhase('Sample Phase 2');
        System.assertEquals('Sample Phase 0', p0.getName());
        List<ZZPhaseModel> startPhaseList = wfmodel.getStartPhaseList();
        List<ZZPhaseModel> phaseList = wfmodel.getPhaseList();
        Test.startTest();
        Map<String, String> action1 = new Map<String, String>{
            'name' => 'Kick Off',
            'next' => 'In Progress'
        };
        Map<String, String> action2 = new Map<String, String>{
            'name' => 'Complete',
            'next' => 'Completed',
            'hook' => 'Complete hook'
        };
        update p0.updateData(new Map<String, Object> {
            'label' => 'New Phase',
            'Parents__c' => p1.getId() + ',' + p2.getId(),
            'Children__c' => '',
            'Phase_Controller_Class__c' => 'Phase_Controller_Class__c',
            'Phase_Controller__c' => 'My Controller',
            'Kick_Off_Function__c' => 'Kick_Off_Function__c',
            'actions' => new List<Object>{action1, action2},
            'statuses' => new List<String>{'New', 'In Progress', 'Completed', 'Skipped'},
            'Default_Status__c' => 'Skipped'
        });
        System.assertEquals(1, LIMITS.getDMLRows());
        System.assertEquals(0, LIMITS.getQueries());

        ZZPhaseModel pm = wfmodel.getPhase('Sample Phase 0');
        System.assertNotEquals('Sample Phase 1', pm.getName());
        System.assertEquals(2, LIMITS.getDMLRows());
        System.assertEquals(2, LIMITS.getQueries());
        System.assertNotEquals(p0.getId(), pm.getId());
        System.assertEquals(0, pm.getParents().size());
        System.assertEquals(0, pm.getChildren().size());
        System.assertEquals(Null, pm.getKickOffFunction());
        System.assertEquals(Null, pm.getPhaseControllerClass());

        System.assertEquals(2, p0.getParents().size());
        System.assertEquals(0, p0.getChildren().size());
        System.assert(!ZZParser.listContains(startPhaseList, p0));
        System.assert(ZZParser.listContains(phaseList, p0));

        ZZPhaseModel pn = wfmodel.getPhase('New Phase');
        System.assert(p0 === pn);
        System.assertEquals(2, LIMITS.getDMLRows());
        System.assertEquals(2, LIMITS.getQueries());
        System.assert(ZZParser.listContains(phaseList, pn));
        System.assert(!ZZParser.listContains(startPhaseList, pn));
        Test.stopTest();

        ZZPhaseModel__c pObj = [SELECT Id, Name, Parents__c, Children__c, Phase_Controller_Class__c, 
                                Kick_Off_Function__c, Phase_Controller__c, Statuses__c, Default_Status__c, 
                                Actions__c FROM ZZPhaseModel__c WHERE Id = :p0.getId()];
        System.assertEquals('New Phase', pObj.Name);
        System.assertEquals(p1.getId() + ',' + p2.getId(), pObj.Parents__c);
        System.assertEquals(Null, pObj.Children__c);
        System.assertEquals('Phase_Controller_Class__c', pObj.Phase_Controller_Class__c);
        System.assertEquals('Kick_Off_Function__c', pObj.Kick_Off_Function__c);
        System.assertEquals('My Controller', pObj.Phase_Controller__c);
        System.assertEquals('New,In Progress,Completed,Skipped', pObj.Statuses__c);
        System.assertEquals('Kick Off,In Progress,\nComplete,Completed,Complete hook', pObj.Actions__c);
        System.assertEquals('Skipped', pObj.Default_Status__c);
    }

    @isTest
    public static void testDestructInDatabase(){
        ZZWorkflowModel wfmodel = ZZWorkflowModel.getWorkflow('Sample Workflow');
        ZZPhaseModel p1 = wfmodel.getPhase('Sample Phase 1');
        Id p1Id = p1.getId();
        p1.destruct();
        List<ZZPhaseModel__c> pmodelObjList = [SELECT Id FROM ZZPhaseModel__c WHERE Id = :p1Id];
        System.assertEquals(0, pmodelObjList.size());
    }

    @isTest
    public static void testDestructWorkflowCache(){
        ZZWorkflowModel wfmodel = ZZWorkflowModel.getWorkflow('Sample Workflow');
        ZZPhaseModel p1 = wfmodel.getPhase('Sample Phase 1');
        p1.destruct();
        System.assertEquals(5, wfmodel.getPhaseList().size());
    }

    @isTest
    public static void testDestructWorkflowCacheAfterCleanUpCache(){
        ZZWorkflowModel wfmodel = ZZWorkflowModel.getWorkflow('Sample Workflow');
        ZZPhaseModel p1 = wfmodel.getPhase('Sample Phase 1');
        ZZPhaseModel.cleanUpCache();
        p1.destruct();
        System.assertEquals(5, wfmodel.getPhaseList().size());
    }

    @isTest
    public static void testDestruct(){
        ZZWorkflowModel wfmodel = ZZWorkflowModel.getWorkflow('Sample Workflow');
        ZZPhaseModel p0 = wfmodel.getPhase('Sample Phase 0');
        ZZPhaseModel p1 = wfmodel.getPhase('Sample Phase 1');
        ZZPhaseModel p3 = wfmodel.getPhase('Sample Phase 3');
        Test.startTest();
        p1.destruct();
        System.assertEquals(2, LIMITS.getDMLStatements());
        System.assertEquals(1, LIMITS.getQueries());
        ZZPhaseModel pnull = ZZPhaseModel.getPhase(p1.getId());
        System.assertEquals(2, LIMITS.getDMLStatements());
        System.assertEquals(2, LIMITS.getQueries());

        ZZPhaseModel pnew = wfmodel.getPhase(p1.getName());
        System.assertEquals(3, LIMITS.getDMLStatements());
        System.assertEquals(4, LIMITS.getQueries());

        List<ZZPhaseModel> parents = p3.getParents();
        System.assertEquals(3, LIMITS.getDMLStatements());
        System.assertEquals(4, LIMITS.getQueries());
        List<ZZPhaseModel> children = p0.getChildren();
        System.assertEquals(3, LIMITS.getDMLStatements());
        System.assertEquals(5, LIMITS.getQueries());

        System.assert(!ZZParser.listContains(children, p1));
        System.assert(!ZZParser.listContains(parents, p1));

        Test.stopTest();
        System.assertEquals(Null, pnull);
    }

    @isTest
    public static void testGetActionMap(){
        ZZPhaseModel__c pObj = new ZZPhaseModel__c(Actions__c = null);
        ZZPhaseModel pmodel = new ZZPhaseModel(pObj);
        Map<String, String> emptyMap = new Map<String, String>();
        System.assertEquals(emptyMap, pmodel.getActionMap('myAction'));
        pObj.Actions__c = '';
        System.assertEquals(emptyMap, pmodel.getActionMap('myAction'));
        pObj.Actions__c = 'Kick Off,,';
        System.assertEquals(emptyMap, pmodel.getActionMap('myAction'));
        System.assertEquals(emptyMap, pmodel.getActionMap('Kick Off'));
        pObj.Actions__c = 'Kick Off,In Progress,';
        System.assertEquals('In Progress', pmodel.getActionMap('Kick Off').get('next'));
        pObj.Actions__c = 'Kick Off,In Progress,My_Hook';
        System.assertEquals('In Progress', pmodel.getActionMap('Kick Off').get('next'));
        System.assertEquals('My_Hook', pmodel.getActionMap('Kick Off').get('hook'));
        pObj.Actions__c = 'Kick Off,In Progress,My_Hook\nComplete,Completed,Complete_Hook';
        System.assertEquals('In Progress', pmodel.getActionMap(null).get('next'));
        System.assertEquals('My_Hook', pmodel.getActionMap(null).get('hook'));
        System.assertEquals('Completed', pmodel.getActionMap('Complete').get('next'));
        System.assertEquals('Complete_Hook', pmodel.getActionMap('Complete').get('hook'));
    }

    @isTest
    public static void testAddChild(){
        ZZWorkflowModel wfmodel = ZZWorkflowModel.getWorkflow('Sample Workflow');
        ZZPhaseModel p0 = wfmodel.getPhase('Sample Phase 0');
        ZZPhaseModel pn = wfmodel.getPhase('New Phase');
        Test.startTest();
        p0.addChild(pn);
        System.assertEquals(0, LIMITS.getQueries());
        System.assertEquals(1, LIMITS.getDMLStatements());
        Test.stopTest();
        List<ZZPhaseModel> children = p0.getChildren();
        System.assert(ZZParser.listContains(children, pn));
        List<ZZPhaseModel> parents = pn.getParents();
        System.assert(ZZParser.listContains(parents, p0));
        ZZPhaseModel__c parentObj = [SELECT Id, Children__c FROM ZZPhaseModel__c WHERE Id = :p0.getId()];
        System.assertEquals(p0.getChildren(), ZZPhaseModel.getPhaseList(parentObj.Children__c.split(',')));
        ZZPhaseModel__c childObj = [SELECT Id, Parents__c FROM ZZPhaseModel__c WHERE Id = :pn.getId()];
        System.assertEquals(pn.getParents(), ZZPhaseModel.getPhaseList(childObj.Parents__c.split(',')));
    }

    @isTest
    public static void testAddStartPhaseAsAChild(){
        ZZWorkflowModel wfmodel = ZZWorkflowModel.getWorkflow('Sample Workflow');
        ZZPhaseModel p0 = wfmodel.getPhase('Sample Phase 0');
        ZZPhaseModel p1 = wfmodel.getPhase('Sample Phase 1');
        Test.startTest();
        p1.addChild(p0);
        System.assertEquals(0, LIMITS.getQueries());
        System.assertEquals(1, LIMITS.getDMLStatements());
        Test.stopTest();
        List<ZZPhaseModel> children = p1.getChildren();
        System.assert(ZZParser.listContains(children, p0));
        List<ZZPhaseModel> parents = p0.getParents();
        System.assert(ZZParser.listContains(parents, p1));
        System.assertEquals(0, wfmodel.getStartPhaseList().size());
        ZZPhaseModel__c parentObj = [SELECT Id, Children__c FROM ZZPhaseModel__c WHERE Id = :p0.getId()];
        System.assertEquals(p0.getChildren(), ZZPhaseModel.getPhaseList(parentObj.Children__c.split(',')));
        ZZPhaseModel__c childObj = [SELECT Id, Parents__c FROM ZZPhaseModel__c WHERE Id = :p1.getId()];
        System.assertEquals(p1.getParents(), ZZPhaseModel.getPhaseList(childObj.Parents__c.split(',')));
    }

    @isTest
    public static void testAddNonExsitingPhaseAsAChild(){
        ZZWorkflowModel wfmodel = ZZWorkflowModel.getWorkflow('Sample Workflow');
        ZZPhaseModel p0 = wfmodel.getPhase('Sample Phase 0');
        ZZPhaseModel p5 = wfmodel.getPhase('Sample Phase 5');
        p5.destruct();
        Test.startTest();
        p0.addChild(p5);
        System.assertEquals(0, LIMITS.getQueries());
        System.assertEquals(0, LIMITS.getDMLStatements());
        Test.stopTest();
        List<ZZPhaseModel> children = p0.getChildren();
        System.assert(!ZZParser.listContains(children, p5));
        System.assertEquals(2, children.size());
    }

    @isTest
    public static void testAddChildAsAChild(){
        ZZWorkflowModel wfmodel = ZZWorkflowModel.getWorkflow('Sample Workflow');
        ZZPhaseModel p0 = wfmodel.getPhase('Sample Phase 0');
        ZZPhaseModel p1 = wfmodel.getPhase('Sample Phase 1');
        p1.destruct();
        Test.startTest();
        p0.addChild(p1);
        System.assertEquals(0, LIMITS.getQueries());
        System.assertEquals(0, LIMITS.getDMLStatements());
        Test.stopTest();
        List<ZZPhaseModel> children = p0.getChildren();
        System.assert(!ZZParser.listContains(children, p1));
        System.assertEquals(1, children.size());
    }

    // Test causing the Apex bug
    @isTest
    public static void testGetPhaseList(){
        ZZWorkflowModel wfmodel = ZZWorkflowModel.getWorkflow('Sample Workflow');
        List<ZZPhaseModel> pmodelList = wfmodel.getPhaseList();
        List<String> pmodelIdList = new List<String>();
        for (ZZPhaseModel pmodel : pmodelList){
            pmodelIdList.add(pmodel.getId());
        }
        System.debug(pmodelList);
        System.debug(pmodelIdList);
        System.assertEquals(6, pmodelIdList.size());
        System.debug('start');
        List<ZZPhaseModel> returnList = ZZPhaseModel.getPhaseList(pmodelIdList);
        for (Id phaseId : pmodelIdList){
            System.assert(ZZParser.listContains(pmodelList, ZZPhaseModel.getPhase(phaseId)));
        }
        System.debug('end');
        System.assertEquals(6, pmodelIdList.size());

        ZZPhaseModel p0 = pmodelList[0];
        ZZPhaseModel p1 = pmodelList[1];
        p0.destruct();
        p1.destruct();
        System.assertEquals(6, pmodelIdList.size());
        System.assertEquals(4, ZZPhaseModel.getPhaseList(pmodelIdList).size());
        System.assertEquals(4, pmodelIdList.size());
        System.assertEquals(4, pmodelList.size());
        System.assert(!ZZParser.listContains(pmodelList, p0));
        System.assert(!ZZParser.listContains(pmodelList, p1));
    }

    @isTest
    public static void testCreateNewPhaseModel() {
        ZZWorkflowModel wfmodel = ZZWorkflowModel.getWorkflow('Sample Workflow');
        wfmodel.getPhaseList();
        ZZPhaseModel__c pObj = new ZZPhaseModel__c(Name = 'Test Phase', Workflow__c = wfmodel.getId());
        Test.startTest();
        ZZPhaseModel p = wfmodel.getPhase('Testing New Phase');
        System.assertEquals('Testing New Phase', p.getName());
        System.assertEquals(1, LIMITS.getDMLStatements());
        System.assertEquals(2, LIMITS.getQueries());

        ZZPhaseModel p1 = ZZPhaseModel.getPhase(pObj);
        System.assertEquals('Test Phase', p1.getName());
        System.assertEquals(1, LIMITS.getDMLStatements());
        System.assertEquals(2, LIMITS.getQueries());
        Test.stopTest();
        pObj = [SELECT Id, Name FROM ZZPhaseModel__c WHERE Id = :p.getId()];
        System.assertEquals('Testing New Phase', pObj.Name);
    }

    @isTest
    public static void testNewPhaseModelUsingId() {
        Test.startTest();
        List<ZZPhaseModel__c> pmodelList = [SELECT Id, Name, Parents__c, Children__c, Phase_Controller_Class__c, Kick_Off_Function__c, Workflow__c FROM ZZPhaseModel__c];
        for (ZZPhaseModel__c pmodelObj : pmodelList) {
            ZZPhaseModel pmodelCls = ZZPhaseModel.getPhase(pmodelObj.Id);
            System.assertEquals(pmodelCls.getId(), pmodelObj.Id);
            System.assertEquals(pmodelCls.getName(), pmodelObj.Name);

            List<ZZPhaseModel> children = pmodelCls.getChildren();
            List<String> childIdList = new List<String>();
            if (pmodelObj.Children__c != Null) childIdList = pmodelObj.Children__c.split(',');
            for (ZZPhaseModel child : children) {
                System.assert(ZZParser.listContainsCopy(childIdList, child.getId()));
            }

            List<ZZPhaseModel> parents = pmodelCls.getParents();
            List<String> parentIdList = new List<String>();
            if (pmodelObj.Parents__c != Null) parentIdList = pmodelObj.Parents__c.split(',');
            for (ZZPhaseModel parent : parents) {
                System.assert(ZZParser.listContainsCopy(parentIdList, parent.getId()));
            }
            ZZWorkflowModel workflow = pmodelCls.getWorkflow();
            System.assertEquals('Sample Workflow', workflow.getName());
            System.assert(workflow === pmodelCls.getWorkflow());
        }
        Test.stopTest();
    }

    public static void testGetParents() {
        ZZWorkflowModel wfmodel = ZZWorkflowModel.getWorkflow('Sample Workflow');
        ZZPhaseModel p1 = wfmodel.getPhase('Sample Phase 1');
        ZZPhaseModel p2 = wfmodel.getPhase('Sample Phase 2');
        ZZPhaseModel p4 = wfmodel.getPhase('Sample Phase 4');
        Test.startTest();
        List<ZZPhaseModel> parents = p4.getParents();
        System.assertEquals(0, LIMITS.getQueries());
        Test.stopTest();
        System.assertEquals(2, parents.size());
        System.assert(p1 === parents[0]);
        System.assert(p2 === parents[1]);
    }

    public static void testGetNoParent() {
        ZZWorkflowModel wfmodel = ZZWorkflowModel.getWorkflow('Sample Workflow');
        ZZPhaseModel p0 = wfmodel.getPhase('Sample Phase 0');
        System.assertEquals(0, p0.getParents().size());
    }
}