const {
  log1, log2, log3, logE, ethScanURI, logTxError
} = require('./util/logUtils');
const hre = require("hardhat");
const { ethers } = hre;

async function main(setup) {
  if(!setup){setup = await require("./_setup")();}
  const {
    hre, ethers,
    log1, log2, log3, logE,
    _addr, _g, _i,
    __reportTokenBalances,
  } = setup;

  const GCF = await ethers.getContractFactory("UniLiqLock");
  const inst = await GCF.deploy(_addr.UniswapV2Factory);
  let dtx = inst.deployTransaction;
  delete dtx.data;//remove data
  log1(`New deploy "${inst.name}" tx: `, dtx);
  const rcpt = await dtx.wait();
  log1(`New deploy "${inst.name}" rcpt: `, rcpt);
  log1(`reminder: ADD THIS ADDRESS to addr object in setup.js`);
  log2(`inst.address: `, inst.address);

}

if(!require.main.filename.includes('sequence_')){
  main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    logTxError(error);
    process.exit(1);
  });
}else{
  module.exports = main
}
