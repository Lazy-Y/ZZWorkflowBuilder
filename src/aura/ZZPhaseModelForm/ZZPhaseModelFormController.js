({
	show : function(component, event, helper) {
		component.set('v.display', 'block');
	},

	close : function(component, event, helper) {
		component.set('v.display', 'none');
	},

	create : function(component, event, helper) {
		var callback = component.get('v.callback');
		var nodeData = component.get('v.nodeData');
		component.set('v.display', 'none');
		var actions = [];
		if (nodeData.Actions__c != null && nodeData.Actions__c != '')
			actions = nodeData.Actions__c.split('\n');
		var actionsList = [];
		actions.forEach(function(action) {
			var actionDetail = action.split(',');
			var actionMap = {};
			actionMap.name = actionDetail[0];
			actionMap.next = actionDetail[1];
			actionMap.hook = actionDetail[2];
			actionsList.push(actionMap);
		})
		nodeData.actions = actionsList;
		nodeData.statuses = nodeData.Statuses__c.split(',');
		callback(nodeData);
	}
})