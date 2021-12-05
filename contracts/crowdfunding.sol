//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';

// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol";
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Counters.sol";
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol";
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/extensions/ERC721URIStorage.sol";


contract projectContract {
    using SafeMath for uint256;
    
    // enum used for defining state of the funding
    enum State {
        Fundraising,
        Expired,
        Successful
    }
    struct Request {
        
        string desc; 
        uint value;
        address payable receipient; 
        bool status;
        uint noOfVoter;
        mapping (address=>bool) voters;
    }
    struct RequestDetails {
        
        string desc; 
        uint value;
        address payable receipient; 
        bool status;
        uint noOfVoter;
    }
   struct Project {
    // State variables
    uint  projectId;
    address payable  creator;
    string  title;
    string  description;
    uint  amountGoal; // required to reach at least this much, else everyone gets refund
    uint  currentBalance;
    uint  deadline;
    string  location;
    string  category;
    
    State  state; // initialize on create  stae = State.Fundraising;
    mapping (address => uint)  contributions;
    uint noOfContributors;
    mapping (uint => Request)  requests;
    uint  numRequests;
   
   }
   struct ProjectR {
    // State variables
    uint  projectId;
    address payable  creator;
    string  title;
    string  description;
    uint  amountGoal; // required to reach at least this much, else everyone gets refund
    uint  currentBalance;
    uint  deadline;
    string  location;
    string  category;
    State  state; 
    uint noOfContributors;
    uint  numRequests;
    RequestDetails[] requestsDetails;
   
   }

   uint counterProjectID;


   Project[] projects;

   ProjectR[] public projectsR;




    

    // Event that will be emitted whenever funding will be received
    event FundingReceived(address contributor, uint amount, uint currentTotal);
    // Event that will be emitted whenever the project request has been fullfilled
    event CreatorPaid(address recipient);

    

    

 
function startProject(
        string memory _projectTitle,
        string memory _projectDesc,
        uint _fundRaisingDeadline,
        uint _goalAmount,
        string memory _location,
        string memory _category) public {
        projects.push();
        uint index = projects.length - 1;
        

        projects[index].projectId = counterProjectID;
        
        projects[index].creator = payable(address(msg.sender));
        projects[index].title = _projectTitle;
        projects[index].description = _projectDesc;
        projects[index].amountGoal = _goalAmount;
        projects[index].deadline = block.timestamp.add(_fundRaisingDeadline.mul(60));
        projects[index].currentBalance = 0;
        projects[index].location = _location;
        projects[index].category = _category;
        projects[index].state = State.Fundraising;

        // we will push these things in ProjectR as well so that we can call them from outside function (as we can't call projects[] because it is a struct that contains nested mapping)
        projectsR.push();
        projectsR[index].projectId = counterProjectID;
        projectsR[index].creator = payable(address(msg.sender));
        projectsR[index].title = _projectTitle;
        projectsR[index].description = _projectDesc;
        projectsR[index].amountGoal = _goalAmount;
        projectsR[index].deadline = block.timestamp.add(_fundRaisingDeadline.mul(60));
        projectsR[index].currentBalance = 0;
        projectsR[index].location = _location;
        projectsR[index].category = _category;
        projectsR[index].state = State.Fundraising;

        counterProjectID++;


        }


    /** Function to fund a project.
      */
    function contribute(uint _projectId) external payable returns(bool){
        require(msg.sender != projects[_projectId].creator, "Project creator can't contribute");
        checkIfFundingCompleteOrExpired(_projectId);
        require( projects[_projectId].state == State.Fundraising, "project expired or succesful can't contribute");
        projects[_projectId].contributions[msg.sender] = projects[_projectId].contributions[msg.sender].add(msg.value);
        projects[_projectId].currentBalance = projects[_projectId].currentBalance.add(msg.value);
        projects[_projectId].noOfContributors++;


        projectsR[_projectId].noOfContributors++;
        projectsR[_projectId].currentBalance = projectsR[_projectId].currentBalance.add(msg.value);


        // emit FundingReceived(msg.sender, msg.value, currentBalance);
        new FundNFT( payable (address (msg.sender)) ); 
         checkIfFundingCompleteOrExpired(_projectId);
        return true;

    }

    /**  Function to change the project state depending on conditions.
      */
    function checkIfFundingCompleteOrExpired(uint _projectId) public {
        if (projects[_projectId].currentBalance >= projects[_projectId].amountGoal) {
            projects[_projectId].state = State.Successful;

            projectsR[_projectId].state = State.Successful;

        // payOut();
        } else if (block.timestamp > projects[_projectId].deadline)  {
            projects[_projectId].state = State.Expired;
            projectsR[_projectId].state = State.Expired;
        }
       
    }


    /** Function to refund donated amount when a project expires.
      */
    function getRefund(uint _projectId) public returns (bool) {
         checkIfFundingCompleteOrExpired(_projectId);
        require( projects[_projectId].state == State.Expired, "project not expired, can't refund");
        require(projects[_projectId].contributions[msg.sender] > 0);


        uint amountToRefund = projects[_projectId].contributions[msg.sender];
        projects[_projectId].contributions[msg.sender] = 0;
         address payable sender = payable(msg.sender);
        if (!sender.send(amountToRefund)) {
            projects[_projectId].contributions[msg.sender] = amountToRefund;
            return false;
        } else {
            projects[_projectId].currentBalance = projects[_projectId].currentBalance.sub(amountToRefund);
            projectsR[_projectId].currentBalance = projectsR[_projectId].currentBalance.sub(amountToRefund);
        }

        return true;
    }

    // /** Function to get specific information about the project.
    //   * Returns all the project's details
    //   */
    function getDetails(uint _projectId) public view returns (ProjectR memory) {
    return projectsR[_projectId];

    }

// function to create request for payout of cetrain amout of money for some requirement

    function createRequest( uint _projectId, string memory _desc, uint _value, address payable _receipient) public  returns(bool){
        require( projects[_projectId].state == State.Successful, "project expired or successful can't create request");
        require(msg.sender == projects[_projectId].creator, "only manager can create Request");
        require(_value <= projects[_projectId].currentBalance);
        uint num = projects[_projectId].numRequests;
        Request storage newRequest = projects[_projectId].requests[num];
        RequestDetails storage newRequestDetails = projectsR[_projectId].requestsDetails[num];
        projects[_projectId].numRequests++;
        projectsR[_projectId].numRequests++;

        newRequest.desc = _desc;
        newRequest.value = _value;
        newRequest.receipient = _receipient;
        newRequest.status = false;
        newRequest.noOfVoter = 0;

        newRequestDetails.desc = _desc;
        newRequestDetails.value = _value;
        newRequestDetails.receipient = _receipient;
        newRequestDetails.status = false;
        newRequestDetails.noOfVoter = 0;

        return true;
    }

    // function to add vote to particular request 
    function voteRequest(uint _projectId, uint _requestNo) public returns(bool, uint){
         require( projects[_projectId].state == State.Successful, "project expired or successful can't create request");
        require(projects[_projectId].contributions[msg.sender] > 0, "you must be a contributor to vote");

        Request storage thisRequest = projects[_projectId].requests[_requestNo];
        RequestDetails storage thisRequestDetails = projectsR[_projectId].requestsDetails[_requestNo];

        require(thisRequest.noOfVoter < projects[_projectId].noOfContributors.div(2));
        require (thisRequest.voters[msg.sender] == false, "you have already voted");
        thisRequest.noOfVoter++;
        thisRequestDetails.noOfVoter++;

        thisRequest.voters[msg.sender] = true;
        // return thisRequest.noOfVoter;
        if(thisRequest.noOfVoter >= projects[_projectId].noOfContributors.div(2)) {
        thisRequest.status = true;
        thisRequestDetails.status = true;
        sendPayoutRequest(_projectId, thisRequest.receipient, thisRequest.value, _requestNo);    
        }
        else {
         
        }
        return (false, thisRequest.noOfVoter);
        
    } 
    // function to send payout to particular address if the vote is won by creator

    function sendPayoutRequest(uint _projectId, address payable _address, uint _value, uint _requestNo) private  returns(bool) {
         Request storage thisRequest = projects[_projectId].requests[_requestNo]; 
         require(thisRequest.noOfVoter >= projects[_projectId].noOfContributors.div(2), "condition not fullfilled yet");
        // _address.transfer(_value);
         if (_address.send(_value)) {
            emit CreatorPaid(_address);
            projects[_projectId].currentBalance = projects[_projectId].currentBalance.sub(_value);
            projectsR[_projectId].currentBalance = projectsR[_projectId].currentBalance.sub(_value);
            return (true);
        } else {
             return (false);
        }
    }

    function getContractBalance() public view returns(uint) {
        return address(this).balance;
    }
    function getNoOfVoters(uint _projectId, uint _requestId) view public returns(uint) {
        Request storage thisRequest = projects[_projectId].requests[_requestId]; 
        return thisRequest.noOfVoter;    
    }

    function getAlProjects() public view returns (ProjectR[] memory) {
     return projectsR;
           
    }

    function myContributions(uint _projectId) public view returns (uint) {
      return projects[_projectId].contributions[msg.sender];
    }
     
    function getAllRequests(uint _projectID) public view returns (RequestDetails[] memory) {
    return projectsR[_projectID].requestsDetails;
    }


}





contract FundNFT is ERC721URIStorage {



using Counters for Counters.Counter;
    // counter starts at 0
    Counters.Counter private _tokenIds;

    constructor (address payable _addressToMint) ERC721("KIRA", "KIRA") { 
      
     uint newItemId = _tokenIds.current();

        _safeMint(_addressToMint, newItemId);
        
        _setTokenURI(newItemId, "https://jsonkeeper.com/b/4ES8");

        _tokenIds.increment();     
    
    }

}

