trigger checkResourceAvailability on Resource_Project__c(
    before insert,
    before update
    
){
    Set<Id> resourcesId = new Set<Id>();
    for(Resource_Project__c rp : Trigger.new){
        resourcesId.add(rp.Resource__c);
    }
    
    List<User> resources = [SELECT Rate_p_Hora__c From User Where Id IN: resourcesId];
    
    Map<Id, Decimal> rateByUser = new Map<Id, Decimal>();
    for(User u : resources){
        rateByUser.put(u.Id, u.Rate_p_Hora__c );
    }
    
    for(Resource_Project__c rp: Trigger.new){
        rp.Resource_Cost__c = rateByUser.get(rp.Resource__c) * rp.Hours_Quantity__c;
    }
    
    if(Trigger.isBefore){
        String message = Alocate_Resources_Helper.getAvailability(Trigger.new);
        if (!message.contains('Success')) {
            Trigger.new[0].addError(message);
        }}
    
    
    
}