import { LightningElement} from 'lwc';

export default class ResourceAllocation extends LightningElement {
    // Aca podria guardar los datos que me lleguen de la query que hagan en Apex, luego puedo mostrar
    /* options = [
        { label: 'Ross', value: 'option1' },
        { label: 'Rachel', value: 'option2' },
    ]; */

    // Roles (hardcodeados)
    roles = [
        {name:"CONSULTANTS"},{name:"DEVELOPERS"},{name:"ARCHITECTS"}
    ];
    

    // Select option1 by default

    handleClick(event) {
        console.log(event);
        console.log("ricardo")
        console.log(roles);
    }
}
