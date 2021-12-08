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
    _txRcpt,
    _receipt, //(logMsg, tx)
    _awaitDeployed, //(<ABI name>, <'new'|address>)
    __testPair, //(tokenAddress)
    _sleep, //(ms)
    _addr, _g, _i,
    __reportTokenBalances,
    __dynamicReportTokenBalances,
  } = setup;
  //await hre.run('compile');

/*
  const tokenBal = (await _i.mocky.balanceOf(_addr.deployer, { ..._g.gasVals })).toString();
  const tokenDecimals = await _i.mocky.decimals();
  let initialLiquidityOfToken = tokenBal;
  // let initialLiquidityOfToken = (parseInt(tokenBal) * (10**18)).toString();
*/
/** NOTE:
 * addLiquidityETH(, amountTokenDesired,,,,) accepts a
 * string of the token supply expanded by its decimal
 * Eg. initialLiquidityOfToken  "1000000000000000000000" for 1 trillion "tokens"
 * **/
  const TOKEN_INST = _i.mocky;
  const TOKEN_ADDR = _i.mocky.address;

  const tokenBal = await TOKEN_INST.balanceOf(_addr.deployer, { ..._g.gasVals });
  const tokenDecimals = await TOKEN_INST.decimals();
  let initialLiquidityOfToken = tokenBal.toString();
  let addr_pair = false;
  console.log(`tokenBal `, tokenBal)
  console.log(`initialLiquidityOfToken `, initialLiquidityOfToken)

  let initialLiquidityOfEth = parseUnits("1", "ether");
  console.log(`initialLiquidityOfEth `, initialLiquidityOfEth)

  if(tokenBal === 0){
    log2('deployer has no mocky tokens');
  }else {
    log2('deployer has mocky tokens, adding them to liquidity...');

    //-------APPROVE & ADD LIQUIDITY--------//

    await _txRcpt(TOKEN_INST, 'approve',[
        _addr.UniswapV2Router02,
        // initialLiquidityOfToken
        MaxUint256
        ,{from: _addr.deployer, ..._g.gasVals}
      ]
    ).then((res)=>{
      log2(`approve success: `, res);
    })
    .catch((err)=>{
      log2(`approve fail: `, err);
    });

    const cStaticResult = await __callStatic(_i.router, 'addLiquidityETH', [
      TOKEN_ADDR,
      initialLiquidityOfToken,
      parseEther("0"), // slippage is unavoidable
      parseEther("0"), // slippage is unavoidable
      deployer.address,
      (Date.now() + (60000 * 15)) // n minutes
      ,{ value: initialLiquidityOfEth, ..._g.gasVals}
    ]);

    if(cStaticResult){
    // if(true){
      console.log(`---performing addLiquidityETH()---`)
      // addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline)
      // payable returns (uint amountToken, uint amountETH, uint liquidity);
      await _txRcpt(_i.router, 'addLiquidityETH',[
          TOKEN_ADDR,
          initialLiquidityOfToken,
          parseEther("0"), // slippage is unavoidable
          parseEther("0"), // slippage is unavoidable
          deployer.address,
          (Date.now() + (60000 * 15)) // n minutes
          ,{ value: initialLiquidityOfEth, ..._g.gasVals}
        ]
      )
      .then(async(res)=>{
        // await __reportTokenBalances()
        //-------PAIR--------//
        addr_pair = await __testPair(TOKEN_ADDR)
        log2(`new pair address: `, addr_pair);
      });

    }
  }
  return addr_pair
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
