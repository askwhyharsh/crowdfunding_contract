// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//

const hre = require("hardhat");

async function main() {

  const Crowdfunding = await hre.ethers.getContractFactory("Project");
  const crowdfunding = await Crowdfunding.deploy("0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266", "NewProject", "test", 2, 100 );

  await crowdfunding.deployed();

  console.log("Crowdfunding project deployed to:", crowdfunding.address);
  let txn = await crowdfunding.getDetails();
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
