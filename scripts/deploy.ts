import { ethers } from "hardhat";

async function main() {
  const ShooterCoin = await ethers.getContractFactory("ShooterCoin");

  console.log("Deploying ShooterCoin...");

  const shooter = await ShooterCoin.deploy();

  await shooter.waitForDeployment();

  console.log("ShooterCoin deployed to:", await shooter.getAddress());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});