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

  /*31622776601683793319
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
  const LockerPairBalance = bals.mockyPair.UniLiqLock[0];
  const DeployerPairBalance = bals.mockyPair.deployer[0];
  const addrLocker = _addr.UniLiqLock;
  const addrLpToken = _addr.MockyPair;
  const addrUser = _addr.deployer;
  const gasVals = _g.gasVals;
  let tokenLockIndex = -1; //TODO:
  let tokenLockID = -1; //TODO:
  let withdrawAmount = LockerPairBalance;
  let _found_lockIndex_ = -1;
  let _found_lockID_ = -1;
  let ACTIONS = {};
  let pl = {};

  // mapping(address => TokenLock[]) public tokenLocks; //map univ2 pair to all its locks
  // pl.tokenLocks = [addrLpToken, gasVals]
  // const cStatic = await __callStatic(_i.uniLiqLock, 'tokenLocks', pl.tokenLocks)
  // event onDeposit(address lpToken, address user, uint256 amount, uint256 lockDate, uint256 unlockDate);
  // event onWithdraw(address lpToken, uint256 amount);

  //.getUserNumLockedTokens(address _user) external view returns (uint256) {
  pl.getUserNumLockedTokens = [addrUser, gasVals];
  //.getNumLocksForToken(address _lpToken) external view returns (uint256) {
  pl.getNumLocksForToken = [addrLpToken, gasVals];
  //.getNumLockedTokens() external view returns (uint256) {
  pl.getNumLockedTokens = [gasVals];
  //.getUserNumLocksForToken(address _user, address _lpToken) external view returns (uint256) {
  pl.getUserNumLocksForToken = [addrUser, addrLpToken, gasVals];

  ACTIONS._GET_LOCK_ID_ = true;
  if(ACTIONS._GET_LOCK_ID_){


    const res_getUserNumLockedTokens = await _txRcpt(_i.uniLiqLock, 'getUserNumLockedTokens', pl.getUserNumLockedTokens);
    if(!res_getUserNumLockedTokens || res_getUserNumLockedTokens==='0'){
      console.log(`user has no locks!`);
    }else{console.log(`user has ${res_getUserNumLockedTokens} locks`);}

    const res_getNumLocksForToken = await _txRcpt(_i.uniLiqLock, 'getNumLocksForToken', pl.getNumLocksForToken);
    if(!res_getNumLocksForToken || res_getNumLocksForToken==='0'){
      console.log(`pair has no locks!`);
    }else{console.log(`pair has ${res_getNumLocksForToken} locks`);}

    //.getLockedTokenAtIndex(uint256 _index) external view
    //   returns (address) {
    pl.getLockedTokenAtIndex = [_found_index_, gasVals];//TODO: get index

    //.getUserLockedTokenAtIndex(address _user, uint256 _index) external view
    //   returns (address) {
    pl.getUserLockedTokenAtIndex = [addrUser, _found_index_, gasVals]; //TODO: get index

    //.getUserLockForTokenAtIndex(address _user, address _lpToken, uint256 _index) external view
    //   returns (uint256, uint256, uint256, uint256, uint256, address) {
    pl.getUserLockForTokenAtIndex = [addrUser, addrLpToken, _found_index_, gasVals];
  }
  
  ACTIONS._PERFORM_LOCK_ = false;
  if(ACTIONS._PERFORM_LOCK_){
    /*
    .lockLPToken(
      address _lpToken,
      uint256 _amount, // amount of LP tokens to lock
      uint256 _unlock_date, // epoch in seconds
      address payable _referral, //referrer user address (for fees discount/rewards promo) if any, or address(0) for none
      bool _fee_in_eth, // true
      address payable _withdrawer //who can withdraw liq on lock expiry
    ) external payable nonReentrant {
    */
    const ethLockFee = parseUnits("0.1", "ether");
    const amountToLock = DeployerPairBalance;
    const releaseEpochAsSeconds = Math.floor((Date.now() / 1000) + (60 * 15)).toString();
    const addrReferral = _addr.null;
    const bFeeInEth = "true";
    /*
      pl.approveBefore_lockLPToken = [addrLocker, MaxUint256, gasVals]
      const cStatic_approve = await _txRcpt(_i.mockyPair, 'approve', pl.approveBefore_lockLPToken)
    */
    pl.lockLPToken = [
      addrLpToken, amountToLock, releaseEpochAsSeconds, addrReferral, bFeeInEth, addrUser, {value: ethLockFee, ...gasVals}
    ]
    // const cStatic_lockLPToken = await __callStatic(_i.uniLiqLock, 'lockLPToken', pl.lockLPToken)
    await _txRcpt(_i.uniLiqLock, 'lockLPToken', pl.lockLPToken)
    
  }

  ACTIONS._WITHDRAW_ = false;
  if(ACTIONS._WITHDRAW_){

    //--withdraw a specified amount from a lock. _index and _lockID ensure the correct lock is changed
    //--this prevents errors when a user performs multiple tx per block possibly with varying gas prices
    //.withdraw(address _lpToken, uint256 _index, uint256 _lockID, uint256 _amount) external nonReentrant {
    pl.withdraw = [addrLpToken, tokenLockIndex, tokenLockID, withdrawAmount, gasVals];

  }


//--extend a lock with a new unlock date, _index and _lockID ensure the correct lock is changed
//.relock(address _lpToken, uint256 _index, uint256 _lockID, uint256 _unlock_date) external nonReentrant {
  const newUnlockDate = new Date('Oct 27, 2021 12:00:00').getTime();
  pl.relock = [addrLpToken, tokenLockIndex, tokenLockID, newUnlockDate, gasVals]
//--increase the amount of tokens per a specific lock, this is preferable to creating a new lock, less fees, and faster loading on our live block explorer
//.incrementLock(address _lpToken, uint256 _index, uint256 _lockID, uint256 _amount) external nonReentrant {
  const incrementAmount = '3' //TODO:
  pl.incrementLock = [addrLpToken, tokenLockIndex, tokenLockID, incrementAmount, gasVals]
//--split a lock into two seperate locks, useful when a lock is about to expire
//--and youd like to relock a portion and withdraw a smaller portion
//.splitLock(address _lpToken, uint256 _index, uint256 _lockID, uint256 _amount) external payable nonReentrant {
  const splitToNewLockAmount = '3' //TODO:
  pl.splitLock = [addrLpToken, tokenLockIndex, tokenLockID, splitToNewLockAmount, gasVals]
//transferLockOwnership(address _lpToken, uint256 _index, uint256 _lockID, address payable _newOwner) external {
//--migrates liquidity to uniswap v3
//.migrate(address _lpToken, uint256 _index, uint256 _lockID, uint256 _amount) external nonReentrant {
  const newOwner = _addr.bbbb //TODO:
  pl.migrate = [addrLpToken, tokenLockIndex, tokenLockID, newOwner, gasVals]

//.getWhitelistedUsersLength() external view returns (uint256) {
//.getWhitelistedUserAtIndex(uint256 _index) external view returns (address) {
  pl.getWhitelistedUserAtIndex = [tokenLockIndex, gasVals]
//.getUserWhitelistStatus(address _user) external view returns (bool) {
  pl.getUserWhitelistStatus = [addrUser, gasVals]

  return
  const {Locked, IsReleaseTimePassed} = await __reportLockStatus()
  if(LockerPairBalance===0 && DeployerPairBalance===0){
    log3('nothing to do! locker & deployer don\'t have any pair tokens');
  }
  else if(Locked){
    log3('nothing to do! tokens are locked but release date not yet passed')
  }
  else if(!Locked && LockerPairBalance>0){

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
  else if(!Locked && DeployerPairBalance>0){

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
