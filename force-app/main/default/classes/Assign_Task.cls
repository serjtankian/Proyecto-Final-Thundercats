public with sharing class Assign_Task {
    
    
    //Trae las custom task pendientes para un resource-project y las retorna.
    public static Map<String,List<Custom_Task__c>> getCustomTask(){
        
        //obtener el id del usuario logueado.
        Id userId = UserInfo.getuserId();
        
        // traer los resources project cuya lookup sera UserId
        List<Resource_Project__c>resource_project_linked=[SELECT Id, Resource__c 
                                                          FROM Resource_Project__c 
                                                          WHERE Resource__c=:userId];
        
        // System.debug(resource_project_linked);
        // iterar la lista y poner los id en un set.
        Set<Id> resources_project_id=new Set<Id>();
        for(Resource_Project__c item:resource_project_linked){
            resources_project_id.add(item.id);
        }
        List<Custom_Task__c> getTask=[Select Id,Name,Status__c,Project_Name__c,Resource_Project__c,Required_Hours__c,Registered_Hours__c
                                      FROM Custom_Task__c 
                                      WHERE Status__c!='Completed' 
                                      AND Resource_Project__c IN:resources_project_id  order by Status__c DESC];
        
        //
        Map<String,List<Custom_Task__c>> taskByProject= new Map<String,List<Custom_Task__c>>(); 
        
        for(Custom_Task__c task:getTask){
            if(!taskByProject.containsKey(task.Project_Name__c)){
                taskByProject.put(task.Project_Name__c,new List<Custom_Task__c>());
                taskByProject.get(task.Project_Name__c).add(task);
            }
            else{
                taskByProject.get(task.Project_Name__c).add(task);
            }
        }
        
        return taskByProject;
        
    }
    //cuenta la cantidad de tareas pendientes por resource-project
    public static Map<String,Integer> countPendingTask(){
        Map<String,Integer> pendigTaskByProject= new Map<String,Integer>();
        
        Map<String,List<Custom_Task__c>> customTaskByProject=getCustomTask();
        
        List<Custom_Task__c> customTaskList= new List<Custom_Task__c>();
        for(List<Custom_Task__c> taskList : customTaskByProject.values()){
            for(Custom_Task__c task :taskList ){
                customTaskList.add(task);
            }
        }
        for(Custom_Task__c task : customTaskList){
            
           if(!pendigTaskByProject.containsKey(task.Project_Name__c)){
         pendigTaskByProject.put(task.Project_Name__c,customTaskByProject.get(task.Project_Name__c).size());
           }
        }
       return pendigTaskByProject;
    }
    // devuelve el nombre del projecto al que pertenece la tarea.
    //public static String getProjectName( ){
    // return getCustomTask()[0].Project_Name__c;
    // }
    // actualiza el campo Registered_Hours__c en la base de datos.
    public static void setRegisteredHours(Id custom_task,Integer hours_Registered){
        Custom_Task__c task=[SELECT id,Registered_Hours__c 
                             FROM Custom_Task__c 
                             WHERE id=:custom_task];
  
        
        if(task.Registered_Hours__c==NULL){
            task.Registered_Hours__c=hours_Registered;
        }
        else{
            task.Registered_Hours__c+=hours_Registered;
        }
        
        update task;
      
    }
    // cambia el status de la custom task a 'In Progress'ó'completed'
    // y lo actualiza en la base de datos.
    public static void change_Status(Id custom_task,String status){
        Custom_Task__c task=[SELECT id, Status__c 
                             FROM Custom_Task__c 
                             WHERE id=:custom_task];
        
        if(status=='Completed'||status=='In Progress' ){
            task.Status__c=status;
        }
        
        update task;
    }
    
}