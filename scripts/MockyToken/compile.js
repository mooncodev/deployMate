const hre = require("hardhat");

async function main() {

  await hre.run('compile');

}

if(!require.main.filename.includes('sequence_')){
  main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
}else{
  module.exports = main
}
