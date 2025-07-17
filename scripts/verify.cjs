const hre = require("hardhat");

async function main() {
  const contractAddress = "0xYourDeployedAddressHere";

  await hre.run("verify:verify", {
    address: contractAddress,
    constructorArguments: [
      "ipfs://",
      "0xYourOwnerAddressHere",
      "0xYourCreatorWalletHere",
      hre.ethers.parseUnits("0.001", "ether")
    ],
  });

  console.log("✅ Contract verified on explorer.");
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});