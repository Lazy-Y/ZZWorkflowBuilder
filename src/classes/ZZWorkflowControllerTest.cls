@isTest
private class ZZWorkflowControllerTest {
	@testSetup
    public static void setup(){
        ZZWorkflowModelTest.setup();
    }

    @isTest
    public static void testGetWorkflowModelMap(){
        ZZWorkflowModel wf1 = ZZWorkflowModel.getWorkflow('Sample Workflow 1');
        ZZWorkflowModel wf2 = ZZWorkflowModel.getWorkflow('Sample Workflow 2');
        ZZWorkflowModel wf3 = ZZWorkflowModel.getWorkflow('Sample Workflow 3');
        Map<String, String> wfmap = ZZWorkflowController.getWorkflowModelMap();
        System.assertEquals(4, wfmap.size());
        System.assert(wfmap.containsKey('Sample Workflow 1'));
        System.assert(wfmap.containsKey('Sample Workflow 2'));
        System.assert(wfmap.containsKey('Sample Workflow 3'));
        System.assert(wfmap.containsKey('Sample Workflow'));
    }

    @isTest
    public static void testKickOff(){
        ZZWorkflowModel wfmodel = ZZWorkflowModel.getWorkflow('New Workflow');
        System.assertNotEquals('Success!', ZZWorkflowController.kickOff('hello'));
        System.assertNotEquals('Success!', ZZWorkflowController.kickOff(wfmodel.getId()));
        ZZWorkflowInstance wfinstance = wfmodel.buildInstance('Test Workflow');
        System.assertEquals('Success!', ZZWorkflowController.kickOff(wfinstance.getId()));
    }

    @isTest
    public static void testGetWorkflowInstanceMapWithBadId(){
        Map<String, String> wfmap = ZZWorkflowController.getWorkflowInstanceMap('bad id');
        System.assertEquals(0, wfmap.size());
        ZZWorkflowModel wfmodel = ZZWorkflowModel.getWorkflow('New Workflow');
        wfmap = ZZWorkflowController.getWorkflowInstanceMap(wfmodel.getId());
        System.assertEquals(0, wfmap.size());
    }

    @isTest
    public static void testSaveStructure(){
        ZZWorkflowModel wfmodel = ZZWorkflowModel.getWorkflow('New Workflow');
        String structure = '{"nodes":{"3ee7ab73-6d34-4afd-b1ef-3a43d6b0c14f":{"label":"n1","id":"3ee7ab73-6d34-4afd-b1ef-3a43d6b0c14f"}},"edges":{}}';
        ZZWorkflowController.saveStructure(wfmodel.getId(), structure);
        List<ZZPhaseModel__c> phaseList = [SELECT Id, Name FROM ZZPhaseModel__c WHERE Workflow__c = :wfmodel.getId()];
        System.assertEquals(1, phaseList.size());
        System.assertEquals('n1', phaseList[0].Name);
        structure = '{"nodes":{"3ee7ab73-6d34-4afd-b1ef-3a43d6b0c14f":{"label":"n1","id":"3ee7ab73-6d34-4afd-b1ef-3a43d6b0c14f"},"1fdf0979-77a8-4cc6-804b-cc3f2bf0a90a":{"label":"n2","id":"1fdf0979-77a8-4cc6-804b-cc3f2bf0a90a"}},"edges":{}}';
        ZZWorkflowController.saveStructure(wfmodel.getId(), structure);
        phaseList = [SELECT Id, Name FROM ZZPhaseModel__c WHERE Workflow__c = :wfmodel.getId()];
        System.assertEquals(2, phaseList.size());
        System.assertEquals('n1', phaseList[0].Name);
        System.assertEquals('n2', phaseList[1].Name);
    }

    @isTest
    public static void testBuildWorkflowModel(){
        String wfmodelId = ZZWorkflowController.buildWorkflowModel('test name');
        ZZWorkflowModel wfmodel = ZZWorkflowModel.getWorkflow((Id)wfmodelId);
        System.assertEquals('test name', wfmodel.getName());
    }

    @isTest
    public static void testBuildWorkflowModelWithExistingName(){
        String wfmodelId = ZZWorkflowController.buildWorkflowModel('Sample Workflow');
        System.assertEquals('Name Duplicated', wfmodelId);
    }

    @isTest
    public static void testBuildWorkflowInstance(){
        ZZWorkflowModel wfmodel = ZZWorkflowModel.getWorkflow('Sample Workflow');
        String newId = ZZWorkflowController.buildWorkflowInstance((String)wfmodel.getId(), 'New Workflow');
        System.assert(ZZParser.isValidId(newId));
    }

    @isTest
    public static void testBuildWorkflowInstanceWithInvalidId(){
        ZZWorkflowModel wfmodel = ZZWorkflowModel.getWorkflow('Sample Workflow');
        System.assertEquals('Invalid Workflow Model Id', ZZWorkflowController.buildWorkflowInstance('Bad Id', 'Name'));
        System.assertEquals('Invalid Workflow Model Id', ZZWorkflowController.buildWorkflowInstance((String)(wfmodel.getPhaseList()[0].getId()), 'Name'));
    }

    @isTest
    public static void testBuildWorkflowInstanceWithDuplicatedName(){
        ZZWorkflowModel wfmodel = ZZWorkflowModel.getWorkflow('Sample Workflow');
        ZZWorkflowInstance wfinstance = wfmodel.buildInstance('New Workflow');
        System.assertEquals('Name Duplicated', ZZWorkflowController.buildWorkflowInstance((String)wfmodel.getId(), 'New Workflow'));
    }

    @isTest
    public static void testGetStructureWithInvalidId(){
        Map<String, Object> structure = new Map<String, Object>();
        List<Object> nodes = new List<Object>();
        List<Object> edges = new List<Object>();
        structure.put('nodes', nodes);
        structure.put('edges', edges);
        ZZWorkflowModel wfmodel = ZZWorkflowModel.getWorkflow('Sample Workflow');
        System.assertEquals(structure, ZZWorkflowController.getStructure('Hello'));
        System.assertEquals(structure, ZZWorkflowController.getStructure(wfmodel.getPhaseList()[0].getId()));
    }

    @isTest
    public static void testGetStructureWithWFModelId(){
        ZZWorkflowModel wfmodel = ZZWorkflowModel.getWorkflow('Sample Workflow');
        Map<String, Object> result = ZZWorkflowController.getStructure(wfmodel.getId());
        System.assert(result.containsKey('nodes'));
        System.assert(result.containsKey('edges'));
        System.assert(!result.containsKey('wfinstance'));
        List<Object> nodes = (List<Object>)result.get('nodes');
        for (Object rawNode : nodes){
            Map<String, Object> node = (Map<String, Object>)rawNode;
            System.assert(node.containsKey('label'));
            System.assert(node.containsKey('id'));
            System.assert(!node.containsKey('Status__c'));
            System.assert(!node.containsKey('color'));
        }
    }

    @isTest
    public static void testGetStructureWithWFInstanceId(){
        ZZWorkflowModel wfmodel = ZZWorkflowModel.getWorkflow('Sample Workflow');
        ZZWorkflowInstance wfinstance = wfmodel.buildInstance('Sample Workflow Instance');
        Map<String, Object> result = ZZWorkflowController.getStructure(wfinstance.getId());
        System.assert(result.containsKey('nodes'));
        System.assert(result.containsKey('edges'));
        System.assert(result.containsKey('wfinstance'));
        Map<String, Object> wfinstanceMap = (Map<String, Object>) result.get('wfinstance');
        System.assert(wfinstanceMap.containsKey('Status__c'));
        List<Object> nodes = (List<Object>)result.get('nodes');
        for (Object rawNode : nodes){
            Map<String, Object> node = (Map<String, Object>)rawNode;
            System.assert(node.containsKey('label'));
            System.assert(node.containsKey('id'));
            System.assert(node.containsKey('Status__c'));
        }
    }

    @isTest
    public static void testSaveStructureBadFormat(){
        ZZWorkflowModel__c wfmodelObj = [SELECT Id, Name, Auto_Kick_Off__c 
                                         FROM ZZWorkflowModel__c][0];
        ZZWorkflowModel wfmodel = ZZWorkflowModel.getWorkflow(wfmodelObj.Id);
        Map<String, Object> structure = ZZWorkflowController.getStructure(wfmodel.getId());
        Map<String, Object> visStructure = ZZParser.convertStructureToVis(structure);
        String newStructure = (String)JSON.serialize(visStructure);
        System.assertEquals('Save structure failed. Bad workflow Id format.', ZZWorkflowController.saveStructure('bad id', newStructure));
    }

    @isTest
    public static void testSaveStructureWrongType(){
        ZZWorkflowModel__c wfmodelObj = [SELECT Id, Name, Auto_Kick_Off__c 
                                         FROM ZZWorkflowModel__c][0];
        ZZWorkflowModel wfmodel = ZZWorkflowModel.getWorkflow(wfmodelObj.Id);
        Map<String, Object> structure = ZZWorkflowController.getStructure(wfmodel.getId());
        Map<String, Object> visStructure = ZZParser.convertStructureToVis(structure);
        ZZWorkflowInstance wfinstance = wfmodel.buildInstance('test wf Instance');
        String newStructure = (String)JSON.serialize(visStructure);
        System.assertEquals('Save structure failed. Id type is not ZZWorkflowModel__c.', ZZWorkflowController.saveStructure(wfinstance.getId(), newStructure));
    }

    @isTest
    public static void testSaveStructureSuccess(){
        ZZWorkflowModel__c wfmodelObj = [SELECT Id, Name, Auto_Kick_Off__c 
                                         FROM ZZWorkflowModel__c][0];
        ZZWorkflowModel wfmodel = ZZWorkflowModel.getWorkflow(wfmodelObj.Id);
        Map<String, Object> structure = ZZWorkflowController.getStructure(wfmodel.getId());
        Map<String, Object> visStructure = ZZParser.convertStructureToVis(structure);
        String newStructure = (String)JSON.serialize(visStructure);
        System.assertEquals('Success!', ZZWorkflowController.saveStructure(wfmodel.getId(), newStructure));
    }

    @isTest
    public static void testGetWorkflowInstanceMap(){
        ZZWorkflowModel wf1 = ZZWorkflowModel.getWorkflow('Sample Workflow 1');
        wf1.buildInstance('Workflow Instance 1 From Model 1');
        wf1.buildInstance('Workflow Instance 2 From Model 1');
        wf1.buildInstance('Workflow Instance 3 From Model 1');
        Map<String, String> wfmap1 = ZZWorkflowController.getWorkflowInstanceMap(wf1.getId());
        System.debug(wfmap1);
        System.assertEquals(3, wfmap1.size());
        System.assert(wfmap1.containsKey('Workflow Instance 1 From Model 1'));
        System.assert(wfmap1.containsKey('Workflow Instance 2 From Model 1'));
        System.assert(wfmap1.containsKey('Workflow Instance 3 From Model 1'));
        
        ZZWorkflowModel wf2 = ZZWorkflowModel.getWorkflow('Sample Workflow 2');
        wf2.buildInstance('Workflow Instance 1 From Model 2');
        wf2.buildInstance('Workflow Instance 2 From Model 2');
        wf2.buildInstance('Workflow Instance 3 From Model 2');
        Map<String, String> wfmap2 = ZZWorkflowController.getWorkflowInstanceMap(wf2.getId());
        System.assertEquals(3, wfmap2.size());
        System.assert(wfmap2.containsKey('Workflow Instance 1 From Model 2'));
        System.assert(wfmap2.containsKey('Workflow Instance 2 From Model 2'));
        System.assert(wfmap2.containsKey('Workflow Instance 3 From Model 2'));
    }

    @isTest
    public static void testSetPhaseStatus(){
        ZZWorkflowModel wfmodel = ZZWorkflowModel.getWorkflow('Sample Workflow');
        ZZWorkflowInstance wfinstance = wfmodel.buildInstance('Sample Workflow Instance');
        ZZPhaseModel pmodel = wfmodel.getPhaseList()[0];
        System.assertEquals('Success!', ZZWorkflowController.setPhaseStatus(wfinstance.getId(), pmodel.getId(), ZZPhaseInstanceTest.Status_Completed));
        System.assertEquals(ZZPhaseInstanceTest.Status_Completed, wfinstance.getPhase(pmodel).getStatus());
    }

    @isTest
    public static void testSetPhaseStatusWithInvalidId(){
        ZZWorkflowModel wfmodel = ZZWorkflowModel.getWorkflow('Sample Workflow');
        ZZWorkflowInstance wfinstance = wfmodel.buildInstance('Sample Workflow Instance');
        ZZPhaseModel pmodel = wfmodel.getPhaseList()[0];
        System.assertNotEquals('Success!', ZZWorkflowController.setPhaseStatus('hello', pmodel.getId(), ZZPhaseInstanceTest.Status_Completed));
        System.assertNotEquals('Success!', ZZWorkflowController.setPhaseStatus(pmodel.getId(), pmodel.getId(), ZZPhaseInstanceTest.Status_Completed));
        System.assertNotEquals('Success!', ZZWorkflowController.setPhaseStatus(pmodel.getId(), wfmodel.getId(), ZZPhaseInstanceTest.Status_Completed));
    }

    @isTest 
    public static void testGetWorkflowStructureWithBadId() {

        Map<String, Object> structure = ZZWorkflowController.getStructure('bad id');

        List<Object> nodes = (List<Object>)structure.get('nodes');
        List<Object> edges = (List<Object>)structure.get('edges');

        System.assertEquals(0, nodes.size());
        System.assertEquals(0, edges.size());

    }

    @isTest 
    public static void testGetWorkflowStructureWithNullId() {

        Map<String, Object> structure = ZZWorkflowController.getStructure(Null);

        List<Object> nodes = (List<Object>)structure.get('nodes');
        List<Object> edges = (List<Object>)structure.get('edges');

        System.assertEquals(0, nodes.size());
        System.assertEquals(0, edges.size());

    }

    @isTest 
    public static void testGetWorkflowStructureWithModelId() {
        ZZWorkflowModel__c wfmodelObj = [SELECT Id, Name, Auto_Kick_Off__c 
                                         FROM ZZWorkflowModel__c][0];
        ZZWorkflowModel wfmodel = ZZWorkflowModel.getWorkflow(wfmodelObj.Id);
        Map<String, Object> structure = ZZWorkflowController.getStructure(wfmodel.getId());

        ZZWorkflowModelTest.checkStructure(structure);

    }

    @isTest 
    public static void testGetWorkflowStructureWithInstanceId() {
        ZZWorkflowModel__c wfmodelObj = [SELECT Id, Name, Auto_Kick_Off__c 
                                         FROM ZZWorkflowModel__c][0];
        ZZWorkflowModel wfmodel = ZZWorkflowModel.getWorkflow(wfmodelObj.Id);
        ZZWorkflowInstance wfinstance = wfmodel.buildInstance('Sample Instance');
        Map<String, Object> structure = ZZWorkflowController.getStructure(wfinstance.getId());

        ZZWorkflowModelTest.checkStructure(structure);

    }

}