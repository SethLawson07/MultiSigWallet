import { ethers } from "hardhat";

async function main() {
  

  // Contracts are deployed using the first signer/account by default
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  const addr1= ethers.Wallet.createRandom();
  const addr2= ethers.Wallet.createRandom();
  const addr3= ethers.Wallet.createRandom();
  const addr4= ethers.Wallet.createRandom();

  console.log("Account balance:", (await deployer.getBalance()).toString());

  const Msw = await ethers.getContractFactory("MultiSigWallet");
  let owners: string [] = [deployer.address,addr1.address,addr2.address,addr3.address,addr4.address];  
  let required : number = 3;
  const msw = await Msw.deploy(owners,required);

  console.log("MultiSigWallet address:", msw.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });