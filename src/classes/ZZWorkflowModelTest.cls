@isTest
public class ZZWorkflowModelTest {
    @testSetup
    public static void setup() {
        ZZWorkflowModel wfmodel = ZZWorkflowModel.getWorkflow('Sample Workflow', False);
        List<ZZPhaseModel> pmodelList = new List<ZZPhaseModel>();
        for (Integer i = 0; i < 6; i++) {
            ZZPhaseModel pmodel = wfmodel.getPhase('Sample Phase ' + String.valueOf(i));
            pmodelList.add(pmodel);
        }
        pmodelList[0].addChild(pmodelList[1]);
        pmodelList[0].addChild(pmodelList[2]);
        pmodelList[1].addChild(pmodelList[3]);
        pmodelList[1].addChild(pmodelList[4]);
        pmodelList[2].addChild(pmodelList[4]);
        pmodelList[3].addChild(pmodelList[5]);
        pmodelList[4].addChild(pmodelList[5]);
    }

    @isTest
    public static void testGetWorkflow(){
        Test.startTest();
        ZZWorkflowModel wfmodel = ZZWorkflowModel.getWorkflow('Sample Workflow');
        System.assertEquals(1, LIMITS.getQueries());
        wfmodel = ZZWorkflowModel.getWorkflow('Sample Workflow');
        System.assert(wfmodel === ZZWorkflowModel.getWorkflow(wfmodel.getId()));
        System.assertEquals(1, LIMITS.getQueries());
        System.assertEquals(0, LIMITS.getDMLStatements());
        Test.stopTest();
    }

    @isTest
    public static void testCreateWorkflow(){
        Test.startTest();
        ZZWorkflowModel wfmodel = ZZWorkflowModel.getWorkflow('New Workflow');
        System.assert(wfmodel === ZZWorkflowModel.getWorkflow(wfmodel.getId()));
        System.assertEquals(2, LIMITS.getQueries());
        System.assertEquals(1, LIMITS.getDMLStatements());
        Test.stopTest();
    }

    @isTest
    public static void testUpdateAddNewPhase() {
        ZZWorkflowModel wfmodel = ZZWorkflowModel.getWorkflow('Sample Workflow');
        ZZPhaseModel__c pmodelObj = new ZZPhaseModel__c(Name = 'New Phase', Workflow__c = wfmodel.getId());
        insert pmodelObj;
        ZZPhaseModel pmodel = ZZPhaseModel.getPhase(pmodelObj.Id);
        Test.startTest();
        wfmodel.updateAddNewPhase(pmodel);
        System.assertEquals(0, LIMITS.getDMLStatements());
        System.assertEquals(0, LIMITS.getQueries());
        Test.stopTest();
        System.assert(ZZParser.listContains(wfmodel.getPhaseList(), pmodel));
        System.assert(ZZParser.listContains(wfmodel.getStartPhaseList(), pmodel));
    }

    @isTest
    public static void testUpdateRemovePhase() {
        ZZWorkflowModel wfmodel = ZZWorkflowModel.getWorkflow('Sample Workflow');
        ZZPhaseModel p0 = wfmodel.getPhase('Sample Phase 0');
        p0.destruct();
        System.assertEquals(5, wfmodel.getPhaseList().size());
    }

    @isTest
    public static void testGetStartPhaseList() {
        ZZWorkflowModel wfmodel = ZZWorkflowModel.getWorkflow('Sample Workflow');
        List<ZZPhaseModel> startPhaseList = wfmodel.getStartPhaseList();
        System.assertEquals(1, startPhaseList.size());
        System.assertEquals(wfmodel.getPhase('Sample Phase 0'), startPhaseList[0]);
        wfmodel.getPhase('New Phase');
        System.assertEquals(2, startPhaseList.size());
        wfmodel.getPhase('Sample Phase 0').destruct();
        System.assertEquals(1, startPhaseList.size());
        System.assertEquals(wfmodel.getPhase('New Phase'), startPhaseList[0]);
    }

    @isTest
    public static void testGetPhaseList() {
        ZZWorkflowModel__c wfmodelObj = [SELECT Id, Name, Auto_Kick_Off__c
                                         FROM ZZWorkflowModel__c][0];
        ZZWorkflowModel wfmodel = ZZWorkflowModel.getWorkflow(wfmodelObj.Id);
        Test.startTest();
        List<ZZPhaseModel> phaseList = wfmodel.getPhaseList();
        System.assertEquals(1, LIMITS.getQueries());
        Test.stopTest();
        for (Integer i = 0; i < phaseList.size(); i++) {
            ZZPhaseModel phase = phaseList[i];
            System.assertEquals('Sample Phase ' + String.valueOf(i), phase.getName());
        }
        phaseList[0].destruct();
        System.assertEquals(5, phaseList.size());
    }

    @isTest
    public static void testSaveStructureNodesMultiple() {
        ZZWorkflowModel wfmodel = ZZWorkflowModel.getWorkflow('New Flow');
        wfmodel.getPhaseList();
        Map<String, Object> structure = new Map<String, Object> {
            'nodes' => new Map<String, Object>{
                'Node 1 Id' => new Map<String, Object>{
                    'label' => 'Node 1',
                    'id' => 'Node 1 Id'
                },
                'Node 2 Id' => new Map<String, Object>{
                    'label' => 'Node 2',
                    'id' => 'Node 2 Id'
                },
                'Node 3 Id' => new Map<String, Object>{
                    'label' => 'Node 3',
                    'id' => 'Node 3 Id'
                }
            },
            'edges' => new Map<String, Object>()
        };
        Test.startTest();
        wfmodel.saveStructure(structure);
        System.assertEquals(2, LIMITS.getDMLStatements());
        System.assertEquals(0, LIMITS.getQueries());
        List<ZZPhaseModel> phaseList = wfmodel.getPhaseList();
        System.assertEquals(3, phaseList.size());
        System.assertEquals('Node 1', phaseList[0].getName());
        System.assertEquals('Node 2', phaseList[1].getName());
        System.assertEquals('Node 3', phaseList[2].getName());

        structure = new Map<String, Object> {
            'nodes' => new Map<String, Object>{
                'Node 1 Id' => new Map<String, Object>{
                    'label' => 'Node 1',
                    'id' => 'Node 1 Id'
                },
                'Node 2 Id' => new Map<String, Object>{
                    'label' => 'Node 2',
                    'id' => 'Node 2 Id'
                },
                'Node 3 Id' => new Map<String, Object>{
                    'label' => 'Node 3',
                    'id' => 'Node 3 Id'
                },
                'Node 4 Id' => new Map<String, Object>{
                    'label' => 'Node 4',
                    'id' => 'Node 4 Id'
                }
            },
            'edges' => new Map<String, Object>()
        };
        wfmodel.saveStructure(structure);
        System.assertEquals(4, LIMITS.getDMLStatements());
        System.assertEquals(0, LIMITS.getQueries());
        Test.stopTest();
        phaseList = wfmodel.getPhaseList();
        System.assertEquals(4, phaseList.size());
        System.assertEquals('Node 1', phaseList[0].getName());
        System.assertEquals('Node 2', phaseList[1].getName());
        System.assertEquals('Node 3', phaseList[2].getName());
        System.assertEquals('Node 4', phaseList[3].getName());
    }

    @isTest
    public static void testSaveStructureNodesMultipleCleanCache() {
        ZZWorkflowModel wfmodel = ZZWorkflowModel.getWorkflow('New Flow');
        Map<String, Object> structure = new Map<String, Object> {
            'nodes' => new Map<String, Object>{
                'Node 1 Id' => new Map<String, Object>{
                    'label' => 'Node 1',
                    'id' => 'Node 1 Id'
                },
                'Node 2 Id' => new Map<String, Object>{
                    'label' => 'Node 2',
                    'id' => 'Node 2 Id'
                },
                'Node 3 Id' => new Map<String, Object>{
                    'label' => 'Node 3',
                    'id' => 'Node 3 Id'
                }
            },
            'edges' => new Map<String, Object>()
        };
        wfmodel.saveStructure(structure);
        List<ZZPhaseModel> phaseList = wfmodel.getPhaseList();
        System.assertEquals(3, phaseList.size());
        System.assertEquals('Node 1', phaseList[0].getName());
        System.assertEquals('Node 2', phaseList[1].getName());
        System.assertEquals('Node 3', phaseList[2].getName());

        ZZPhaseModel.cleanUpCache();

        structure = new Map<String, Object> {
            'nodes' => new Map<String, Object>{
                'Node 1 Id' => new Map<String, Object>{
                    'label' => 'Node 1',
                    'id' => 'Node 1 Id'
                },
                'Node 2 Id' => new Map<String, Object>{
                    'label' => 'Node 2',
                    'id' => 'Node 2 Id'
                },
                'Node 3 Id' => new Map<String, Object>{
                    'label' => 'Node 3',
                    'id' => 'Node 3 Id'
                },
                'Node 4 Id' => new Map<String, Object>{
                    'label' => 'Node 4',
                    'id' => 'Node 4 Id'
                }
            },
            'edges' => new Map<String, Object>()
        };
        wfmodel.saveStructure(structure);
        phaseList = wfmodel.getPhaseList();
        System.assertEquals(4, phaseList.size());
        System.assertEquals('Node 1', phaseList[0].getName());
        System.assertEquals('Node 2', phaseList[1].getName());
        System.assertEquals('Node 3', phaseList[2].getName());
        System.assertEquals('Node 4', phaseList[3].getName());
    }

    @isTest
    public static void testSaveStructureNodesChanged() {
        ZZWorkflowModel__c wfmodelObj = [SELECT Id, Name, Auto_Kick_Off__c
                                         FROM ZZWorkflowModel__c][0];
        ZZWorkflowModel wfmodel = ZZWorkflowModel.getWorkflow(wfmodelObj.Id);
        List<ZZPhaseModel> phaseList = wfmodel.getPhaseList();
        Set<ZZPhaseModel> oldPhaseSet = new Set<ZZPhaseModel>(phaseList);
        ZZPhaseModel p0 = phaseList[0];
        ZZPhaseModel p1 = phaseList[1];
        ZZPhaseModel p2 = phaseList[2];
        ZZPhaseModel p3 = phaseList[3];
        ZZPhaseModel p4 = phaseList[4];
        ZZPhaseModel p5 = phaseList[5];

        Map<String, Object> structure = ZZWorkflowController.getStructure(wfmodel.getId());
        List<Object> edges = (List<Object>) structure.get('edges');
        List<Map<String, Object>> newEdges = new List<Map<String, Object>>();
        for (Object edgeObj : edges) {
            Map<String, Object> edge = (Map<String, Object>) edgeObj;
            if (edge.get('from') == p2.getId() || edge.get('to') == p2.getId() ||
                    edge.get('from') == p4.getId() || edge.get('to') == p4.getId()) {}
            else if (edge.get('from') == p1.getId() && edge.get('to') == p3.getId()) {}
            else newEdges.add(edge);
        }
        List<Object> nodes = (List<Object>) structure.get('nodes');
        List<Map<String, Object>> newNodes = new List<Map<String, Object>>();
        for (Object nodeObj : nodes) {
            Map<String, Object> node = (Map<String, Object>) nodeObj;
            if (node.get('id') != p2.getId() && node.get('id') != p4.getId())
                newNodes.add(node);
        }

        Map<String, Object> p6map = new Map<String, Object> {
            'id' => 'TempId',
            'label' => 'Sample Phase 6'
        };
        newNodes.add(p6map);
        Map<String, Object> edge1to6 = new Map<String, Object> {
            'from' => p1.getId(),
            'to' => p6map.get('id'),
            'arrows' => 'to'
        };
        Map<String, Object> edge6to3 = new Map<String, Object> {
            'from' => p6map.get('id'),
            'to' => p3.getId(),
            'arrows' => 'to'
        };
        newEdges.add(edge1to6);
        newEdges.add(edge6to3);

        structure.put('nodes', newNodes);
        structure.put('edges', newEdges);

        Id p2id = p2.getId();
        Id p4id = p4.getId();

        // New Structure: 0 -> 1 -> 6 -> 4 -> 5
        Map<String, Object> visStructure = ZZParser.convertStructureToVis(structure);
        Test.startTest();
        System.assertEquals('Success!', wfmodel.saveStructure(visStructure));
        System.assertEquals(0, LIMITS.getQueries());
        System.assertEquals(3, LIMITS.getDMLStatements());
        Test.stopTest();
        // Check p2 and p4 no longer exist, but p6 does
        Set<ZZPhaseModel> phaseSet = new Set<ZZPhaseModel>(phaseList);
        System.assert(!phaseSet.contains(p2));
        System.assert(!phaseSet.contains(p4));
        ZZPhaseModel p6 = Null;
        for (ZZPhaseModel phase : phaseList) {
            if (!oldPhaseSet.contains(phase))
                p6 = phase;
        }
        System.assertNotEquals(Null, p6);
        System.assertNotEquals(p6map.get('id'), p6.getId());

        ZZPhaseModel__c p1Obj = [SELECT Id, Name, Children__c, Parents__c
                                 FROM ZZPhaseModel__c WHERE Id = :p1.getId()];
        ZZPhaseModel__c p3Obj = [SELECT Id, Name, Children__c, Parents__c
                                 FROM ZZPhaseModel__c WHERE Id = :p3.getId()];
        ZZPhaseModel__c p6Obj = [SELECT Id, Name, Children__c, Parents__c
                                 FROM ZZPhaseModel__c WHERE Id = :p6.getId()];
        System.assertEquals(0, [SELECT Id, Name FROM ZZPhaseModel__c WHERE Id = :p2id].size());
        System.assertEquals(0, [SELECT Id, Name FROM ZZPhaseModel__c WHERE Id = :p4id].size());
        System.assertNotEquals(Null, p6Obj);

        // Check edges are connected correctly 1 -> 6 -> 3
        System.assertEquals(1, p1.getChildren().size());
        System.assert(p6 === p1.getChildren()[0]);
        System.assertEquals(1, p6.getChildren().size());
        System.assert(p3 === p6.getChildren()[0]);

        System.assertEquals(1, p6.getParents().size());
        System.assert(p1 === p6.getParents()[0]);
        System.assertEquals(1, p3.getParents().size());
        System.assert(p6 === p3.getParents()[0]);

        System.assertEquals(p1.getId(), p6Obj.Parents__c);
        System.assertEquals(p6.getId(), p3Obj.Parents__c);
        System.assertEquals(p6.getId(), p1Obj.Children__c);
        System.assertEquals(p3.getId(), p6Obj.Children__c);
    }

    @isTest
    public static void testSaveStructureEdgesChanged() {
        ZZWorkflowModel__c wfmodelObj = [SELECT Id, Name, Auto_Kick_Off__c
                                         FROM ZZWorkflowModel__c][0];
        ZZWorkflowModel wfmodel = ZZWorkflowModel.getWorkflow(wfmodelObj.Id);
        List<ZZPhaseModel> phaseList = wfmodel.getPhaseList();
        ZZPhaseModel p0 = phaseList[0];
        ZZPhaseModel p1 = phaseList[1];
        ZZPhaseModel p2 = phaseList[2];
        ZZPhaseModel p3 = phaseList[3];
        ZZPhaseModel p4 = phaseList[4];
        ZZPhaseModel p5 = phaseList[5];

        Map<String, Object> structure = ZZWorkflowController.getStructure(wfmodel.getId());
        List<Object> edges = (List<Object>) structure.get('edges');
        List<Map<String, Object>> newEdges = new List<Map<String, Object>>();
        for (Object edgeObj : edges) {
            Map<String, Object> edge = (Map<String, Object>) edgeObj;
            if (edge.get('from') == p2.getId() || edge.get('to') == p2.getId() ||
                    edge.get('from') == p4.getId() || edge.get('to') == p4.getId()) {}
            else newEdges.add(edge);
        }

        // New structure: 0 -> 1 -> 3 -> 5
        //                2
        //                4
        structure.put('edges', newEdges);
        System.debug(newEdges);
        Test.startTest();
        System.assertEquals('Success!', wfmodel.saveStructure(ZZParser.convertStructureToVis(structure)));
        System.assertEquals(0, LIMITS.getQueries());
        System.assertEquals(1, LIMITS.getDMLStatements());
        Test.stopTest();
        ZZPhaseModel__c p2Obj = [SELECT Children__c, Parents__c FROM ZZPhaseModel__c WHERE Id = : p2.getId()];
        System.assertEquals(Null, p2Obj.Parents__c);
        System.assertEquals(Null, p2Obj.Children__c);
        ZZPhaseModel__c p4Obj = [SELECT Children__c, Parents__c FROM ZZPhaseModel__c WHERE Id = : p4.getId()];
        System.assertEquals(Null, p4Obj.Parents__c);
        System.assertEquals(Null, p4Obj.Children__c);
        System.assertEquals(0, p2.getChildren().size());
        System.assertEquals(0, p2.getParents().size());
        System.assertEquals(0, p4.getChildren().size());
        System.assertEquals(0, p4.getParents().size());

        System.assertEquals(0, p0.getParents().size());
        System.assertEquals(1, p1.getParents().size());
        System.assertEquals(0, p2.getParents().size());
        System.assertEquals(1, p3.getParents().size());
        System.assertEquals(0, p4.getParents().size());
        System.assertEquals(1, p5.getParents().size());

        System.assert(p0 === p1.getParents()[0]);
        System.assert(p1 === p3.getParents()[0]);
        System.assert(p3 === p5.getParents()[0]);

        System.assertEquals(1, p0.getChildren().size());
        System.assertEquals(1, p1.getChildren().size());
        System.assertEquals(0, p2.getChildren().size());
        System.assertEquals(1, p3.getChildren().size());
        System.assertEquals(0, p4.getChildren().size());
        System.assertEquals(0, p5.getChildren().size());

        System.assert(p1 === p0.getChildren()[0]);
        System.assert(p3 === p1.getChildren()[0]);
        System.assert(p5 === p3.getChildren()[0]);

        Set<ZZPhaseModel> startPhaseSet = new Set<ZZPhaseModel>(wfmodel.getStartPhaseList());
        System.assertEquals(3, startPhaseSet.size());
        System.assert(startPhaseSet.contains(p0));
        System.assert(startPhaseSet.contains(p2));
        System.assert(startPhaseSet.contains(p4));

        Map<String, Object> edge4to0 = new Map<String, Object> {
            'from' => p4.getId(),
            'to' => p0.getId(),
            'arrows' => 'to'
        };
        Map<String, Object> edge5to2 = new Map<String, Object> {
            'from' => p5.getId(),
            'to' => p2.getId(),
            'arrows' => 'to'
        };
        newEdges.add(edge4to0);
        newEdges.add(edge5to2);

        Integer numQueries = LIMITS.getQueries();
        Integer numDMLStatments = LIMITS.getDMLStatements();
        // New structure: 4 -> 0 -> 1 -> 3 -> 5 -> 2
        System.assertEquals('Success!', wfmodel.saveStructure(ZZParser.convertStructureToVis(structure)));
        System.assertEquals(numQueries, LIMITS.getQueries());
        System.assertEquals(numDMLStatments + 1, LIMITS.getDMLStatements());

        System.assert(p5 === p2.getParents()[0]);
        System.assert(p2 === p5.getChildren()[0]);
        System.assert(p4 === p0.getParents()[0]);
        System.assert(p0 === p4.getChildren()[0]);

        ZZPhaseModel__c p0Obj = [SELECT Children__c, Parents__c FROM ZZPhaseModel__c WHERE Id = : p0.getId()];
        p2Obj = [SELECT Children__c, Parents__c FROM ZZPhaseModel__c WHERE Id = : p2.getId()];
        p4Obj = [SELECT Children__c, Parents__c FROM ZZPhaseModel__c WHERE Id = : p4.getId()];
        ZZPhaseModel__c p5Obj = [SELECT Children__c, Parents__c FROM ZZPhaseModel__c WHERE Id = : p5.getId()];
        System.assertEquals(p4.getId(), p0Obj.Parents__c);
        System.assertEquals(p5.getId(), p2Obj.Parents__c);
        System.assertEquals(p0.getId(), p4Obj.Children__c);
        System.assertEquals(p2.getId(), p5Obj.Children__c);
    }

    @isTest
    public static void testSaveStructureNamesChanged() {
        ZZWorkflowModel__c wfmodelObj = [SELECT Id, Name, Auto_Kick_Off__c
                                         FROM ZZWorkflowModel__c][0];
        ZZWorkflowModel wfmodel = ZZWorkflowModel.getWorkflow(wfmodelObj.Id);
        ZZPhaseModel p0old = wfmodel.getPhase('Sample Phase 0');
        Map<String, Object> structure = ZZWorkflowController.getStructure(wfmodel.getId());

        List<Object> nodes = (List<Object>) structure.get('nodes');
        for (Object nodeObj : nodes) {
            Map<String, Object> nodeMap = (Map<String, Object>) nodeObj;
            nodeMap.put('label', 'New ' + nodeMap.get('label'));
        }
        Map<String, Object> visStructure = ZZParser.convertStructureToVis(structure);
        Test.startTest();
        wfmodel.saveStructure(visStructure);
        System.assertEquals(1, LIMITS.getDMLStatements());
        System.assertEquals(0, LIMITS.getQueries());
        Test.stopTest();
        List<ZZPhaseModel> phaseList = wfmodel.getPhaseList();
        for (ZZPhaseModel phase : phaseList)
            System.assert(phase.getName().startsWith('New Sample Phase '));

        List<ZZPhaseModel__c> phaseObjList = [SELECT Id, Name FROM ZZPhaseModel__c WHERE Workflow__c = :wfmodel.getId()];
        for (ZZPhaseModel__c phaseObj : phaseObjList)
            System.assert(phaseObj.Name.startsWith('New Sample Phase '));
        ZZPhaseModel p0new = wfmodel.getPhase('Sample Phase 0');
        System.assertNotEquals(p0old.getId(), p0new.getId());
    }


    @isTest
    public static void testNewWorkflowModelUsingId() {
        ZZWorkflowModel__c wfmodelObj = [SELECT Id, Name, Auto_Kick_Off__c FROM ZZWorkflowModel__c][0];
        Test.startTest();
        ZZWorkflowModel wfmodelCls = ZZWorkflowModel.getWorkflow(wfmodelObj.Id);
        System.assertEquals(1, LIMITS.getQueries());
        System.assertEquals(0, LIMITS.getDMLStatements());
        Test.stopTest();
        System.assertEquals(wfmodelObj.Id, wfmodelCls.getId());
        System.assertEquals('Sample Workflow', wfmodelCls.getName());
        System.assertEquals(1, wfmodelCls.getStartPhaseList().size());
        System.assertEquals(0, wfmodelCls.getStartPhaseList()[0].getParents().size());
        System.assertEquals(wfmodelObj.Auto_Kick_Off__c, wfmodelCls.isAutoKickOff());
    }

    @isTest
    public static void testBuildInstance() {
        ZZWorkflowModel__c wfmodelObj = [SELECT Id, Name, Auto_Kick_Off__c FROM ZZWorkflowModel__c][0];
        ZZWorkflowModel wfmodel = ZZWorkflowModel.getWorkflow(wfmodelObj.Id);
        wfmodel.getPhaseList();
        Test.startTest();
        ZZWorkflowInstance workflow = wfmodel.buildInstance('My First Workflow');
        System.assertEquals(3, LIMITS.getQueries());
        System.assertEquals(2, LIMITS.getDMLStatements());
        System.assertEquals('My First Workflow', workflow.getName());

        //Check phase 0
        ZZPhaseInstance startPhase = workflow.getStartPhaseList()[0];
        System.assertEquals('My First Workflow - Sample Phase 0', startPhase.getName());
        List<ZZPhaseInstance> phase0children = startPhase.getChildren();

        //Check phase 1
        ZZPhaseInstance phase1 = findPhaseWithName(phase0children,
                                 'My First Workflow - Sample Phase 1');
        System.assertNotEquals(Null, phase1);
        List<ZZPhaseInstance> phase1children = phase1.getChildren();

        //Check phase 2
        ZZPhaseInstance phase2 = findPhaseWithName(phase0children,
                                 'My First Workflow - Sample Phase 2');
        System.assertNotEquals(Null, phase2);
        List<ZZPhaseInstance> phase2children = phase2.getChildren();

        //Check phase 3
        ZZPhaseInstance phase3 = findPhaseWithName(phase1children,
                                 'My First Workflow - Sample Phase 3');
        System.assertNotEquals(Null, phase3);
        List<ZZPhaseInstance> phase3children = phase3.getChildren();

        //Check phase 4
        ZZPhaseInstance phase4 = findPhaseWithName(phase1children,
                                 'My First Workflow - Sample Phase 4');
        System.assertNotEquals(Null, phase4);
        phase4 = findPhaseWithName(phase2children,
                                   'My First Workflow - Sample Phase 4');
        System.assertNotEquals(Null, phase4);
        List<ZZPhaseInstance> phase4children = phase4.getChildren();

        //Check phase 5
        ZZPhaseInstance phase5 = findPhaseWithName(phase3children,
                                 'My First Workflow - Sample Phase 5');
        System.assertNotEquals(Null, phase5);
        phase5 = findPhaseWithName(phase4children,
                                   'My First Workflow - Sample Phase 5');
        System.assertNotEquals(Null, phase5);
        List<ZZPhaseInstance> phase5children = phase5.getChildren();
        System.assertEquals(0, phase5children.size());
        System.assertEquals(3, LIMITS.getQueries());
        System.assertEquals(2, LIMITS.getDMLStatements());
        Test.stopTest();
    }

    public static void checkStructure(Map<String, Object> structure) {
        ZZWorkflowModel__c wfmodelObj = [SELECT Id, Name, Auto_Kick_Off__c
                                         FROM ZZWorkflowModel__c][0];
        ZZWorkflowModel wfmodel = ZZWorkflowModel.getWorkflow(wfmodelObj.Id);
        List<ZZPhaseModel> plist = wfmodel.getPhaseList();

        List<Object> nodes = (List<Object>)structure.get('nodes');
        List<Object> edges = (List<Object>)structure.get('edges');

        for (Integer i = 0; i < nodes.size(); i++) {
            Map<String, Object> node = (Map<String, Object>)nodes[i];
            System.assertEquals('Sample Phase ' + String.valueOf(i), node.get('label'));
            System.assertEquals(plist[i].getId(), node.get('id'));
        }

        List<Map<String, Object>> expectedEdges = new List<Map<String, Object>> {
            new Map<String, Object>{'from' => plist[0].getId(), 'to' => plist[2].getId()},
            new Map<String, Object>{'from' => plist[0].getId(), 'to' => plist[1].getId()},
            new Map<String, Object>{'from' => plist[1].getId(), 'to' => plist[4].getId()},
            new Map<String, Object>{'from' => plist[1].getId(), 'to' => plist[3].getId()},
            new Map<String, Object>{'from' => plist[2].getId(), 'to' => plist[4].getId()},
            new Map<String, Object>{'from' => plist[3].getId(), 'to' => plist[5].getId()},
            new Map<String, Object>{'from' => plist[4].getId(), 'to' => plist[5].getId()}
        };

        for (Integer i = 0; i < edges.size(); i++) {
            Map<String, Object> edge = (Map<String, Object>)edges[i];
            Map<String, Object> expectedEdge = (Map<String, Object>)expectedEdges[i];
            System.assertEquals(expectedEdge.get('from'), edge.get('from'));
            System.assertEquals(expectedEdge.get('to'), edge.get('to'));
        }
    }

    public static ZZPhaseInstance findPhaseWithName(List<ZZPhaseInstance> phaseList, String name) {
        for (ZZPhaseInstance phase : phaseList)
            if (phase.getName() == name) return phase;
        return Null;
    }
}