({
	show : function(component, event, helper) {	
		var type = component.get('v.type');
		var sleepTime = 1000;
		if (type.toLowerCase() != 'success'){
			sleepTime = 3000;
		}
		component.set('v.display', 'block');
		setTimeout(function() {
			component.set('v.display', 'none')
		}, sleepTime);
	}
})