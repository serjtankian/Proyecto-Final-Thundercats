public with sharing class Alocate_Resources_Helper {
  public static void getAvailableResources(Id projectId) {
    //Obtener el UserId
    Id userId = UserInfo.getuserId(); //get current userId

    //Listar los project en el que ese user es project manager.
    //y además deben filtrarse por status__c = 'Pre-kickoff'.
    Project__c projectRecord = [
      SELECT Id, Name, Project_Manager__c, Status__c, Total_Hours__c
      FROM Project__c
      WHERE
        Project_Manager__c = :userId
        AND Id = :projectId
        AND Status__c = 'Pre-Kickoff'
    ];

    //listar los registros resource/project que pertenezcan a este proyecto

    List<Resource_Project__c> resourceProject = [
      SELECT
        Resource__c,
        Project__c,
        Hours_Quantity__c,
        Resource__r.rol__c,
        Resource_Start_Date__c,
        Resource_End_Date__c
      FROM Resource_Project__c
      WHERE Project__c = :projectId
    ];

    //Listar los resource que esten disponibles en el periodo que este proyecto dure
  
  }
}
