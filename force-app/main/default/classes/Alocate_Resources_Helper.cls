public with sharing class Alocate_Resources_Helper {
  public static void getAvailableResources(Id projectId) {
    //Obtener el UserId
    Id userId = UserInfo.getuserId(); //get current userId

    //Listar los project en el que ese user es project manager.
    //y además deben filtrarse por status__c = 'Pre-kickoff'.
    Project__c projectRecord = [
      SELECT Id, Name, Project_Manager__c, Status__c, Total_Hours__c, Start_Date__c,End_Date__c
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

    //Listar los roles que necesitamos cubrir
    List<AggregateResult> rolesToBeCovered = [
      SELECT SUM(Hours_Quantity__c) Hours, Rol__c Rol
      FROM Project_Line_Item__c
      WHERE Project__c = :projectId
      GROUP BY Rol__c
    ];

    //armar un Mapa de horas por roles
    Map<String, Decimal> hoursByRol = new Map<String, Decimal>();
    for (AggregateResult rtbc : rolesToBeCovered) {
      hoursByRol.put((String) rtbc.get('Rol'), (Decimal) rtbc.get('Hours'));
    }
    //Listar los Users (Resources) que matcheen a los roles requeridos en el project

    List<User> resources = [
      SELECT FirstName, LastName, Rol__c, Rate_p_Hora__c
      FROM User
      WHERE Rol__c = :hoursByRol.keySet()
    ];
    System.debug(resources);
    Set<Id> resourceIdSet=new Set<Id>();
    //Se guarda en un mapa lista de resources disponibles por rol
    Map<String,Set<Id>> availableUsersByRol = new Map<String,Set<Id>>();
  for (Resource_Project__c rp : [SELECT Resource_Start_Date__c,Resource_End_Date__c ,Resource__c, Resource__r.Rol__c from Resource_Project__c  WHERE Resource__c In: resources ] ) {
   if(rp.Resource_End_Date__c<projectRecord.Start_Date__c){
     resourceIdSet.add(rp.Resource__c);
    availableUsersByRol.put(rp.Resource__r.Rol__c,resourceIdSet);
   }
   else if (rp.Resource_End_Date__c<projectRecord.End_Date__c) {
    resourceIdSet.add(rp.Resource__c);
    availableUsersByRol.put(rp.Resource__r.Rol__c,resourceIdSet);
   }
   else if(rp.Resource_Start_Date__c>projectRecord.Start_Date__c){
    resourceIdSet.add(rp.Resource__c);
    availableUsersByRol.put(rp.Resource__r.Rol__c,resourceIdSet);
   }
   else if(rp.Resource_Start_Date__c>projectRecord.End_Date__c){
    resourceIdSet.add(rp.Resource__c);
    availableUsersByRol.put(rp.Resource__r.Rol__c,resourceIdSet);
   }
   else if(resourceIdSet.contains(rp.Resource__c)){
    resourceIdSet.remove(rp.Resource__c);
   }
  }

  }
}
//Listar los resource que esten disponibles en el periodo que este proyecto dure

//fecha en que empieza y termina el proyecto - 1/5 empieza 31/5 termina
//Rango de fecha en la que el recurso esta ocupado a partir de la fehca de comienzo del proyecto?
/*
mostrar las posiciones sin asignar

solamente le permita asignar personas que tengan el mismo rol 

disponibles en el rango de fechas del proyecto.
*/
