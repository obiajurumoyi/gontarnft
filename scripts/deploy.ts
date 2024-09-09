import { ethers } from "hardhat";

async function main() {
  const gontar = await ethers.deployContract("GontarV9", [6021]);

  await gontar.waitForDeployment();

  console.log(gontar.target);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
