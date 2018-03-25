public class ZZParser {
    private static List<String> errMsgList = new List<String>();

    /**
     * Record error message
     * @param errMsg
     */
    public static void addErrMsg(String errMsg){
        System.debug(errMsg);
        errMsgList.add(errMsg);
    }

    /**
     * Get copy of err msg list
     * @return 
     */
    public static List<String> getErrMsgList(){
        return new List<String>(errMsgList);
    }

    /**
     * Whether list contains an object
     * @param  l   List
     * @param  obj Object
     * @return
     */
    public static Boolean listContains(List<Object> l, Object obj){
        for (Object item : l)
            if (obj === item) return True;
        return False;
    }
    /**
     * Whether list contains an object which has the same value
     * @param  l   List
     * @param  obj Object
     * @return
     */
    public static Boolean listContainsCopy(List<Object> l, Object obj){
        for (Object item : l)
            if (obj == item) return True;
        return False;
    }
    
    /**
     * Construct List of Phase Instance from a series of Phase Instance Id seperated by ','
     * @param  phaseIds a series of Phase Instance Id seperated by ','
     * @return          List of Phase Instance
     */
    public static List<ZZPhaseInstance> parsePInstanceList(String phaseIds){
        List<ZZPhaseInstance> phaseList = new List<ZZPhaseInstance>();
        if (phaseIds != Null && phaseIds != ''){
            List<String> phaseIdList = phaseIds.split(',');
            for (String phaseId : phaseIdList){
                phaseList.add(ZZPhaseInstance.getPhase(phaseId));
            }
        }
        return phaseList;
    }

    /**
     * Convert List nodes, edges to map, node id => node, edge id => edge
     * @param  structure List structure
     * @return
     */
    public static Map<String, Object> convertStructureToVis(Map<String, Object> structure){
        Map<String, Object> newStructure = new Map<String, Object>();
        List<Object> nodes = (List<Object>)structure.get('nodes');
        List<Object> edges = (List<Object>)structure.get('edges');
        Map<String, Object> newNodes = new Map<String, Object>();
        Map<String, Object> newEdges = new Map<String, Object>();

        for (Object nodeMapObj : nodes){
            Map<String, Object> nodeMap = (Map<String, Object>) nodeMapObj;
            newNodes.put((String)nodeMap.get('id'), nodeMap);
        }
        for(Integer i = 0; i < edges.size(); i++) {
            Map<String, Object> edgeMap = (Map<String, Object>) edges[i];
            String randId = String.valueOf(i);
            edgeMap.put('id', randId);
            newEdges.put(randId, edgeMap);
        }

        newStructure.put('nodes', newNodes);
        newStructure.put('edges', newEdges);
        return newStructure;
    }


    /**
     * Check whether the string is a valid Id
     * @param  Idparam
     * @return
     */
    public static Boolean isValidId(String Idparam) {
        if (Idparam == Null) return False;
        String id = String.escapeSingleQuotes(Idparam);
        if((id.length() == 15 || id.length() == 18) && Pattern.matches('^[a-zA-Z0-9]*$', id)) {
            return True;
        }
        return False;
    }
}