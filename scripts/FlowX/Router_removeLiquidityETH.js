const {
  log1, log2, log3, logE, ethScanURI, logTxError
} = require('./util/logUtils');

async function main(setup) {
  if(!setup){setup = await require("./_setup")();}
  const {
    hre, ethers,
    provider, BigNumber, bigNumberify,
    parseEther, parseUnits,
    MaxUint256,
    log1, log2, log3, logE,//(logMsg, data)
    accounts, deployer, user,
    __callStatic, //(instance, methodAsString, argsArray)
    _receipt, //(logMsg, tx)
    _txRcpt,
    _awaitDeployed, //(<ABI name>, <'new'|address>)
    __testPair, //(tokenAddress)
    _sleep, //(ms)
    _addr, _g, _i,
    __reportTokenBalances,
    __dynamicRtbObject,
    __dynamicReportTokenBalances,
  } = setup;
  //await hre.run('compile');

  console.log('_i.mockyPair.signer.address: ', await _i.mockyPair.signer.address)
  await _txRcpt(_i.mocky, 'approve',[
      _addr.UniswapV2Router02,
      // initialLiquidityOfToken
      ethers.constants.MaxUint256
      ,{from: _addr.deployer, ..._g.gasVals}
    ]
  )

  /*
    const tokenBal = (await _i.mocky.balanceOf(_addr.deployer, { ..._g.gasVals })).toString();
    const tokenDecimals = await _i.mocky.decimals();
    let initialLiquidityOfToken = tokenBal;
    // let initialLiquidityOfToken = (parseInt(tokenBal) * (10**18)).toString();
  */
  await __dynamicReportTokenBalances({
    tokens: {'_i.mocky': _i.mocky, '_i.mockyPair': _i.mockyPair},
    addrs: {
      '_addr.deployer':_addr.deployer,
      '_addr.UniswapV2Router02': _addr.UniswapV2Router02,
      '_addr.MockyPair': _addr.MockyPair,
      '_addr.WETH': _addr.WETH,
    }
  })

  const MINIMUM_LIQUIDITY = BigNumber.from(10).pow(3)
  const tokenBal = await _i.mockyPair.balanceOf(_addr.deployer, { ..._g.gasVals });
  const tokenDecimals = await _i.mocky.decimals();
  let initialLiquidityOfToken = parseInt(tokenBal.toString())/* / (10**tokenDecimals)*/;
  initialLiquidityOfToken = initialLiquidityOfToken.toString();

  console.log(`tokenBal `, tokenBal);
  console.log(`initialLiquidityOfToken `, initialLiquidityOfToken);



    //-------APPROVE & ADD LIQUIDITY--------//


/*
  removeLiquidityETH(
    address token,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline
) public virtual override ensure(deadline) returns (uint amountToken, uint amountETH)
*/
    if(true){
      console.log(`---performing removeLiquidityETH()---`)

      await _txRcpt(_i.router, 'removeLiquidityETH',[
          _addr.MockyToken,
          initialLiquidityOfToken,
          parseEther("0"), // slippage is unavoidable
          parseEther("0"), // slippage is unavoidable
          // initialLiquidityOfToken,
          // initialLiquidityOfEth,
          deployer.address,
          (Date.now() + (60000 * 15)) // n minutes
          ,{ ..._g.gasVals }
        ]
      )
      //log2(`__testPair address: `, await __testPair(_addr.MockyToken));

    }

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
