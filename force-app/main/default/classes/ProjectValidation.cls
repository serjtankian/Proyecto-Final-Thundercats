public class ProjectValidation {
    
    public static void getValidation(List<Project__c> project_updated){
        // Se realiza una query que traiga los Resources_project asociados a ese Id de Project.
        List<Resource_Project__c> asignatedResources=[SELECT Id ,Project__c ,Resource__c
                                                      From Resource_Project__c 
                                                      where Project__c IN : project_updated];
        
        
    
        // pedir solo las tareas con status in progress
        List<Custom_Task__c> task_Resource=[SELECT Id,Resource_Project__c,Status__c 
                                            FROM Custom_Task__c 
                                            WHERE Resource_Project__c IN:asignatedResources];
        
        
        //Se crea una lista de tipo Set donde se guardaran los id de Resources.
        Set<Id> resourcesId=new Set<Id>();
        //Se itera la lista de Resource_Project y se guarda el id de la lookup de Resource__c.
        for(Resource_Project__c teamMember:asignatedResources){
            resourcesId.add(teamMember.Resource__c);
            
        }
        //Si el Squad Lead no es null y no coincide con la lista de Resources_Project asignado,
        //Entonces no pertenece al Projecto y por lo tanto se debe lanzar el addError.
        if(project_updated[0].Squad_Lead__c!=null &&!resourcesId.contains(project_updated[0].Squad_Lead__c)){
            project_updated[0].addError('the selected Squad leader is not assigned to this project. Select a resource that has been assigned to the same project.');
           
        }
        //System.debug(task_Resource);
        for(Custom_Task__c task:task_Resource){
            if(project_updated[0].Status__c=='Completed'&& task.Status__c!='Completed' ){
                project_updated[0].addError('the project cannot change its status to completed until all assigned tasks are complete');
               
            }
            
        }
    }

}