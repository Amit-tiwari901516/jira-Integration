import { LightningElement, wire, track } from 'lwc';
import getAllBenopsBoardTickets from '@salesforce/apex/JIRA_Integration.getAllBenopsBoardTickets';
import updateIssueStatus from '@salesforce/apex/JIRA_Integration.updateIssueStatus';
import updateAssignee from '@salesforce/apex/JIRA_Integration.updateAssignee';
import getUsers from '@salesforce/apex/JIRA_Integration.getUsers';
import fetchJiraCommentsOnKeyClick from '@salesforce/apex/JIRA_Integration.fetchJiraCommentsOnKeyClick';
import getAttachmentsByIssueKey from '@salesforce/apex/JIRA_Integration.getAttachmentsByIssueKey';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class JiraIntegration extends LightningElement {
    isLoading = true;
    error;
    tickets;
    EditButtonPopup = false;
    selectedTicketKey;
    selectedStatus;
    @track selectedAssigneesUser = {};
    @track assigneeOptions = [];
    selectedAssigneeId;
    commentPage = false;
    MainPage = false;
    comments;
    attachmentsSection = false;
    attachments;
    attachmentError;

    @wire(getAllBenopsBoardTickets)
    wiredTickets({ error, data }) {
        if (data) {
            this.tickets = JSON.parse(data[0]).issues.map(issue => ({
                key: issue.key,
                summary: issue.fields.summary,
                displayName : issue.fields.displayName,
                status : issue.fields.status.name
            }));
            this.isLoading = false;
            this.MainPage = true;

            this.tickets.forEach(ticket => {
                this.selectedAssigneesUser[ticket.key] = ticket.assigneeId || '';
            });
            
        } else if (error) {
            this.error = error;
            this.isLoading = false;
        }
    }
    
    handleEditIssue(event) {
        const selectedKey = event.target.dataset.id;
        const selectedTicket = this.tickets.find(ticket => ticket.key === selectedKey);
        if (selectedTicket) {
            this.selectedTicketKey = selectedKey;
            this.selectedStatus = selectedTicket.status;
            this.EditButtonPopup = true;
        }
    }

    handleStatusChange(event) {
        this.selectedStatus = event.detail.value;
    }

    closeEditPopup() {
        this.EditButtonPopup = false;
    }
       
    @wire(getUsers)
    wiredUsers({ error, data }) {
        if (data) {
            console.log('Result: '+JSON.stringify(data));
            const users = JSON.parse(data);
            console.log('users'+ users);
            this.assigneeOptions = users.map(user => ({
                label: user.displayName,
                value: user.accountId
            }));
        } else if (error) {
            console.error('Error fetching users:', error);
        }
    }
    
    handleAssigneeChange(event) {
        this.selectedTicketKey = event.target.dataset.key;
        const selectedAssigneeId = event.detail.value;
    
        console.log('Selected ticket key:', this.selectedTicketKey);
        console.log('Selected assignee ID:', selectedAssigneeId);
    
        this.selectedAssigneesUser[this.selectedTicketKey] = selectedAssigneeId;
        console.log('Updated assignee information:', this.selectedAssigneesUser);
       
    }
    
    handleAssigneeUpdate(event) {
        const ticketKey = event.target.dataset.key;
        console.log('ticketKey'+ ticketKey);
        const selectedAssigneeId = this.selectedAssigneesUser[ticketKey];
        console.log('selectedAssigneeId'+ selectedAssigneeId);
    
        console.log('Updating assignee for ticket:', ticketKey, 'with assignee ID:', selectedAssigneeId);
    
        if (selectedAssigneeId) {
            updateAssignee({ issueKey: ticketKey, assigneeId: selectedAssigneeId })
                .then(result => {
                    console.log('Assignee updated successfully:', result);
                })
                .catch(error => {
                    console.error('Error updating assignee:', error);
                });
        } else {
            console.error('No assignee selected for ticket:', ticketKey);
        }
    }
       
    handleTicketClick(event) {
        const selectedKey = event.target.dataset.id;
        this.selectedTicketKey = selectedKey;
        this.MainPage = false;
        this.commentPage = true;

        fetchJiraCommentsOnKeyClick({ issueKey: this.selectedTicketKey })
        .then(result => {
           
            console.log('Result++>'+ JSON.stringify(result));
            // this.comments = result;
            // console.log('comment result'+ this.comments );
            let parsedResult = JSON.parse(result);
            console.log('parsedResult result'+ parsedResult )
            this.attachments = parsedResult.attachments;
            this.comments = parsedResult.comments;
            this.error = null;
        })
        .catch(error => {
            this.error = error;
            this.attachments = null;
            this.comments = null;
        });

    }

    navigateBack() {
        this.commentPage = false;
        this.attachmentsSection = false;
        this.MainPage = true;
    } 
   
    viewAttachmentsHandler(event) {
        const selectedKey = event.target.dataset.id;
        this.selectedTicketKey = selectedKey;
        this.isLoading = true;
        this.MainPage = false;
        this.attachmentsSection = true;
    
        getAttachmentsByIssueKey({ issueKey: this.selectedTicketKey })
            .then(result => {
                if (result.error) {
                    console.error('Error fetching attachments:', result.error);
                    throw new Error(result.error);
                }
                console.log('Attachments:', result.attachments);
                this.attachments = result.attachments;
                this.isLoading = false;
                this.attachmentError = null;
            })
            .catch(error => {
                console.error('Error fetching attachments:', error.message);
                this.attachmentError = error.message;
                this.attachments = null;
                this.isLoading = false;
            });
    }
       
}