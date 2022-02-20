require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");


const dotenv = require("dotenv")
dotenv.config()

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {

  defaultNetwork: "hardhat",
  networks: {
      hardhat: {

      },
      matic: {
        url: process.env.ALCHEMY_URL_MATIC,
        accounts: [`0x${process.env.PRIVATE_KEY}`]
      }
  },
  solidity: {
    version: "0.8.4",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  etherscan: {
    // Your API key for Etherscan - matic
    // Obtain one at https://etherscan.io/
    apiKey: "E3ZH5H64P4IJQ7KI78R582I43UA6PEFFNK"
  }

};
