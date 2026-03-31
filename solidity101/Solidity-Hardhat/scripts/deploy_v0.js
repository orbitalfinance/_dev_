// Importa Hardhat Runtime Environment (HRE)HRE è un oggetto che ti dà accesso a tutte le funzionalità di Hardhat:
// - ethers.js integrato
// - network, account, compilazione, deploy, ecc.
const hre = require("hardhat");


// Funzione principale asincrona
// Usiamo `async/await` per gestire le operazioni asincrone (es. deploy)
async function main() {

    // Otteniamo un "contract factory" per SimpleStorage
    // Il factory è un oggetto che rappresenta il contratto da deployare:
    // include ABI, bytecode e metodi per deployarlo.
    const SimpleStorage = await hre.ethers.getContractFactory("SimpleStorage");

    // Eseguiamo il deploy del contratto sulla rete attiva (es. localhost)
    // Questo invia una transazione "CREATE" con il bytecode del contratto
    const simpleStorage = await SimpleStorage.deploy();

    // Aspettiamo che il contratto venga effettivamente deployato
    // In ethers v6, `.waitForDeployment()` sostituisce `.deployed()` (v5)
    // Finché non è "minato", l'indirizzo non è valido.
    await simpleStorage.waitForDeployment();

    // Stampiamo l'indirizzo Ethereum dove il contratto è stato deployato
    // `.target` è usato in ethers v6 (equivalente a `.address` in v5)
    console.log(`SimpleStorage deployed to: ${simpleStorage.target}`);
}


// Gestione degli errori:
// Se qualcosa fallisce (es. errore di deploy), catturiamo l'eccezione
// e stampiamo un messaggio d’errore, poi forziamo l’uscita con codice 1
main().catch((error) => {
    console.error("Error:", error);
    process.exitCode = 1;
});

