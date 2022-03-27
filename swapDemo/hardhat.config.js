require("@nomiclabs/hardhat-waffle");
// const networkJson = require('./utils/network.json')
let dotenv = require('dotenv')
dotenv.config({path:"./utils/.env"})

const privateKey = process.env.PrivateKey


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


module.exports = {
  solidity: {
    compilers : [{
      version: "0.5.16",
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        }
      }
    },
    {
      version: "0.6.6",
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        }
      }
    },
    {
      version: "0.6.12",
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        }
      }
    },
    {
      version: "0.7.6",
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        }
      }
    },
    {
      version: "0.8.0",
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        }
      }
    }]
  },
  defaultNetwork: "ropsten",
  networks : {
    hardhat: {
    },
    ropsten: {
      url: "https://ropsten.infura.io/v3/eec9cf2db0da438f98c6010fd65a20c1",
      accounts: [privateKey]
    }
  }
};