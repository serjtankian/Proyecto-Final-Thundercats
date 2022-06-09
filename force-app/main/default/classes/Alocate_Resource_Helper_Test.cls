@isTest
public with sharing class Alocate_Resource_Helper_Test {
  public static List<User> newResources = new List<User>();
  public static List<Opportunity> oppsToInsert = new List<Opportunity>();

  @isTest
  static void Alocate_Resource_Helper_Cases() {
    //Make Resources
    List<String> rolesList = new List<String>{
      'Project Manager',
      'Developer',
      'Consultant',
      'Architect'
    };
    for (Integer i = 0; i < 4; i++) {
      User nUser = new User(
        LastName = 'Test' + i,
        FirstName = 'User',
        Alias = 'user' + i,
        Email = 'gmz_leo@hotmail.com',
        IsActive = true,
        EmailEncodingKey = 'UTF-8',
        Rol__c = rolesList[i],
        TimeZoneSidKey = 'America/Argentina/Buenos_Aires',
        Username = 'user' + i + '@proyectofinal.com',
        LocaleSidKey = 'es_AR',
        ProfileId = '00e8a000002AO3YAAW',
        LanguageLocaleKey = 'es',
        Rate_p_Hora__c = 150
      );
      newResources.add(nUser);
    }

    insert newResources;

    Date closeDate = Date.today().addDays(90);
    Date startDate = Date.today().addDays(10);
    Date endDate = Date.today().addDays(40);

    //create Accounts
    List<Account> accList = new List<Account>();
    for (Integer i = 0; i < 2; i++) {
      accList.add(new Account(Name = 'Test Account' + i));
    }
    insert accList;

    //create a opportunities

    for (Integer i = 0; i < 2; i++) {
      Opportunity opp = new Opportunity(
        Name = 'Test Example Opportunity' + i,
        StageName = 'Prospecting',
        CloseDate = closeDate,
        Start_Date__c = startDate,
        End_Date__c = endDate,
        AccountId = accList[i].Id,
        Project_Manager__c = UserInfo.getUserId()
      );
      oppsToInsert.add(opp);
    }
    insert oppsToInsert;
    //system.debug(oppsToInsert);

    //Create Opportunity Line Items
    List<Opportunity_Line_Item__c> oliList = new List<Opportunity_Line_Item__c>();

    for (Integer i = 0; i < 2; i++) {
      for (Integer j = 0; j < 4; j++) {
        Opportunity_Line_Item__c opp = new Opportunity_Line_Item__c(
          Hours_Quantity__c = 10 * (j + 1),
          Opportunity__c = oppsToInsert[i].id,
          Amount__c = 1000 * (j + 1)
        );

        switch on j {
          when 0 {
            opp.Rol__c = 'Developer';
          }
          when 1 {
            opp.Rol__c = 'Developer';
          }
          when 2 {
            opp.Rol__c = 'Consultant';
          }
          when 3 {
            opp.Rol__c = 'Architect';
          }
          when else {
          }
        }

        oliList.add(opp);
      }
    }

    insert oliList;

    // List<Opportunity> oppsToUpdate = [
    //   SELECT Id, StageName
    //   FROM Opportunity
    //   WHERE Id IN :oppsToInsert
    // ];
    List<User> ResourcesList = [
      SELECT Name, Rol__c
      FROM User
      WHERE
        (Rol__c = 'Consultant'
        OR Rol__c = 'Developer'
        OR Rol__c = 'Architect'
        OR Rol__c = 'Project Manager')
        AND FirstName = 'User'
    ];
    // System.debug('ResourcesList Post Created' + ResourcesList);

    for (Opportunity opp : oppsToInsert) {
      opp.StageName = 'Closed Won';
    }
    update oppsToInsert;

    //Assign resources to 1 project
    Project__c projectRecord = [
      SELECT Id, Start_Date__c, End_Date__c, Project_Manager__c
      FROM Project__c
      WHERE Opportunity__c = :oppsToInsert[0].Id
    ];

    List<Resource_Project__c> resourceProjectsToCreate = new List<Resource_Project__c>();

    for (Integer i = 0; i < ResourcesList.Size(); i++) {
      Resource_Project__c rp = new Resource_Project__c(
        Resource__c = ResourcesList[i].id,
        Project__c = projectRecord.id,
        Hours_Quantity__c = 20
      );

      switch on i {
        // projects dates overlap, discarded resource
        when 0 {
          rp.Resource_Start_Date__c = projectRecord.Start_Date__c.addDays(-1);
          rp.Resource_End_Date__c = projectRecord.End_Date__c.addDays(1);
        }
        //after project start, accepted resource
        when 1 {
          rp.Resource_Start_Date__c = projectRecord.Start_Date__c.addDays(10);
          rp.Resource_End_Date__c = projectRecord.End_Date__c.addDays(30);
        }
        //partial overlap, before start of project, , accepted resource
        when 2 {
          rp.Resource_Start_Date__c = projectRecord.Start_Date__c.addDays(-30);
          rp.Resource_End_Date__c = projectRecord.End_Date__c.addDays(-10);
        }
        //partial overlap, after start of project, , accepted resource
        when 3 {
          rp.Resource_Start_Date__c = projectRecord.Start_Date__c.addDays(20);
          rp.Resource_End_Date__c = projectRecord.End_Date__c.addDays(5);
        }
        when else {
        }
      }
      resourceProjectsToCreate.add(rp);
    }

    insert resourceProjectsToCreate;
    //m.debug(resourceProjectsToCreate);

    List<Project__c> projectId = [
      SELECT Id
      FROM Project__c
      WHERE Project_Manager__c = :UserInfo.getUserId()
    ];

    Test.startTest();
    for (Integer i = 0; i < rolesList.size(); i++) {
      if (i > 0) {
        System.assertEquals(
          1,
          Alocate_Resources_Helper.getAvailableResources(
              projectId[1].Id,
              rolesList[i]
            )
            .size()
        );
      } else {
        System.assertEquals(
          null,
          Alocate_Resources_Helper.getAvailableResources(
            projectId[1].Id,
            rolesList[i]
          )
        );
      }
    }

    List<String> roles = new List<String>();
    roles.add('Architect');
    roles.add('Developer');
    roles.add('Consultant');

    List<String> returnedRoles = Alocate_Resources_Helper.getRoles(
      projectRecord.Id
    );
    for (Integer i = 0; i < roles.size(); i++) {
      System.assertEquals(true, returnedRoles.contains(roles[i]));
    }

    Date resourceStartDate = projectRecord.Start_Date__c.addDays(-1);
    Date resourceEndDate = projectRecord.End_Date__c.addDays(1);
    try {
      insert new Resource_Project__c(
        Resource__c = ResourcesList[0].Id,
        Resource_Start_Date__c = resourceStartDate,
        Resource_End_Date__c = resourceEndDate,
        Project__c = projectRecord.Id,
        Hours_Quantity__c = 100
      );
    } catch (DMLException e) {
      system.assertEquals(
        'Resource User Test0 Is not available from ' +
        resourceStartDate.format().removeEnd('00:00:00') +
        ' to ' +
        resourceEndDate.format().removeEnd('00:00:00'),
        e.getDmlMessage(0)
      );
    }

    Test.stopTest();
  }
}