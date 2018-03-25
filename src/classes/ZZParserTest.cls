@isTest
public class ZZParserTest {
    @isTest
    public static void testConvertStructureToVis(){
        Test.startTest();
        Map<String, Object> structure = new Map<String, Object>{
            'nodes' => new List<Object>{
                new Map<String, String>{
                    'id' => 'TestNodeId',
                    'label' => 'TestNodeLabel'
                }
            },
            'edges' => new List<Object>{
                new Map<String, String>{
                    'from' => 'SampleParentId',
                    'to' => 'SampleChildId',
                    'arrows' => 'to'
                }
            }
        };
        Map<String, Object> visStructure = ZZParser.convertStructureToVis(structure);

        Map<String, Object> nodes = (Map<String, Object>)visStructure.get('nodes');
        Map<String, Object> edges = (Map<String, Object>)visStructure.get('edges');
        System.assertEquals(1, nodes.size());
        System.assertEquals(1, edges.size());
        for (String nodeId : nodes.keySet()){
            Map<String, String> node = (Map<String, String>) nodes.get(nodeId);
            System.assertEquals('TestNodeId', nodeId);
            System.assertEquals('TestNodeId', node.get('id'));
            System.assertEquals('TestNodeLabel', node.get('label'));
        }
        for (String edgeId : edges.keySet()){
            Map<String, String> edge = (Map<String, String>) edges.get(edgeId);
            System.assertEquals('0', edgeId);
            System.assertEquals('0', edge.get('id'));
            System.assertEquals('SampleParentId', edge.get('from'));
            System.assertEquals('SampleChildId', edge.get('to'));
            System.assertEquals('to', edge.get('arrows'));
        }
        System.assertEquals(0, LIMITS.getDMLStatements());
        System.assertEquals(0, LIMITS.getQueries());
        Test.stopTest();
    }

    @isTest
    public static void testParsePInstanceList(){
        ZZWorkflowModelTest.setup();
        ZZWorkflowModel__c wfmodelObj = [SELECT Id, Name, Auto_Kick_Off__c FROM ZZWorkflowModel__c][0];
        ZZWorkflowModel wfmodel = ZZWorkflowModel.getWorkflow(wfmodelObj.Id);
        ZZWorkflowInstance wfinstance = wfmodel.buildInstance('Test Workflow Instance');
        List<ZZPhaseInstance__c> pinstanceObjList = [SELECT Id FROM ZZPhaseInstance__c];
        List<String> pinstandIdList = new List<String>();
        for (ZZPhaseInstance__c pinstance : pinstanceObjList){
            pinstandIdList.add(pinstance.Id);
        }
        String pinstandIds = String.join(pinstandIdList, ',');
        List<ZZPhaseInstance> pinstanceList = ZZParser.parsePinstanceList(pinstandIds);
        for (ZZPhaseInstance pinstance : pinstanceList){
            System.assert(ZZParser.listContainsCopy(pinstandIdList, (String)pinstance.getId()));
        }
    }

    @isTest
    public static void testParsePInstanceListWithEmptyStringOrNull(){
        System.assertEquals(0, ZZParser.parsePinstanceList('').size());
        System.assertEquals(0, ZZParser.parsePinstanceList(Null).size());
    }
    
    @isTest
    public static void testListContains(){
        List<String> l = new List<String>{'hello', 'world', 'owen'};
        System.assert(ZZParser.listContains(l, 'owen'));
    }
    
    @isTest
    public static void testListNotContains(){
        List<String> l = new List<String>{'hello', 'world', 'owen'};
        System.assert(!ZZParser.listContains(l, 'Zhong'));
    }
}