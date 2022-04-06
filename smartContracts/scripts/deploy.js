async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  const Heliumwars = await ethers.getContractFactory("Heliumwars");
  console.log("Deploying Heliumwars...");
  const heliumwars = await Heliumwars.deploy();
  await heliumwars.deployed();
  console.log("Heliumwars deployed to:", heliumwars.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
