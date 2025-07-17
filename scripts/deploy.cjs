const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying with account:", deployer.address);

  const Contract = await hre.ethers.getContractFactory("LHISA_LecceNFT");

  const baseURI = "ipfs://bafybeia25bydiudkbb..."; // ← URI completo IPFS
  const owner = deployer.address;
  const creatorWallet = "0x83114bA5262CD62AF6E7d619035d20bfaF33Eaa5"; // ← indirizzo corretto
  const eurToWei = hre.ethers.parseEther("0.001");

  const contract = await Contract.deploy(baseURI, owner, creatorWallet, eurToWei);

  await contract.waitForDeployment();
  console.log("✅ Contract deployed to:", await contract.getAddress());
}

main().catch((error) => {
  console.error("❌ Deploy failed:", error);
  process.exitCode = 1;
});
