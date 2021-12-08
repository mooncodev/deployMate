// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
//import "hardhat/console.sol";

//import "./oz430/Context.sol";
import "./oz430/Ownable.sol";
//import "./oz430/SafeMath.sol";
//import "./oz430/IERC20.sol";
//import "./oz430/IERC20Metadata.sol";
import "./oz430/ERC20.sol";

import "./uniswap/IUniswapV2Factory.sol";
//import "./uniswap/IUniswapV2Pair.sol";
//import "./uniswap/IUniswapV2Router01.sol";
import "./uniswap/IUniswapV2Router02.sol";

//import './dpt/IterableMapping.sol';
//import './dpt/IDividendPayingTokenOptional.sol';
//import './dpt/IDividendPayingToken.sol';
//import './dpt/DividendPayingToken.sol';
import './dpt/FlowXDividendTracker.sol';

//import "../oz430/Ownable.sol";
//import "./DividendPayingToken.sol";
//import "./IterableMapping.sol";

contract FlowX is ERC20, Ownable {
  string private _name = 'FlowX';
  string private _symbol = 'FLOWX';
  uint8 private _decimals = 9;

//  using SafeMath for uint256;

  IUniswapV2Router02 public uniswapV2Router;
  FlowXDividendTracker public divTracker;

  address public immutable uniswapV2Pair;

  bool private liquidating;


  uint256 public MAX_SELL_LIMIT_AMT;

  uint256[2] public FEE_RWDS;
  uint256[2] public FEE_CHTY;
  uint256[2] public FEE_MKTG;
  uint256[2] public FEE_LQTY;
  uint256 public TOTAL_FEES_BUYS;
  uint256 public TOTAL_FEES_SELLS;

  uint256 private TKN_SPLIT_RWDS;
  uint256 private TKN_SPLIT_CHTY;
  uint256 private TKN_SPLIT_MKTG;
  uint256 private TKN_SPLIT_LQTY;
  bool _devFeeEnabled = false;
  bool public tradingEnabled = false;

  mapping (address => bool) private _isBlackListedBot;
  address private constant ADDR_UNIROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
  address payable private ADDR_PAYABLE_CHTY;
  address payable private ADDR_PAYABLE_MKTG;
  uint256 public gasForProcessing;
  uint256 public tokenLiquidationThreshold;

  function activate() public onlyOwner {
    require(!tradingEnabled);
    _devFeeEnabled = true;
    tradingEnabled = true;
  }
  function setTokenLiquidationThreshold() public onlyOwner {
    tokenLiquidationThreshold = tokenAmt;
  }

  // exclude from fees and max transaction amount
  mapping (address => bool) private _isExcludedFromFees;
  mapping (address => bool) private _isExcludedFromRewards;

  // store AMM pair addresses. Any transfer *to* these addresses
  // could be subject to a maximum transfer amount
  mapping (address => bool) public automatedMarketMakerPairs;

  //  event UpdatedDividendTracker(address indexed newAddress, address indexed oldAddress);
  //  event UpdatedUniswapV2Router(address indexed newAddress, address indexed oldAddress);
  event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
  event LiquidityWalletUpdated(address indexed newLiquidityWallet, address indexed oldLiquidityWallet);
  event Liquified(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);
  event SwapAndProcessDevSplits(uint256 tokensSwapped, uint256 ethReceived);
  event SentDividends(uint256 tokensSwapped, uint256 amount);
  event ProcessedDividendTracker(
    uint256 iterations,
    uint256 claims,
    uint256 lastProcessedIndex,
    bool indexed automatic,
    uint256 gas,
    address indexed processor
  );

  constructor() ERC20(_name, _symbol) {
    // use by default 150,000 gas to process auto-claiming dividends
    gasForProcessing = 150000;
    // liquidate tokens for ETH when the contract reaches 10k tokens by default
    tokenLiquidationThreshold = 10000 * (10**_decimals);
    MAX_SELL_LIMIT_AMT = 1000000000 * (10**_decimals);//1bn
    //[reflections, charity, marketing, liquidity][buys,sells]
    FEE_RWDS = [200,400];
    FEE_CHTY = [100,100];
    FEE_MKTG = [100,100];
    FEE_LQTY = [100,200];
    TOTAL_FEES_BUYS = FEE_RWDS[0] + FEE_CHTY[0] + FEE_MKTG[0] + FEE_LQTY[0];
    TOTAL_FEES_SELLS = FEE_RWDS[1] + FEE_CHTY[1] + FEE_MKTG[1] + FEE_LQTY[1];
    //    console.log("Deploying FlowX with arg:", uniRouter);
    ADDR_PAYABLE_CHTY = payable(0xb849fBBfB25b679ADdFAD5Ebe94132c9ec7803aa);
    ADDR_PAYABLE_MKTG = payable(0xF2d5C58cB49148D7cFC00E833328f15D92e95fdC);

    divTracker = new FlowXDividendTracker();
    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(ADDR_UNIROUTER);
    // Create a uniswap pair for this new token
    address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());

    uniswapV2Router = _uniswapV2Router;
    uniswapV2Pair = _uniswapV2Pair;

    _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

    // exclude from receiving dividends
    divTracker.excludeFromDividends(address(divTracker));
    divTracker.excludeFromDividends(address(this));
    divTracker.excludeFromDividends(owner());
    divTracker.excludeFromDividends(address(_uniswapV2Router));
    divTracker.excludeFromDividends(address(0x000000000000000000000000000000000000dEaD));

    // exclude from paying fees or having max transaction amount
    excludeFromFees(owner());
    excludeFromFees(address(this));

    /* _mint is only called here, and CANNOT be called ever again */
    _mint(owner(), 500_000_000_000 * (10**_decimals)); //500bn
  }

  receive() external payable {}

  function decimals() public view override returns (uint8) {
    return _decimals;
  }

  function _transfer(address from, address to, uint256 amount) internal override {
    require(from != address(0));
    require(to != address(0));
    require(!_isBlackListedBot[to], "nobots");
    require(!_isBlackListedBot[msg.sender], "nobots");
    require(!_isBlackListedBot[from], "nobots");

    //transfers will have a max during launch phase
    // after launch phase only sells will have a max
    if(from != owner() && to != owner()){
      require(amount <= MAX_SELL_LIMIT_AMT, "MAX_SELL_LIMIT_AMT");
      require(tradingEnabled);
    }

    if (from == uniswapV2Pair || to == uniswapV2Pair) {
      //require(!antiBot.scanAddress(from, uniswapV2Pair, tx.origin),  "Beep Beep Boop, You're a piece of poop");
      // require(!antiBot.scanAddress(to, uniswair, tx.origin), "Beep Beep Boop, You're a piece of poop");
    }

    if (amount == 0) {ERC20._transfer(from, to, 0); return;}

    liquidating = false;
    uint8 nBuyOrSell = automatedMarketMakerPairs[from] ? 0 : automatedMarketMakerPairs[to] ? 1 : 2;

    if (nBuyOrSell == 1 //on sells
      && from != address(uniswapV2Router) //router -> pair is removing liquidity which shouldn't have max
      && !_isExcludedFromFees[to] //no max for those excluded from fees
    ) {
      require(amount <= MAX_SELL_LIMIT_AMT, "MAX_SELL_LIMIT_AMT.");
    }

    uint256 contractTokenBalance = balanceOf(address(this));

    // SWAP / LIQUIDATION
    if ( contractTokenBalance >= tokenLiquidationThreshold
      && _devFeeEnabled
      && nBuyOrSell != 1
      && from != owner() && to != owner()
    ) {
      liquidating = true;
      _swapAndProcessDevSplits();
      _swapAndProcessRewardsSplits();
    }

    bool applyFees = !(_isExcludedFromFees[from] || _isExcludedFromFees[to] || liquidating || nBuyOrSell==2);

    //fees are collected as tokens held by the contract until a liquidation is triggered.
    //fees are only split into their individual parts during the liquidation
    //allocations are held until liquidation in the SPLIT vars, for later reference to split everything properly.
    if (applyFees) {
      uint256 totalFeeThisTx = nBuyOrSell==0?TOTAL_FEES_BUYS:TOTAL_FEES_SELLS;
      uint256 fees = amount * ((totalFeeThisTx/100) / 100);
      amount = amount - fees;
      uint256 divByTotalFee = fees / totalFeeThisTx;
      TKN_SPLIT_RWDS += (FEE_RWDS[nBuyOrSell]/100) * divByTotalFee;
      TKN_SPLIT_CHTY += (FEE_CHTY[nBuyOrSell]/100) * divByTotalFee;
      TKN_SPLIT_MKTG += (FEE_MKTG[nBuyOrSell]/100) * divByTotalFee;
      TKN_SPLIT_LQTY += (FEE_LQTY[nBuyOrSell]/100) * divByTotalFee;
      //perform the intended transfer
      ERC20._transfer(from, address(this), fees);
    }

    //perform the intended transfer, where amount may or may not have been modified via applyFees
    ERC20._transfer(from, to, amount);

//    divTracker.setBalance(payable(from), balanceOf(from));
//    divTracker.setBalance(payable(to), balanceOf(to));

    try divTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
    try divTracker.setBalance(payable(to), balanceOf(to)) {} catch {}

//    if (!liquidating) {
//      uint256 gas = gasForProcessing;
//      try divTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
//        emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
//      } catch {
//      }
//    }
  }
  function _swapAndProcessDevSplits() private {
    // capture the contract's current and adjusted ETH balances.
    // we prevent the liquidity event from including
    // any ETH manually sent to the contract
    uint256 tokenSplitTotal = TKN_SPLIT_CHTY + TKN_SPLIT_MKTG + TKN_SPLIT_LQTY;
    uint256 initialContractEthBal = address(this).balance;
    // swap tokens for ETH
    _swapTokensForEth(tokenSplitTotal); // <-  breaks the ETH -> HATE swap when swap+liquify is triggered
    // how much ETH did we just swap into?
    uint256 totalEthCreatedThisSwap = address(this).balance - initialContractEthBal;

    uint256 divBySplitTotal = totalEthCreatedThisSwap / tokenSplitTotal;
    uint256 ETH_SPLIT_CHTY = TKN_SPLIT_CHTY * divBySplitTotal;
    uint256 ETH_SPLIT_MKTG = TKN_SPLIT_MKTG * divBySplitTotal;
    uint256 ETH_SPLIT_LQTY = TKN_SPLIT_LQTY * divBySplitTotal;

    ADDR_PAYABLE_CHTY.transfer(ETH_SPLIT_CHTY);
    ADDR_PAYABLE_MKTG.transfer(ETH_SPLIT_MKTG);
    _addLiquidity(ETH_SPLIT_LQTY);
    emit SwapAndProcessDevSplits(tokenSplitTotal, totalEthCreatedThisSwap);
  }

  function _swapAndProcessRewardsSplits() private {
    _swapTokensForEth(TKN_SPLIT_RWDS);
    //we liquidate all remaining ETH
    uint256 dividends = address(this).balance;
    //we invoke the recieve() method on the tracker and it handles distribution from there
    (bool success,) = address(divTracker).call{value: dividends}("");
    if (success) {
      emit SentDividends(TKN_SPLIT_RWDS, dividends);
    }
  }

  //performs the conversion from tokens (held by the contract) into ETH
  function _swapTokensForEth(uint256 tokenAmount) private {
    // generate the uniswap pair path of token -> weth
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = uniswapV2Router.WETH();
//    uint256 memory UINT256_MAX = ~uint256(0);
    //contract approves v2Router for the tx of n amount
    _approve(address(this), address(uniswapV2Router), tokenAmount);

    // make the swap specifying contract itself as token holder to receive ETH
    uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
      tokenAmount,
      0, // accept any amount of ETH
      path,
      address(this),
      block.timestamp
    );
  }

  function _addLiquidity(uint256 amountWEI) private {
    uint256 MAXUINT256 = ~uint256(0);
    require(amountWEI < address(this).balance, "FlowX: Contract doesn't hold this much ETH to add to liquidity");
    _approve(address(this), address(uniswapV2Router), MAXUINT256);
    uniswapV2Router.addLiquidityETH{ value: amountWEI }(address(this),0,0,0,owner(),block.timestamp+(60*15));
  }
  function recoverEth() external onlyOwner {// DEV ONLY
    payable(_msgSender()).transfer(address(this).balance);
  }


  function enableDevFee(bool enabled) public onlyOwner{
    _devFeeEnabled = enabled;
  }
  function setMaxSellLimit(uint256 amount) external onlyOwner {
    MAX_SELL_LIMIT_AMT = amount;
  }

  function excludeFromRewards(address account) public onlyOwner {
    require(!divTracker.isExcludedFromDividends(account), "FlowX: Account is already excluded from rewards");
    divTracker.excludeFromDividends(address(account));
  }
  function isExcludedFromRewards(address account) public view returns(bool) {
    return divTracker.isExcludedFromDividends(account);
  }
  function excludeFromFees(address account) public onlyOwner {
    require(!_isExcludedFromFees[account], "FlowX: Account is already excluded from fees");
    _isExcludedFromFees[account] = true;
  }
  function isExcludedFromFees(address account) public view returns(bool) {
    return _isExcludedFromFees[account];
  }



  function fxdt_claim() external {
    divTracker.processAccount(payable(msg.sender), false);
  }
  function fxdt_getClaimWait() external view returns(uint256) {
    return divTracker.claimWait();
  }
  function fxdt_updateClaimWait(uint256 claimWait) external onlyOwner {
    divTracker.updateClaimWait(claimWait);
  }

  function fxdt_getGasForTransfer() external view returns(uint256) {
    return divTracker.gasForTransfer();
  }
  function fxdt_setGasForTransfer(uint256 gasForTransfer) external onlyOwner {
    divTracker.updateGasForTransfer(gasForTransfer);
  }
  function fxdt_setGasForProcessing(uint256 newValue) public onlyOwner {
    // Need to make gas fee customizable to future-proof against Ethereum network upgrades.
    require(newValue != gasForProcessing, "FlowX: Cannot update gasForProcessing to same value");
    gasForProcessing = newValue;
  }


  function fxdt_getNumberOfTokenHolders() external view returns(uint256) {
    return divTracker.getNumberOfTokenHolders();
  }
  function fxdt_balanceOf(address account) public view returns (uint256) {
    return divTracker.balanceOf(account);
  }
  function fxdt_withdrawableDividendOf(address account) public view returns(uint256) {
    return divTracker.withdrawableDividendOf(account);
  }
  function fxdt_totalDividendsDistributed() external view returns (uint256) {
    return divTracker.totalDividendsDistributed();
  }
  function fxdt_getAccount(address account) external view returns (
    address, int256, int256, uint256, uint256, uint256, uint256, uint256
  ) {
    return divTracker.getAccount(account);
  }
  function fxdt_getAccountAtIndex(uint256 index) external view returns (
    address, int256, int256, uint256, uint256, uint256, uint256, uint256
  ) {
    return divTracker.getAccountAtIndex(index);
  }
  function fxdt_process(uint256 gas) external returns (uint256, uint256, uint256){
    return divTracker.process(gas);
//    emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, false, gas, tx.origin);
  }
  function fxdt_getLastProcessedIndex() external view returns(uint256) {
    return divTracker.getLastProcessedIndex();
  }

  function setFeePcts (uint256[2] calldata rewardsPct, uint256[2] calldata liquidityPct, uint256[2] calldata marketingPct, uint256[2] calldata charityPct) external {
    FEE_RWDS = rewardsPct;
    FEE_CHTY = charityPct;
    FEE_MKTG = marketingPct;
    FEE_LQTY = liquidityPct;
    TOTAL_FEES_BUYS = FEE_RWDS[0] + FEE_CHTY[0] + FEE_MKTG[0] + FEE_LQTY[0];
    TOTAL_FEES_SELLS = FEE_RWDS[1] + FEE_CHTY[1] + FEE_MKTG[1] + FEE_LQTY[1];
  }

  function setAutomatedMarketMakerPair(address pair, bool toggle) public onlyOwner {
    require(pair != uniswapV2Pair, "FlowX: The Uniswap pair cannot be removed from automatedMarketMakerPairs");
    _setAutomatedMarketMakerPair(pair, toggle);
  }
  function _setAutomatedMarketMakerPair(address pair, bool toggle) private {
    require(automatedMarketMakerPairs[pair] != toggle, "FlowX: Automated market maker pair is already set to that value");
    automatedMarketMakerPairs[pair] = toggle;
    if(toggle) {
      divTracker.excludeFromDividends(pair);
    }
    emit SetAutomatedMarketMakerPair(pair, toggle);
  }


  function setCharityWallet(address payable account) external onlyOwner() {
    ADDR_PAYABLE_CHTY = account;
  }
  function setMarketingWallet(address payable account) external onlyOwner() {
    ADDR_PAYABLE_MKTG = account;
  }

  function addBotToBlackList(address account) external onlyOwner() {
    require(account != ADDR_UNIROUTER, 'We can not blacklist Uniswap router.');
    require(!_isBlackListedBot[account], "Account is already blacklisted");
    _isBlackListedBot[account] = true;
  }
  function removeBotFromBlackList(address account) external onlyOwner() {
    require(_isBlackListedBot[account], "Account is not blacklisted");
    delete _isBlackListedBot[account];
  }


}