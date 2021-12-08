const {
  log1, log2, log3, logE, ethScanURI, logTxError
} = require('./util/logUtils');

async function main(setup) {
  if(!setup){setup = await require("./_setup")();}
  const {
    hre, ethers,
    provider, BigNumber,
    parseEther, parseUnits,
    MaxUint256,
    log1, log2, log3, logE,//(logMsg, data)
    accounts, deployer, user,
    __callStatic, //(instance, methodAsString, argsArray)
    _receipt, //(logMsg, tx)
    _awaitDeployed, //(<ABI name>, <'new'|address>)
    __testPair, //(tokenAddress)
    _sleep, //(ms)
    _addr, _g, _i,
    __reportTokenBalances,
    __dynamicRtbObject,
    __dynamicReportTokenBalances,
  } = setup;
  //await hre.run('compile');

  await __reportTokenBalances()

  await _i.router.swapExactETHForTokens(
    1,
    [_addr.weth, _addr.MockyToken],
    _addr.deployer,
    2525644800,
    {
      gasLimit: 4000000,
      value: parseEther("100"),
    },
  );

  await __reportTokenBalances()

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
