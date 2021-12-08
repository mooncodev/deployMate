const { ChainId, Token, WETH, Pair, TokenAmount, Fetcher, Route, Trade, TradeType, Percent  }
  = require("@uniswap/sdk");

async function main(setup) {
  if(!setup){setup = await require("./!setup_flowx")();}
  const {
    accounts, _addr, _g, _i, _deployNew,appendToLog, _txRcpt,_txRcptAs
  } = setup;
  const [deployer, charity, marketing, aaaa, bbbb, cccc, dddd] = accounts;

  const oneMillion = (1_000_000 * (10**9)).toString();
  const oneBillion = (1_000_000_000 * (10**9)).toString();


  const _FlowX = new Token(ChainId.ROPSTEN, _addr.FlowX, 9);


  const _FlowXPair = await Fetcher.fetchPairData(_FlowX, WETH[_FlowX.chainId]);
  const route = new Route([_FlowXPair], WETH[_FlowX.chainId]);
  console.log(route.midPrice.toSignificant(6)); // 201.306
  console.log(route.midPrice.invert().toSignificant(6)); // 0.00496756

  const trade = new Trade(
    route,
    new TokenAmount(WETH[_FlowX.chainId], oneBillion),
    TradeType.EXACT_INPUT
  );
  console.log(trade.executionPrice.toSignificant(6));
  console.log(trade.nextMidPrice.toSignificant(6));

  const slippageTolerance = new Percent("50", "10000"); // 50 bips, or 0.50%

  const amountOutMin = trade.minimumAmountOut(slippageTolerance).raw; // needs to be converted to e.g. hex
  const path = [WETH[_FlowX.chainId].address, _FlowX.address];
  const to = _addr.aaaa; // should be a checksummed recipient address
  const deadline = Math.floor(Date.now() / 1000) + 60 * 20; // 20 minutes from the current Unix time
  const value = trade.inputAmount.raw; // // needs to be converted to e.g. hex

  /** BUY **/
  // function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)

  await _txRcptAs(aaaa, _i.router, 'swapETHForExactTokens',[
      oneMillion,
      path,
      to,
      deadline, // n minutes
      {value:value,..._g.gasVals}
    ]
  );

  /** SELL **/
  // function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)

}

if(!require.main.filename.includes('sequence_')){
  main().then(() => process.exit(0)).catch(err => {
    console.error(err);process.exit(1);});
}else{module.exports = main}
