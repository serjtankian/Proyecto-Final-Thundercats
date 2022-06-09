import { LightningElement, api, wire } from 'lwc';
import setRegisteredHours from '@salesforce/apex/Assign_Task.setRegisteredHours';
import change_Status from '@salesforce/apex/Assign_Task.change_Status';

export default class LoadHoursTasks extends LightningElement {
  @api task;

  get status(){
    if(this.task.Status__c == "Uninitiated"){
      return  false;
    }
    if(this.task.Status__c == "In Progress"){
      return  true;
    }
  }

  handleClick() {
  change_Status({custom_task: this.task.Id, status: "In Progress"})
    .then((result) => {
      this.error = undefined;
      console.log(this.error);
    })
    .catch((error) => {
      this.error = error;
      console.log(this.error);
    });
  }

  numberInput
  inpuntOnChange(event) {
    this.numberInput = event.target.value;
  }

  handleClickPusHours(){
     setRegisteredHours({custom_task: this.task.Id, hours_Registered: this.numberInput})
      .then((result) => {
        this.error = undefined;
        console.log(this.error);
      })
      .catch((error) => {
        this.error = error;
        console.log(this.error);
      });
  }

  handleClickChangeStatus(){
      change_Status({custom_task: this.task.Id, status: "Completed"})
      .then((result) => {
        this.error = undefined;
        console.log(this.error);
      })
      .catch((error) => {
        this.error = error;
        console.log(this.error);
      });
  }

}