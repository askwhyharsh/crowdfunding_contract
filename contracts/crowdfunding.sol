//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';



contract Project {
    using SafeMath for uint256;
    
    // enum used for defining state of the funding
    enum State {
        Fundraising,
        Expired,
        Successful
    }

    // State variables
    uint public projectId;
    address payable public creator;
    uint public amountGoal; // required to reach at least this much, else everyone gets refund
    uint public completeAt;
    uint256 public currentBalance;
    uint public deadline;
    string public title;
    string public description;
    State public state = State.Fundraising; // initialize on create
    mapping (address => uint) public contributions;

    uint public minimumContribution;
    // variables for voting of decisions

    uint public noOfContributors;
    struct Request {
       
        string desc; 
        uint value;
        address payable receipient; 
        bool status;
        uint noOfVoter;
        mapping (address=>bool) voters;
    }

    mapping (uint => Request)  public requests;
    uint public numRequests;

    

    // Event that will be emitted whenever funding will be received
    event FundingReceived(address contributor, uint amount, uint currentTotal);
    // Event that will be emitted whenever the project starter has received the funds
    event CreatorPaid(address recipient);

    // Modifier to check current state
    modifier inState(State _state) {
        require(state == _state);
        _;
    }


    constructor
    (   uint projectID,
        address payable _projectStarter,
        string memory _projectTitle,
        string memory _projectDesc,
        uint _fundRaisingDeadline,
        uint _goalAmount
    ) {
        projectId = projectID;
        creator = _projectStarter;
        title = _projectTitle;
        description = _projectDesc;
        amountGoal = _goalAmount;
        deadline = _fundRaisingDeadline;
        minimumContribution = 1000 wei;
        currentBalance = 0;
    }

    /** Function to fund a project.
      */
    function contribute() external inState(State.Fundraising) payable returns(bool){
        require(msg.sender != creator, "Project creator can't contribute");
        require(msg.value> minimumContribution, "Minimum Contribution should be 1000 wei");
        contributions[msg.sender] = contributions[msg.sender].add(msg.value);
        currentBalance = currentBalance.add(msg.value);
        noOfContributors++;
        emit FundingReceived(msg.sender, msg.value, currentBalance);
        checkIfFundingCompleteOrExpired();
        return true;

    }

    /**  Function to change the project state depending on conditions.
      */
    function checkIfFundingCompleteOrExpired() public {
        if (currentBalance >= amountGoal) {
            state = State.Successful;
            // payOut();
        } else if (block.timestamp > deadline)  {
            state = State.Expired;
        }
        completeAt = block.timestamp;
    }

    /** Function to refund donated amount when a project expires.
      */
    function getRefund() public inState(State.Expired) returns (bool) {
        require(contributions[msg.sender] > 0);

        uint amountToRefund = contributions[msg.sender];
        contributions[msg.sender] = 0;
         address payable sender = payable(msg.sender);
        if (!sender.send(amountToRefund)) {
            contributions[msg.sender] = amountToRefund;
            return false;
        } else {
            currentBalance = currentBalance.sub(amountToRefund);
        }

        return true;
    }

    // /** Function to get specific information about the project.
    //   * Returns all the project's details
    //   */
    function getDetails() public view returns 
    (
        address payable projectStarter,
        string memory projectTitle,
        string memory projectDesc,
        uint256 deadLine,
        State currentState,
        uint256 currentAmount,
        uint256 goalAmount
    ) {
        projectStarter = creator;
        projectTitle = title;
        projectDesc = description;
        deadLine = deadline;
        currentState = state;
        currentAmount = currentBalance;
        goalAmount = amountGoal;
    }

// function to create request for payout of cetrain amout of money for some requirement

    function createRequest( string memory _desc, uint _value, address payable _receipient) public inState(State.Successful) returns(bool){
        require(msg.sender == creator, "only manager can create Request");
        require(_value <= currentBalance);

        Request storage newRequest = requests[numRequests];
        numRequests++;
        newRequest.desc = _desc;
        newRequest.value = _value;
        newRequest.receipient = _receipient;
        newRequest.status = false;
        newRequest.noOfVoter = 0;
        return true;
    }

    // function to add vote to particular request 
    function voteRequest(uint _requestNo) public returns(bool, uint){
        require(contributions[msg.sender] > 0, "you must be a contributor to vote");
        Request storage thisRequest = requests[_requestNo];
        require(thisRequest.noOfVoter < noOfContributors.div(2));
        require (thisRequest.voters[msg.sender] == false, "you have already voted");
        thisRequest.noOfVoter++;
        thisRequest.voters[msg.sender] = true;
        // return thisRequest.noOfVoter;
        if(thisRequest.noOfVoter >= noOfContributors.div(2)) {
            thisRequest.status = true;
            sendPayoutRequest(thisRequest.receipient,thisRequest.value, _requestNo);
       
        }
        else {
           
        }
        return (false, thisRequest.noOfVoter);

    } 
    // function to send payout to particular address if the vote is won by creator

    function sendPayoutRequest(address payable _address, uint _value, uint _requestNo) public inState(State.Successful) returns(bool, uint) {
         Request storage thisRequest = requests[_requestNo];
         require(thisRequest.noOfVoter >= noOfContributors.div(2), "condition not fullfilled yet");
        // _address.transfer(_value);
         if (_address.send(_value)) {
            emit CreatorPaid(_address);
            currentBalance = currentBalance.sub(_value);
            return (true, thisRequest.noOfVoter);
        } else {
             return (false, thisRequest.noOfVoter);
        }
    }

    function getContractBalance() public view returns(uint) {
        return address(this).balance;
    }
    function getNoOfVoters(uint _requestId) view public returns(uint) {
        Request storage thisRequest = requests[_requestId];
        return thisRequest.noOfVoter;
    }
}





// Contract to run/execute/create new project and add it to an array list on above contract





contract crowdfunding  {
    using SafeMath for uint256;

    // List of existing projects
    Project[] private projects;
    uint projectID;

// Event that will be emitted whenever a new project is started
    event ProjectStarted(
        address contractAddress,
        address projectStarter,
        string projectTitle,
        string projectDesc,
        uint256 deadline,
        uint256 goalAmount
    );
    // Function to start a new project.


function startProject(
        string memory title,
        string memory description,
        uint durationInDays,
        uint amountToRaise
    ) external {
        uint raiseUntil = block.timestamp.add(durationInDays.mul(1 days));
       
        Project newProject = new Project( projectID ,payable(msg.sender), title, description, raiseUntil, amountToRaise);
        projects.push(newProject);
        projectID++;

        emit ProjectStarted(

            address(newProject),
            msg.sender,
            title,
            description,
            raiseUntil,
            amountToRaise
        );
    }        

//   Function to get all projects' contract addresses.
    //   A list of all projects' contract addreses
      
    function returnAllProjects() external view returns(Project[] memory){
        return projects;
    }

    function returnSpecificProject(uint _projectID) public view returns(Project) {
        return projects[_projectID];
    }


}

