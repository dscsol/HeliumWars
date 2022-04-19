require("@openzeppelin/hardhat-upgrades");
require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-etherscan");
require("dotenv").config();
/**
 * @type import('hardhat/config').HardhatUserConfig
 */

module.exports = {
  solidity: "0.8.4",
  paths: {
    sources: "./contracts",
    cache: "./cache",
    artifacts: "./artifacts",
  },
  networks: {
    rinkeby: {
      url: `${process.env.URL}`,
      accounts: [`${process.env.PRIVATEKEY}`],
    },
  },
  etherscan: {
    apiKey: `${process.env.APIKEY}`,
  },
};
