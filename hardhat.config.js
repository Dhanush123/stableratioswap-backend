require("@nomiclabs/hardhat-waffle");
require('dotenv').config();

// Go to https://www.alchemyapi.io, sign up, create
// a new App in its dashboard, and replace "KEY" with its key
const ALCHEMY_API_KEY = process.env.ALCHEMY_API_KEY;

// Replace this private key with your Kovan account private key
// To export your private key from Metamask, open Metamask and
// go to Account Details > Export Private Key
// Be aware of NEVER putting real Ether into testing accounts
const KOVAN_PRIVATE_KEY = process.env.KOVAN_PRIVATE_KEY;

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async () => {
  const accounts = await ethers.getSigners();

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
  solidity: {
    compilers: [
      {
        version: "0.6.8"
      },
      {
        version: "0.6.12"
      },
      {
        version: "0.5.0"
      },
      {
        version: "0.6.6"
      }
    ],
    settings: {
      outputSelection: {
        "*": {
          "*": [
            "storageLayout",
            "evm.bytecode.object",
            "evm.deployedBytecode.object",
            "abi",
            "evm.bytecode.sourceMap",
            "evm.deployedBytecode.sourceMap",
            "metadata"
          ],
          "": ["ast"]
        }
      },
      // outputSelection: {
      //   "*": {
      //       "*": ["storageLayout"],
      //   },
      // },
    },
    settings: {
      optimizer: {
        enabled: true,
        runs: 999999
      }
    }
  },
  networks: {
    hardhat: {
      chainId: 31337
    },
    kovan: {
      // url: `https://eth-kovan.alchemyapi.io/v2/${ALCHEMY_API_KEY}`,
      url: `https://kovan.infura.io/v3/${process.env.REACT_APP_KOVAN_INFURA_KEY}`,
      accounts: [`0x${KOVAN_PRIVATE_KEY}`]
    }
  }
};

