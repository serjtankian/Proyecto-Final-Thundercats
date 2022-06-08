public with sharing class Alocate_Resources_Helper {
  //////////////////////////////////////getAvailableResources//////////////////////////////////////////////
 //This method returns list of available resources ordered by role.
 //returned format: {}
 @AuraEnabled(cacheable=true)
 public static List<User> getAvailableResources(
   String projectId,
   String role
 ) {
   //get UserId
   Id userId = UserInfo.getuserId(); //get current userId

   //List projects dates tath, current user is project manager.
   //status__c = 'Pre-kickoff'.
   Project__c projectRecord = [
     SELECT Start_Date__c, End_Date__c
     FROM Project__c
     WHERE
       Project_Manager__c = :userId
       AND Id = :projectId
       AND Status__c = 'Pre-Kickoff'
   ];

   //Project's resource project registers

   List<Resource_Project__c> resourceProject = [
     SELECT
       Resource__c,
       Project__c,
       Resource__r.rol__c,
       Resource__r.Name,
       Resource_Start_Date__c,
       Resource_End_Date__c
     FROM Resource_Project__c
     WHERE Project__c = :projectId
   ];

   //get hours by role
   Map<String, Decimal> hoursbyRole = new Map<String, Decimal>(
     generateHoursByRoles(projectId)
   );

   //
   List<User> resources = [
     SELECT FirstName, LastName, Rol__c
     FROM User
     WHERE Rol__c = :hoursByRole.keySet()
   ];

   //Se guarda en un mapa lista de resources disponibles por rol
   Map<String, List<User>> availableUsersByRole = new Map<String, List<User>>();

   List<Resource_Project__c> rpList = [
     SELECT
       Resource__r.Name,
       Resource__r.FirstName,
       Resource__r.LastName,
       Resource_Start_Date__c,
       Resource_End_Date__c,
       Resource__c,
       Resource__r.Rol__c,
       Project__c
     FROM Resource_Project__c
     WHERE Resource__c IN :resources
   ];

   //List forbidden resources to quit from availablesResourcesByRol
   List<User> forbiddenResources = new List<User>();

   for (Resource_Project__c rp : rpList) {
     //Check that condition 1 , Resource_End_Date__c < projectRecord.Start_Date__c
     if (
       rp.Resource_End_Date__c < projectRecord.Start_Date__c &&
       rp.Project__c != projectId
     ) {
       datesCheckHelper(availableUsersByRole, rp);
       //Check that condition 2 , Resource_End_Date__c < project Start_Date__c
     } else if (
       rp.Resource_End_Date__c < projectRecord.End_Date__c &&
       rp.Project__c != projectId
     ) {
       datesCheckHelper(availableUsersByRole, rp);

       //Check that condition 3 , Resource_Start_Date__c > project Start_Date__c
     } else if (
       rp.Resource_Start_Date__c > projectRecord.Start_Date__c &&
       rp.Project__c != projectId
     ) {
       datesCheckHelper(availableUsersByRole, rp);
       //Check that condition 4 , .Resource_Start_Date__c > project End_Date__c
     } else if (
       rp.Resource_Start_Date__c > projectRecord.End_Date__c &&
       rp.Project__c != projectId
     ) {
       datesCheckHelper(availableUsersByRole, rp);
       //If the resource does not meet the previous conditions and it exists in the map,
       // because a resource-project allowed the entry in a previous condition,
       //remove the resource from the map.
     } else {
       if (!forbiddenResources.contains(rp.Resource__r))
         forbiddenResources.add(rp.Resource__r);
     }
   }
   //System.debug('Forbidden resources' + forbiddenResources);

   //list free resources, without assigned projects
   List<Resource_Project__c> asiggnedResources = [
     SELECT Resource__r.Name, Resource__r.rate_p_hora__c
     FROM Resource_Project__c
   ];

   Set<Id> assignedResourceIds = new Set<Id>();
   for (Resource_Project__c rp : asiggnedResources) {
     assignedResourceIds.add(rp.Resource__c);
   }

   List<User> freeResources = [
     SELECT Name, Rol__c, Rate_p_Hora__c
     FROM User
     WHERE Id NOT IN :(assignedResourceIds)
   ];

   for (User fr : freeResources) {
     if (hoursByRole.keySet().contains(fr.Rol__c)) {
       if (!availableUsersByRole.containsKey(fr.Rol__c)) {
         availableUsersByRole.put(fr.rol__c, new List<User>());
         availableUsersByRole.get(fr.Rol__c).add(fr);
       } else {
         availableUsersByRole.get(fr.Rol__c).add(fr);
       }
     }
   }

   //check forbidden resources
   for (user res : forbiddenResources) {
     if (
       availableUsersByRole.containsKey(res.Rol__c) &&
       availableUsersByRole.get(res.Rol__c).contains(res)
     ) {
       availableUsersByRole.get(res.Rol__c)
         .remove(availableUsersByRole.get(res.Rol__c).indexOf(res));
       if (availableUsersByRole.get(res.Rol__c).size() == 0) {
         availableUsersByRole.remove(res.Rol__c);
       }
     }
   }

   System.debug('Antes del For ' + availableUsersByRole);
   for (List<User> uList : availableUsersByRole.values()) {
     for (User u : ulist) {
       if (u.Rol__c != role) {
         availableUsersByRole.remove(u.Rol__c);
       }
       system.debug(u);
     }
   }
   System.debug('Despues del For ' + availableUsersByRole.get(role));

   return availableUsersByRole.get(role);
 }


 ///////////////////////////////////////////////////////datesCheckerHelper/////////////////////////////////////
 //This method is a helper of getAvailableResources

 private static void datesCheckHelper(
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
 /////////////////////////////////////////////////////getCalculatedProjectHours/////////////////////////////////////
 //This method returns a map with Covered or Uncovered keys, to informate coverage hours
 @AuraEnabled(cacheable=true)
 public static Map<String, Map<String, Decimal>> getCalculatedProjectHours(
   Id projectId
 ) {
   List<Resource_Project__c> covered = [
     SELECT Hours_Quantity__c, Resource__r.Rol__c
     FROM Resource_Project__c
     WHERE Project__c = :projectId
   ];
   //map the query results to obtain the covered hours by roles

   Map<String, Decimal> coveredHours = new Map<String, Decimal>();

   //Sum the covered hours

   for (Resource_Project__c cv : covered) {
     if (!coveredHours.containsKey(cv.Resource__r.Rol__c)) {
       coveredHours.put(cv.Resource__r.Rol__c, cv.Hours_Quantity__c);
     } else {
       coveredHours.put(
         cv.Resource__r.Rol__c,
         coveredHours.get(cv.Resource__r.Rol__c) + cv.Hours_Quantity__c
       );
     }
   }

   Map<String, Map<String, Decimal>> coverage = new Map<String, Map<String, Decimal>>();

   coverage.put('Covered', coveredHours);
   coverage.put('ToCover', generateHoursByRoles(projectId));
   System.debug(coverage);
   return coverage;

   //Este for estÃ¡ por si debe devolver una respuesta condicionada por el parametro Role
   // for (String r : hoursByRole.keyset()) {
   //   if (r == Role) {
   //     return hoursByRole.get(Role) - coveredHours.get(Role);
   //   }
   // }
 }

 /////////////////////////////////////////////////////getRoles/////////////////////////////////////////////
 //This method returns
 @AuraEnabled(cacheable=true)
 public static List<String> getRoles(Id projectId) {
   return new List<String>(generateHoursByRoles(projectId).keyset());
 }

 public static Map<String, Decimal> generateHoursByRoles(Id projectId) {
   //Listar los roles que necesitamos cubrir
   List<AggregateResult> rolesToBeCovered = [
     SELECT SUM(Hours_Quantity__c) Hours, Rol__c Role
     FROM Project_Line_Item__c
     WHERE Project__c = :projectId
     GROUP BY Rol__c
   ];

   //armar un Mapa de horas por roles
   Map<String, Decimal> hoursByRole = new Map<String, Decimal>();
   for (AggregateResult rtbc : rolesToBeCovered) {
     hoursByRole.put((String) rtbc.get('Role'), (Decimal) rtbc.get('Hours'));
   }

   return hoursByRole;
 }

 /*
     Disparo de este metodo por el momento mediante llamada por el boton Assing de Js y Html
     
     *****Recurso
     -INPUT 1 -Fecha de comienzo seteada
     -INPUT 2 -Fecha de finalizacion seteada
     -Escaneo de fechas disponibles con respecto a la fecha ingresada, comparacion entre ellas y devolucion de los limites minimo y maximo para el recurso
     el limite minimo siempre es la fecha de startDay del project y el maximo devuelto es la fecha endDate del project
     
     *****Proyecto
     -Data de fecha inicio fin en registro de proyecto
     */

     public static String getAvailability(
       List<Resource_Project__c> resourcesProjecsToCreate
     ) {
       List<Resource_Project__c> resourceProjectList = [
         SELECT
           Resource_Start_Date__c,
           Resource_End_Date__c,
           Resource__c,
           Resource__r.Name
         FROM Resource_Project__c
       ];
   
       List<Resource_Project__c> forbiddenResources = new List<Resource_Project__c>();
   
       for (Resource_Project__c rpTocreate : resourcesProjecsToCreate) {
         for (Resource_Project__c rp : resourceProjectList) {
           if (
             (rp.Resource__c == rpTocreate.Resource__c) &&
             rpTocreate.Resource_Start_Date__c <= rp.Resource_Start_Date__c &&
             rpTocreate.Resource_End_Date__c >= rp.Resource_Start_Date__c
           ) {
             if (!forbiddenResources.contains(rp)) {
               forbiddenResources.add(rp);
             }
           } else if (
             (rp.Resource__c == rpTocreate.Resource__c) &&
             rpTocreate.Resource_Start_Date__c <= rp.Resource_End_Date__c &&
             rpTocreate.Resource_End_Date__c >= rp.Resource_End_Date__c
           ) {
             if (!forbiddenResources.contains(rp)) {
               forbiddenResources.add(rp);
             }
           } else if (
             (rp.Resource__c == rpTocreate.Resource__c) &&
             rpTocreate.Resource_Start_Date__c <= rp.Resource_Start_Date__c &&
             rpTocreate.Resource_End_Date__c >= rp.Resource_End_Date__c
           ) {
             if (!forbiddenResources.contains(rp)) {
               forbiddenResources.add(rp);
             }
           } else if (
             (rp.Resource__c == rpTocreate.Resource__c) &&
             rpTocreate.Resource_Start_Date__c >= rp.Resource_Start_Date__c &&
             rpTocreate.Resource_End_Date__c <= rp.Resource_End_Date__c
           ) {
             if (!forbiddenResources.contains(rp)) {
               forbiddenResources.add(rp);
             }
           } else {
           }
         }
       }
       if (forbiddenResources.size() != 0) {
         for (Resource_Project__c rp : forbiddenResources) {
           return 'Resource ' +
             rp.Resource__r.Name +
             ' Is not available from ' +
             rp.Resource_Start_Date__c.format().removeEnd('00:00:00') +
             ' to ' +
             rp.Resource_End_Date__c.format().removeEnd('00:00:00');
         }
       } else {
         return 'Success!';
       }
   
       return '';
     }

     @AuraEnabled
   public static String insertResourceProject(
   List<Resource_Project__c> listResourceProject
   ) {
   try {
     upsert listResourceProject;
     return 'Success';
   } catch (System.DMLException e) {
     System.debug(e.getDmlMessage(0));
     return e.getDmlMessage(0);
   }
   }

  }