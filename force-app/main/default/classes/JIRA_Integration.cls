public class JIRA_Integration {
    
    private static final String BASE_URL = 'callout:Jira_Tickets/rest/api/2/';
    
    public class CommentWrapper {
        @AuraEnabled
        public String contentText { get; set; }
        @AuraEnabled
        public String author { get; set; }
        @AuraEnabled
        public String body { get; set; }
        @AuraEnabled
        public String emailAddress { get; set; }
        @AuraEnabled
        public DateTime updatedDate { get; set; }
        @AuraEnabled
        public DateTime createDate { get; set; }
        
    }
    
    @AuraEnabled(cacheable=true)
    public static List<String> getAllBenopsBoardTickets() {
       	HttpRequest req = new HttpRequest();
        req.setEndpoint(BASE_URL + 'search/?jql=');
        req.setMethod('GET');
        req.setHeader('Content-Type', 'application/json');
        
        // Send HTTP request
        Http http = new Http();
        HttpResponse response = http.send(req);
        System.debug('response'+response);
        
        // Parse response and return data
        List<String> tickets = new List<String>();
        if(response.getStatusCode() == 200) {
            String responseBody = response.getBody();
            System.debug('responseBody'+responseBody);
            // Add response body to the list
            tickets.add(responseBody);
        } else {
            // Handle error
            System.debug('Error fetching Jira tickets: ' + response.getBody());
        }
        return tickets;
    }
    
    @AuraEnabled
    public static void updateIssueStatus(String issueKey, String newStatus) {
        
    }
    
    @AuraEnabled(cacheable=true)
    public static String fetchJiraCommentsOnKeyClick(String issueKey) {
        String endpointBase = BASE_URL+ 'issue/' + issueKey;
        Map<String, Object> response = new Map<String, Object>();
        
        // Fetch attachments
        //response.put('attachments', getIssueField(endpointBase + '?fields=attachment', 'attachment'));
        
        // Fetch comments
        response.put('comments', getIssueComments(endpointBase + '/comment'));
        
        return JSON.serialize(response);
    }
    
   /* private static List<Object> getIssueField(String endpoint, String fieldName) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        req.setHeader('Content-Type', 'application/json');
        Http http = new Http();
        HttpResponse res = http.send(req);
        
        if (res.getStatusCode() == 200) {
            Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            if (results.containsKey('fields')) {
                Map<String, Object> fields = (Map<String, Object>) results.get('fields');
                return (List<Object>) fields.get(fieldName);
            }
        }
        return new List<Object>();  // return empty list if no data or error
    }*/
    
	private static List<Map<String, Object>> getIssueComments(String endpoint) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        req.setHeader('Content-Type', 'application/json');
        Http http = new Http();
        HttpResponse res = http.send(req);
        
        List<Map<String, Object>> commentDetails = new List<Map<String, Object>>();
        
        if (res.getStatusCode() == 200) {
            Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            List<Object> comments = (List<Object>) results.get('comments');
            for (Object comment : comments) {
                Map<String, Object> commentMap = (Map<String, Object>) comment;
                Map<String, Object> author = (Map<String, Object>) commentMap.get('author');
                String authorName = (String) author.get('displayName');
                String body = (String) commentMap.get('body');
                
                // Simulated extraction of attachment URLs from comment
                List<String> attachmentUrls = new List<String>();
                if (commentMap.containsKey('attachments')) {
                    List<Object> attachments = (List<Object>) commentMap.get('attachments');
                    for (Object attachment : attachments) {
                        Map<String, String> attachmentMap = (Map<String, String>) attachment;
                        attachmentUrls.add(attachmentMap.get('content'));
                    }
                }
                
                Map<String, Object> commentData = new Map<String, Object>{
                    'authorName' => authorName,
                        'body' => body,
                        'attachmentUrls' => attachmentUrls
                        };
                            commentDetails.add(commentData);
            }
        }
        return commentDetails;
    }
    
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getAttachmentsByIssueKey(String issueKey) {
        
        System.debug('getAttachmentsByIssueKey'+issueKey);
        Map<String, Object> result = new Map<String, Object>();
        List<Map<String, String>> attachmentDetails = new List<Map<String, String>>();
        
        HttpRequest request = new HttpRequest();
        request.setEndpoint(BASE_URL + '/issue/' + issueKey +'?fields=attachment');
        request.setMethod('GET');
        request.setHeader('Content-Type', 'application/json');
        
        Http http = new Http();
        
        try {
            HttpResponse response = http.send(request);
            
            if (response.getStatusCode() == 200) {
                String responseBody = response.getBody();
                System.debug('Response body: ' + responseBody);
                Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
                System.debug('JSON Response: ' + jsonResponse);
                Map<String, Object> fields = (Map<String, Object>) jsonResponse.get('fields');
                System.debug('Fields: ' + fields);
                
                if (fields != null && fields.containsKey('attachment')) {
                    List<Object> attachmentsList = (List<Object>) fields.get('attachment');
                    if (attachmentsList != null && !attachmentsList.isEmpty()) {
                        for (Object attachment : attachmentsList) {
                            Map<String, Object> attachmentMap = (Map<String, Object>) attachment;
                            String attachmentId = (String) attachmentMap.get('id');
                            String attachmentFileName = (String) attachmentMap.get('filename');
                            System.debug('attachmentFileName'+attachmentFileName);
                            String attachmentMimeType = (String) attachmentMap.get('mimeType');
                            System.debug('attachmentMimeType'+attachmentMimeType);
                            String attachmentContent = (String) attachmentMap.get('content');
                            System.debug('attachmentContent'+attachmentContent);
                            String thumbnailUrl =  (String) attachmentMap.get('thumbnail');
                            System.debug('thumbnailUrl'+thumbnailUrl);
                            
                            Map<String, String> attachmentInfo = new Map<String, String>();
                            attachmentInfo.put('id', attachmentId);
                            attachmentInfo.put('filename', attachmentFileName);
                            attachmentInfo.put('mimeType', attachmentMimeType);
                            attachmentInfo.put('content', attachmentContent);
                            attachmentMap.put('thumbnail', thumbnailUrl);
                            
                            attachmentDetails.add(attachmentInfo);
                        }
                    }
                }
                
                result.put('attachments', attachmentDetails);
                result.put('error', null);
            } else {
                String errorMessage = 'HTTP Error: ' + response.getStatusCode() + ' ' + response.getBody();
                System.debug(errorMessage);
                result.put('attachments', null);
                result.put('error', errorMessage);
            }
        } catch(Exception e) {
            String exceptionMessage = 'Exception: ' + e.getMessage();
            System.debug(exceptionMessage);
            result.put('attachments', null);
            result.put('error', exceptionMessage);
        }
        
        return result;
    } 
     
    @AuraEnabled(cacheable=true)
    public static String getUsers() {

        HttpRequest req = new HttpRequest();
        req.setEndpoint(BASE_URL + 'user/assignable/search?project=KAN');
        req.setMethod('GET');
        req.setHeader('Content-Type', 'application/json');
        
        Http http = new Http();   
        HttpResponse response = http.send(req);
        System.debug('Get User response'+ response);
            
            if (response.getStatusCode() == 200) {
                return response.getBody();
            }
       
        return null;
    }
    
    @AuraEnabled
    public static String updateAssignee(String issueKey, String assigneeId) {
        // Prepare the request body
        Map<String, Object> requestBodyMap = new Map<String, Object>{
            'fields' => new Map<String, Object>{
                'assignee' => new Map<String, String>{
                    'accountId' => assigneeId
                        }
            }
        };
            
            String requestBody = JSON.serialize(requestBodyMap);
        System.debug('requestBody for assignee'+ requestBody);
        
        HttpRequest request = new HttpRequest();
        request.setEndpoint(BASE_URL + 'issue/' + issueKey);
        request.setMethod('PUT');
        request.setHeader('Content-Type', 'application/json'); 
        request.setBody(requestBody);
        
        // Send the request
        Http http = new Http();
        try {
            HttpResponse response = http.send(request);
            System.debug('response for assignee'+ response);
            
            if (response.getStatusCode() == 204) {
                return 'Issue ' + issueKey + ' updated successfully.';
            } else {
                return 'Failed to update issue ' + issueKey + '. Status code: ' + response.getStatusCode() + ', Message: ' + response.getStatus();
            }
        } catch (Exception e) {
            return 'An error occurred while updating the issue: ' + e.getMessage();
        }
    }
    
}