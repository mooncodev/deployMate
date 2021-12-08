const hre = require("hardhat");
const { ethers } = hre;
const { BigNumber, provider } = ethers;
const { MaxUint256 } = ethers.constants;
const { parseEther, parseUnits } = ethers.utils;
const oovAddrs = require("./util/oovAddresses");
const {log1, log2, log3, logE, logTxError, ethScanURI, appendToLog} = require('./util/logUtils');
const gVals = {gasLimit: 4512788, gasPrice: parseUnits('5.2', 'gwei')};
const fifteenMinutes = (Date.now() + (60000 * 15)).toString();
/** NOTE:
 * addLiquidityETH(, amountTokenDesired,,,,) accepts a
 * string of the token supply expanded by its decimal
 * Eg. initialLiquidityOfToken  "1000000000000000000000" for 1 trillion "tokens"
 * **/
let i={};
let addr = {
  flowx: "0xEe6432228774737B00C02b097BBEc597AAbFe637",
  flowxPair: "0xF514086fe52C2c43a05a885f43bBc12E0F22aec7",
  router: "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D",
  factory: "0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f",
  deployer: "0xda46eee9b7E7f5d40d599c778a5E607F7e8242BD",
  chtywallet: "0xb849fBBfB25b679ADdFAD5Ebe94132c9ec7803aa",
  mktgwallet: "0xF2d5C58cB49148D7cFC00E833328f15D92e95fdC",
  ...oovAddrs,
};

async function main() {

  i.router = await ethers.getContractAt('IUniswapV2Router02', addr.router)
  i.factory = await ethers.getContractAt('IUniswapV2Factory', addr.factory)
  i.weth = await ethers.getContractAt('IWETH', addr.weth);

  addr.flowxPair =  await i.factory.getPair(addr.flowx, addr.weth,{...gVals});

  i.flowx = await ethers.getContractAt("FlowX", "0xEe6432228774737B00C02b097BBEc597AAbFe637");

  const tokenBal = await i.flowx.balanceOf(addr.deployer);
  const tokenDecimals = await i.flowx.decimals();
  let tokensToPool = (12850487932 *(10**9)).toString();
  // let tokensToPool = tokenBal.toString();
  let addr_pair = false;

  let ethToPool = parseUnits("2.231", "ether");

  console.log(`tokenBal `, tokenBal)
  console.log(`initialLiquidityOfToken `, tokensToPool)
  console.log(`initialLiquidityOfEth `, ethToPool)


  // await performApprove();

  const args = {
    approve: [addr.router, tokensToPool, gVals],
    // addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline)
    // payable returns (uint amountToken, uint amountETH, uint liquidity);
    addLiquidityETH: [
      addr.flowx, tokensToPool, '0', '0',
      addr.deployer, fifteenMinutes,
      {value: ethToPool, ...gVals}
    ]
  }
  /*//-------APPROVE--------//*/
  const tx = await i.flowx.approve(...args.approve);
  tx.wait().then((res)=>{console.log(`_txRcpt res: `, res);})
  .catch((err)=>{console.log(`_txRcpt err: `, err);})
  
  await ___pause___();
  
  /*//-------STATIC ADDLIQUIDITY--------//*/
  const cStatic = await i.router.callStatic.addLiquidityETH(...args.addLiquidityETH)
  .then(res=>{console.log(`:CALLSTATIC SUCCESS:`);})
  .catch(err=>{
    console.log(`::CALLSTATIC FAILED::`, err);
    console.log(`super special message: `, err.error.message)
  })

  await ___pause___();

  /*//-------ADDLIQUIDITY--------//*/
  if(!cStatic.error){
    console.log(`---performing addLiquidityETH()---`)
    const tx = await i.router.addLiquidityETH(...args.addLiquidityETH);
    tx.wait()
    .then((res)=>{console.log(`_txRcpt res: `, res);})
    .catch((err)=>{console.log(`_txRcpt err: `, err);})


  }

}

function _sleep(ms){return new Promise(r=>setTimeout(r, ms))}//await _sleep(5000);
async function ___pause___(){await _sleep(1000)}


main().then()
