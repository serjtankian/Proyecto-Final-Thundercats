public with sharing class Alocate_Resources_Helper {
  public static Map<String, Decimal> hoursByRol = new Map<String, Decimal>();
  @AuraEnabled(cacheable=true)
  public static List<User> getAvailableResources(String projectId) {
    //Obtener el UserId
    Id userId = UserInfo.getuserId(); //get current userId

    //Listar los project en el que ese user es project manager.
    //y además deben filtrarse por status__c = 'Pre-kickoff'.
    Project__c projectRecord = [
      SELECT
        Id,
        Name,
        Project_Manager__c,
        Status__c,
        Total_Hours__c,
        Start_Date__c,
        End_Date__c
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
        Resource__r.Name,
        Resource_Start_Date__c,
        Resource_End_Date__c
      FROM Resource_Project__c
      WHERE Project__c = :projectId
      //WITH SECURITY_ENFORCED
    ];

    //Listar los roles que necesitamos cubrir
    List<AggregateResult> rolesToBeCovered = [
      SELECT SUM(Hours_Quantity__c) Hours, Rol__c Rol
      FROM Project_Line_Item__c
      WHERE Project__c = :projectId
      GROUP BY Rol__c
    ];

    //armar un Mapa de horas por roles
    
    for (AggregateResult rtbc : rolesToBeCovered) {
      hoursByRol.put((String) rtbc.get('Rol'), (Decimal) rtbc.get('Hours'));
    }

    //Listar los Users (Resources) que matcheen a los roles requeridos en el project
    List<User> resources = [
      SELECT FirstName, LastName, Rol__c, Rate_p_Hora__c
      FROM User
      WHERE Rol__c = :hoursByRol.keySet()
    ];

    //Se guarda en un mapa lista de resources disponibles por rol
    Map<String, List<User>> availableUsersByRol = new Map<String, List<User>>();

    List<Resource_Project__c> rpList = [
      SELECT
        Resource__r.Name,
        Resource__r.FirstName,
        Resource__r.LastName,
        Resource_Start_Date__c,
        Resource_End_Date__c,
        Resource__c,
        Resource__r.Rol__c,
        Project__c,
        Resource__r.Id,
        Resource__r.Rate_p_Hora__c
      FROM Resource_Project__c
      WHERE Resource__c IN :resources
      WITH SECURITY_ENFORCED
    ];

    List<User> forbiddenResources = new List<User>();

    for (Resource_Project__c rp : rpList) {
      //Check that condition 1 , Resource_End_Date__c < projectRecord.Start_Date__c
      if (
        rp.Resource_End_Date__c < projectRecord.Start_Date__c &&
        rp.Project__c != projectId
      ) {
        datesCheckHelper(availableUsersByRol, rp);
        //Check that condition 2 , Resource_End_Date__c < project Start_Date__c
      } else if (
        rp.Resource_End_Date__c < projectRecord.End_Date__c &&
        rp.Project__c != projectId
      ) {
        datesCheckHelper(availableUsersByRol, rp);

        //Check that condition 3 , Resource_Start_Date__c > project Start_Date__c
      } else if (
        rp.Resource_Start_Date__c > projectRecord.Start_Date__c &&
        rp.Project__c != projectId
      ) {
        datesCheckHelper(availableUsersByRol, rp);
        //Check that condition 4 , .Resource_Start_Date__c > project End_Date__c
      } else if (
        rp.Resource_Start_Date__c > projectRecord.End_Date__c &&
        rp.Project__c != projectId
      ) {
        datesCheckHelper(availableUsersByRol, rp);
        //If the resource does not meet the previous conditions and it exists in the map,
        // because a resource-project allowed the entry in a previous condition,
        //remove the resource from the map.
      } else {
        if (!forbiddenResources.contains(rp.Resource__r))
          forbiddenResources.add(rp.Resource__r);
      }
    }
    System.debug('Forbidden resources' + forbiddenResources);
    //Si hay resources que no tienen asignado ningun proyecto colocarlos en el mapa

    List<Resource_Project__c> asiggnedResources = [
      SELECT Resource__r.Name, Id
      FROM Resource_Project__c
    ];

    Set<Id> assignedResourceIds = new Set<Id>();
    for (Resource_Project__c rp : asiggnedResources) {
      assignedResourceIds.add(rp.Resource__c);
    }

    List<User> freeResources = [
      SELECT Name, Rol__c,Rate_p_hora__c
      FROM User
      WHERE Id NOT IN :(assignedResourceIds)
    ];

    for (User fr : freeResources) {
      if (hoursByRol.keySet().contains(fr.Rol__c)) {
        if (!availableUsersByRol.containsKey(fr.Rol__c)) {
          availableUsersByRol.put(fr.rol__c, new List<User>());
          availableUsersByRol.get(fr.Rol__c).add(fr);
        } else {
          availableUsersByRol.get(fr.Rol__c).add(fr);
        }
      }
    }

    //quitar de availableResourcesByRol los recursos que sí entraron en el mapa pero finalmente no podian prticipar
    for (user res : forbiddenResources) {
      if (
        availableUsersByRol.containsKey(res.Rol__c) &&
        availableUsersByRol.get(res.Rol__c).contains(res)
      ) {
        
        availableUsersByRol.get(res.Rol__c)
          .remove(availableUsersByRol.get(res.Rol__c).indexOf(res));
        if (availableUsersByRol.get(res.Rol__c).size() == 0) {
          availableUsersByRol.remove(res.Rol__c);
        }
      }
    }

    List<User> lista = new List<User>();
    for(List<User> lu : availableUsersByRol.values()){
      for(User u: lu){
        lista.add(u);
      }
    }
    system.debug(lista);
    return lista;

    //System.debug(availableUsersByRol);
  }

  public static void datesCheckHelper(
    Map<String, List<User>> datamap,
    Resource_Project__c rp
  ) {
    if (!datamap.containsKey(rp.Resource__r.rol__c)) {
      datamap.put(rp.Resource__r.rol__c, new List<User>());
    }
    if (!datamap.get(rp.Resource__r.Rol__c).contains(rp.Resource__r)) {
      datamap.get(rp.Resource__r.rol__c).add(rp.Resource__r);
    }
  }

  @AuraEnabled(cacheable=true)
  public static List<String> getRoles(Id projectId) {
    getAvailableResources(projectId);
   //System.debug(new List<String>(hoursByRole.keySet()));
    return new List<String>(hoursByRol.keySet());
  }
}