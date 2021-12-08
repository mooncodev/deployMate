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
    _txRcpt,
    _awaitDeployed, //(<ABI name>, <'new'|address>)
    __reportLockStatus,
    __testPair, //(tokenAddress)
    _sleep, //(ms)
    _addr, _g, _i,
    __reportTokenBalances,
    __dynamicRtbObject,
    __dynamicReportTokenBalances,
  } = setup;
  //await hre.run('compile');

  /*
  scenarios:
  0) mockyHolder: deployer,   pairHolder: null,       Locked: false, releasePassed: false,
 ---perform addLiquidity---
  1) mockyHolder: UniFactory, pairHolder: deployer,   Locked: false, releasePassed: false,
 ---perform lockTokens---
  2) mockyHolder: UniFactory, pairHolder: FTPLiqLock, Locked: true,   releasePassed: false,
 --- releaseTokens---
  3) mockyHolder: UniFactory, pairHolder: FTPLiqLock, Locked: false,  releasePassed: true,
 ---perform releaseTokens---
  4) mockyHolder: UniFactory, pairHolder: deployer,   Locked: false, releasePassed: false,
 ---perform removeLiquidity---
  5) mockyHolder: deployer,   pairHolder: deployer--, Locked: false, releasePassed: false,
 * */
  const bals = await __reportTokenBalances();
  const LLockerHasPairTokens = bals.mockyPair.FTPLiqLock > 0;
  const DeployerHasPairTokens = bals.mockyPair.deployer > 0;
  const {Locked, IsReleaseTimePassed} = await __reportLockStatus()

  if(!LLockerHasPairTokens && !DeployerHasPairTokens){
    log3('nothing to do! locker & deployer don\'t have any pair tokens');
  }
  else if(Locked){
    log3('nothing to do! tokens are locked but release date not yet passed')
  }
  else if(!Locked && LLockerHasPairTokens){

    const cStatic = await __callStatic(_i.ftpLiqLock, 'releaseTokens', [_addr.MockyPair])

    if(cStatic){
      //releaseTokens(address _uniPair)
      await _txRcpt(_i.ftpLiqLock, 'releaseTokens',[
          _addr.MockyPair
          ,{..._g.gasVals}
        ]
      );
    }

  }
  else if(!Locked && DeployerHasPairTokens){

    const blockTime = _g.getBlockTimestamp;
    const setReleaseDate = Math.floor((Date.now() / 1000) + (60 * 15)).toString();
    log3('blockTime      ',blockTime);
    log3('setReleaseDate ',setReleaseDate);

/*
    await _txRcpt(_i.mockyPair,'approve',[
        _addr.FTPLiqLock,
        MaxUint256
        ,{..._g.gasVals}
      ]
    );
*/

    //lockTokens(address _uniPair, uint256 _epoch, address _tokenPayout)
    await _txRcpt(_i.ftpLiqLock, 'lockTokens',[
        _addr.MockyPair,
        setReleaseDate, // n minutes
        _addr.deployer
        ,{..._g.gasVals}
      ]
    );

  }

  await __reportTokenBalances();
  await __reportLockStatus()

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
