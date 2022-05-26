import { LightningElement, api, wire } from 'lwc';
import getAvailableResources from '';

export default class ResourceAllocation extends LightningElement {

    @api recordId; //Obtengo el Id del proyecto que en ese momento esta abierto en salesforce

    // Aca podria guardar los datos que me lleguen de la query que hagan en Apex, luego puedo mostrar
    /* options = [
        { label: 'Ross', value: 'option1' },
        { label: 'Rachel', value: 'option2' },
    ]; */

    // Roles (hardcodeados)
    roles = [
        { name: "CONSULTANTS" }, { name: "DEVELOPERS" }, { name: "ARCHITECTS" }
    ];


    // Select option1 by default
    handleClick(event) {
        console.log(event);
        console.log("ricardo")
        console.log(roles);
    }

    @wire(getAvailableResources, { projectId: '$recordId'})
    availableResources;

    renderedCallback() {

        console.log(this.availableResources);
    
    }
}