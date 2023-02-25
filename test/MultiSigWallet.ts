import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("Msw", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployMswFixture() {
    


    // Contracts are deployed using the first signer/account by default
    const [owner, addr1,addr2,addr3,addr4,to] = await ethers.getSigners();

    const Msw = await ethers.getContractFactory("MultiSigWallet");
    let owners: string [] = [owner.address, addr1.address,addr2.address,addr3.address,addr4.address];
    let required : number = 3;
    const msw = await Msw.deploy(owners,required);
    
    return { msw, owner, addr1,addr2,addr3,addr4,to };
  }

    describe("Deployment", function () {
      it("Should set the right owner", async function () {
        const { msw, owner } = await loadFixture(deployMswFixture);

        expect(await msw.deployer()).to.equal(owner.address);
      });

    
    });
 
    describe("Transactions", function () {
      it("Should add a transaction", async function () {
        const { msw,to } = await loadFixture(deployMswFixture);  
        const value = ethers.utils.parseEther("1.0");
        const data = "0x123456";

        await msw.submitTransaction(to.address,value,data);

        expect(await msw.getTransactionCount()).to.equal(1);
      });

     it("should confirmation a transaction", async function () {
        const { msw,to } = await loadFixture(deployMswFixture);
        const value = ethers.utils.parseEther("1.0");
        const data = "0x123456";
       
        await msw.submitTransaction(to.address,value,data);         
        await msw.confirmTransaction(0);
               
        expect((await  msw.getTransaction(0)).numConfirmations).to.equal(1);
      });

      it("should execute a transaction", async function () {
        const { msw,addr1,addr2,to } = await loadFixture(deployMswFixture);
        
        const value = ethers.utils.parseEther("2.0");
        const data = "0x123456";
                
        await msw.submitTransaction(to.address,value,data,{value});              
        await msw.confirmTransaction(0);
        await msw.connect(addr1).confirmTransaction(0);
        await msw.connect(addr2).confirmTransaction(0);

        await msw.executeTransaction(0);
        
        expect((await msw.getTransaction(0)).executed).to.equal(true);
      });

      it("should cancel a transaction", async function () {
        const { msw,to } = await loadFixture(deployMswFixture);
        const value = ethers.utils.parseEther("1.0");
        const data = "0x123456";
        
        await msw.submitTransaction(to.address,value,data);
        await msw.confirmTransaction(0);         
        await msw.revokeTransaction(0);
       
        expect((await  msw.getTransaction(0)).numConfirmations).to.equal(0);
      });

  });
});