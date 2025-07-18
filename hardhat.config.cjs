// hardhat.config.cjs
require("dotenv").config(); // Carica le variabili d'ambiente dal file .env
require("@nomicfoundation/hardhat-ethers"); // Importa i plugin Hardhat per ethers

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.26", // La versione di Solidity per il tuo contratto
    settings: {
      optimizer: {
        enabled: true,
        runs: 200, // Numero di runs per l'ottimizzatore
      },
    },
  },
  networks: {
    hardhat: {
      // Configurazioni per la rete Hardhat di default (sviluppo locale)
    },
    polygon: {
      url: process.env.NODE_URL_POLYGON_MAINNET || "", // URL del nodo Polygon Mainnet da .env
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [], // Chiave privata da .env
      chainId: 137, // Chain ID di Polygon Mainnet
      gasPrice: 30 * 10**9, // Gas Price impostato a 30 Gwei (30 * 10^9 Wei)
    },
    // Puoi aggiungere altre reti qui, es:
    // goerli: {
    //   url: process.env.NODE_URL_GOERLI || "",
    //   accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
    //   chainId: 5,
    // },
  },
  // Configurazione per etherscan (per la verifica automatica dei contratti)
  // Assicurati di avere `npm install @nomicfoundation/hardhat-etherscan`
  etherscan: {
    apiKey: process.env.POLYGONSCAN_API_KEY, // La tua API Key di Polygonscan da .env
  },
};
