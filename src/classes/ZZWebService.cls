@RestResource(urlMapping='/ZZWebService/*')
global with sharing class ZZWebService {
    @HttpGet
    global static List<String> getInfo(){
        List<String> result = new List<String>();
        result.add('SUCCESS');
        result.add('\n');
        result.add('/services/apexrest/ZZWebService/ExecuteAction');
        result.add('Method Type: POST');
        result.add('Params:');
        result.add('piid, the id of the phase instance');
        result.add('action, the name of the action');
        result.add('\n');
        result.add('/services/apexrest/ZZWebService');
        result.add('Method Type: POST');
        result.add('Params:');
        result.add('model_name, name of the workflow model');
        result.add('instance_name, the name the new workflow instance');
        result.add('action, either build or kick off, when the action is kick off while the workflow does not exist. Automatically create one.');
        result.add('workflowParams, the parameters for the workflow');
        result.add('defaults, can be null, List<Map<String, String>> list of the default status.');
        result.add('e.g.: [{"name": <Name of the phase model>, "status": <The default status>, "params": <Non Default Parameters>}]');
        result.add('\n');
        return result;
    }

    @HttpPost
    global static String manageWorkflow(String model_name, String instance_name, String action, String workflowParams, List<Map<String, String>> defaults){
        if (action == 'build' || action == 'kick off'){
            ZZWorkflowModel wfmodel = ZZWorkflowModel.getWorkflow(model_name);
            ZZWorkflowInstance wfinstance = wfmodel.buildInstance(instance_name);
            if (workflowParams != null){
                wfinstance.setParams(workflowParams);
            }
            if (defaults != null){
                wfinstance.updateDefaults(defaults);
            }
            if (action == 'kick off'){
                wfinstance.kickOff();
            }
            return 'SUCCESS';
        }
        else{
            return 'Unknown Action';
        }
    }
}