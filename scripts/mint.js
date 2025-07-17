const { ethers } = require("hardhat");

async function main() {
    const contractAddress = "0x2A4974aaDFFcFbe721A0B9f41059f6D62fdaface";
    const tokenId = 100;
    const quantity = 1;

    const pricePerUnit = ethers.utils.parseUnits("0.04", "ether").mul(tokenId);
    const totalPrice = pricePerUnit.mul(quantity);

    const [deployer] = await ethers.getSigners();
    console.log(`Minting from wallet: ${deployer.address}`);

    const contract = await ethers.getContractAt("LHISA_LecceNFT", contractAddress);

    const tx = await contract.mintNFT(tokenId, quantity, {
        value: totalPrice
    });

    console.log("Transaction submitted:", tx.hash);
    const receipt = await tx.wait();
    console.log("✅ Mint complete. Gas used:", receipt.gasUsed.toString());
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});

