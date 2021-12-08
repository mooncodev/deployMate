const hre = require("hardhat");
const { ethers } = hre;
const { BigNumber, provider } = ethers;
const { MaxUint256 } = ethers.constants;
const { parseEther, parseUnits, formatUnits } = ethers.utils;
const oovAddrs = require("./util/oovAddresses");
const {__, log, log2, log3, logE, ethScanURI, appendToLog} = require('./util/logUtils');
const gVals = {gasLimit: 4512788, gasPrice: 41000};
const inTenMinutes = Math.floor(Date.now() / 1000) + 60 * 10;

let tx, cstx, i={};
let addr = {
  flowx: "0x1b27023D065f89B89df9e3D321F2c46db4f2A410",
  flowxPair: "0xF514086fe52C2c43a05a885f43bBc12E0F22aec7",
  router: "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D",
  factory: "0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f",
  deployer: "0xda46eee9b7E7f5d40d599c778a5E607F7e8242BD",
  chtywallet: "0xb849fBBfB25b679ADdFAD5Ebe94132c9ec7803aa",
  mktgwallet: "0xF2d5C58cB49148D7cFC00E833328f15D92e95fdC",
  ...oovAddrs,
};

async function main() {
  const [deployer, chtywallet, mktgwallet, aaaa, bbbb, cccc, dddd]
    = await ethers.getSigners();
  gVals.gasPrice = formatUnits(await provider.getGasPrice(), "wei");


// ...often this gas price is easier to understand or
// display to the user in gwei


  i.router = await ethers.getContractAt('IUniswapV2Router02', addr.router);
  i.factory = await ethers.getContractAt('IUniswapV2Factory', addr.factory);
  i.weth = await ethers.getContractAt('IWETH', addr.weth);
  i.flowx = await ethers.getContractAt("FlowX", addr.flowx);

  addr.flowxPair =  await i.factory.getPair(addr.flowx, addr.weth, gVals);


  const fxBal = await i.flowx.balanceOf(addr.deployer);__(`tokenBal `, fxBal)


  let tokensToPool = expand(12850487932, 9).toString();
  let ethToPool = parseUnits("2.231", "ether").toString();
  __(`tokensToPool `, tokensToPool);
  __(`ethToPool `, ethToPool);


  const args = {
    transfer: [addr.deployer, tokensToPool, gVals],
  }

  __(`-------------transfer()-------------`);
  tx = await i.flowx.transfer(...args.transfer)
  await wait(tx.hash, `transfer`);
  
  await ___pause___();


}

function expand(amt, decimal){return amt*(10**decimal)}
function ___pause___(){return new Promise(r=>setTimeout(r,1000))}//await ___pause___();
async function wait(txhash, label, confirmation=1) {
  return new Promise((resolve,reject)=> {
    if (label) {console.log(`> Awaiting "${label}"\n tx: ${txhash}`);
    } else {console.log(`> Awaiting tx: ${txhash}`);}
    ethers.provider.waitForTransaction(txhash, confirmation)
    .then((rcpt)=>{__(`receipt: `, rcpt);resolve(rcpt);})
    .catch((err)=>{__(`tx err: `, err);reject(err)});
  })
}
main().then()
