({
    initComponent: function(component){

    },

	addToBody : function(component, cmp) {
        var body = component.get('v.body');
        body.push(cmp);
        component.set('v.body', body);
	},

	addCmp: function(component, cmp, status, errorMessage){
		if (status === "SUCCESS") {
			this.addToBody(component, cmp);
        }
        else if (status === "INCOMPLETE") {
        	this.fireToast(component, 'info', 'No response from server or client is offline.');
            // Show offline error
        }
        else if (status === "ERROR") {
        	this.fireToast(component, 'error', 'Error: ' + errorMessage);
            // Show error message
        }
	},

	fireToast: function(component, type, message){
        var event = component.getEvent("toast");
        event.setParams({
            type: type,
            message: message
        });
        event.fire();
	},

    loadWFModelMap: function(component){
        var action = component.get('c.getWorkflowModelMap');
        action.setCallback(this, function(result){
            var wfmodels = result.getReturnValue();
            component.set('v.wfmodelMap', wfmodels);
            var wfmodelList = Object.keys(wfmodels);
            var wfmodelPicklist = component.find('wfmodelPicklist');
            wfmodelPicklist.setValueList(wfmodelList);
        });
        $A.enqueueAction(action);
    },

    loadWFInstanceMap: function(component){
        var action = component.get('c.getWorkflowInstanceMap');
        action.setParams({
            wfmodelId: this.getWFModelId(component)
        });
        action.setCallback(this, function(result){
            var wfinstances = result.getReturnValue();
            component.set('v.wfinstanceMap', wfinstances);
            var wfinstanceList = Object.keys(wfinstances);
            var wfinstancePicklist = component.find('wfinstancePicklist');
            wfinstancePicklist.setValueList(wfinstanceList);
        });
        $A.enqueueAction(action);
    },

    initNetwork: function(component){
        var container = document.getElementById('graph');

        var data = {
            nodes: [],
            edges: []
        };

        var options = {
            physics: false,
            manipulation: {
                enabled: false,
                addNode: function(data, callback) {
                    var pmodelCreator = component.find('pmodelCreator');
                    data.Actions__c = 'Kick Off,In Progress,\nComplete,Completed,\nDefer,Deferred\nRerun,New,';
                    data.Statuses__c = 'New,In Progress,Completed,Deferred';
                    pmodelCreator.set('v.nodeData', data);
                    pmodelCreator.set('v.callback', callback);
                    pmodelCreator.show();
                },
                addEdge: function(data, callback) {
                    data.arrows = 'to';
                    if (data.from != data.to) {
                        callback(data);
                    }
                },
                editEdge: false
            }
        };

        var helper = this;
        var network = new vis.Network(container, data, options);

        network.on("selectNode", function (params) {
            var phasePane = component.find('phasePane');
            phasePane.show();

            var nodes = network.body.data.nodes;
            var node = nodes.get(params.nodes[0]);
            phasePane.setup(node);
        });

        component.set('v.network', network);
    },

    setWFModel: function(component){
        var wfmodelPicklist = component.find('wfmodelPicklist');
        var phasePane = component.find('phasePane');
        phasePane.hide();
        var wfmodelName = wfmodelPicklist.get('v.value');
        var display = wfmodelName != '' && wfmodelName != null;
        var wfinstancePicklist = component.find('wfinstancePicklist');
        var buildBtn = component.find('wfBuildBtn');
        var kickOffBtn = component.find('wfKickOffBtn');
        var saveBtn = component.find('wfSaveBtn');
        var paramDiv = component.find('parameters').getElement();

        wfinstancePicklist.set('v.value', '');
        if (display){
            // Show and setup wfinstance picklist
            wfinstancePicklist.set('v.display', 'block');
            this.loadWFInstanceMap(component);
            this.loadStructure(component, this.getWFModelId(component));
            paramDiv.style.display = 'block';
        }
        else{
            wfinstancePicklist.set('v.display', 'none');
            paramDiv.style.display = 'none';
            this.clearNetworkData(component);
        }
        this.setNetworkEditable(component, display);
        buildBtn.set('v.disabled', !display);
        saveBtn.set('v.disabled', !display);
        kickOffBtn.set('v.disabled', true);
    },

    setWFInstance: function(component){
        var wfinstancePicklist = component.find('wfinstancePicklist');
        var wfinstanceName = wfinstancePicklist.get('v.value');
        var display = wfinstanceName != '' && wfinstanceName != null;
        var kickOffBtn = component.find('wfKickOffBtn');
        var phasePane = component.find('phasePane');
        var saveBtn = component.find('wfSaveBtn');
        phasePane.hide();
        kickOffBtn.set('v.disabled', !display);

        if (display){
            this.loadStructure(component, this.getWFInstanceId(component));
        }
        else{
            this.setWFModel(component);
        }
        this.setNetworkEditable(component, !display);
        saveBtn.set('v.disabled', display);
    },

    loadStructure: function(component, workflowId){
        var action = component.get('c.getStructure');
        action.setParams({
            workflowId: workflowId
        });
        action.setCallback(this, function(result){
            var structure = result.getReturnValue();
            component.set('v.wfparams', structure.Parameters__c);
            if (workflowId == this.getWFModelId(component))
                this.setNetworkData(component, structure);
            else
                this.updateNetworkData(component, structure);
        });
        $A.enqueueAction(action);      
    },

    setNetworkData: function(component, structure){
        var network = component.get('v.network');
        network.setData({ nodes: structure.nodes, edges: structure.edges });
    },

    updateNetworkData: function(component, structure){
        var network = component.get('v.network');
        this.colorNode(structure.nodes);
        var nodes = network.body.data.nodes;
        Object.keys(structure.nodes).forEach(function(key){
            nodes.update(structure.nodes[key]);
        });
    },

    colorNode: function(nodes){
        function hashCode(str) { // java String#hashCode
            var hash = 0;
            for (var i = 0; i < str.length; i++) {
               hash = str.charCodeAt(i) + ((hash << 5) - hash);
            }
            return hash;
        } 

        function intToRGB(i){
            var c = ((i & 0x00FFFFFF) | 0x00404040);
            c = c.toString(16).toUpperCase();
            return "#" + "00000".substring(0, 6 - c.length) + c;
        }

        if (nodes){
            nodes.forEach(function(node) {
                if ('Status__c' in node){
                    var hash = hashCode(node.Status__c);
                    node.color = intToRGB(hash);
                }
            })
        }
    },

    setNetworkEditable: function(component, editable){
        var network = component.get('v.network');
        network.setOptions({'manipulation': {'enabled': editable}});
    },

    clearNetworkData: function(component){
        var network = component.get('v.network');
        network.setData({ nodes: [], edges: []});
    }, 

    getWFModelId: function(component){
        var wfmodelPicklist = component.find('wfmodelPicklist');
        var wfmodelName = wfmodelPicklist.get('v.value');
        var wfmodelMap = component.get('v.wfmodelMap');
        if (wfmodelMap.hasOwnProperty(wfmodelName)){
            return wfmodelMap[wfmodelName];
        }
        else{
            return null;
        }
    },

    getWFInstanceId: function(component){
        var wfinstancePicklist = component.find('wfinstancePicklist');
        var wfinstanceName = wfinstancePicklist.get('v.value');
        var wfinstanceMap = component.get('v.wfinstanceMap');
        if (wfinstanceMap.hasOwnProperty(wfinstanceName)){
            return wfinstanceMap[wfinstanceName];
        }
        else {
            return null;
        }
    },

    getPhaseId: function(component){
        var phasePane = component.find('phasePane');
        var node = phasePane.get('v.node');
        return node.id;
    },

    handleWFInstanceCreated: function(component){
        var wfinstanceCreator = component.find('wfinstanceCreator');
        var wfinstanceRecord = wfinstanceCreator.get('v.wfinstanceRecord');
        var wfinstancePicklist = component.find('wfinstancePicklist');
        
        var wfinstanceMap = component.get('v.wfinstanceMap');
        wfinstanceMap[wfinstanceRecord.Name] = wfinstanceRecord.Id;
        
        var wfinstanceList = Object.keys(wfinstanceMap);
        var wfinstancePicklist = component.find('wfinstancePicklist');
        wfinstancePicklist.setValueList(wfinstanceList);

        wfinstancePicklist.set('v.value', wfinstanceRecord.Name);
        this.setWFInstance(component);
    }
})