trigger TriggerProject on Project__c (before update) {
  ProjectValidation.getValidation(Trigger.new);
 
}