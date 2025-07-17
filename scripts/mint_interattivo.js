const { ethers } = require("hardhat");
const readline = require("readline");

async function prompt(question) {
    const rl = readline.createInterface({
        input: process.stdin,
        output: process.stdout
    });

    return new Promise((resolve) => {
        rl.question(question, (answer) => {
            rl.close();
            resolve(answer.trim());
        });
    });
}

async function main() {
    const contractAddress = "0x2A4974aaDFFcFbe721A0B9f41059f6D62fdaface";

    const tokenIdInput = await prompt("Inserisci il tokenId da mintare (es. 100): ");
    const quantityInput = await prompt("Inserisci la quantità da mintare (es. 1): ");

    const tokenId = parseInt(tokenIdInput);
    const quantity = parseInt(quantityInput);

    if (isNaN(tokenId) || isNaN(quantity) || tokenId <= 0 || quantity <= 0) {
        console.error("❌ Inserisci valori validi per tokenId e quantità.");
        process.exit(1);
    }

    const pricePerUnit = ethers.parseEther("0.04") * BigInt(tokenId);
    const totalPrice = pricePerUnit * BigInt(quantity);

    const [deployer] = await ethers.getSigners();
    console.log(`\n📤 Minting NFT dal wallet: ${deployer.address}`);
    console.log(`📦 Token ID: ${tokenId}, Quantità: ${quantity}, Prezzo totale: ${ethers.formatEther(totalPrice)} MATIC`);

    const contract = await ethers.getContractAt("LHISA_LecceNFT", contractAddress);

    const tx = await contract.mintNFT(tokenId, quantity, {
        value: totalPrice
    });

    console.log("\n⏳ Transazione inviata:", tx.hash);
    const receipt = await tx.wait();
    console.log("✅ Mint completato. Gas utilizzato:", receipt.gasUsed.toString());
}

main().catch((error) => {
    console.error("❌ Errore:", error);
    process.exit(1);
});
