const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();

  console.log("Deploying contract with address:", deployer.address);

  const baseURI = "ipfs://bafybeia25bydviudkbbiqaj5ea3kisfb3tepzmobtkuq4bw5qjv52cmaxu";
  const owner = "0x83114bA5262CD62AF6E7d619035d20bfaF33Eaa5";
  const creator = "0x83114bA5262CD62AF6E7d619035d20bfaF33Eaa5";
  const eurToWei = "1000000000000000";

  const ContractFactory = await hre.ethers.getContractFactory("LHISA_LecceNFT");

  const contract = await ContractFactory.deploy(baseURI, owner, creator, eurToWei);
  await contract.waitForDeployment();

  console.log("✅ Contract deployed to:", await contract.getAddress());
}

main().catch((error) => {
  console.error("❌ Error during deployment:", error);
  process.exit(1);
});
