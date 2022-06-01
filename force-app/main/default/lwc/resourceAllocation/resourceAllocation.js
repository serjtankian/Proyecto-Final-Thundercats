import { LightningElement, api, wire } from 'lwc';
import getAvailableResources from '@salesforce/apex/Alocate_Resources_Helper.getAvailableResources';
import getRoles from '@salesforce/apex/Alocate_Resources_Helper.getRoles'

export default class ResourceAllocation extends LightningElement {


    @api
    recordId;
    roles;
    
    @wire(getAvailableResources, { projectId: '$recordId' })
    data;

    @wire(getRoles, { projectId: '$recordId' })
    arrOfAvaliableRoles;



    anotherFn() {
        console.log("cacatua")
        console.log(data.data)
    }



    /*   renderedCallback({data, error}) {
         if(data){
             console.log(data)
             console.log("entre")
              this.roles = data;
              this.arrOfAvaliableRoles = Object.keys(this.roles[0]) 
          } else if (error) {
             console.log('data.error')
         }
     }  */

    // Roles (hardcodeados)
    /*  roles = [
       { name: "CONSULTANTS" }, { name: "DEVELOPERS" }, { name: "ARCHITECTS" }
     ]
 
     users = [
       {id: 1, fullName: "Ciro Bogari", usdPh: 10},
       {id: 2, fullName: "Khabib Nurmagomedov", usdPh: 20},
       {id: 3, fullName: "khamzat Chimaev", usdPh: 15},
     ]
 
     // Select option1 by default
     handleClick(event) {
         console.log(event);
         console.log("ricardo")
         console.log(roles);
     } */
    /* data = { consultant: ["mario", "luigi"], developers: ["roca", "tagliata"], architects: null }
     
    fnRoleFilter() {
        roles = []
        for (const key in data) {
            if (data[key] != null) {
                roles.push(key)
            }
        }
        console.log(roles)
        return roles
    }

    filteredRoles = fnRoleFilter()
    
    fnRoles(){
        newArr = {}
        for(let i = 0; i < filteredRoles.length; i++) {
            newArr.push({name:filteredRoles[i]})
        }
        console.log(newArr)
        return newArr;
    }

    roles = fnRoles(); */



}


