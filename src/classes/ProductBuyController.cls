public class ProductBuyController {

	
    public String nameProd{get;set;}
    public String email{get;set;}
	public String firstName{get;set;}
    public String lastName{get;set;}
    public Decimal priceProd{get;set;}
    public Decimal amountProd{get;set;}

    private Decimal amountAll{get;set;}
    private String ContactId{get;set;}
    private String prodId{get;set;}
    private String firstNameOld{get;set;}
    private String lastNameOld{get;set;}
    
    public ProductBuyController (){
    	viewPage(); 
    }
    Pattern p = Pattern.compile( '([a-zA-Z0-9_\\-\\.]+)@(((\\[a-z]{1,3}\\.[a-z]{1,3}\\.[a-z]{1,3}\\.)|(([a-zA-Z0-9\\-]+\\.)+))([a-zA-Z]{2,4}|[0-9]{1,3}))');
    
    private void viewPage(){
          this.prodId= Apexpages.currentPage().getparameters().get('id');
        if (this.prodId != null){
           	Product_Table__c Prod = [SELECT Id, Name, Unit_Price__c, Unit__c  FROM Product_Table__c WHERE id=:this.ProdId ];
           	this.nameProd   = Prod.Name;
         	this.priceProd  = Prod.Unit_Price__c == null ?  0 :  Prod.Unit_Price__c;
         	this.amountAll  = Prod.Unit__c == null ?  0 :  Prod.Unit__c;
        }
    }
 
    public PageReference saveInfoBuy(){
		if( String.isBlank(this.email)){
        	ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'Please, enter Email!!! '));  
        	return null;  
       	}
	
        Matcher m = p.matcher(this.email);
        if (!m.matches()) {
     	   	ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'Invalid email format '));  
			return null;   
        }         
        if( String.isBlank(this.firstName)){
        	ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'Please, enter First Name!!! '));  
            return null;  
        }
        if(String.isBlank(this.lastName)){
      		ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'Please, enter Last Name!!! '));
            return null;  
        }
        if(this.amountProd == 0){
          	ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'Please, enter  Amount Product!!! ')); 
            return null;  
        }
      
        Savepoint sp = Database.setSavepoint();


        if(this.ContactId != null){
            if( this.firstName !=  this.firstNameOld ||   this.lastName !=  this.lastNameOld){
             List<Contact> contact = [SELECT id,FirstName,LastName FROM Contact WHERE id=:this.ContactId LIMIT 1];    
                for (Integer i = 0; i<contact.size(); i++ ){
                	contact[i].FirstName = this.firstName;
                    contact[i].LastName = this.lastName;
                }
                upsert contact;  
            }
        }
        ELSE {
            Contact insertContact = new Contact(
                 FirstName = this.firstName,
                 LastName  = this.lastName,
                 Email     = this.email
            );
            insert insertContact;
            this.ContactId = insertContact.id;
        }
        
        Order_Table__c ordTable = new Order_Table__c(
            Contact__c   = this.ContactId,
            MyProduct__c = this.prodId,
            Units__c     = this.amountProd,
            Order_Amo__c = this.amountProd * this.priceProd
		);
		insert ordTable;
        
         Product_Table__c Prods = [SELECT Id, Unit__c  FROM Product_Table__c WHERE id=:this.ProdId ];   
         Prods.Unit__c = this.amountAll - this.amountProd; 
         update Prods;
        
         if( this.amountAll - this.amountProd  < 0 ){
            Database.rollback(sp);
          	ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'Sorry, only ' + this.amountAll + ' items are available')); 
            return null;  
        }
     
         PageReference pgProductList = new PageReference('/apex/Product_List');
         pgProductList.getParameters().put('message', 'Buy was successful!!!');
         pgProductList.setRedirect(true);
         return pgProductList;        
    }  
    public void getNameContact(){
        System.debug('this.email ' + this.email);
       	List<Contact> contact = [SELECT id,FirstName,LastName FROM Contact WHERE Email=:this.email LIMIT 1]; 
       	if(contact.size() > 0){
		for (Integer i = 0; i<contact.size(); i++ ){
    		this.firstName =  contact[i].FirstName;
            this.lastName = contact[i].LastName; 
            this.firstNameOld = this.firstName;
            this.lastNameOld = this.lastName;
            this.ContactId = contact[i].id;
            }
        }
    }
}