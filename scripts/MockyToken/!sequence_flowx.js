const {logTxError} = require('./util/logUtils');
async function run(path){
  console.log(`%%% run(${path}) init %%%`)
  await require(path)(setup)
  .then(()=>{console.log(`%%% run(${path}) finished %%%`)})
  .catch(e=>{debugger;console.error(e);throw Error})
}

async function main() {
  const setup = await require("./_setup")();
  const {
    hre, ethers,
    provider, BigNumber,
    parseEther, parseUnits,
    MaxUint256,
    log1, log2, log3, logE,//(logMsg, data)
    accounts, deployer, user,
    __callStatic, //(instance, methodAsString, argsArray)
    _txRcpt,
    _receipt, //(logMsg, tx)
    _awaitDeployed, //(<ABI name>, <'new'|address>)
    __testPair, //(tokenAddress)
    _sleep, //(ms)
    _addr, _g, _i,
    __reportTokenBalances,
  } = setup;

  /** DEPLOY FLOWX **/
  // const instFlowX = await require('./DeployNew_FlowX')(setup);

  _addr.FlowX = "0x9DdAF6398FE6f68E32A85cde7F75638A8c2f44E6";
  _i.flowx = await ethers.getContractAt("FlowX", _addr.FlowX);
  flowxListeners();
  await flowxBals();
  /** GET FLOWX PAIR **/
  _addr.FlowX = _i.flowx.address
  _addr.FlowXPair = _i.flowx.uniswapV2Pair();
  _i.flowxPair = await ethers.getContractAt('IUniswapV2Pair', _addr.FlowXPair);

  /** EXCLUDE WHITEBIT HOTWALLET FROM FEES/REWARDS **/
  await _txRcpt(_i.flowx, 'excludeFromFees',['0x39f6a6c85d39d5abad8a398310c52e7c374f2ba3'])
  await _txRcpt(_i.flowx, 'excludeFromRewards',['0x39f6a6c85d39d5abad8a398310c52e7c374f2ba3'])

  /** ADD LIQUIDITY TO FLOWX PAIR **/
  await require('./flowx_addLiquidityETH')(setup);

  /** LOCK LIQUIDITY TO FLOWX PAIR **/
  // await require('./UniLiqLock_toggle')(setup)

  /** USERS TRANSACT FLOWX **/
  await require('./flowx_user_transactions')(setup);

  /** USER 2 BUYS FLOWX **/
  await require('./reportTokenBalances')(setup)
  const newPairAddress = await require('./Router_addLiquidityETH')(setup)

  // await run('./Router_removeLiquidityETH')
  await require('./reportTokenBalances')(setup)
  console.log('_addr.FlowX: ',setup._addr.FlowX)
  console.log('_addr.FlowXPair: ',setup._addr.FlowXPair)
  //await run('./FTPLiqLock_report')
  // await run('./FTPLiqLock_toggle')
  // await run('./FTPLiqLock_report')
  //await run('./reportTokenBalances')
  // await require('./Router_swapExactETHForTokens')(setup)

  function flowxListeners(){
    setup._i.flowx.on('SwapAndSendToDev', (swapTokens, newBalance) =>{console.log('::Event SwapAndSendToDev:: ',swapTokens, newBalance)});
    setup._i.flowx.on('SetAutomatedMarketMakerPair',(pair, value)=>{console.log('::Event SetAutomatedMarketMakerPair:: ',pair, value)});
    setup._i.flowx.on('LiquidityWalletUpdated',(newLiquidityWallet, oldLiquidityWallet)=>{console.log('::Event LiquidityWalletUpdated:: ',newLiquidityWallet, oldLiquidityWallet)});
    setup._i.flowx.on('GasForProcessingUpdated',(newValue, oldValue)=>{console.log('::Event GasForProcessingUpdated:: ',newValue, oldValue)});
    setup._i.flowx.on('LiquidationThresholdUpdated',(newValue, oldValue)=>{console.log('::Event LiquidationThresholdUpdated:: ',newValue, oldValue)});
    setup._i.flowx.on('Liquified',(tokensSwapped, ethReceived, tokensIntoLiqudity)=>{console.log('::Event Liquified:: ',tokensSwapped, tokensIntoLiqudity)});
    setup._i.flowx.on('SentDividends',(tokensSwapped, amount)=>{console.log('::Event SentDividends:: ',tokensSwapped, amount)});
  }

  async function flowxBals(){
    const czechem = {
      deployer: _addr.deployer, charity: _addr.charity, marketing: _addr.marketing,
      aaaa: _addr.aaaa, bbbb: _addr.bbbb, cccc: _addr.cccc, dddd: _addr.dddd,
      UniswapV2Router02: _addr.UniswapV2Router02, UniswapV2Factory: _addr.UniswapV2Factory,
      FlowXPair: _addr.FlowXPair, UniLiqLock: _addr.UniLiqLock,
    }
    for (const [addrKey, addrValue] of Object.entries(czechem)) {
      const bal = await _i.flowx.balanceOf(addrValue, { ..._g.gasVals });
      log3(`flowx bal for ${addrKey}: `, [bal.toString(), (parseInt(bal.toString()) / (10**9)).toFixed(2)])
    }
  }
}



main().then(() => process.exit(0)).catch(error => {debugger;
  logTxError(error);console.error(error);process.exit(1);
});
