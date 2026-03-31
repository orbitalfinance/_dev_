const hre = require("hardhat");


//set "HARDHAT_NETWORK=localhost" && node scripts\interact.js SimpleStorage 0x1234... retrieve
//set "HARDHAT_NETWORK=localhost" && node scripts\interact.js SimpleStorage 0x1234... store 27
//set "HARDHAT_NETWORK=localhost" && node scripts\interact.js SimpleStorage 0x1234... favoriteNumber

async function main() {
  // set "HARDHAT_NETWORK=localhost" && node scripts/interact.js <ContractName> <Address> <Function/public variable> [arg1 arg2 ...]
  const [, , contractName, contractAddress, fnName, ...fnArgs] = process.argv;


  if (!contractName || !contractAddress) {
    console.error("\n Error");
    process.exit(1);
  }

  const contract = await hre.ethers.getContractAt(contractName, contractAddress);

  /* ---------- Stampa tutti gli output delle funzioni/variabili public ---------- */

  if (fnName === "--all") {
    const getters = contract.interface.fragments.filter(
      (f) =>
        f.type === "function" &&
        f.inputs.length === 0 &&
        (f.stateMutability === "view" || f.stateMutability === "pure")
    );

    //  Con questi tre predicati ottieni esattamente:
    //  • i getter auto-generati per le variabili public scalari
    //  • ogni altra funzione di sola lettura senza argomenti (se esiste).

    for (const g of getters) {
      try {
        const val = await contract[g.name]();
        const out =
          typeof val === "bigint" ? val.toString() : val;
        console.log(`• ${g.name} →`, out);
      } catch (e) {
        console.error(`(Errore chiamando ${g.name})`, e);
      }
    }
    return;
  }


  /* ---------------------- Chiamata funzione ------------------------- */

  if (typeof contract[fnName] !== "function") {
    console.error(`Errore: input non trovato`);
    process.exit(1);
  }

  const fragment = contract.interface.getFunction(fnName);
  const isReadOnly = ["view", "pure"].includes(fragment.stateMutability);

  if (isReadOnly) {
    const res = await contract[fnName](...fnArgs);
    console.log("Risultato:", typeof res === "bigint" ? res.toString() : res);
  } else {
    const tx = await contract[fnName](...fnArgs);
    console.log("Hash transazione:", tx.hash);
    await tx.wait();
    console.log("Transazione minata");
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});

