({
	validate : function(component) {
		var valid = true;
		var nameCmp = component.find('name');
		nameCmp.showHelpMessageIfInvalid();
		valid = nameCmp.get('v.validity').valid;

		if (valid){
			var wfmodel = component.get('v.wfmodel');
			if ($A.util.isEmpty(wfmodel)){
				valid = false;
			}
			return valid;
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

	fireNewValue: function(component){
		component.getEvent('setValue').fire();
	}
})