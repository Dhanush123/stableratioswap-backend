// const { expect } = require("chai");
// const { smockit } = require("@eth-optimism/smock");

// import {AaveProtocolDataProvider} from "@aave/protocol-v2/contracts/misc/AaveProtocolDataProvider.sol";

// describe("Greeter", function() {
//   let stableRatioSwap;
//   const MyMockContract = await smockit(MyContract)

// MyMockContract.smocked.myFunction.will.return.with({
//     valueA: 'Some value',
//     valueB: 1234,
//     valueC: true
// })


//   beforeEach(async () => {
// 		const StableRatioSwap = await ethers.getContractFactory("StableRatioSwap");
// 		stableRatioSwap = await StableRatioSwap.deploy();
// 		await stableRatioSwap.deployed();

    
// 	});

//   it("verify constructor setup", async function () {
// 		const MyMockContract = await smockit(myERC20);
// 		const MyOtherContract = await ethers.getContractFactory(
// 			"MyOtherContract"
// 		);
// 		const myOtherContract = await MyOtherContract.deploy(
// 			MyMockContract.address
// 		);
//   });
// }

  // it("Should return the new greeting once it's changed", async function() {
  //   const Greeter = await ethers.getContractFactory("Greeter");
  //   const greeter = await Greeter.deploy("Hello, world!");
    
  //   await greeter.deployed();
  //   expect(await greeter.greet()).to.equal("Hello, world!");

  //   await greeter.setGreeting("Hola, mundo!");
  //   expect(await greeter.greet()).to.equal("Hola, mundo!");
  // });
// });
