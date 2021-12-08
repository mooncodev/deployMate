const fs = require('fs-extra');
const path = require('path')
const {spawnSync} = require('child_process');

async function main() {
  const newDeployAddr = `0x18f8120a46768B800E3B35C59C9F620202C3e7F9`;
  cmdEtherscanVerify(newDeployAddr)
}

function cmdEtherscanVerify(deployAddr){
  const PROJECTROOT = __dirname.match('.*deployMate')[0];
  //npx hardhat verify --network mainnet DEPLOYED_CONTRACT_ADDRESS "Constructor argument 1"
  const child = spawnSync(`npx.cmd`,
    [`hardhat`, `verify`, `--network ropsten`, deployAddr],
    { cwd:PROJECTROOT,encoding : 'utf8' });
  console.log("stdout: \n",child.stdout);
}


if(!require.main.filename.includes('sequence_')){
  main().then(() => process.exit(0)).catch(err => {
    console.error(err);process.exit(1);});
}else{module.exports = main}
