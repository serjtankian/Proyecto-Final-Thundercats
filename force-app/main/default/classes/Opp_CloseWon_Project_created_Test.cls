@isTest
public class Opp_CloseWon_Project_created_Test {
   
  public static Map<Id, List<Opportunity_Line_Item__c>> oppLineItemsByOppId = new Map<Id, List<Opportunity_Line_Item__c>>();
  
   @TestSetup
  static void makeData() {
    //create dates
    Date closeDate = Date.today().addDays(30);
    Date startDate = Date.today().addDays(10);
    Date endDate = Date.today().addDays(15);

    //create Accounts
    List<Account> accList = new List<Account>();
    for (Integer i = 0; i < 3; i++) {
      accList.add(new Account(Name = 'Test Account' + i));
    }
    insert accList;

    //create a opportunitys
    List<Opportunity> oppsToInsert = new List<Opportunity>();
    for (Integer i = 0; i < 3; i++) {
      Opportunity opp = new Opportunity(
        Name = 'Test Example Opportunity' + i,
        StageName = 'Prospecting',
        CloseDate = closeDate,
        Start_Date__c = startDate,
        End_Date__c = endDate,
        AccountId = accList[i].Id
      );
      oppsToInsert.add(opp);
    }
    insert oppsToInsert;

    //Create Opportunity Line Items
    List<Opportunity_Line_Item__c> oliList = new List<Opportunity_Line_Item__c>();

    for (Integer i = 0; i < 3; i++) {
      oliList.add(
        new Opportunity_Line_Item__c(
          Hours_Quantity__c = 10,
          Opportunity__c = oppsToInsert[0].id,
          Rol__c = 'Project Manager',
          Amount__c = 1000
        )
      );
    }
    insert oliList;
    oppLineItemsByOppId.put(oppsToInsert[0].id, oliList);
  }

  ////////////////////////////Test method///////////////////////////////////

  @isTest
  private static void ProjectCreatedTest() {
    List<Opportunity> oppttyList = [
      SELECT
        Id,
        Name,
        Start_Date__c,
        End_Date__c,
        StageName,
        Opportunity_Amount__c
      FROM Opportunity
    ];
    List<Id> oppIds = new List<Id>();

    Test.startTest();
    for (Opportunity op : oppttyList) {
      op.StageName = 'Closed Won';
      oppIds.add(op.Id);
    }
    update oppttyList;
    Test.stopTest();

    //when opp is closedWon, create a new project register.
    List<Project__c> projectList = [
      SELECT
        Id,
        Name,
        Opportunity__c,
        Start_Date__c,
        End_Date__c,
        Status__c,
        Total_Hours__c,
        Amount__c
      FROM Project__c
      WHERE Opportunity__c IN :oppIds
    ];

    //Number of created Projects must be 3
    System.assertEquals(
      3,
      projectList.size(),
      'Number of created Projects must be 3'
    );
    for (Integer i = 0; i < 3; i++) {
      //check the correct Relationship of project to opportunity
      System.assertEquals(
        oppIds[i],
        projectList[i].Opportunity__c,
        'Incorrect relatioship of Project__c to Opportunity Object'
      );
      //check Correct Dates
      System.assertEquals(
        Date.today().addDays(10),
        projectList[i].Start_Date__c,
        'Incorrect start date!, must be ' + oppttyList[i].Start_Date__c
      );
      System.assertEquals(
        Date.today().addDays(15),
        projectList[i].End_Date__c,
        'Incorrect End date!, must be ' + oppttyList[i].End_Date__c
      );

      //Check origin of opportunity, Stage of this must be 'Closed Won'
      System.assertEquals(oppttyList[i].StageName, 'Closed Won');

      //Check start Status of projects
      System.assertEquals('Pre-Kickoff', projectList[i].Status__c);
    }
    //Check correct Rollup Summary of data
    System.assertEquals(
      oppttyList[0].Opportunity_Amount__c,
      3000,
      'Rollup Summary must be 3000'
    );
    System.assertEquals(
      projectList[0].Amount__c,
      3000,
      'Rollup Summary must be 3000'
    );
    System.assertEquals(
      projectList[0].Total_Hours__c,
      30,
      'Rollup Summary must be 30'
    );
  }
}
