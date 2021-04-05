// This is a script for deploying your contracts. You can adapt it to deploy
// yours, or create new ones.
const PROJECT_NAME = 'StableRatioSwap';
console.log("!!!!",__dirname);

async function main() {
  console.log("!!!!",__dirname);
  // This is just a convenience check
  if (network.name === "hardhat") {
    console.warn(
      "You are trying to deploy a contract to the Hardhat Network, which" +
        "gets automatically created and destroyed every time. Use the Hardhat" +
        " option '--network localhost'"
    );
  }

  // ethers is avaialble in the global scope
  const [deployer] = await ethers.getSigners();
  console.log(
    "Deploying the contracts with the account:",
    await deployer.getAddress()
  );

  console.log("Account balance:", (await deployer.getBalance()).toString());

  const StableRatioSwap = await ethers.getContractFactory(PROJECT_NAME);
  const stableRatioSwap = await StableRatioSwap.deploy();
  await stableRatioSwap.deployed();

  console.log(`${PROJECT_NAME} address:`, stableRatioSwap.address);

  // We also save the contract's artifacts and address in the frontend directory
  saveFrontendFiles(stableRatioSwap);
}

function saveFrontendFiles(stableRatioSwap) {
  const fs = require("fs");
  const contractsDir = __dirname + "/../../stableratioswap-frontend/src/contracts";

  if (!fs.existsSync(contractsDir)) {
    fs.mkdirSync(contractsDir);
  }

  let content = {};
  content[PROJECT_NAME] = stableRatioSwap.address;

  fs.writeFileSync(
    contractsDir + "/contract-address.json",
    JSON.stringify(content, undefined, 2)
  );

  const StableRatioSwapArtifact = artifacts.readArtifactSync(PROJECT_NAME);

  fs.writeFileSync(
    contractsDir + `/${PROJECT_NAME}.json`,
    JSON.stringify(StableRatioSwapArtifact, null, 2)
  );
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
