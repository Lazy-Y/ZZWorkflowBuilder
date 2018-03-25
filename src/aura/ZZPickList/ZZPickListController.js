({
    init: function(component, event, helper){
        component.set('v.filterList', component.get('v.valueList'));
    },

    setValueList: function(component, event, helper){
        var params = event.getParam('arguments');
        var valueList = params.valueList;
        component.set('v.valueList', valueList);
        component.filter();
    },

    show: function(component, event, helper) {
        component.set('v.state', 'is-open');
    },

    hide: function(component, event, helper) {
        component.set('v.state', 'combobox-picklist');
    },

    onblur: function(component, event, helper) {
        setTimeout(function(){
            component.set('v.state', 'combobox-picklist');
        }, 50)
    },

    select: function(component, event, helper) {
        var value = event.target.title;
        if (value == 'None') value = '';
        component.set('v.value', value);
        var event = component.getEvent("setValue");
        event.fire();
        component.hide();
    },

    filter: function(component, event, helper){
        var input = component.find('input').getElement();
        var value = input.value.toLowerCase();
        var valueList = component.get('v.valueList');
        if (value == '' || value == null){
            component.set('v.filterList', valueList);
        }
        else{
            var filterList = [];
            valueList.forEach(function(item){
                var tempItem = item.lowercase
                if (item.toLowerCase().startsWith(value)){
                    filterList.push(item);
                }
            });
            component.set('v.filterList', filterList);
        }
    }
})