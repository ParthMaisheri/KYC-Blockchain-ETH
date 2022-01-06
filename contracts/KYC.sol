pragma solidity ^0.5.9;

contract KYC{
    
    struct Customer{
        string userName;
        string customerData;
        uint upVotes;
        uint downVotes;
        address bank;
        bool KYC_status;
    }

    struct Bank{
        string Name;
        address ethAddress;
        string regNumber;
        uint downVotes;
        bool isAllowedToVote;
        uint KYCCount;
    }

    struct KYCRequest{
        string userName; 
        string customerData;
        address bank;
    }
    
    uint TotalNoOfBanks;
    address admin ;

    constructor() public {
        admin = msg.sender;
        TotalNoOfBanks = 0;
    }

    
    mapping(string => KYCRequest) requests;
    mapping(string => Customer) customers;
    mapping(address => Bank) bankList;

    //bank
    //Add Request
    function addRequests(string memory _userName,string memory  _customerData) public {
            require(requests[_userName].bank == address(0),"Customer Already Present");
            require(customers[_userName].bank == address(0),"Customer Already Present in CustomerList");
            require(bankList[msg.sender].ethAddress != address(0),"Function Allowed only for Resgitered Banks");
            requests[_userName].userName = _userName;
            requests[_userName].customerData = _customerData;
            requests[_userName].bank = msg.sender ;
            bankList[msg.sender].KYCCount += 1;

    }


    //Add Customer
    function addCustomer(string memory _userName,string memory  _customerData) public {
            require(requests[_userName].bank != address(0),"No Such Customer Found!");
            require(customers[_userName].bank == address(0),"Customer Already Present");
            require(bankList[msg.sender].ethAddress != address(0),"Function Allowed only for Resgitered Banks");
            customers[_userName].userName = _userName;
            customers[_userName].customerData = _customerData;
            customers[_userName].bank = msg.sender;
            customers[_userName].upVotes = 0;
            customers[_userName].downVotes = 0;
            customers[_userName].KYC_status = true;



    }
    //Remove Request
    function removeRequest(string calldata _userName) public{
        require(requests[_userName].bank != address(0),"No Such Customer Found!");
        delete requests[_userName];

    }

    //View Customer
    function viewCustomer(string memory  _userName)public view returns(string memory ,string memory ,uint ,uint ,address ) {
        require(customers[_userName].bank != address(0),"No Such Customer Found!");
        return(customers[_userName].userName,customers[_userName].customerData,customers[_userName].upVotes,customers[_userName].downVotes,customers[_userName].bank);
    }

    //Upvote Customers
    function upVoteKYCRequests(string memory _userName) public isAllowedToVote {
        require(customers[_userName].bank != address(0),"No Such Customer Found!");
        require(bankList[msg.sender].ethAddress != address(0),"Function Allowed only for Resgitered Banks");
        require(customers[_userName].bank != msg.sender,"You can't upvote as you only added this request"); //requesting bank cannot upvote for kyc as it has upvoted in start as default
        customers[_userName].upVotes += 1;
        
        KYC_statusCheck(_userName);
    }

    //Downvote Customers
    function downVoteKYCRequests(string memory _userName) public isAllowedToVote {
        require(customers[_userName].bank != address(0),"No Such Customer Found!");
        require(bankList[msg.sender].ethAddress != address(0),"Function Allowed only for Resgitered Banks");
        require(customers[_userName].bank != msg.sender,"You can't downvote as you only added this request"); //requesting bank cannot upvote for kyc as it has upvoted in start as default
        customers[_userName].downVotes += 1;

    //    if(customer[_userName].bankVoteMap)
        KYC_statusCheck(_userName);
    }

    // checking KYS conditions of a customer
    function KYC_statusCheck(string memory _userName) internal {
        
        if(customers[_userName].downVotes >= TotalNoOfBanks/3){
            customers[_userName].KYC_status =false;  
        }
        else if(customers[_userName].upVotes > customers[_userName].downVotes){
            customers[_userName].KYC_status = true;  
        }
        else{
            customers[_userName].KYC_status = true; 
        }

        if(customers[_userName].downVotes == TotalNoOfBanks - 1 ){
            bankList[customers[_userName].bank].isAllowedToVote = false;
        }
    }

    //Modify Customer
    function modifyCustomer( string memory  _userName,string memory  _newCustomerData) public {
        require(customers[_userName].bank == msg.sender,"No Such Customer Found!");
        //customers[_userName].userName = _userName;
        customers[_userName].customerData  = _newCustomerData;
        customers[_userName].bank = msg.sender;
        customers[_userName].KYC_status = true;
        customers[_userName].upVotes = 0;
        customers[_userName].downVotes = 0; 
        delete requests[_userName];

    }

    //Get Bank Complaints
    function viewComplaints(address _bankAddress) public view returns(uint){
        return(bankList[_bankAddress].downVotes);
    }

    //View Bank Details
    function viewBankDetails(address _bankAddress) public view returns(string memory Name,
        address ethAddress,
        string memory regNumber,
        uint downVotes,
        bool isAllowedToVote,
        uint KYCCount){
        return(bankList[_bankAddress].Name,bankList[_bankAddress].ethAddress,bankList[_bankAddress].regNumber,bankList[_bankAddress].downVotes,bankList[_bankAddress].isAllowedToVote,bankList[_bankAddress].KYCCount);
    }

    //Report Bank
    function reportABank(address _bankAddress) public{
        require(_bankAddress != msg.sender,"You can't vote for yourself");
        require(bankList[msg.sender].ethAddress != address(0),"Function Allowed only for Resgitered Banks");

        bankList[_bankAddress].downVotes += 1;


        if(bankList[_bankAddress].downVotes < TotalNoOfBanks/3){
            bankList[_bankAddress].isAllowedToVote = true;
        }
        else{
            bankList[_bankAddress].isAllowedToVote = false;
        }
    }

    //admin
    function addBank(string memory  _name,address _bankAddress,string memory  _regNumber)public isAdmin{
        bankList[_bankAddress].Name = _name;
        bankList[_bankAddress].ethAddress = _bankAddress;
        bankList[_bankAddress].regNumber = _regNumber;
        bankList[_bankAddress].isAllowedToVote = true;
        bankList[_bankAddress].KYCCount = 0 ; 
        TotalNoOfBanks += 1; 
    }

    function removeBank(address _bankAddress)public isAdmin{
        delete bankList[_bankAddress];
        TotalNoOfBanks -=1;
    }

    function ChangeVotingStatusOfBank(address _bankAddress) public isAdmin{
        bankList[_bankAddress].isAllowedToVote = !bankList[_bankAddress].isAllowedToVote;
    }

//modifiers

    modifier isAllowedToVote{
        require(bankList[msg.sender].isAllowedToVote == true,"You Are Not Allowed to Vote");
        _;
    }

    modifier isAdmin{
    require(admin == msg.sender,"YOU HAVE NO ACCESS TO THIS FUNCTION!");
    _;
    }




}