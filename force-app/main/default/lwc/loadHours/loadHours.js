import { LightningElement, api, wire, track } from 'lwc';
import getCustomTask from'@salesforce/apex/Assign_Task.getCustomTask';

export default class LoadHours extends LightningElement {
  @track
  projects = [];
  connectedCallback(){
    getCustomTask()
    .then((projectsMap) => {      
      for(const projectName in projectsMap) {
        this.projects.push({
        name: projectName,
        tasks: projectsMap[projectName]
      });
      }

    })
    .catch((error) => {
      this.error = error;
      console.log(this.error);
    });
  }

}