//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';


// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol";
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Counters.sol";
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol";
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/extensions/ERC721URIStorage.sol";


contract FundNFT is ERC721URIStorage {

    // counter starts at 0
    uint private _tokenId;
// we will take uri from the contract. make sure you have imported ERC721 and ERC721URIStorage from openzeppelin 
    constructor (address payable _addressToMint, string memory uri) ERC721("LIGHT", "LT") { 
      
     uint newItemId = _tokenId;

        _safeMint(_addressToMint, newItemId);
        
        _setTokenURI(newItemId, uri);

        _tokenId++;     
    
    }

}


contract Crowdfunding {
using SafeMath for uint256;
address payable owner;
// enum used for defining state of the funding
    enum State {
        Fundraising, // 0 in value
        Expired, // 1 in value
        Successful // 2 in value
    }

uint private treasury;

constructor() {
owner = payable(msg.sender);
}
struct Project {
    // State variables
    uint  projectId; // id of projects/campaigns (start from 0 )
    address payable  creator; // address of the fund raiser
    string  title; // title of the campaign
    string  description; // description of the campaign
    uint  amountGoal; // required to reach at least this much, else everyone gets refund
    uint  currentBalance; // the current balance of the project or the fund raised balance 
    uint  deadline; // the deadline till when project should get succesful - (in unix time)
    string  location; // Location of the creator/ fund raiser
    string  category; // category of the campaign
    string img; // the cover img of the campaign (ipfs link)
    State  state; // initialize on create with  state = State.Fundraising;
    uint noOfContributors; // total contributors of the campaign / project
    Request[] requests; // total withdrawal requests created by the fund raiser
    uint  numRequests; // Number of requests of withdrawal created by fund raiser
    
   }

struct Request {
        uint requestId; // Id of request created for withdrawal (will start from 0)
        string desc; // Description of the request
        uint value; // the value or amount to withdraw by the campaign creator 
        address payable receipient; // addres to withdrawa the funds
        bool status; // status of withdrawal (false => means not completed) true => means completed the withdrawal
        uint noOfVoter; // number of Voters who voted for withdrawal for this request
        
    }


  struct Contributions {
      uint  projectId;
      mapping (address => uint)  contributions; // contributions of particular address
    }

    struct Voters {
       uint requestId;
       mapping (address=>bool) voters; // a mapping to keep track of which address has voted for withdrawal and which haven't
    
    }
 

   Voters[] arrayVoters;
   Contributions[] arrayContributors;
   

   uint counterProjectID;


   Project[] projects;

  

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
        string memory _category, string memory _img) public {

        projects.push(); // we will first push a empty struct  and then fill the detials
				arrayContributors.push(); // we will also push a empty struct of type contributions of anyone for keeping track of contributions of every project
        uint index = projects.length - 1;
       

        projects[index].projectId = counterProjectID; // project id given in increasing order
        
        projects[index].creator = payable(address(msg.sender));
        projects[index].title = _projectTitle;
        projects[index].description = _projectDesc;
        projects[index].amountGoal = _goalAmount;
        projects[index].deadline = block.timestamp.add(_fundRaisingDeadline.mul(60)); // we need to add the current time in the deadline given as deadline (as deadline given will be difference in current time and end time)
        projects[index].currentBalance = 0;
        projects[index].location = _location;
        projects[index].category = _category;
        projects[index].img = _img;
        projects[index].state = State.Fundraising;
        
        // we will also assign project id to arraycontributor
      
				arrayContributors[index].projectId = counterProjectID; 
    

        counterProjectID++;


        }

  /**  Function to change the project state depending on conditions.
      */
    function checkIfFundingCompleteOrExpired(uint _projectId) public {
      // if current balance is more than or equal to the goal, project status should change to succesfull
        if (projects[_projectId].currentBalance >= projects[_projectId].amountGoal) {
            projects[_projectId].state = State.Successful;

           
            
       // if time when this function was called is more than the deadline then project status should change to expired

        
        } else if (block.timestamp > projects[_projectId].deadline)  {
            projects[_projectId].state = State.Expired;
         
          
        }
         // else should remain in fundraising status
        else {
             projects[_projectId].state = State.Fundraising;
           

        }
       
    }


/** Function to fund a project.
      */
// in order to contribute,we will take the projectID to find the project which contributor wants to contribute to , also this function will be of payable type
    function contribute(uint _projectId) external payable returns(bool){
         require(msg.sender != projects[_projectId].creator, "Project creator can't contribute");
          checkIfFundingCompleteOrExpired(_projectId); // check if funding completed or expired or not
          require( projects[_projectId].state == State.Fundraising, "expired or succesful"); 
      // now we will add the funds to the current balance of this particular project
           projects[_projectId].currentBalance = projects[_projectId].currentBalance.add(msg.value);
     // let's add the contribution record of the contributor of this project 
           arrayContributors[_projectId].contributions[msg.sender] = arrayContributors[_projectId].contributions[msg.sender].add(msg.value);
      // let's emit our event     
           emit FundingReceived(msg.sender, msg.value, projects[_projectId].currentBalance);
      // now will will check if the contributor has already funded once or ist it the first time, if this is the first time we will reward him NFT and also increase the number of Contributor count
         if (arrayContributors[_projectId].contributions[msg.sender] == 0) {
         projects[_projectId].noOfContributors++;
        // we will write the FundNFT contract in the end, but here we will have to pass the address of the contributor and the URI of the NFT to reward for contributing
        new FundNFT( payable (address (msg.sender)), "https://gateway.pinata.cloud/ipfs/QmUa2KQr7xmuFA9VCMLKbGFDBGwXnEroHxoFNVahs49HtQ"); 
         checkIfFundingCompleteOrExpired(_projectId);  // we are revoking this function so if after this contribution if the state changes it will update that
        }
         else {
         
          checkIfFundingCompleteOrExpired(_projectId); // we are revoking this function so if after this contribution if the state changes it will update that

         }
        return true;

    }


/** Function to refund donated amount when a project expires.
      */
    function getRefund(uint _projectId) public returns (bool) {
     // first of all we will check if the project is expired or not  
         checkIfFundingCompleteOrExpired(_projectId);
     // project should be in expired state in order for contributors to get their refund
        require( projects[_projectId].state == State.Expired , "project not expired, can't refund");
        require(arrayContributors[_projectId].contributions[msg.sender] > 0, "you have not contributed to this project");


        uint amountToRefund = arrayContributors[_projectId].contributions[msg.sender];
     // let's make contribution of msg.sender to 0 
       arrayContributors[_projectId].contributions[msg.sender] = 0;
         address payable sender = payable(msg.sender);
        if (!sender.send(amountToRefund)) {
     // if the .send returns false, this will be again restore the amount in the contribution of msg.sender
           arrayContributors[_projectId].contributions[msg.sender] = amountToRefund;
            return false;
        } else {
      // if the transaction of .send is successful, it will run this - reducing the current balance of the campaign
            projects[_projectId].currentBalance = projects[_projectId].currentBalance.sub(amountToRefund);
        }
         return true;
    }



function getDetails(uint _projectId) public view returns (Project memory) {
    return projects[_projectId];
  
    }



// function to create request for payout of certain amout of money for some requirement

    function createRequest( uint _projectId, string memory _desc, uint _value, address payable _receipient) public  {
// we will check if the project is successful or not. Also only creator can create a withdrawal request
        require( projects[_projectId].state == State.Successful, "project expired or successful can't create request");
        require(msg.sender == projects[_projectId].creator, "only manager can create Request");
        require(_value <= projects[_projectId].currentBalance, "withdrawal is more than balance");

// we will push a empty struct of Request type in project  
        projects[_projectId].requests.push();
// we will push a empty strcut of Voters Struct type in voters to keep track of who voted and who haven't
        arrayVoters.push();
// we will create num for id/index
        uint num = projects[_projectId].requests.length - 1;

      // assign values to request that we pushed in the project   

         projects[_projectId].requests[num].desc = _desc;
         projects[_projectId].requests[num].value = _value;
         projects[_projectId].requests[num].receipient = _receipient;
         projects[_projectId].requests[num].requestId = num;
     // we will now increment number of request (numRequest)
        projects[_projectId].numRequests++;
        

    }



// function to send payout to particular address if the vote is won by creator (private function)

    function sendPayout (uint _projectId, address payable _address, uint _value, uint _requestNo) private  returns(bool) {
         Request storage thisRequest = projects[_projectId].requests[_requestNo]; 
         require(thisRequest.noOfVoter >= projects[_projectId].noOfContributors.div(2), "condition not fullfilled yet");
        // _address.transfer(_value);
        uint amountToTransfer = _value*97/100;
        uint fee = _value*3/100; // we will take 3% fee on withdrawal 
        treasury += fee; // add the fee to treasury
         if (_address.send(amountToTransfer) ) {
            emit CreatorPaid(_address);
            owner.transfer(fee); 
            projects[_projectId].currentBalance = projects[_projectId].currentBalance.sub(_value);
            
            return (true);
        } else {
             return (false);
        }
    }



 // function to add vote to particular request 
    function voteRequest(uint _projectId, uint _requestNo) public {
   
        require( projects[_projectId].state == State.Successful, "project expired or successful can't create request");
        require(arrayContributors[_projectId].contributions[msg.sender] > 0, "you must be a contributor to vote");
       
        
     // checking if the voter has already voted or not
        require (arrayVoters[_projectId].voters[msg.sender] == false, "you have already voted");
     // increament number of voter
        projects[_projectId].requests[_requestNo].noOfVoter++;
      // mark vote of msg.sender to true
       arrayVoters[_projectId].voters[msg.sender] = true;
      // check if voting won or not, if won do the payout and change the done status to true

        if(projects[_projectId].requests[_requestNo].noOfVoter*2 >= projects[_projectId].noOfContributors && projects[_projectId].requests[_requestNo].value <= projects[_projectId].currentBalance) {
        projects[_projectId].requests[_requestNo].status = true;
        sendPayout(_projectId, projects[_projectId].requests[_requestNo].receipient, projects[_projectId].requests[_requestNo].value, _requestNo);    
        }
        
    }


   function getContractBalance() public view returns(uint) {
        return address(this).balance;
    }

    function getAllProjects() public view returns (Project[] memory) {
     return projects;
           
    }

    function myContributions(uint _projectId, address _address) public view returns (uint) {
      return arrayContributors[_projectId].contributions[_address];
    }
     
    function getAllRequests(uint _projectID) public view returns (Request[] memory) {
    return projects[_projectID].requests;
    }


   
}

