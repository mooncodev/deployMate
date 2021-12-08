const hre = require("hardhat");
const { ethers } = hre;
const { parseEther, parseUnits } = ethers.utils;
const {log1, log2, log3, logE, logTxError, ethScanURI, appendToLog} = require('./util/logUtils');

async function main() {
  const abiLabel = "FlowX";
  // const gVals = {gasLimit: 4512788, gasPrice: parseUnits('5.2', 'gwei')};
  const gcf = await ethers.getContractFactory(abiLabel);
  let inst = await gcf.deploy();
  let dtx = inst.deployTransaction;
  delete dtx.data;
  log1(`New deploy "${abiLabel}" tx: `, dtx);
  log3(`awaiting reciept for ${abiLabel}...`);
  const rcpt = await inst.deployTransaction.wait();
  delete rcpt.logsBloom;
  delete rcpt.logs;
  delete rcpt.events;
  log1(`New deploy "${abiLabel}" rcpt: `, rcpt);
  log3(`rcpt.contractAddress: `, rcpt.contractAddress);

/*
  const inst = await _deployNew({
    artifact:"FlowX",
    libraries: {
      // IterableMapping: "0x605203ec54Bc2ce23847844194193009C339Ab69",
    },
    deployArgs:[
      // "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D",
      { ...gVals }
    ]
  })
*/

  appendToLog({
    [`New FlowX Deployment`]: inst.address,
    'owner':inst.from,
    'pair':inst.uniswapV2Pair(),
    // 'divtracker':inst.dividendTracker()
  })
  return inst;

}

if(!require.main.filename.includes('sequence_')){
  main().then(() => process.exit(0)).catch(err => {
    console.error(err);process.exit(1);});
}else{module.exports = main}
