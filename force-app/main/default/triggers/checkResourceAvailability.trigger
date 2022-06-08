trigger checkResourceAvailability on Resource_Project__c (before insert, before update) {
    String message = Alocate_Resources_Helper.getAvailability(trigger.new); 
    if(!message.contains('Success')){
        trigger.new[0].addError(message); 
    }        
}