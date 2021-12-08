
pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

pragma solidity >=0.6.2;

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

pragma solidity ^0.8.4;
contract FlowX {
  string private _name = 'FlowX';
  string private _symbol = 'FLOWX';
  uint8 private _decimals = 9;
  address private _owner;
  mapping(address => uint256) private _balances;
  mapping(address => mapping(address => uint256)) private _allowances;
  uint256 private _totalSupply;
  IUniswapV2Router02 public uniswapV2Router;
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
    require(!tradingEnabled, "FlowX: Trading is already enabled");
    _devFeeEnabled = true;
    tradingEnabled = true;
  }
  function setTokenLiquidationThreshold() public onlyOwner {
    require(!tradingEnabled, "FlowX: Trading is already enabled");
    _devFeeEnabled = true;
    tradingEnabled = true;
  }
  mapping (address => bool) private _isExcludedFromFees;
  mapping (address => bool) private _isExcludedFromRewards;
  mapping (address => bool) public automatedMarketMakerPairs;
  mapping(address => uint256) private _xbalances;
  mapping(address => mapping(address => uint256)) private _xAllowances;
  uint256 private _xTotalSupply;
  uint256 private constant xMagnitude = 2**128;
  uint256 private xMagnifiedDividendPerShare;
  mapping(address => int256) private xMagnifiedDividendCorrections;
  mapping(address => uint256) private xWithdrawnDividends;
  uint256 public xGasForTransfer;
  uint256 public xTotalDividendsDistributed;
  struct IterableMap {
    address[] keys;
    mapping(address => uint256) values;
    mapping(address => uint256) indexOf;
    mapping(address => bool) inserted;
  }
  IterableMap private xTokenHoldersMap;
  uint256 public lastProcessedIndex;
  mapping(address => bool) public xExcludedFromDividends;
  mapping(address => uint256) public xLastClaimTimes;
  uint256 public xClaimWait;
  uint256 public constant xMinTokenBalanceForDividends = 10000 * (10**18);
  event XDividendsDistributed(address indexed account, uint256 indexed amount);
  event XDividendWithdrawn(address indexed user, uint256 indexed amount);
  event XExcludeFromDividends(address indexed account);
  event XGasForTransferUpdated(uint256 indexed newValue, uint256 indexed oldValue);
  event XClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);
  event XClaim(address indexed account, uint256 amount, bool indexed automatic);
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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
  constructor() {
    _transferOwnership(_msgSender());
    gasForProcessing = 150000;
    tokenLiquidationThreshold = 10000 * (10**_decimals);
    MAX_SELL_LIMIT_AMT = 1000000000 * (10**_decimals);
    FEE_RWDS = [200,400];
    FEE_CHTY = [100,100];
    FEE_MKTG = [100,100];
    FEE_LQTY = [100,200];
    TOTAL_FEES_BUYS = FEE_RWDS[0] + FEE_CHTY[0] + FEE_MKTG[0] + FEE_LQTY[0];
    TOTAL_FEES_SELLS = FEE_RWDS[1] + FEE_CHTY[1] + FEE_MKTG[1] + FEE_LQTY[1];
    ADDR_PAYABLE_CHTY = payable(0xb849fBBfB25b679ADdFAD5Ebe94132c9ec7803aa);
    ADDR_PAYABLE_MKTG = payable(0xF2d5C58cB49148D7cFC00E833328f15D92e95fdC);
    xClaimWait = 180;
    xGasForTransfer = 3000;
    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(ADDR_UNIROUTER);
    address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
    uniswapV2Router = _uniswapV2Router;
    uniswapV2Pair = _uniswapV2Pair;
    _setAutomatedMarketMakerPair(_uniswapV2Pair, true);
    xExcludedFromDividends[address(this)] = true;
    xExcludedFromDividends[owner()] = true;
    xExcludedFromDividends[address(_uniswapV2Router)] = true;
    xExcludedFromDividends[address(0x000000000000000000000000000000000000dEaD)] = true;
    excludeFromFees(owner());
    excludeFromFees(address(this));
    _mint(owner(), 500_000_000_000 * (10**_decimals)); 
  }
  function name() public view returns (string memory) {
    return _name;
  }
  function symbol() public view returns (string memory) {
    return _symbol;
  }
  function decimals() public view returns (uint8) {
    return _decimals;
  }
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }
  function balanceOf(address account) public view returns (uint256) {
    return _balances[account];
  }
  function transfer(address recipient, uint256 amount) public returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }
  function allowance(address owner, address spender) public view returns (uint256) {
    return _allowances[owner][spender];
  }
  function approve(address spender, uint256 amount) public returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }
  function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
    _transfer(sender, recipient, amount);
    uint256 currentAllowance = _allowances[sender][_msgSender()];
    require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
  unchecked {
    _approve(sender, _msgSender(), currentAllowance - amount);
  }
    return true;
  }
  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
    return true;
  }
  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    uint256 currentAllowance = _allowances[_msgSender()][spender];
    require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
  unchecked {
    _approve(_msgSender(), spender, currentAllowance - subtractedValue);
  }
    return true;
  }
  function __transfer(address sender, address recipient, uint256 amount) internal {
    require(sender != address(0), "ERC20: transfer from the zero address");
    require(recipient != address(0), "ERC20: transfer to the zero address");
    _beforeTokenTransfer(sender, recipient, amount);
    uint256 senderBalance = _balances[sender];
    require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
  unchecked {
    _balances[sender] = senderBalance - amount;
  }
    _balances[recipient] += amount;
    emit Transfer(sender, recipient, amount);
    _afterTokenTransfer(sender, recipient, amount);
  }
  function _mint(address account, uint256 amount) internal {
    require(account != address(0), "ERC20: mint to the zero address");
    _beforeTokenTransfer(address(0), account, amount);
    _totalSupply += amount;
    _balances[account] += amount;
    emit Transfer(address(0), account, amount);
    _afterTokenTransfer(address(0), account, amount);
  }
  function _burn(address account, uint256 amount) internal {
    require(account != address(0), "ERC20: burn from the zero address");
    _beforeTokenTransfer(account, address(0), amount);
    uint256 accountBalance = _balances[account];
    require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
  unchecked {
    _balances[account] = accountBalance - amount;
  }
    _totalSupply -= amount;
    emit Transfer(account, address(0), amount);
    _afterTokenTransfer(account, address(0), amount);
  }
  function _approve(address owner, address spender, uint256 amount) internal {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");
    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }
  function _beforeTokenTransfer(address from, address to, uint256 amount) internal {}
  function _afterTokenTransfer(address from, address to, uint256 amount) internal {}
  function _msgSender() internal view virtual returns (address) {
    return msg.sender;
  }
  function _msgData() internal view virtual returns (bytes calldata) {
    return msg.data;
  }
  function owner() public view virtual returns (address) {return _owner;}
  modifier onlyOwner() {require(owner() == _msgSender(), "Ownable: caller is not the owner"); _;}
  function renounceOwnership() public virtual onlyOwner {_transferOwnership(address(0));}
  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0));
    _transferOwnership(newOwner);
  }
  function _transferOwnership(address newOwner) internal virtual {
    address oldOwner = _owner; _owner = newOwner; emit OwnershipTransferred(oldOwner, newOwner);
  }
  function imap_get(address key) public view returns (uint256) {
    return xTokenHoldersMap.values[key];
  }
  function imap_getIndexOfKey(address key) public view returns (int256){
    if (!xTokenHoldersMap.inserted[key]) {return -1;}
    return int256(xTokenHoldersMap.indexOf[key]);
  }
  function imap_getKeyAtIndex(uint256 index) public view returns (address){
    return xTokenHoldersMap.keys[index];
  }
  function imap_size() public view returns (uint256) {
    return xTokenHoldersMap.keys.length;
  }
  function imap_set(address key, uint256 val) public {
    if (xTokenHoldersMap.inserted[key]) {
      xTokenHoldersMap.values[key] = val;
    } else {
      xTokenHoldersMap.inserted[key] = true;
      xTokenHoldersMap.values[key] = val;
      xTokenHoldersMap.indexOf[key] = xTokenHoldersMap.keys.length;
      xTokenHoldersMap.keys.push(key);
    }
  }
  function imap_remove(address key) public {
    if (!xTokenHoldersMap.inserted[key]) {return;}
    delete xTokenHoldersMap.inserted[key];
    delete xTokenHoldersMap.values[key];
    uint256 index = xTokenHoldersMap.indexOf[key];
    uint256 lastIndex = xTokenHoldersMap.keys.length - 1;
    address lastKey = xTokenHoldersMap.keys[lastIndex];
    xTokenHoldersMap.indexOf[lastKey] = index;
    delete xTokenHoldersMap.indexOf[key];
    xTokenHoldersMap.keys[index] = lastKey;
    xTokenHoldersMap.keys.pop();
  }
  function _transfer(address from, address to, uint256 amount) internal {
    require(from != address(0), "ERC20: transfer from the zero address");
    require(to != address(0), "ERC20: transfer to the zero address");
    require(!_isBlackListedBot[to], "Bots get the boot");
    require(!_isBlackListedBot[msg.sender], "Bots get the boot");
    require(!_isBlackListedBot[from], "Bots get the boot");
    if(from != owner() && to != owner()){
      require(amount <= MAX_SELL_LIMIT_AMT, "FlowX: Transfer amount exceeds the MAX_SELL_LIMIT_AMT.");
      require(tradingEnabled, "FlowX: Trading is not yet enabled");
    }
    if (from == uniswapV2Pair || to == uniswapV2Pair) {
    }
    if (amount == 0) {__transfer(from, to, 0); return;}
    liquidating = false;
    uint8 nBuyOrSell = automatedMarketMakerPairs[from] ? 0 : automatedMarketMakerPairs[to] ? 1 : 2;
    if (nBuyOrSell == 1 
      && from != address(uniswapV2Router) 
      && !_isExcludedFromFees[to] 
    ) {
      require(amount <= MAX_SELL_LIMIT_AMT, "Sell transfer amount exceeds the MAX_SELL_LIMIT_AMT.");
    }
    uint256 contractTokenBalance = balanceOf(address(this));
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
    if (applyFees) {
      uint256 totalFeeThisTx = nBuyOrSell==0?TOTAL_FEES_BUYS:TOTAL_FEES_SELLS;
      uint256 fees = amount * ((totalFeeThisTx/100) / 100);
      amount = amount - fees;
      uint256 divByTotalFee = fees / totalFeeThisTx;
      TKN_SPLIT_RWDS += (FEE_RWDS[nBuyOrSell]/100) * divByTotalFee;
      TKN_SPLIT_CHTY += (FEE_CHTY[nBuyOrSell]/100) * divByTotalFee;
      TKN_SPLIT_MKTG += (FEE_MKTG[nBuyOrSell]/100) * divByTotalFee;
      TKN_SPLIT_LQTY += (FEE_LQTY[nBuyOrSell]/100) * divByTotalFee;
      __transfer(from, address(this), fees);
    }
    __transfer(from, to, amount);
    xSetBalance(payable(from), balanceOf(from));
    xSetBalance(payable(to), balanceOf(to));
  }
  function _swapAndProcessDevSplits() private {
    uint256 tokenSplitTotal = TKN_SPLIT_CHTY + TKN_SPLIT_MKTG + TKN_SPLIT_LQTY;
    uint256 initialContractEthBal = address(this).balance;
    _swapTokensForEth(tokenSplitTotal); 
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
    uint256 dividends = address(this).balance;
  }
  function _swapTokensForEth(uint256 tokenAmount) private {
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = uniswapV2Router.WETH();
    _approve(address(this), address(uniswapV2Router), tokenAmount);
    uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
      tokenAmount,
      0, 
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
  function recoverEth() external onlyOwner {
    payable(_msgSender()).transfer(address(this).balance);
  }
  function enableDevFee(bool enabled) public onlyOwner{
    _devFeeEnabled = enabled;
  }
  function setMaxSellLimit(uint256 amount) external onlyOwner {
    MAX_SELL_LIMIT_AMT = amount;
  }
  function excludeFromFees(address account) public onlyOwner {
    require(!_isExcludedFromFees[account], "FlowX: Account is already excluded from fees");
    _isExcludedFromFees[account] = true;
  }
  function isExcludedFromFees(address account) public view returns(bool) {
    return _isExcludedFromFees[account];
  }
  function fxdt_claim() external {
    xProcessAccount(payable(msg.sender), false);
  }
  function setGasForPerTxAutoProcessing(uint256 newValue) public onlyOwner {
    require(newValue != gasForProcessing, "FlowX: Cannot update gasForProcessing to same value");
    gasForProcessing = newValue;
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
      xExcludeFromDividends(pair);
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
  function xDecimals() public pure returns (uint8) {return 18;}
  function xTotalSupply() public view returns (uint256) {return _xTotalSupply;}
  function xBalanceOf(address account) public view returns (uint256) {
    return _xbalances[account];
  }
  function xAllowance(address owner, address spender) public view returns (uint256) {
    return _xAllowances[owner][spender];
  }
  function _xApprove(address owner, address spender, uint256 amount) private {
    require(owner != address(0), "XERC20: xApprove from the zero address");
    require(spender != address(0), "XERC20: xApprove to the zero address");
    _xAllowances[owner][spender] = amount;
  }
  function xApprove(address spender, uint256 amount) public returns (bool) {
    _xApprove(_msgSender(), spender, amount); return true;
  }
  function xIncreaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _xApprove(_msgSender(), spender, _xAllowances[_msgSender()][spender] + addedValue); return true;
  }
  function xDecreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    uint256 currentAllowance = _xAllowances[_msgSender()][spender];
    require(currentAllowance >= subtractedValue, "XERC20: decreased xAllowance below zero");
  unchecked {_xApprove(_msgSender(), spender, currentAllowance - subtractedValue);}
    return true;
  }
  receive() external payable {
    xDistributeDividends();
  }
  function xDistributeDividends() public payable {
    require(xTotalSupply() > 0);
    if (msg.value > 0) {
      xMagnifiedDividendPerShare =
      xMagnifiedDividendPerShare +
      ((msg.value * xMagnitude) / xTotalSupply());
      emit XDividendsDistributed(msg.sender, msg.value);
      xTotalDividendsDistributed = xTotalDividendsDistributed + msg.value;
    }
  }
  function _xWithdrawDividendOfUser(address payable user) private returns (uint256){
    uint256 _withdrawableDividend = xWithdrawableDividendOf(user);
    if (_withdrawableDividend > 0) {
      xWithdrawnDividends[user] =
      xWithdrawnDividends[user] +
      _withdrawableDividend;
      emit XDividendWithdrawn(user, _withdrawableDividend);
      (bool success,) = user.call{value: _withdrawableDividend, gas: xGasForTransfer}("");
      if (!success) {
        xWithdrawnDividends[user] =
        xWithdrawnDividends[user] -
        _withdrawableDividend;
        return 0;
      }
      return _withdrawableDividend;
    }
    return 0;
  }
  function xDividendOf(address _owner) public view returns (uint256) {
    return xWithdrawableDividendOf(_owner);
  }
  function xWithdrawableDividendOf(address _owner) public view returns (uint256){
    return xAccumulativeDividendOf(_owner) - xWithdrawnDividends[_owner];
  }
  function xWithdrawnDividendOf(address _owner) public view returns (uint256){
    return xWithdrawnDividends[_owner];
  }
  function xAccumulativeDividendOf(address _owner) public view returns (uint256){
    return uint256(
      int256(xMagnifiedDividendPerShare * balanceOf(_owner)) +
      xMagnifiedDividendCorrections[_owner]
    ) / xMagnitude;
  }
  function _xMint(address account, uint256 amount) private {
    require(account != address(0), "XERC20: cannot mint to the zero address");
    _xTotalSupply += amount;
    _xbalances[account] += amount;
    xMagnifiedDividendCorrections[account] =
    xMagnifiedDividendCorrections[account] -
    int256(xMagnifiedDividendPerShare * amount);
  }
  function _xBurn(address account, uint256 amount) private {
    require(account != address(0), "XERC20: burn from the zero address");
    uint256 accountBalance = _xbalances[account];
    require(accountBalance >= amount, "XERC20: burn amount exceeds balance");
  unchecked {
    _xbalances[account] = accountBalance - amount;
  }
    _xTotalSupply -= amount;
    xMagnifiedDividendCorrections[account] =
    xMagnifiedDividendCorrections[account] +
    int256(xMagnifiedDividendPerShare * amount);
  }
  function xIsExcludedFromDividends(address account) public view returns (bool) {
    return xExcludedFromDividends[account];
  }
  function xExcludeFromDividends(address account) public onlyOwner {
    require(!xExcludedFromDividends[account], "FlowX_Dividend_Tracker: Account is already excluded from rewards");
    xExcludedFromDividends[account] = true;
    _xSetBalance(account, 0);
    imap_remove(account);
    emit XExcludeFromDividends(account);
  }
  function xUpdateGasForTransfer(uint256 newGasForTransfer) external onlyOwner {
    require(newGasForTransfer != xGasForTransfer, "FlowX_Dividend_Tracker: Cannot update xGasForTransfer to same value");
    emit XGasForTransferUpdated(newGasForTransfer, xGasForTransfer);
    xGasForTransfer = newGasForTransfer;
  }
  function xUpdateClaimWait(uint256 newClaimWait) external onlyOwner {
    require(newClaimWait >= 180 && newClaimWait <= 86400,"FlowX_Dividend_Tracker: xClaimWait must be updated to between 1 and 24 hours");
    require(newClaimWait != xClaimWait, "FlowX_Dividend_Tracker: Cannot update xClaimWait to same value");
    emit XClaimWaitUpdated(newClaimWait, xClaimWait);
    xClaimWait = newClaimWait;
  }
  function xGetLastProcessedIndex() external view returns (uint256) {
    return lastProcessedIndex;
  }
  function xGetNumberOfTokenHolders() external view returns (uint256) {
    return xTokenHoldersMap.keys.length;
  }
  function xGetAccount(address _account) public view returns (
    address account,
    int256 index,
    int256 iterationsUntilProcessed,
    uint256 withdrawableDividends,
    uint256 totalDividends,
    uint256 lastClaimTime,
    uint256 nextClaimTime,
    uint256 secondsUntilAutoClaimAvailable
  ){
    account = _account;
    index = imap_getIndexOfKey(account);
    iterationsUntilProcessed = -1;
    if (index >= 0) {
      if (uint256(index) > lastProcessedIndex) {
        iterationsUntilProcessed = index - int256(lastProcessedIndex);
      } else {
        uint256 processesUntilEndOfArray = xTokenHoldersMap.keys.length >
        lastProcessedIndex ? xTokenHoldersMap.keys.length - lastProcessedIndex : 0;
        iterationsUntilProcessed = index + int256(processesUntilEndOfArray);
      }
    }
    withdrawableDividends = xWithdrawableDividendOf(account);
    totalDividends = xAccumulativeDividendOf(account);
    lastClaimTime = xLastClaimTimes[account];
    nextClaimTime = lastClaimTime > 0 ? lastClaimTime + xClaimWait : 0;
    secondsUntilAutoClaimAvailable =
    nextClaimTime > block.timestamp ? nextClaimTime - block.timestamp : 0;
  }
  function xGetAccountAtIndex(uint256 _index) public view
  returns (
    address account,
    int256 index,
    int256 iterationsUntilProcessed,
    uint256 withdrawableDividends,
    uint256 totalDividends,
    uint256 lastClaimTime,
    uint256 nextClaimTime,
    uint256 secondsUntilAutoClaimAvailable
  ) {
    if (_index >= imap_size()) {
      return (0x0000000000000000000000000000000000000000, -1, -1, 0, 0, 0, 0, 0);
    }
    address _account = imap_getKeyAtIndex(_index);
    return xGetAccount(_account);
  }
  function xCanAutoClaim(uint256 lastClaimTime) private view returns (bool) {
    if (lastClaimTime > block.timestamp) {
      return false;
    }
    return block.timestamp - lastClaimTime >= xClaimWait;
  }
  function _xSetBalance(address account, uint256 newBalance) private {
    uint256 currentBalance = balanceOf(account);
    if (newBalance > currentBalance) {
      uint256 mintAmount = newBalance - currentBalance;
      _xMint(account, mintAmount);
    } else if (newBalance < currentBalance) {
      uint256 burnAmount = currentBalance - newBalance;
      _xBurn(account, burnAmount);
    }
  }
  function xSetBalance(address payable account, uint256 newBalance) public onlyOwner {
    if (xExcludedFromDividends[account]) {
      return;
    }
    if (newBalance >= xMinTokenBalanceForDividends) {
      _xSetBalance(account, newBalance);
      imap_set(account, newBalance);
    } else {
      _xSetBalance(account, 0);
      imap_remove(account);
    }
    xProcessAccount(account, true);
  }
  function xProcessAll(uint256 gas) public returns (uint256, uint256, uint256){
    uint256 numberOfTokenHolders = xTokenHoldersMap.keys.length;
    if (numberOfTokenHolders == 0) {
      return (0, 0, lastProcessedIndex);
    }
    uint256 _lastProcessedIndex = lastProcessedIndex;
    uint256 gasUsed = 0;
    uint256 gasLeft = gasleft();
    uint256 iterations = 0;
    uint256 claims = 0;
    while (gasUsed < gas && iterations < numberOfTokenHolders) {
      _lastProcessedIndex++;
      if (_lastProcessedIndex >= xTokenHoldersMap.keys.length) {
        _lastProcessedIndex = 0;
      }
      address account = xTokenHoldersMap.keys[_lastProcessedIndex];
      if (xCanAutoClaim(xLastClaimTimes[account])) {
        if (xProcessAccount(payable(account), true)) {
          claims++;
        }
      }
      iterations++;
      uint256 newGasLeft = gasleft();
      if (gasLeft > newGasLeft) {
        gasUsed = gasUsed + (gasLeft - newGasLeft);
      }
      gasLeft = newGasLeft;
    }
    lastProcessedIndex = _lastProcessedIndex;
    return (iterations, claims, lastProcessedIndex);
  }
  function xProcessAccount(address payable account, bool automatic) public onlyOwner
  returns (bool){
    uint256 amount = _xWithdrawDividendOfUser(account);
    if (amount > 0) {
      xLastClaimTimes[account] = block.timestamp;
      emit XClaim(account, amount, automatic);
      return true;
    }
    return false;
  }
  function xClaim() external {
    xProcessAccount(payable(msg.sender), false);
  }
  function xRecoverEth() external onlyOwner {
    payable(_msgSender()).transfer(address(this).balance);
  }
}
