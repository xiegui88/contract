// scripts/deploy.js

const readline = require("readline");
const { ethers } = require("hardhat");

async function askQuestion(query) {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
  });

  return new Promise((resolve) =>
    rl.question(query, (ans) => {
      rl.close();
      resolve(ans);
    })
  );
}

async function main() {
  const contractName = await askQuestion("请输入要部署的合约名称: ");

  // 根据合约名称确定完全限定名
  const fullyQualifiedName = `contracts/${contractName}.sol:${contractName}`;

  const [deployer] = await ethers.getSigners();
  console.log("部署账户:", deployer.address);

  const ContractFactory = await ethers.getContractFactory(fullyQualifiedName);

  // 检查是否是 MintableERC20，如果是则需要传入 owner 地址
  let contract;
  if (contractName === "MintableERC20") {
    contract = await ContractFactory.deploy(deployer.address); // 使用部署者作为初始 owner
  } else {
    contract = await ContractFactory.deploy();
  }

  await contract.waitForDeployment();

  console.log(`${contractName} 合约部署地址:`, await contract.getAddress());
}

main().catch((error) => {
  console.error("部署失败:", error);
  process.exitCode = 1;
});
