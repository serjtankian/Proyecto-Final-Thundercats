import { api, LightningElement, wire } from 'lwc';
import getAvailableResources from '@salesforce/apex/Alocate_Resources_Helper.getAvailableResources';
import insertResourceProject from '@salesforce/apex/Alocate_Resources_Helper.insertResourceProject';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getCalculatedProjectHours from '@salesforce/apex/Alocate_Resources_Helper.getCalculatedProjectHours'

import RESOURCE_PROJECT from '@salesforce/schema/Resource_Project__c';
import RESOURCE_ID from '@salesforce/schema/Resource_Project__c.Resource__c';
import PROJECT_ID from '@salesforce/schema/Resource_Project__c.Project__c';
import RESOURCE_START_DATE from '@salesforce/schema/Resource_Project__c.Resource_Start_Date__c';
import RESOURCE_END_DATE from '@salesforce/schema/Resource_Project__c.Resource_End_Date__c';
import HOURS_QUANTITY from '@salesforce/schema/Resource_Project__c.Hours_Quantity__c';

const columns = [
    { label: 'Name', fieldName: 'Name' },
    { label: 'Rate per Hour', fieldName: 'Rate_p_hora__c', type: 'currency' },
    {
        label: 'Start Date', fieldName: 'Start_Date', type: 'date', editable: true, typeAttributes: {
            day: 'numeric',
            month: 'numeric',
            year: 'numeric'
        }
    },
    {
        label: 'End Date', fieldName: 'End_Date', type: 'date', editable: true, typeAttributes: {
            day: 'numeric',
            month: 'numeric',
            year: 'numeric'
        }
    }

];



export default class resourceAllocationSon extends LightningElement {


    @api
    rol;
    @api
    recordId;
    hours;
    columns = columns;

    @wire(getAvailableResources, { projectId: '$recordId', role: '$rol' })
    resources;

    getBusinessDatesCount(startDate, endDate) {
        let count = 0;
        let yearSD = startDate.substring(0, 4)
        let monthSD = Number(startDate.substring(5, 7)) - 1
        let finalMonthSD = '0' + monthSD
        let daySD = startDate.substring(8, 10)
        let yearED = endDate.substring(0, 4)
        let monthED = Number(endDate.substring(5, 7)) - 1
        let finalMonthED = '0' + monthED
        let dayED = endDate.substring(8, 10)

        startDate = new Date(yearSD, finalMonthSD, daySD)
        endDate = new Date(yearED, finalMonthED, dayED)
        const curDate = new Date(startDate.getTime());
        while (curDate <= endDate) {
            const dayOfWeek = curDate.getDay();
            curDate.setDate(curDate.getDate() + 1);
            if (dayOfWeek !== 6 && dayOfWeek !== 0) count++;
        }
        return count;
    }
    
    handleSave(event) {
        const fields = {}
        fields[RESOURCE_ID.fieldApiName] = this.template.querySelector("lightning-datatable").getSelectedRows()[0].Id
        fields[PROJECT_ID.fieldApiName] = this.recordId;
        fields[RESOURCE_START_DATE.fieldApiName] = (event.detail.draftValues[0].Start_Date).substring(0, 10);
        fields[RESOURCE_END_DATE.fieldApiName] = (event.detail.draftValues[0].End_Date).substring(0, 10);

        let hours = this.getBusinessDatesCount(fields[RESOURCE_START_DATE.fieldApiName], fields[RESOURCE_END_DATE.fieldApiName]) * 8
        fields[HOURS_QUANTITY.fieldApiName] = hours;
        console.log(hours)

        const recordInput = { apiName: RESOURCE_PROJECT.objectApiName, fields }
        console.log(recordInput)
        insertResourceProject({ listResourceProject: [fields] })
            .then((result) => {
                if (result == 'Success') {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Resource allocated!',
                            message: result,
                            variant: 'Success'
                        })
                    )
                } else {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error: ',
                            message: result,
                            variant: 'error',
                        })
                    )
                }
                
                
            })



            
    }

    
    connectedCallback() {
        let newObj = {}
        getCalculatedProjectHours({ projectId: this.recordId })
            .then((result) => {
                for (let key in result.ToCover) {
                    if (!(result.Covered[key])) {
                        newObj[key] = result.ToCover[key] - 0
                        this.hours = newObj[this.rol] 
                    } else {
                        newObj[key] = result.ToCover[key] - result.Covered[key]
                        this.hours = newObj[this.rol]
                    }
                }
            })
            .catch((error) => {
                console.log(error.body.message);
            })
    }

}

/* {developer:{covered:250,toCovered:500}} */



