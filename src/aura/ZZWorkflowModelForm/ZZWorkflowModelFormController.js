({
    init: function(component, event, helper) {
        component.find('wfmodelCreator').getNewRecord(
            'ZZWorkflowModel__c',
            null,
            false,
            $A.getCallback(function() {
                var wfmodel = component.get('v.wfmodel');
                var error = component.get('v.error');
                if (error || (wfmodel === null)) {
                    console.log('Error init ' + error);
                } else {

                }
            }));
    },
    show: function(component, event, helper) {
    	component.set('v.display', 'block');
    },
    create: function(component, event, helper) {
        if (helper.validate(component)) {
            component.find('wfmodelCreator').saveRecord(function(saveResult) {
                if (saveResult.state === 'SUCCESS' || saveResult.STATE === 'DRAFT') {
                    helper.fireToast(component, 'success', 'Create new Workflow Model successfully!');
                    helper.fireNewValue(component);
                } else if (saveResult.state === "INCOMPLETE") {
                    // handle the incomplete state
                    helper.fireToast(component, 'info', "User is offline, device doesn't support drafts.");
                } else if (saveResult.state === "ERROR") {
                    // handle the error state
                    helper.fireToast(component, 'error', 'Problem saving contact, error: ' +
                        JSON.stringify(saveResult.error));
                } else {
                    helper.fireToast(component, 'info', 'Unknown problem, state: ' + saveResult.state +
                        ', error: ' + JSON.stringify(saveResult.error))
                }
            })
            component.set('v.display', 'none');
        }
    },
    close: function(component, event, helper) {
        component.set('v.display', 'none');
    }
})