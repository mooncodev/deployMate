const {logTxError} = require('./util/logUtils');

async function main() {
  const setup = await require("./_setup")();
  async function run(path){
    console.log(`%%% run(${path}) init %%%`)
    await require(path)(setup)
    .then(()=>{console.log(`%%% run(${path}) finished %%%`)})
    .catch(e=>{debugger;console.error(e);throw Error})
  }

  const newMockyAddress = await require('./DeployNew_MockyToken')(setup);
  setup._addr.MockyToken = newMockyAddress;
  await require('./reportTokenBalances')(setup)
  const newPairAddress = await require('./Router_addLiquidityETH')(setup)
  setup._addr.MockyPair = newMockyAddress;
  await require('./FTPLiqLock_report')(setup)
  await require('./FTPLiqLock_toggle')(setup)
  await require('./FTPLiqLock_report')(setup)
  // await run('./Router_removeLiquidityETH')
  await require('./reportTokenBalances')(setup)
  console.log('_addr.MockyToken: ',setup._addr.MockyToken)
  console.log('_addr.MockyPair: ',setup._addr.MockyPair)
  //await run('./FTPLiqLock_report')
  // await run('./FTPLiqLock_toggle')
  // await run('./FTPLiqLock_report')
  //await run('./reportTokenBalances')
  // await require('./Router_swapExactETHForTokens')(setup)

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
.then(() => process.exit(0))
.catch(error => {
  debugger;
  logTxError(error);
  console.error(error);
  process.exit(1);
});
