const hre = require("hardhat");
const { ethers } = hre;
const {log1, log2, log3, logE} = require('./util/chalks');

const { _receipt, _awaitDeployed, _sleep, ethScanURI } = require("./util/utils.js");
const { BigNumber, provider } = ethers;
const { MaxUint256 } = ethers.constants;
const { parseEther, parseUnits } = ethers.utils;
let tx, rcpt, weth, addr_pair, pair, bals;

const addr_alleth_UniswapV2Router02 = "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D";
const addr_ropsten_WETH = "0xc778417E063141139Fce010982780140Aa0cD5Ab";
const addr_alleth_UniswapV2Factory = "0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f";
const addr_alleth_UniV2Pair = "?";
const addr_ropsten_currentPair = "0xbd9A172dBd14F381e90106fBf59B0F1C9c62Eb5c";
const addr_ropsten_FACTORY_V3 = "0x1F98431c8aD98523631AE4a59f267346ea31F984";
const addr_ropsten_MockyToken = "0xE1f5d27cE84D46BD4295C2F94887Ff87a8ac6A27";
const addr_ropsten_FTPLiqLock = "0x3Fcc7d2decE3750427Aa2a6454c1f1FE6d7B1c92";
const addr_allbsc_PANCAKEROUTER = "0x10ED43C718714eb63d5aA57B78B54704E256024E"
const addr_allbsc_PANCAKEFACTORY = "0xca143ce32fe78f1f7019d7d551a6402fc5350c73"
const addr_bsc_WBNB = "0xbb4cdb9cbd36b01bd1cbaebf2de08d9173bc095c"
const addr_alleth_WETH = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";
const addr_alleth_USDC = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";
const addr_usdcWethPool = "0x8ad599c3A0ff1De082011EFDDc58f1908eb6e6D8";
const PROJECT_ROOT = `${__dirname}/../../..`;


async function main() {
  await hre.run('compile');
  const accounts = await ethers.getSigners();
  const [deployer, user] = accounts;
  console.log("Using account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance() / 10**18).toString());
  console.log("hre.network.name:", hre.network.name);

  const getBlockNumber = await provider.getBlockNumber().then(r=>{log3('getBlockNumber',r);return r});
  const getBlock = await provider.getBlock(getBlockNumber).then(r=>{log3('getBlock',r);return r});
  const getBlockTimestamp = getBlock.timestamp;
  const getFeeData = await provider.getFeeData().then(r=>{log3('getFeeData',r);return r});
  const getGasPrice = getFeeData.gasPrice;
  const gasLimit = getBlock.gasLimit.toString();
  console.log("getGasPrice:", getGasPrice.toString());
  const gasVals = {gasLimit: 4512388, gasPrice: parseUnits('5.0', 'gwei')};

  //-------ESTABLISH TOKEN--------//
  const mocky = await _awaitDeployed({
    name:'MockyToken',
    newOrExisting: 0?'new':addr_ropsten_MockyToken
  })
  //-------ESTABLISH GENERIC INSTANCES--------//
  const router = await ethers.getContractAt('IUniswapV2Router02', addr_alleth_UniswapV2Router02)
  const factory = await ethers.getContractAt('IUniswapV2Factory', addr_alleth_UniswapV2Factory)
  const ftpLiqLock = await ethers.getContractAt('FTPLiqLock', addr_ropsten_FTPLiqLock)
  //-------ESTABLISH WETH--------//
  const addr_WETH = await router.WETH();
  console.log("addr_WETH:", addr_WETH);
  weth = await ethers.getContractAt('IWETH', addr_WETH);
  //-------ESTABLISH PAIR--------//
  addr_pair = await __testPair(mocky.address)
  if(addr_pair){pair = await ethers.getContractAt('IUniswapV2Pair', addr_pair);}
  else{console.log('NO PAIR FOUND')}


  //--------END OF SETUP---------//
  //--------BEGIN ACTION---------//

  bals = await __reportTokenBalances()

  if(bals.mocky.deployer === 0){
    log2('deployer has no mocky tokens, moving to test the lock');
  }else {
    log2('deployer has mocky tokens, adding them to liquidity...');

    //-------APPROVE & ADD LIQUIDITY--------//
    await _receipt('approve>>router',
      await mocky
      .approve(
        router.address,
        bals.mocky.deployer
        // ethers.constants.MaxUint256
        ,{from: deployer.address, ...gasVals}
      )
    );

    const ONE_ETH = parseUnits("0.5", "ether");
    let initialLiquidityOfToken = parseEther('500000000');
    let initialLiquidityOfEth = ONE_ETH;
    initialLiquidityOfToken = bals.mocky.deployer
    // addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline)
    // payable returns (uint amountToken, uint amountETH, uint liquidity);
    await _receipt('addLiquidityETH',
      await router.connect(deployer)
      .addLiquidityETH(
        mocky.address,
        initialLiquidityOfToken,
        parseEther("0"), // slippage is unavoidable
        parseEther("0"), // slippage is unavoidable
        // initialLiquidityOfToken,
        // initialLiquidityOfEth,
        deployer.address,
        (Date.now() + (60000 * 15)) // n minutes
        ,{ value: initialLiquidityOfEth, ...gasVals}
      )
    );

    bals = await __reportTokenBalances()
    //-------PAIR--------//
    addr_pair = await __testPair(mocky.address)
  }

  // removeLiquidityETH(address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline)
  // returns (uint amountToken, uint amountETH);


  //------- REPORT LOCK STATUS --------//
  //getLockedTokens(address _uniPair)
  //returns (bool Locked, uint256 ReleaseDate, address PayoutAddress)
  const getLockedTokens = await ftpLiqLock
    .getLockedTokens(
      addr_pair
      ,{...gasVals}
    )
  const [lockStatus, releaseDate, payoutAddress] = getLockedTokens;

  if(lockStatus){
    log2('lock was true', getLockedTokens)
  }else{
    log2('lock was false, approving & locking...', lockStatus)
    //------- APPROVE & LOCK LIQUIDITY --------//
    await _receipt('approve>>ftpLiqLock',
      await pair
      .approve(
        ftpLiqLock.address,
        MaxUint256
        ,{...gasVals}
      )
    );

    //lockTokens(address _uniPair, uint256 _epoch, address _tokenPayout)
    await _receipt('lockTokens',
      await ftpLiqLock
      .lockTokens(
        addr_pair,
        (Date.now() + (60000 * 15)), // n minutes
        deployer.address
        ,{...gasVals}
      )
    );
  }
  bals = await __reportTokenBalances()

  //------- REPORT TOKEN BALANCES --------//
  async function __reportTokenBalances(){
    log3('__reportTokenBalances():')
    const bals = {
      mocky: {
        'deployer':await getTokenBal(mocky, deployer.address),
        'router':await getTokenBal(mocky, router.address),
        'factory':await getTokenBal(mocky, factory.address),
        'addr_pair':await getTokenBal(mocky, addr_pair),
        'ftpLiqLock':await getTokenBal(mocky, ftpLiqLock.address),
      },
      pair: {
        'deployer':await getTokenBal(pair, deployer.address),
        'router':await getTokenBal(pair, router.address),
        'factory':await getTokenBal(pair, factory.address),
        'addr_pair':await getTokenBal(pair, addr_pair),
        'ftpLiqLock':await getTokenBal(pair, ftpLiqLock.address),
      },
      eth: {
        'deployer':await getEthBal(deployer.address),
        'router':await getEthBal(router.address),
        'factory':await getEthBal(factory.address),
        'addr_pair':await getEthBal(addr_pair),
        'ftpLiqLock':await getEthBal(ftpLiqLock.address),
      }
    }
    log3('balances: ',bals);
    return bals;
  }
  async function getTokenBal(instToken, addrToCheck){
    if(instToken.balanceOf==null){return false}
    const tokenBal = await instToken.balanceOf(addrToCheck, { ...gasVals });
    const tokenDecimals = await instToken.decimals();
    return parseInt(tokenBal.toString()) / (10**tokenDecimals);
  }
  async function getEthBal(addrToCheck){
    if(!addrToCheck){return false}
    const ethBal = await provider.getBalance(addrToCheck);
    return parseInt(ethBal.toString()) / (10**18);
  }
  async function __testPair(tokenAddress){
    //getPair(address tokenA, address tokenB)
    return await factory.connect(deployer)
    .getPair(tokenAddress, addr_WETH
      ,{...gasVals});
  }




  // await uniswapRouter.swapExactETHForTokens(
  //   1,
  //   [addr_alleth_WETH, addr_alleth_USDC],
  //   accounts[0].address,
  //   2525644800,
  //   {
  //     gasLimit: 4000000,
  //     value: parseEther("100"),
  //   },
  // );


}


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
.then(() => process.exit(0))
.catch(error => {
  console.error(error);
  logE('error.reason/code: ' + error.reason + ` ` + error.code);
  if(error.transaction){
    logE('error.transactionHash: ' + error.transactionHash);
    logE(ethScanURI.tx + error.transactionHash);
    logE('error.transaction: ' + JSON.stringify(error.transaction));
    logE('tx.value: ' + error.transaction.value.toString());
    logE('tx.gasPrice: ' + error.transaction.gasPrice.toString());
    logE('tx.gasLimit: ' + error.transaction.gasLimit.toString());
    if(error.transaction.effectiveGasPrice){
      logE('tx.effectiveGasPrice: ' + error.transaction.effectiveGasPrice.toString());
    }
    if(error.transaction.cumulativeGasUsed){
      logE('tx.cumulativeGasUsed: ' + error.transaction.cumulativeGasUsed.toString());
    }
    if(error.transaction.gasUsed){
      logE('tx.gasUsed: ' + error.transaction.gasUsed.toString());
    }
    if(error.transaction.nonce){
      logE('tx.nonce: ' + error.transaction.nonce.toString());
    }
  }
  process.exit(1);
});
