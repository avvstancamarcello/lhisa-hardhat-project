// scripts/set_base_uri.cjs
require("dotenv").config();
const { ethers } = require("hardhat");

async function main() {
    // --- CONFIGURAZIONE ---
    const CONTRACT_ADDRESS = "0x2A4974aaDFFCfbe721A0B9f41059f6D62fdaface"; // Indirizzo del contratto deployato
    const NEW_BASE_URI = "ipfs://bafybeidxlbnyoz4dyx5k5ydjya4kf4wsq6gx72vxhpzbdeda54w4ya3xsy/"; // Il tuo nuovo CID della cartella IPFS

    // Recupera il signer (l'owner del contratto) dalla chiave privata nel .env
    const provider = new ethers.JsonRpcProvider(process.env.NODE_URL_POLYGON_MAINNET);
    const signer = new ethers.Wallet(process.env.PRIVATE_KEY, provider);

    console.log("------------------------------------------");
    console.log("Inizio aggiornamento della Base URI...");
    console.log("Account Owner (firmatario):", signer.address);
    console.log("Contratto Target:", CONTRACT_ADDRESS);
    console.log("Nuova Base URI:", NEW_BASE_URI);
    console.log("------------------------------------------");

    // Carica l'ABI del contratto (assicurati che sia la versione corretta nel tuo Hardhat artifacts)
    const LHISALecceNFT = await ethers.getContractFactory("LHISA_LecceNFT");
    const contract = new ethers.Contract(CONTRACT_ADDRESS, LHISALecceNFT.interface, signer);

    // Chiama la funzione setBaseURI
    try {
        const tx = await contract.setBaseURI(NEW_BASE_URI);
        console.log("📝 Transazione inviata. Hash:", tx.hash.substring(0, 10) + "...");
        console.log("⏳ In attesa di conferma transazione...");
        await tx.wait();
        console.log("✅ Base URI aggiornata con successo!");
    } catch (error) {
        console.error("❌ Errore durante l'aggiornamento della Base URI:", error.message);
        if (error.code === 'CALL_EXCEPTION' && error.data) {
            try {
                const decodedError = contract.interface.parseError(error.data);
                console.error("Errore decodificato:", decodedError.name, decodedError.args);
            } catch (decodeError) {
                console.error("Impossibile decodificare errore on-chain:", decodeError.message);
            }
        }
        console.error("Assicurati che l'account:", signer.address, "sia l'owner del contratto e abbia MATIC per il gas.");
    }

    console.log("------------------------------------------");
    console.log("Processo completato.");
    console.log("------------------------------------------");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
