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
    address payable public owner;

    function changeOwner(address payable _newOwner) external {
        require( payable(msg.sender) == owner, "only owner can change owner");
        owner = _newOwner;
    }
    // enum used for defining state of the funding
    enum State {
        Fundraising,
        Expired,
        Successful
    }
    struct Request {
        uint requestId;
        string desc; 
        uint value;
        address payable receipient; 
        bool status;
        uint noOfVoter;
        mapping (address=>bool) voters;
    }
    struct RequestDetails {
        uint requestId;
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
    string img;
    string uri;
    State  state; // initialize on create  stae = State.Fundraising;
    mapping (address => uint)  contributions;
    uint noOfContributors;
    Request[] requests;
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
    string img;
    string uri;
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
        string memory _category, string memory _img, string memory _uri) public {
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
        projects[index].img = _img;
        projects[index].uri = _uri;
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
        projectsR[index].img = _img;
        projectsR[index].uri = _uri;
        projectsR[index].state = State.Fundraising;
    

        counterProjectID++;


        }


    /** Function to fund a project.
      */
    function contribute(uint _projectId) external payable returns(bool){
        require(msg.sender != projects[_projectId].creator, "Project creator can't contribute");
        checkIfFundingCompleteOrExpired(_projectId);
        require( projects[_projectId].state == State.Fundraising, "expired or succesful"); 
       
        projects[_projectId].currentBalance = projects[_projectId].currentBalance.add(msg.value);
        projects[_projectId].noOfContributors++;


        projectsR[_projectId].noOfContributors++;
        projectsR[_projectId].currentBalance = projectsR[_projectId].currentBalance.add(msg.value);

        // emit FundingReceived(msg.sender, msg.value, currentBalance);
         if (projects[_projectId].contributions[msg.sender] == 0) {
        new FundNFT( payable (address (msg.sender)),  projects[_projectId].uri); 
        projects[_projectId].contributions[msg.sender] = projects[_projectId].contributions[msg.sender].add(msg.value);
        checkIfFundingCompleteOrExpired(_projectId);
         }
         else {
          projects[_projectId].contributions[msg.sender] = projects[_projectId].contributions[msg.sender].add(msg.value);
          checkIfFundingCompleteOrExpired(_projectId);

         }
        return true;

    }

    /**  Function to change the project state depending on conditions.
      */
    function checkIfFundingCompleteOrExpired(uint _projectId) public {
        if (projects[_projectId].currentBalance >= projects[_projectId].amountGoal) {
            projects[_projectId].state = State.Successful;

            projectsR[_projectId].state = State.Successful;
            

        
        } else if (block.timestamp > projects[_projectId].deadline)  {
            projects[_projectId].state = State.Expired;
            projectsR[_projectId].state = State.Expired;
          
        }
        else {
             projects[_projectId].state = State.Fundraising;
            projectsR[_projectId].state = State.Fundraising;

        }
       
    }


    /** Function to refund donated amount when a project expires.
      */
    function getRefund(uint _projectId) public returns (bool) {
         checkIfFundingCompleteOrExpired(_projectId);
        require( projects[_projectId].state == State.Expired, "project not expired, can't refund");
        require(projects[_projectId].contributions[msg.sender] > 0, "you have not contributed to this project");


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

    function createRequest( uint _projectId, string memory _desc, uint _value, address payable _receipient) public  {
        require( projects[_projectId].state == State.Successful, "project expired or successful can't create request");
        require(msg.sender == projects[_projectId].creator, "only manager can create Request");
        require(_value <= projects[_projectId].currentBalance, "withdrawal is more than balance");
        projects[_projectId].requests.push();
        projectsR[_projectId].requestsDetails.push();
        uint num = projects[_projectId].requests.length - 1;
        projectsR[_projectId].requestsDetails[num];

         projects[_projectId].requests[num].desc = _desc;
         projects[_projectId].requests[num].value = _value;
         projects[_projectId].requests[num].receipient = _receipient;
         projects[_projectId].requests[num].requestId = num;

        projectsR[_projectId].requestsDetails[num].desc = _desc;
        projectsR[_projectId].requestsDetails[num].value = _value;
        projectsR[_projectId].requestsDetails[num].receipient = _receipient;
        projectsR[_projectId].requestsDetails[num].requestId = num;
        
        projects[_projectId].numRequests++;
        projectsR[_projectId].numRequests++;

    }

    // function to add vote to particular request 
    function voteRequest(uint _projectId, uint _requestNo) public {
         require( projects[_projectId].state == State.Successful, "project expired or successful can't create request");
        require(projects[_projectId].contributions[msg.sender] > 0, "you must be a contributor to vote");

        // Request storage thisRequest = projects[_projectId].requests[_requestNo];
        // RequestDetails storage thisRequestDetails = projectsR[_projectId].requestsDetails[_requestNo];

        require (projects[_projectId].requests[_requestNo].voters[msg.sender] == false, "you have already voted");
        projects[_projectId].requests[_requestNo].noOfVoter++;
        projectsR[_projectId].requestsDetails[_requestNo].noOfVoter++;

        projects[_projectId].requests[_requestNo].voters[msg.sender] = true;
        // return thisRequest.noOfVoter;
        if(projects[_projectId].requests[_requestNo].noOfVoter*2 >= projects[_projectId].noOfContributors && projectsR[_projectId].requestsDetails[_requestNo].value <= projects[_projectId].currentBalance) {
        projects[_projectId].requests[_requestNo].status = true;
        projectsR[_projectId].requestsDetails[_requestNo].status = true;
        sendPayoutRequest(_projectId, projects[_projectId].requests[_requestNo].receipient, projects[_projectId].requests[_requestNo].value, _requestNo);    
        }
        else {
            
         
        }
        
    } 
    // function to send payout to particular address if the vote is won by creator

    function sendPayoutRequest(uint _projectId, address payable _address, uint _value, uint _requestNo) private  returns(bool) {
         Request storage thisRequest = projects[_projectId].requests[_requestNo]; 
         require(thisRequest.noOfVoter >= projects[_projectId].noOfContributors.div(2), "condition not fullfilled yet");
        // _address.transfer(_value);
        uint amountToTransfer = _value*97/100;
        uint fee = _value*3/100;
         if (_address.send(amountToTransfer) ) {
            emit CreatorPaid(_address);
            owner.transfer(fee);
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

    function getAllProjects() public view returns (ProjectR[] memory) {
     return projectsR;
           
    }

    function myContributions(uint _projectId, address _address) public view returns (uint) {
      return projects[_projectId].contributions[_address];
    }
     
    function getAllRequests(uint _projectID) public view returns (RequestDetails[] memory) {
    return projectsR[_projectID].requestsDetails;
    }


}





contract FundNFT is ERC721URIStorage {



using Counters for Counters.Counter;
    // counter starts at 0
    Counters.Counter private _tokenIds;

    constructor (address payable _addressToMint, string memory uri) ERC721("LIGHT", "LT") { 
      
     uint newItemId = _tokenIds.current();

        _safeMint(_addressToMint, newItemId);
        
        _setTokenURI(newItemId, uri);

        _tokenIds.increment();     
    
    }

}


