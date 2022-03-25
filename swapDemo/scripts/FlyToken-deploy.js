const { ethers } = require("hardhat");
const { writeAddr } = require("../utils/artifact_log.js");
const { abi, bytecode } = require("../artifacts/contracts/FlyToken/FlyToken.sol/FlyToken.json");


async function main() {
  // We get the contract to deploy
  let [owner]  = await ethers.getSigners();
  const AirToken = await new ethers.ContractFactory(abi, bytecode, owner);
  const token = await AirToken.deploy("FlyToken", "FT");
  await token.deployed();

  console.log("FlyToken deployed to:", token.address);
  await writeAddr(token.address, "FlyToken", network.name);

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
