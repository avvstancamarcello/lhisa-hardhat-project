const hre = require("hardhat");

async function main() {
  const contractAddress = "0xc72F5B05B6323eDf0DA660AD1b1bd26b08050916"; // ← Contratto Polygon
  const CID = "bafybeia25bydviudkbbiqaj5ea3kisfb3tepzmobtkuq4bw5qjv52cmaxu";

  const contract = await hre.ethers.getContractAt("LHISA_LecceNFT", contractAddress);
  const [deployer] = await hre.ethers.getSigners();

  console.log("👤 Using account:", deployer.address);

  for (let tokenId = 5; tokenId <= 100; tokenId += 5) {
    const tx = await contract.setTokenCID(tokenId, CID);
    console.log(`🔄 Setting CID for tokenId ${tokenId}... TX: ${tx.hash}`);
    await tx.wait();
    console.log(`✅ Confirmed tokenId ${tokenId}`);
  }

  console.log("🎯 All token CIDs updated on Polygon.");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
