({
    init: function(component, event, helper) {
        component.find('wfinstanceCreator').getNewRecord(
            'ZZWorkflowInstance__c',
            null,
            false,
            $A.getCallback(function() {
                var wfinstance = component.get('v.wfinstance');
                var error = component.get('v.error');
                if (error || (wfinstance === null)) {
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
            var wfmodelId = component.get('v.wfmodelId');
            var wfinstanceRecord = component.get('v.wfinstanceRecord');
            wfinstanceRecord.Model__c = wfmodelId;
            component.find('wfinstanceCreator').saveRecord(function(saveResult) {
                if (saveResult.state === 'SUCCESS' || saveResult.STATE === 'DRAFT') {
                    helper.fireToast(component, 'success', 'Create new Workflow instance successfully!');
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