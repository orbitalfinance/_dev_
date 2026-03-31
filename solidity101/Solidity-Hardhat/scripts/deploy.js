// Importa Hardhat Runtime Environment (HRE) è un oggetto che ti dà accesso a tutte le funzionalità di Hardhat:
// - ethers.js integrato
// - network, account, compilazione, deploy, ecc.

// Da linea di comando Windows:
// set "CONTRACT=SimpleStorage_v2" && npx hardhat run --network localhost scripts\deploy.js

// Da linea di comando Unix-like (Git Bash, WSL, ecc.):
// CONTRACT=SimpleStorage_v2 npx hardhat run --network localhost scripts\deploy.js


const hre = require("hardhat");
const contractName = process.env.CONTRACT;

// Usiamo `async/await` per gestire le operazioni asincrone (es. deploy)
async function main() {

    console.log(`Deploying contract: ${contractName}`);

    // Otteniamo un "contract factory": un oggetto che rappresenta il contratto da deployare.
    // Include ABI, bytecode e metodi per deployarlo.
    const MyContract = await hre.ethers.getContractFactory(contractName);

    // Eseguiamo il deploy del contratto sulla rete attiva (es. localhost)
    // Questo invia una transazione "CREATE" con il bytecode del contratto
    const myContract = await MyContract.deploy();

    // Aspettiamo che il contratto venga effettivamente deployato.
    // Finché non è "minato", l'indirizzo non è valido.
    await myContract.waitForDeployment();

    // Stampiamo l'indirizzo Ethereum dove il contratto è stato deployato
    // `.target` è usato in ethers v6 (equivalente a `.address` in v5)
    console.log(`${contractName} deployed to: ${myContract.target}`);
}


// Gestione degli errori:
// Se qualcosa fallisce (es. errore di deploy) si stampa un messaggio d’errore.
main().catch((error) => {
    console.error("Error:", error);
    process.exitCode = 1;
});

