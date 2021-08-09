const { expect } = require("chai");

describe("Real Estate NFT", () => {
  it("should return the correct value", async () => {
    const RealNFT = await ethers.getContractFactory("RealEstateNFT");
    const realNFT = await RealNFT.deploy(issuerAddress, 25000, 3, 50, BNBToken);
    await realNFT.deployed();
  })
});