// scripts/interact.js

const fs = require("fs");
const path = require("path");
const readline = require("readline");

// 创建一个全局的 readline 接口
const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
});

// 统一的提问函数
async function askQuestion(query) {
  return new Promise((resolve) => rl.question(query, resolve));
}

function parseArg(val, type) {
  if (type.startsWith("uint") || type.startsWith("int")) return BigInt(val);
  if (type === "bool") return val.toLowerCase() === "true";
  return val;
}

async function main() {
  try {
    // 获取合约名称和地址
    const contractName = await askQuestion("请输入合约名称(例如 MintableERC20): ");
    const contractAddress = await askQuestion("请输入合约地址: ");

    const [user] = await ethers.getSigners();
    console.log("使用账户与合约交互:", user.address);

    const artifactPath = path.join(__dirname, `../artifacts/contracts/${contractName}.sol/${contractName}.json`);

    // 检查合约文件是否存在
    if (!fs.existsSync(artifactPath)) {
      console.error(`错误: 找不到合约 ${contractName} 的编译文件`);
      return;
    }

    const artifact = JSON.parse(fs.readFileSync(artifactPath, "utf8"));
    const abi = artifact.abi;
    const contract = new ethers.Contract(contractAddress, abi, user);
    const functions = abi.filter(fn => fn.type === "function");

    while (true) {
      console.log("\n可用方法：");
      functions.forEach((fn, i) => {
        const inputTypes = fn.inputs.map(input => `${input.name}:${input.type}`).join(", ");
        console.log(`${i + 1}. ${fn.name}(${inputTypes}) [${fn.stateMutability}]`);
      });
      console.log(`${functions.length + 1}. 退出`);

      const choiceStr = await askQuestion("请输入方法编号：");
      const choice = parseInt(choiceStr);

      if (choice === functions.length + 1) {
        console.log("退出...");
        break;
      }

      if (isNaN(choice) || choice < 1 || choice > functions.length) {
        console.log("无效选择，请重新输入！");
        continue;
      }

      const fn = functions[choice - 1];
      const args = [];

      for (const input of fn.inputs) {
        const val = await askQuestion(`请输入参数 ${input.name} (${input.type}): `);
        args.push(parseArg(val, input.type));
      }

      try {
        if (fn.stateMutability === "view" || fn.stateMutability === "pure") {
          const result = await contract[fn.name](...args);
          console.log("函数返回值:", result.toString());
        } else {
          const tx = await contract[fn.name](...args);
          console.log("交易发送成功，等待确认...");
          console.log("交易哈希:", tx.hash);
          await tx.wait();
          console.log("交易已确认！");
        }
      } catch (err) {
        console.error("执行失败：", err.message || err);
      }
    }
  } catch (err) {
    console.error("主程序异常:", err);
  } finally {
    rl.close();
  }
}

main().catch(err => {
  console.error("主程序异常:", err);
  rl.close();
  process.exit(1);
});
