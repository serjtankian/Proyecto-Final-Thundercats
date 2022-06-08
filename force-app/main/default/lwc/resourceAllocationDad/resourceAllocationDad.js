import { LightningElement, api, wire } from 'lwc';
import getRoles from '@salesforce/apex/Alocate_Resources_Helper.getRoles'

export default class ResourceAllocation extends LightningElement {

    @api
    recordId;
    hours;
    @wire(getRoles, { projectId: '$recordId' })
    arrOfAvaliableRoles; // ["Developer","Architect"]

}
