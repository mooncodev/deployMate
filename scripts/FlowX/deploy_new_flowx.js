const hre = require("hardhat");
const { ethers } = hre;
const { BigNumber, provider } = ethers;
const {spawnSync} = require('child_process');
const { MaxUint256 } = ethers.constants;
const { parseEther, parseUnits, formatUnits } = ethers.utils;
const oovAddrs = require("./util/oovAddresses");
const {__, log, log2, log3, logE, ethScanURI, appendToLog} = require('./util/logUtils');
const gVals = {gasLimit: 4512788, gasPrice: 41000};
const inTenMinutes = (Math.floor(Date.now() / 1000) + 60 * 10).toString();
// String.prototype.n = function(){return parseInt(this)};

let tx,rcpt, cstx, i={}
  ;
let addr = {
  flowx: "???",
  flowxPair: "???",
  router: "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D",
  factory: "0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f",
  deployer: "0xda46eee9b7E7f5d40d599c778a5E607F7e8242BD",
  chtywallet: "0xb849fBBfB25b679ADdFAD5Ebe94132c9ec7803aa",
  mktgwallet: "0xF2d5C58cB49148D7cFC00E833328f15D92e95fdC",
  ...oovAddrs,
};

async function main() {
  const abiLabel = "FlowX";
  // const gVals = {gasLimit: 4512788, gasPrice: parseUnits('5.2', 'gwei')};
  const gcf = await ethers.getContractFactory(abiLabel);
  let inst = await gcf.deploy();
  tx = inst.deployTransaction;
  delete tx.data;
  __(`New deploy "${abiLabel}" tx: `, tx);
  __(`awaiting reciept for ${abiLabel}...`);
  await wait(inst.deployTransaction.hash, `deploy: ${inst.address}`);
  rcpt = tx;
  rcpt = await inst.deployTransaction.wait();
  delete rcpt.logsBloom;
  delete rcpt.logs;
  delete rcpt.events;
  __(`New deploy "${abiLabel}" rcpt: `, rcpt);
  __(`rcpt.contractAddress: `, rcpt.contractAddress);

  await ___pause___();

  addr.flowx = rcpt.contractAddress;
  i.flowx = await ethers.getContractAt("FlowX", addr.flowx);

  i.factory = await ethers.getContractAt('IUniswapV2Factory', addr.factory);
  addr.flowxPair =  await i.factory.getPair(addr.flowx, addr.weth, gVals);

  appendToLog({
    'NewFlowXDeploy': addr.flowx,
    'owner':inst.from,
    'pair':addr.flowxPair,
    // 'divtracker':inst.dividendTracker()
  })

  const PROJECTROOT = __dirname.match('.*deployMate')[0];
  const child = spawnSync(`npx.cmd`,
    [`hardhat`, `verify`, `--network ropsten`, addr.flowx],
    { cwd:PROJECTROOT,encoding : 'utf8' });
  console.log("etherscan verify stdout: \n",child.stdout);
  return inst;

}

function expand(amt, decimal){return amt*(10**decimal)}
function ___pause___(){return new Promise(r=>setTimeout(r,1000))}//await ___pause___();
function num(string){return parseInt(string);}
async function wait(txhash, label, confirmation=1) {
  return new Promise((resolve,reject)=> {
    if (label) {console.log(`> Awaiting "${label}"\n tx: ${txhash}`);
    } else {console.log(`> Awaiting tx: ${txhash}`);}
    ethers.provider.waitForTransaction(txhash, confirmation)
    .then((rcpt)=>{__(`receipt: `, rcpt);resolve(rcpt);})
    .catch((err)=>{__(`tx err: `, err);reject(err)});
  })
}

if(!require.main.filename.includes('sequence_')){
  main().then(() => process.exit(0)).catch(err => {
    console.error(err);process.exit(1);});
}else{module.exports = main}
