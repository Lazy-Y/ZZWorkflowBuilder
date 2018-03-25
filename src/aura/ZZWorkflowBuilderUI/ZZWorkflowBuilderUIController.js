({
    init: function(component, event, helper){
        helper.initComponent(component);
        helper.initNetwork(component);
        helper.loadWFModelMap(component);
    },

    executePhaseAction: function(component, event, helper){
        var action = component.get('c.executeAction');
        action.setParams({
            wfinstanceId: helper.getWFInstanceId(component),
            pmodelId: helper.getPhaseId(component),
            action: event.getParam('action')
        });
        action.setCallback(this, function(result) {
            if (result.getReturnValue() == 'Success!') {
                helper.setWFInstance(component);
            }
        });
        $A.enqueueAction(action);
    },

    kickOffWorkflow: function(component, event, helper){
        var action = component.get('c.kickOff');
        action.setParams({
            wfinstanceId: helper.getWFInstanceId(component)
        });
        action.setCallback(this, function(result){
            if (result.getReturnValue() == 'Success!') {
                helper.setWFInstance(component);
            }
        });
        $A.enqueueAction(action);
    },

    setParams: function(component, event, helper){
        var wfinstId = helper.getWFInstanceId(component);
        if (wfinstId){
            var wfparams = component.get('{!v.wfparams}');
            var action = component.get('c.saveParams');
            action.setParams({
                wfinstanceId: wfinstId,
                params: wfparams
            });
            action.setCallback(this, function(result) {
                var result = result.getReturnValue();
                console.log(result);
            })
            $A.enqueueAction(action);
        }
    },

    setPhaseParams: function(component, event, helper){
        var wfinstanceId = helper.getWFInstanceId(component);
        var phasePane = component.find('phasePane');
        var pmodelId = phasePane.get('v.node.id');
        var params = phasePane.get('v.node.Parameters__c');

        var action = component.get('c.savePhaseParams');
        action.setParams({
            wfinstanceId: wfinstanceId,
            pmodelId: pmodelId,
            params: params
        });
        action.setCallback(this, function(result) {
            var result = result.getReturnValue();
            console.log(result);
        })
        $A.enqueueAction(action);
    },

    editPhase: function(component, event, helper){
        var phasePane = component.find('phasePane');
        var node = phasePane.get('v.node');

        var pmodelCreator = component.find('pmodelCreator');
        function savePhaseModel(nodeData) {
            phasePane.setup(nodeData);
            var network = component.get('v.network');
            var nodes = network.body.data.nodes;
            nodes.update(nodeData);
        }
        pmodelCreator.set('v.nodeData', node);
        pmodelCreator.set('v.callback', savePhaseModel);
        pmodelCreator.show();
    },

    clonePhase: function(component, event, helper){
        function generateId() {
            var S4 = function() {
               return (((1+Math.random())*0x10000)|0).toString(16).substring(1);
            };
            return (S4()+S4()+"-"+S4()+"-"+S4()+"-"+S4()+"-"+S4()+S4()+S4());
        }
        var phasePane = component.find('phasePane');
        var node = phasePane.get('v.node');
        var nodeCopy = Object.assign({}, node);
        nodeCopy.label += ' Copy';
        nodeCopy.id = generateId();
        var network = component.get('v.network');
        var nodes = network.body.data.nodes;
        nodes.add(nodeCopy);
    },

    handlePicklistValueChange: function(component, event, helper){
        var cmpId = event.getSource().getLocalId()
        switch (cmpId){
            case 'wfmodelPicklist':
                helper.setWFModel(component);
                break;
            case 'wfinstancePicklist':
                helper.setWFInstance(component);
                break;
            case 'wfmodelCreator':
                helper.loadWFModelMap(component);
                break;
            case 'wfinstanceCreator':
                helper.handleWFInstanceCreated(component);
                break;
        }
    },

    handleToast: function(component, event, helper){
        $A.createComponent('c:ZZToast', {
            type: event.getParam('type'),
            message: event.getParam('message')
        }, function(cmp, status, errorMessage){
            helper.addToBody(component, cmp);
        });
        var toaster = component.find('toaster');
        toaster.set('v.type', event.getParam('type'));
        toaster.set('v.message', event.getParam('message'));
        toaster.show();
    },

    createWFModel: function(component, event, helper){
        var wfmodelCreator = component.find('wfmodelCreator');
        wfmodelCreator.show();
    },

    saveWFModel: function(component, event, helper){
        var network = component.get('v.network');
        var nodes = network.body.data.nodes._data;
        
        for (var nodeId in nodes){
            var positions = network.getPositions(nodeId);
            nodes[nodeId].x = positions[nodeId].x;
            nodes[nodeId].y = positions[nodeId].y;
        }

        var structure = {
            nodes: nodes,
            edges: network.body.data.edges._data,
            Parameters__c: component.get('v.wfparams')
        };
        console.log(JSON.stringify(nodes));
        var action = component.get('c.saveStructure');
        action.setParams({
            workflowId: helper.getWFModelId(component),
            structure: JSON.stringify(structure)
        });
        action.setCallback(this, function(result) {
            var result = result.getReturnValue();
            if (result == 'Success!') {
                helper.fireToast(component, 'success', 'Saving structure success!.');
            }
            else {
                helper.fireToast(component, 'error', 'Saving structure error. ' + result);
                // Show error message
            }
            helper.loadStructure(component, helper.getWFModelId(component));
        });
        $A.enqueueAction(action);
    },

    buildWFInstance: function(component, event, helper){
        var wfmodelPicklist = component.find('wfmodelPicklist');
        var wfmodelName = wfmodelPicklist.get('v.value');
        var wfmodelId = helper.getWFModelId(component);

        var wfinstanceCreator = component.find('wfinstanceCreator');
        var wfinstanceRecord = wfinstanceCreator.get('v.wfinstanceRecord');
        wfinstanceRecord.Parameters__c = component.get('v.wfparams');
        wfinstanceCreator.set('v.wfinstanceRecord', wfinstanceRecord);
        wfinstanceCreator.set('v.wfmodelName', wfmodelName);
        wfinstanceCreator.set('v.wfmodelId', wfmodelId);
        wfinstanceCreator.show();
    }
})