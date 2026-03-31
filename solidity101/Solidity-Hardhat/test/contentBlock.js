const { ethers } = require("hardhat");

async function main() {
  const provider = ethers.provider;

  // Leggi i primi due blocchi
  const block1 = await provider.getBlock(1, true); // true = include tx details

  console.log("\n🔗 Block 1:");
  console.log({
    number: block1.number,
    hash: block1.hash,
    parentHash: block1.parentHash,
    timestamp: block1.timestamp,
    transactions: block1.transactions.map(tx => tx.hash),
  });

}

main().catch(console.error);
