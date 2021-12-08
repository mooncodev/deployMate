const fs = require('fs-extra');
const path = require('path')
const {spawnSync} = require('child_process');


function cmdContractSize(filename){
  const PROJECTROOT = __dirname.match('.*deployMate')[0];
  const child = spawnSync(`npx.cmd`, [`hardhat`, `size-contracts`], { cwd:PROJECTROOT,encoding : 'utf8' });
  console.log("stdout: \n",child.stdout);
}

async function main(setup) {
  // if(!setup){setup = await require("./_setup")();}
  // const {} = setup;
  cmdContractSize()
}

if(!require.main.filename.includes('sequence_')){
  main().then(() => process.exit(0)).catch(err => {
    console.error(err);process.exit(1);});
}else{module.exports = main}
