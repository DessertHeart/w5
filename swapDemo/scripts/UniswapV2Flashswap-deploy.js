const { ethers } = require("hardhat");
// const { writeAddr } = require("../utils/artifact_log.js");
const { abi, bytecode } = require("../artifacts/contracts/UniswapV2Flashswap/UniswapV2Flashswap.sol/UniswapV2Flashswap.json");
const airTokenAddr = require(`../depolyments/${network.name}/AirToken.json`);
const flyTokenAddr = require(`../depolyments/${network.name}/FlyToken.json`);

async function main() {
  // We get the contract to deploy
  let [owner]  = await ethers.getSigners();
  const UniswapV2Flashswap = await new ethers.ContractFactory(abi, bytecode, owner);
  // 入参: ropsten上地址: factoryV2, factoryV3, router
  const uniswapV2Flashswap = await UniswapV2Flashswap.deploy("", "", "", airTokenAddr.address, flyTokenAddr.address);
  await uniswapV2Flashswap.deployed();

  console.log("AirToken deployed to:", uniswapV2Flashswap.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
