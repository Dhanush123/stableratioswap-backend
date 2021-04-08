const { expect } = require("chai");

describe("StableRatioSwap", function() {
  it("optInStatus should be false if createUser is called once", async function() {
    const StableRatioSwap = await ethers.getContractFactory("StableRatioSwap");
    const stableRatioSwap = await StableRatioSwap.deploy();
    await stableRatioSwap.deployed();
    const CreateUser = await stableRatioSwap.createUser();
    expect(await CreateUser.createUserStatus).to.equal(true);
  });
});
