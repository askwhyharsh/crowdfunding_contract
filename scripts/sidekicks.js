// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//

const { ethers } = require("hardhat");
const hre = require("hardhat");

async function main() {
  const [owner, creator, contributor] = await ethers.getSigners();
  // const Crowdfunding = await hre.ethers.getContractFactory("crowdfunding");
  // const crowdfunding = await Crowdfunding.deploy();
  // await crowdfunding.deployed();

  // const usdc = await hre.ethers.getContractFactory("USDC");
  // const USDC = await usdc.connect(contributor).deploy();

  // await USDC.deployed();

  const throwitincontract = await hre.ethers.getContractFactory("sidekicks");
  const ThrowItIn = await throwitincontract.deploy();

  await ThrowItIn.deployed();

  console.log("sidekicks project deployed to:", ThrowItIn.address);
  //   console.log("USDC address ", USDC.address);
  //   console.log("balance of usdc", await USDC.connect(contributor).balanceOf(contributor.address));

  //   let txn2 = await ThrowItIn.getAllProjects();

  //   console.log(txn2)
  //   // string memory _projectTitle,
  //   // string memory _projectDesc,
  //   // string memory _website,
  //   // string memory _twitter,
  //   // string memory _discord,
  //   // uint _fundRaisingDeadline,
  //   // uint _goalAmount,
  //   // string memory _location,
  //   // string memory _category, string memory _img, string memory _uri
  // let start1 = await ThrowItIn.connect(creator).startProject("NewProject", 2, 100,  "uri" );

  //    start1.wait();

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

// deployed already address = 0x84D23022287e347f21d51be039D058545177d407
