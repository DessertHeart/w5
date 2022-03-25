const { ethers } = require("hardhat");
const { writeAddr } = require("../utils/artifact_log.js");
const { abi, bytecode } = require("../artifacts/contracts/AirToken/AirToken.sol/AirToken.json");
// const { abi:masterChefAbi, bytecode:masterChefBytecode } = require("../artifacts/contracts/sushiswap/contracts/MasterChef.sol/MasterChef.json");
// const masterChefAddr = require(`../deployments/${network.name}/MasterChef.json`);

async function main() {
  // We get the contract to deploy
  let [owner]  = await ethers.getSigners();
  const AirToken = await new ethers.ContractFactory(abi, bytecode, owner);
  const token = await AirToken.deploy("AirToken", "AT");
  await token.deployed();

  console.log("AirToken deployed to:", token.address);
  await writeAddr(token.address, "AirToken", network.name);

  // // 使用合约接口和签名器Singer 连接到现有合约实例
  // const MasterChef = await new ethers.ContractFactory(masterChefAbi, masterChefBytecode, owner);
  // const masterchef = await MasterChef.attach(masterChefAddr.address);

  // // 获取目前交易池长度（初始化时为0）
  // let pid = await masterchef.poolLength();
  // console.log("get pool length, pid: ", pid.toNumber()); // ether.js方法

  // // 添加sushi交易池
  // let tx = await masterchef.add(100, token.address, false);
  // // 完全等待交易完成.wait()
  // await tx.wait();
  // console.log("add lp token");  
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
