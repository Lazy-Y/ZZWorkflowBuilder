({
    show: function(component, event, helper) {
        var body = component.find('body').getElement();
        body.style.display = 'block';
    },

    hide: function(component, event, helper) {
        var body = component.find('body').getElement();
        body.style.display = 'none';
    },

    setup: function(component, event, helper) {
        var params = event.getParam('arguments');
        var node = params.node;

        var model = component.find('model').getElement();
        var instance = component.find('instance').getElement();
        var editBtn = component.find('editBtn');
        var cloneBtn = component.find('cloneBtn');
        var default_status = component.find('default_status').getElement();
        var controller = component.find('controller').getElement();
        var paramsArea = component.find('params')

        component.set('v.node', node);
        editBtn.set('v.disabled', 'Status__c' in node);
        cloneBtn.set('v.disabled', 'Status__c' in node);
        if ('Status__c' in node) {
            model.style.display = 'none';
            instance.style.display = 'block';
            default_status.style.display = 'none';
            controller.style.display = 'none';
            paramsArea.set('v.readonly', false);
        } else {
            model.style.display = 'block';
            instance.style.display = 'none';
            default_status.style.display = 'block';
            controller.style.display = 'block';
            paramsArea.set('v.readonly', true);
        }
    },

    setParams: function(component, event, helper){
        var event = component.getEvent("setPhaseParams");
        event.fire();
    },

    clonePhase: function(component, event, helper){
        var event = component.getEvent("clonePhase");
        event.fire();
    },

    editPhase: function(component, event, helper){
        var event = component.getEvent("editPhase");
        event.fire();
    },

    executeAction: function(component, event, helper) {
        var node = component.get('v.node');
        if ('Status__c' in node) {
            var actionName = event.currentTarget.dataset.action;
            var event = component.getEvent("executeAction");
            event.setParams({
                action: actionName
            });
            event.fire();
        }
    }
})