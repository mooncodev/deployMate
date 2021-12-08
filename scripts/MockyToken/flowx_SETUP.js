module.exports = async function (){
  const hre = require("hardhat");
  const { ethers } = hre;
  const { BigNumber, provider } = ethers;
  const { MaxUint256 } = ethers.constants;
  const { parseEther, parseUnits } = ethers.utils;
  const {log1, log2, log3, logE, logTxError, ethScanURI, appendToLog} = require('./util/logUtils');

  function expandTo9Decimals(n) {
    return BigNumber(n).mul(BigNumber(10).pow(9))
  }
  function expandTo18Decimals(n) {
    return BigNumber(n).mul(BigNumber(10).pow(18))
  }
  const accounts = await ethers.getSigners();
  const [deployer, chtywallet, mktgwallet, lqtywallet, aaaa, bbbb, cccc, dddd] = accounts;

  console.log("Using account:", deployer.address);
  console.log("hre.network.name:", hre.network.name);

  let _g = {}
  _g.PROJECT_ROOT = `${__dirname}/../../..`;
  _g.getBlockNumber = await provider.getBlockNumber();
  _g.getBlock = await provider.getBlock(_g.getBlockNumber);
  _g.getBlockTimestamp = _g.getBlock.timestamp;
  _g.getFeeData = await provider.getFeeData();
  _g.getGasPrice = _g.getFeeData.gasPrice;
  _g.gasLimit = _g.getBlock.gasLimit.toString();
  _g.gasVals = {gasLimit: 4512388, gasPrice: parseUnits('6.2', 'gwei')};


  let _addr = {
    ropsten: {
      chtywallet: "0xb849fBBfB25b679ADdFAD5Ebe94132c9ec7803aa",
      mktgwallet: "0xF2d5C58cB49148D7cFC00E833328f15D92e95fdC",
      lqtywallet: "0xF2d5C58cB49148D7cFC00E833328f15D92e95fdC",
      aaaa: "0xb41bf98ff97453661a21dc99c8f0a655e30baaaa",
      bbbb: "0x36c695ed875658ee9e87226b002e64ed8102bbbb",
      cccc: "0x6c8afec8e9d22016ad5d22457a07913b899dcccc",
      dddd: "0x5e9aff74c382335a7ccd7e6b31e0982b6750dddd",
      FlowX: "0xEe6432228774737B00C02b097BBEc597AAbFe637",
      UniswapV2Router02: "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D",
      UniswapV2Factory: "0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f",
      FTPLiqLock: "0x3Fcc7d2decE3750427Aa2a6454c1f1FE6d7B1c92",
      UniLiqLock: "0xdBc5b192652178e2f35f48583241d9b50C8d8FB9",
      ref__deployer: "0x1eE134E4Fccd51aEbB0B2d1e475ae4f57d41ac70",
      ref__WETH: "0xc778417E063141139Fce010982780140Aa0cD5Ab",
    },
    mainnet:{
      UniswapV2Router02: "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D",
      UniswapV2Factory: "0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f",
      UniV2Pair: "?",
      WETH: "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
      USDC: "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",
      Vendetta: "0x06736757b9a7f64e408b187205f266e96792df79",
      VendettaFrogeDeployer: "0x22b91423ecd5cb31e0b31ab95002c5baf7b2e7a6",
      VendettaSmthn: "0x77d72be452cc46a78b77645fff8692d11073016d",
    }
  }[hre.network.name];
  _addr.deployer = deployer.address;
  _addr.chtywallet = chtywallet.address;
  _addr.mktgwallet = mktgwallet.address;
  _addr.lqtywallet = lqtywallet.address;
  _addr.aaaa = aaaa.address;
  _addr.bbbb = bbbb.address;
  _addr.cccc = cccc.address;
  _addr.dddd = dddd.address;
  _addr.null = "0x0000000000000000000000000000000000000000";

  let _i = {};
  //-------ESTABLISH TOKEN--------//
  _i.flowx = await ethers.getContractAt("FlowX", _addr.FlowX);
  //-------ESTABLISH GENERIC INSTANCES--------//
  _i.router = await ethers.getContractAt('IUniswapV2Router02', _addr.UniswapV2Router02)
  _i.factory = await ethers.getContractAt('IUniswapV2Factory', _addr.UniswapV2Factory)
  _i.ftpLiqLock = await ethers.getContractAt('FTPLiqLock', _addr.FTPLiqLock)
  _i.uniLiqLock = await ethers.getContractAt('UniLiqLock', _addr.UniLiqLock)
  //-------ESTABLISH WETH--------//
  _addr.WETH = await _i.router.WETH();
  _i.weth = await ethers.getContractAt('IWETH', _addr.WETH);
  //-------PAIR--------//
  // _addr.MockyPair = await __testPair(_addr.MockyToken);
  // if(_addr.MockyPair !== _addr.null){
  //   _i.mockyPair = await ethers.getContractAt('IUniswapV2Pair', _addr.MockyPair);
  // } else{console.log('NO PAIR FOUND')}



  function _sleep(ms) {//usage: await _sleep(5000);
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  async function __callStatic(instance, strMethod, argsArray){
    let result;
    console.log(`__callStatic: inst.callStatic.${strMethod}: `)
    await instance.callStatic
      [strMethod](
      ...argsArray
    )
    .then((res)=>{
      console.log(`::CALLSTATIC SUCCESS::`);
      console.log(`res: `, res);
      reportAnyBigNums(res);
      result = true;
    })
    .catch((err)=>{
      console.log(`::CALLSTATIC FAILED::`)
      console.log(`__callStatic err: `, err)
      console.log(`__callStatic err.error: `, err.error)
      result = false;
    })
    return result;
  }
  async function __reportLockStatus(){
    //getLockedTokens(address _uniPair)
    //returns (bool Locked, uint256 ReleaseDate, address PayoutAddress)
    const {Locked, ReleaseDate, PayoutAddress} = await _i.ftpLiqLock
    .getLockedTokens(
      _addr.MockyPair
      ,{..._g.gasVals}
    )
    log2('lockStatus: ', Locked)
    const releaseEpoch = ReleaseDate.toNumber()*1000;
    const currentEpoch = Date.now();
    const releaseDateString = new Date(releaseEpoch).toISOString();
    const currentDateString = new Date(currentEpoch).toISOString();
    console.log('releaseDateString: ', releaseDateString)
    console.log('currentDateString: ', currentDateString)
    const bIsReleaseTimePassed = releaseEpoch < currentEpoch;
    log2('payoutAddress: ', PayoutAddress)
    return {Locked: Locked, IsReleaseTimePassed: bIsReleaseTimePassed};
  }

  function reportAnyBigNums(obj, depthKey='', depthCount=0){
    if(depthCount===0){console.log(`---init reportAnyBigNums()---`)}
    for (const [key, value] of Object.entries(obj)) {
      if(depthCount>2){continue;}//don't recurse too deep
      if(key.length<3){continue;}//exclude short keyname props (ie. digit keynames)
      if(value==null || typeof(value)!=='object'){continue;}
      if(value._isBigNumber){//this object is a BigNumber
        if(depthKey.length){
          console.log(`found BigNumber "${depthKey} > ${key}" is: `, value.toString())}
        else{console.log(`found BigNumber "${key}" is: `, value.toString())}
      }else{//possibly recurse
        //value is an object without _isBigNumber
        // , check its props for new objects to recurse over
        for (const [_key, _value] of Object.entries(value)) {
          if(typeof(_value)==='object'){
            reportAnyBigNums(_value, _key, depthCount++)
          }
        }
      }
    }
  }

  async function _receipt(txName, tx){
    log1(`${txName} tx: `, tx)
    const rcpt = await tx.wait();
    log2(`${txName} rcpt: `, rcpt)
    await _sleep(5000);
    return rcpt
  }

  async function _txRcpt(inst, strMethod, argsArray){
    let csresult;
    await inst.callStatic
      [strMethod](
      ...argsArray
    )
    .then((res)=>{
      console.log(`::CALLSTATIC SUCCESS::`, res);
      reportAnyBigNums(res);
      csresult = true;
    })
    .catch((err)=>{
      console.log(`::CALLSTATIC FAILED::`, err)
      console.log(`super special message: `, err.error.message)
      csresult = false;
    })
    if(!csresult){return false}
    console.log(`init _txRcpt: inst.${strMethod}: `);
    let result;
    const tx = await inst
      [strMethod](
      ...argsArray
    );
    log1(`${strMethod} tx: `, tx);
    log3(`awaiting reciept for ${strMethod}...`);
    await tx.wait()
      .then((res)=>{
        reportAnyBigNums(res);
        result = true;
        console.log(`::_txRcpt>${strMethod} SUCCESS::`);
        console.log(`_txRcpt>rcpt res: `, res);
        try{log3(ethScanURI.tx + res.transactionHash);}catch(e){}
      })
      .catch((err)=>{
        console.log(`::_txRcpt>${strMethod} FAILED::`);
        logTxError(err)
        result = false;
      })
    ;
    await _sleep(5000);
    return result;

  }
  async function _txRcptAs(acct, inst, strMethod, argsArray){
    let csresult;
    await inst.connect(acct).callStatic
      [strMethod](
      ...argsArray
    )
    .then((res)=>{
      console.log(`::CALLSTATIC SUCCESS::`, res);
      reportAnyBigNums(res);
      csresult = true;
    })
    .catch((err)=>{
      console.log(`::CALLSTATIC FAILED::`, err)
      console.log(`super special message: `, err.error.message)
      csresult = false;
    })
    if(!csresult){return false}
    console.log(`init _txRcpt: inst.${strMethod}: `);
    let result;
    const tx = await inst.connect(acct)
      [strMethod](
      ...argsArray
    );
    log1(`${strMethod} tx: `, tx);
    log3(`awaiting reciept for ${strMethod}...`);
    await tx.wait()
      .then((res)=>{
        reportAnyBigNums(res);
        result = true;
        console.log(`::_txRcpt>${strMethod} SUCCESS::`);
        console.log(`_txRcpt>rcpt res: `, res);
        try{log3(ethScanURI.tx + res.transactionHash);}catch(e){}
      })
      .catch((err)=>{
        console.log(`::_txRcpt>${strMethod} FAILED::`);
        logTxError(err)
        result = false;
      })
    ;
    await _sleep(5000);
    return result;

  }

  async function __testPair(tokenAddress){
    //getPair(address tokenA, address tokenB)
    return await _i.factory.connect(deployer)
    .getPair(
      tokenAddress,
      _addr.WETH
      ,{..._g.gasVals}
    );
  }

  async function _awaitDeployed(opts) {
    let inst;
    if(opts.newOrExisting === 'new'){
      const gcf = await ethers.getContractFactory(opts.name);
      inst = await gcf.deploy();
      let dtx = inst.deployTransaction;
      dtx.data = '';
      log1(`New deploy "${opts.name}" tx: `, dtx);
      log3(`awaiting reciept for ${opts.name}...`);
      const rcpt = await inst.deployTransaction.wait();
      log1(`New deploy "${opts.name}" rcpt: `, rcpt);
    } else{
      inst = await ethers.getContractAt(opts.name, opts.newOrExisting)
      log3(`Using Existing Deploy for "${opts.name}"`);
      log3(`Token Address:`, inst.address);
    }
    await _sleep(5000);
    return inst;
  }
  async function _deployNew(opts) {
    const gcf = await ethers.getContractFactory(opts.artifact,
      opts.libraries?{libraries: opts.libraries}:{});
    let inst;
    if(opts.deployArgs){ inst = await gcf.deploy(...opts.deployArgs);
    }else{ inst = await gcf.deploy(); }
    let dtx = inst.deployTransaction;
    delete dtx.data;
    log1(`New deploy "${opts.artifact}" tx: `, dtx);
    log3(`awaiting reciept for ${opts.artifact}...`);
    const rcpt = await inst.deployTransaction.wait();
    delete rcpt.logsBloom;
    delete rcpt.logs;
    delete rcpt.events;
    log1(`New deploy "${opts.artifact}" rcpt: `, rcpt);
    log3(`rcpt.contractAddress: `, rcpt.contractAddress);
    appendToLog({[`New ${opts.artifact} Deployment`]: inst.address})
    await _sleep(3000);
    return inst;
  }


//------- REPORT TOKEN BALANCES --------//
  async function __reportTokenBalances(){
    return (await __dynamicReportTokenBalances({
      tokens: {
        'flowx': _i.flowx,
        'flowxPair': _i.flowxPair,
      },
      addrs: {
        'deployer': _addr.deployer,
        'UniswapV2Router02': _addr.UniswapV2Router02,
        'UniswapV2Factory': _addr.UniswapV2Factory,
        'flowxPair': _addr.FlowXPair,
        'UniLiqLock': _addr.UniLiqLock,
        'WETH': _addr.WETH,
      }
    }))
  }
  async function __dynamicReportTokenBalances(o){
    const output = {eth:{}};
    for (const [addrKey, addrValue] of Object.entries(o.addrs)) {
      for (const [tokenKey, tokenValue] of Object.entries(o.tokens)) {
        if(output[tokenKey]==null){output[tokenKey] = {};}
        output[tokenKey][addrKey] = await getTokenBal(tokenValue, addrValue);
      }
      output.eth[addrKey] = await getEthBal(addrValue);
    }
    log3('bals: ',output);
    return output;
  }
  async function getTokenBal(instToken, addrToCheck){
    if(instToken==null){return "no instance"}
    if(instToken.balanceOf==null){return "no balanceOf method"}
    if(addrToCheck===_addr.null){return "0x00 address"}
    const tokenBal = await instToken.balanceOf(addrToCheck, { ..._g.gasVals });
    const tokenDecimals = await instToken.decimals();
    return [tokenBal.toString(), (parseInt(tokenBal.toString()) / (10**tokenDecimals)).toFixed(2)];
  }
  async function getEthBal(addrToCheck){
    if(!addrToCheck){return false}
    if(addrToCheck===_addr.null){return "0x00 address"}
    const ethBal = await provider.getBalance(addrToCheck);
    return parseInt(ethBal.toString()) / (10**18);
  }

//...notice: this is an ethers.js throttled action
// let etherscanProvider = new ethers.providers.EtherscanProvider();
// etherscanProvider.getHistory(deployer.address).then((history) => {
//   console.log(history)
// });
  log3('_g.getBlockNumber: ',_g.getBlockNumber);
  // log3('_g.getFeeData: ',_g.getFeeData);
  log3('_g.getGasPrice: ',_g.getGasPrice.toString());
  log3('_g.gasLimit: ',_g.gasLimit);
  // log3('_g.gasVals: ',_g.gasVals);
  // log3('_addr: ',_addr);
  // log3('_addr.WETH: ',_addr.WETH);

  return {
    hre, ethers,
    provider, BigNumber,
    parseEther, parseUnits,
    MaxUint256,
    log1, log2, log3, logE,
    appendToLog,
    accounts, deployer,
    expandTo9Decimals,
    expandTo18Decimals,
    __reportLockStatus,
    _receipt,
    _txRcpt,_txRcptAs,
    __callStatic,
    _awaitDeployed,
    _deployNew,
    __testPair,
    _sleep,
    _addr,
    _g,
    _i,
    __reportTokenBalances,
    __dynamicReportTokenBalances,
  }

}

