public with sharing class Assign_Task {
    
    // Trae las custom task pendientes para un resource-project y las retorna.
    public static List<Custom_Task__c> getCustomTask(Id resource_project_Id){
        List<Custom_Task__c> getTask=[Select Id,Name,Status__c,Project_Name__c,Resource_Project__c,Required_Hours__c,Registered_Hours__c
                                      FROM Custom_Task__c 
                                      WHERE Status__c!='Completed' 
                                      AND Resource_Project__c=:resource_project_Id ];
        return getTask;
        
    }
    public static Integer countPendingTask(Id resource_project_Id){
             
        return getCustomTask(resource_project_Id).size();
    }
    // actualiza el campo Registered_Hours__c en la base de datos.
    public static void setRegisteredHours(Id custom_task,Integer hours_Registered){
        List<Custom_Task__c> task=[SELECT id,Registered_Hours__c 
                                   FROM Custom_Task__c 
                                   WHERE id=:custom_task];
        
        for(Custom_Task__c item:task){
            if(item.Registered_Hours__c==NULL){
              item.Registered_Hours__c=hours_Registered;
            }
            else{
                item.Registered_Hours__c+=hours_Registered;
            }
          }
        update task;
    }
    // cambia el status de la custom task a 'In Progress'ó'completed'
    // y lo actualiza en la base de datos.
    public static void change_Status(Id custom_task,String status){
     List<Custom_Task__c> task=[SELECT id, Status__c 
                                FROM Custom_Task__c 
                                WHERE id=:custom_task];
        for(Custom_Task__c item:task){
            if(status=='Completed'){
             item.Status__c=status;
            }
            else if(status=='In Progress'){
              item.Status__c=status;  
            }
        }
        update task;
    }
    
    //Query de la tarea:
    /*Recurso asignado
Proyecto
Resumen de la tarea a realizar
Descripción
Fecha inicio/Fin
Horas estimadas
*/
    
}