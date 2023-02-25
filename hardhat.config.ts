import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

require('dotenv').config();

const {STAGING_ALCHEMY_KEY,PRIVATE_KEY} = process.env;
const config: HardhatUserConfig = {
  solidity: "0.8.9",
  networks: {
    goerli: {
    
      url: STAGING_ALCHEMY_KEY,
      accounts: [`0x${PRIVATE_KEY}`]
    },
  },
};

export default config;
