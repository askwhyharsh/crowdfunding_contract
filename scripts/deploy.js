// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//

const hre = require("hardhat");

async function main() {

  const Crowdfunding = await hre.ethers.getContractFactory("crowdfunding");
  const crowdfunding = await Crowdfunding.deploy();

  await crowdfunding.deployed();

  console.log("Crowdfunding project deployed to:", crowdfunding.address);
  let txn2 = await crowdfunding.returnAllProjects();

  console.log(txn2)
let contract1 = await crowdfunding.startProject("NewProject", "test", 2, 100 )
 console.log(contract1);
 
  let txn = await crowdfunding.returnAllProjects();

   console.log(txn)

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
