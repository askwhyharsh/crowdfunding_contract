//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0; 
//for remix
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol";
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol";
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";

// for hardhat 
import "hardhat/console.sol";
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';



contract sidekicks {
using SafeMath for uint256;
address payable owner;
// enum used for defining state of the funding

uint counterProjectID;
 
constructor() {  
owner = payable(msg.sender);
}
struct Project {
    // State variables
    uint  projectId;
    address payable  creator; // address of the fund raiser
   
    uint  totalSupport; // the current balance of the project or the fund raised balance 
    
    uint cryptoKicks; // total contributors of the campaign / project
   
   }

Project[] projects;

mapping(address=> uint[]) projectsOfAddress;


  struct Contributions {
      uint  projectId;
      mapping (address => uint)  contributions;
 
    }
   Contributions[] arrayContributors;

 

  // Event that will be emitted whenever funding will be received
    event cryptoKick(address sender, uint amount, uint projectID,uint currentTotal);
    // Event that will be emitted whenever the project request has been fullfilled
    event projectRegistered(address owner, uint projectID);

function startProject() public {

        projects.push(); // we will first push a empty struct  and then fill the detials
		arrayContributors.push(); // we will also push a empty struct of type contributions of anyone for keeping track of contributions of every project
        uint index = projects.length - 1;
       

        projects[index].projectId = counterProjectID; // project id given in increasing order
        
        projects[index].creator = payable(address(msg.sender));
        
       
        projects[index].totalSupport = 0;
    
       
        arrayContributors[index].projectId = counterProjectID; 
         projectsOfAddress[msg.sender].push(counterProjectID);                                   

        counterProjectID++;
        emit projectRegistered(msg.sender, counterProjectID);

        }

       


/** Function to fund a project.
      */
// in order to contribute,we will take the projectID to find the project which contributor wants to contribute to , also this function will be of payable type
    function contribute(uint _projectId) external payable returns(bool){
        require(msg.value != 0, "contribution can't be 0");
        projects[_projectId].creator.transfer(msg.value);
        projects[_projectId].totalSupport += msg.value;

       if(arrayContributors[_projectId].contributions[msg.sender] == 0 ) {
           projects[_projectId].cryptoKicks++;
       }

        arrayContributors[_projectId].contributions[msg.sender] += msg.value;
        emit cryptoKick(msg.sender, msg.value, _projectId, projects[_projectId].totalSupport);
        return true;

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
     
   
}