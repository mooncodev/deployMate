// Sources flattened with hardhat v2.6.1 https://hardhat.org

// File contracts/oz430/Context.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


// File contracts/oz430/Ownable.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _transferOwnership(_msgSender());
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File contracts/oz430/IERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


// File contracts/oz430/IERC20Metadata.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}


// File contracts/oz430/ERC20.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;



contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }
    function name() public view virtual override returns (string memory) {
        return _name;
    }    
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }    
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }    
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }    
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
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
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }
    function _burn(address account, uint256 amount) internal virtual {
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}


// File contracts/FlowX.sol

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;
//import "hardhat/console.sol";

//import "./oz430/Context.sol";
//import "./oz430/SafeMath.sol";
//import "./oz430/IERC20.sol";
//import "./oz430/IERC20Metadata.sol";
//import "./uniswap/IUniswapV2Factory.sol";
//import "./uniswap/IUniswapV2Pair.sol";
//import "./uniswap/IUniswapV2Router01.sol";
//import "./uniswap/IUniswapV2Router02.sol";
//import "./IUniV2Mins.sol";

//import './dpt/IterableMapping.sol';
//import './dpt/IDividendPayingTokenOptional.sol';
//import './dpt/IDividendPayingToken.sol';
//import './dpt/DividendPayingToken.sol';
//import './dpt/FlowXDividendTracker.sol';

//import "../oz430/Ownable.sol";
//import "./DividendPayingToken.sol";
//import "./dpt/IterableMapping.sol";
interface IUniV2FactoryMin {
  event PairCreated(address indexed token0, address indexed token1, address pair, uint);
  function getPair(address tokenA, address tokenB) external view returns (address pair);
  function createPair(address tokenA, address tokenB) external returns (address pair);
}
interface IUniV2RouterMin {
  function factory() external pure returns (address);
  function WETH() external pure returns (address);
  function addLiquidity(address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, address to, uint deadline
  ) external returns (uint amountA, uint amountB, uint liquidity);
  function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline
  ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
  function removeLiquidity(address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin, address to, uint deadline
  ) external returns (uint amountA, uint amountB);
  function removeLiquidityETH(address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline
  ) external returns (uint amountToken, uint amountETH);
  function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline
  ) external returns (uint[] memory amounts);
  function swapTokensForExactTokens(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline
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
  /*END 01, BEGIN 02*/
  function removeLiquidityETHSupportingFeeOnTransferTokens(address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline
  ) external returns (uint amountETH);
  function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s
  ) external returns (uint amountETH);
  function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external;
}
contract FlowX is ERC20, Ownable {
  string private _name = 'FlowX';
  string private _symbol = 'FLOWX';
  uint8 private _decimals = 9;


//  using SafeMath for uint256;

  IUniV2RouterMin public uniswapV2Router;

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

  function activate() external onlyOwner {
    _devFeeEnabled = true;
    tradingEnabled = true;
  }
  function setTokenLiquidationThreshold(uint256 tokenAmt) external onlyOwner {
    tokenLiquidationThreshold = tokenAmt;
  }

  // exclude from fees and max transaction amount
  mapping (address => bool) public _isExcludedFromFees;

  // store AMM pair addresses. Any transfer *to* these addresses
  // could be subject to a maximum transfer amount (aka sells)
  mapping (address => bool) public automatedMarketMakerPairs;

  mapping(address => uint256) private _xbalances;
//  mapping(address => mapping(address => uint256)) private _xAllowances;
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

//  using IterableMapping for IterableMapping.Map;
  IterableMap private xTokenHoldersMap;
  uint256 public xLastProcessedIndex;
  mapping(address => bool) public xExcludedFromDividends;
  mapping(address => uint256) public xLastClaimTimes;
  uint256 public xClaimWait;
  uint256 public constant xMinTokenBalanceForDividends = 10000 * (10**18);
  event XDividendWithdrawn(address indexed user, uint256 indexed amount);
  event XClaim(address indexed account, uint256 amount);

  constructor() ERC20(_name, _symbol){
    _transferOwnership(_msgSender());
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

    xClaimWait = 180;
    xGasForTransfer = 3000;

    IUniV2RouterMin _uniswapV2Router = IUniV2RouterMin(ADDR_UNIROUTER);
    // Create a uniswap pair for this new token
    address _uniswapV2Pair = IUniV2FactoryMin(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
    uniswapV2Router = _uniswapV2Router;
    uniswapV2Pair = _uniswapV2Pair;
    _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

    // exclude from receiving dividends
    xExcludedFromDividends[address(this)] = true;
    xExcludedFromDividends[owner()] = true;
    xExcludedFromDividends[address(_uniswapV2Router)] = true;
    xExcludedFromDividends[address(0x000000000000000000000000000000000000dEaD)] = true;

    // exclude from paying fees or having max transaction amount
    excludeFromFees(owner());
    excludeFromFees(address(this));

    /* _mint is only called here, and CANNOT be called ever again */
    _mint(owner(), 500_000_000_000 * (10**_decimals)); //500bn
  }


  /*BEGIN ITERABLEMAP METHODS*/
/*
  function imap_get(address key) public view returns (uint256) {
    return xTokenHoldersMap.values[key];
  }
*/
  function imap_getIndexOfKey(address key) public view returns (int256){
    if (!xTokenHoldersMap.inserted[key]) {return -1;}
    return int256(xTokenHoldersMap.indexOf[key]);
  }
  function imap_getKeyAtIndex(uint256 index) public view returns (address){
    return xTokenHoldersMap.keys[index];
  }
//  function imap_size() public view returns (uint256) {
//    return xTokenHoldersMap.keys.length;
//  }
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
  function decimals() public view override returns (uint8) {
    return _decimals;
  }

  /*BEGIN FLOWX METHODS*/
  function _transfer(address from, address to, uint256 amount) internal override{
    require(amount > 0);
    require(from != address(0));
    require(to != address(0));
    require(!_isBlackListedBot[to], "no bots");
    require(!_isBlackListedBot[msg.sender], "no bots");
    require(!_isBlackListedBot[from], "no bots");

    //transfers will have a max during launch phase
    // after launch phase only sells will have a max
    if(from != owner() && to != owner()){
      require(tradingEnabled);
    }

/*
    if (from == uniswapV2Pair || to == uniswapV2Pair) {
      //require(!antiBot.scanAddress(from, uniswapV2Pair, tx.origin),  "Beep Beep Boop, You're a piece of poop");
      // require(!antiBot.scanAddress(to, uniswair, tx.origin), "Beep Beep Boop, You're a piece of poop");
    }
*/
    liquidating = false;
    uint256 ratio;
    uint8 nBuyOrSell = automatedMarketMakerPairs[from] ? 0 : automatedMarketMakerPairs[to] ? 1 : 2;

    if (nBuyOrSell == 1 //on sells
      && from != address(uniswapV2Router) //router -> pair is removing liquidity which shouldn't have max
      && !_isExcludedFromFees[to] //no max for those excluded from fees
    ) {
      require(amount <= MAX_SELL_LIMIT_AMT, "sell>MAX_SELL_LIMIT_AMT.");
    }

    uint256 contractTokenBalance = balanceOf(address(this));

    // SWAP / LIQUIDATION
    if ( contractTokenBalance >= tokenLiquidationThreshold
      && _devFeeEnabled
      && nBuyOrSell == 1 //liquidation only on sells
      && from != owner() && to != owner()
    ) {
      liquidating = true;
      //_swapAndProcessDevSplits();
      //function _swapAndProcessDevSplits() private {
      // capture the contract's current and adjusted ETH balances.
      // we prevent the liquidity event from including
      // any ETH manually sent to the contract
      uint256 lqtyTokenHalf = TKN_SPLIT_LQTY / 2;
      uint256 lqtyEthHalf = TKN_SPLIT_LQTY - lqtyTokenHalf;
      uint256 tokenSplitTotal = TKN_SPLIT_CHTY + TKN_SPLIT_MKTG + lqtyEthHalf + TKN_SPLIT_RWDS;
      uint256 initialContractEthBal = address(this).balance;
      // swap tokens for ETH
//      _swapTokensForEth(tokenSplitTotal); // <-  breaks the ETH -> HATE swap when swap+liquify is triggered

//        function _swapTokensForEth(uint256 tokenAmount) private {
      // generate the uniswap pair path of token -> weth
      address[] memory path = new address[](2);
      path[0] = address(this);
      path[1] = uniswapV2Router.WETH();
  //    uint256 memory UINT256_MAX = ~uint256(0);
      //contract approves v2Router for the tx of n amount
      _approve(address(this), address(uniswapV2Router), tokenSplitTotal);

      // make the swap specifying contract itself as token holder to receive ETH
      uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
        tokenSplitTotal,
        0, // accept any amount of ETH
        path,
        address(this),
        block.timestamp
      );
//        }

      // how much ETH did we just swap into?
      uint256 totalEthCreatedThisSwap = address(this).balance - initialContractEthBal;
      ratio = totalEthCreatedThisSwap / tokenSplitTotal;
      uint256 ETH_SPLIT_CHTY = TKN_SPLIT_CHTY * ratio;
      uint256 ETH_SPLIT_MKTG = TKN_SPLIT_MKTG * ratio;
      uint256 ETH_SPLIT_LQTY = TKN_SPLIT_LQTY * ratio;

      ADDR_PAYABLE_CHTY.transfer(ETH_SPLIT_CHTY);
      ADDR_PAYABLE_MKTG.transfer(ETH_SPLIT_MKTG);
//      if(ETH_SPLIT_LQTY <= address(this).balance){ // this failsafe check should not be needed
      _approve(address(this), address(uniswapV2Router), ETH_SPLIT_LQTY); //consider ETH_SPLIT_LQTY instead of MAXUINT
      uniswapV2Router.addLiquidityETH{ value: ETH_SPLIT_LQTY }(
        address(this),lqtyTokenHalf,0,0,owner(),block.timestamp
      );

//      }
      //function _addLiquidity(uint256 amountWEI) private {
      //}
      //_addLiquidity(ETH_SPLIT_LQTY);
    //}

      //_swapAndProcessRewardsSplits();
      //function _swapAndProcessRewardsSplits() private {
//      _swapTokensForEth(TKN_SPLIT_RWDS);
        //we liquidate all remaining ETH
      //uint256 dividends = address(this).balance;
        //we invoke the recieve() method on the tracker and it handles distribution from there
        /* TODO: instead of sending ETH to a different contract
                 we should activate xDistributeDividends here with the ETH amt

            (bool success,) = address(divTracker).call{value: dividends}("");
        */
      //}
    }

    bool applyFees = !(_isExcludedFromFees[from] || _isExcludedFromFees[to] || liquidating || nBuyOrSell==2);

    //fees are collected as tokens held by the contract until a liquidation is triggered.
    //fees are only split into their individual parts during the liquidation
    //allocations are held until liquidation in the SPLIT vars, for later reference to split everything properly.
    if (applyFees) {
      uint256 totalFeeThisTx = nBuyOrSell==0?TOTAL_FEES_BUYS:TOTAL_FEES_SELLS;
      uint256 fees = amount * ((totalFeeThisTx/100) / 100);
      amount = amount - fees;
      ratio = fees / totalFeeThisTx;
      TKN_SPLIT_RWDS += (FEE_RWDS[nBuyOrSell]/100) * ratio;
      TKN_SPLIT_CHTY += (FEE_CHTY[nBuyOrSell]/100) * ratio;
      TKN_SPLIT_MKTG += (FEE_MKTG[nBuyOrSell]/100) * ratio;
      TKN_SPLIT_LQTY += (FEE_LQTY[nBuyOrSell]/100) * ratio;
      //give our contract some tokens as a fee
      ERC20._transfer(from, address(this), fees);
    }

    //perform the intended transfer, where amount may or may not have been modified via applyFees
    ERC20._transfer(from, to, amount);

    xSetBalance(payable(from), balanceOf(from));
    xSetBalance(payable(to), balanceOf(to));

//    if (!liquidating) {
//      uint256 gas = gasForProcessing;
//      try xProcessAll(gas) returns (uint256 iterations, uint256 claims, uint256 xLastProcessedIndex) {
//      } catch {
//      }
//    }
  }

  //performs the conversion from tokens (held by the contract) into ETH
/*
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
*/

  function enableDevFee(bool enabled) external onlyOwner{
    _devFeeEnabled = enabled;
  }
  function setMaxSellLimit(uint256 amount) external onlyOwner {
    MAX_SELL_LIMIT_AMT = amount;
  }
  function excludeFromFees(address account) public onlyOwner {
    require(!_isExcludedFromFees[account]);
    _isExcludedFromFees[account] = true;
  }
/*
  function isExcludedFromFees(address account) public view returns(bool) {
    return _isExcludedFromFees[account];
  }
*/

/*
  function setGasForPerTxAutoProcessing(uint256 newValue) external onlyOwner {
    // Need to make gas fee customizable to future-proof against Ethereum network upgrades.
    gasForProcessing = newValue;
  }
*/
  function setFeePcts (uint256[2] calldata rewardsPct, uint256[2] calldata liquidityPct,
  uint256[2] calldata marketingPct, uint256[2] calldata charityPct) external {
    FEE_RWDS = rewardsPct;
    FEE_CHTY = charityPct;
    FEE_MKTG = marketingPct;
    FEE_LQTY = liquidityPct;
    TOTAL_FEES_BUYS = FEE_RWDS[0] + FEE_CHTY[0] + FEE_MKTG[0] + FEE_LQTY[0];
    TOTAL_FEES_SELLS = FEE_RWDS[1] + FEE_CHTY[1] + FEE_MKTG[1] + FEE_LQTY[1];
  }

  function setAutomatedMarketMakerPair(address pair, bool toggle) public onlyOwner {
    require(pair != uniswapV2Pair);
    _setAutomatedMarketMakerPair(pair, toggle);
  }
  function _setAutomatedMarketMakerPair(address pair, bool toggle) private {
    require(automatedMarketMakerPairs[pair] != toggle);
    automatedMarketMakerPairs[pair] = toggle;
    if(toggle) {
      xExcludeFromDividends(pair);
    }
  }


  function setCharityWallet(address payable account) external onlyOwner() {
    ADDR_PAYABLE_CHTY = account;
  }
  function setMarketingWallet(address payable account) external onlyOwner() {
    ADDR_PAYABLE_MKTG = account;
  }
  function setBlackList(address account, bool toggle) external onlyOwner() {
    if(toggle) {
      require(account != ADDR_UNIROUTER);
      _isBlackListedBot[account] = true;
    }else{
      delete _isBlackListedBot[account];
    }
  }

 /*********DIVIDEND TOKEN & TRACKER**********/
//  function xDecimals() public pure returns (uint8) {return 18;}
  function xTotalSupply() public view returns (uint256) {return _xTotalSupply;}
  function xBalanceOf(address account) public view returns (uint256) {
    return _xbalances[account];
  }
/*
  function xAllowance(address owner_, address spender) public view returns (uint256) {
    return _xAllowances[owner_][spender];
  }
  function _xApprove(address owner_, address spender, uint256 amount) private {
    require(owner_ != address(0));
    require(spender != address(0));
    _xAllowances[owner_][spender] = amount;
  }
  function xApprove(address spender, uint256 amount) public returns (bool) {
    _xApprove(_msgSender(), spender, amount); return true;
  }
*/
/*
  function xIncreaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _xApprove(_msgSender(), spender, _xAllowances[_msgSender()][spender] + addedValue); return true;
  }
  function xDecreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    uint256 currentAllowance = _xAllowances[_msgSender()][spender];
    require(currentAllowance >= subtractedValue, "XERC20: below zero");
  unchecked {_xApprove(_msgSender(), spender, currentAllowance - subtractedValue);}
    return true;
  }
*/

  /* END XERC20 */
  receive() external payable {
//    xDistributeDividends();
    require(xTotalSupply() > 0);
    if (msg.value > 0) {
      xMagnifiedDividendPerShare =
      xMagnifiedDividendPerShare +
      ((msg.value * xMagnitude) / xTotalSupply());
      xTotalDividendsDistributed = xTotalDividendsDistributed + msg.value;
    }

  }
/*
  function xDistributeDividends() public payable {
    require(xTotalSupply() > 0);
    if (msg.value > 0) {
      xMagnifiedDividendPerShare =
      xMagnifiedDividendPerShare +
      ((msg.value * xMagnitude) / xTotalSupply());
      xTotalDividendsDistributed = xTotalDividendsDistributed + msg.value;
    }
  }
*/

/*
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
*/

/*
  function xDividendOf(address owner_) public view returns (uint256) {
    return xWithdrawableDividendOf(owner_);
  }
*/
  function xWithdrawableDividendOf(address owner_) public view returns (uint256){
    return xAccumulativeDividendOf(owner_) - xWithdrawnDividends[owner_];
  }
/*
  function xWithdrawnDividendOf(address owner_) public view returns (uint256){
    return xWithdrawnDividends[owner_];
  }
*/
  function xAccumulativeDividendOf(address owner_) public view returns (uint256){
    return uint256(
      int256(xMagnifiedDividendPerShare * balanceOf(owner_)) +
      xMagnifiedDividendCorrections[owner_]
    ) / xMagnitude;
  }
/*
  function _xMint(address account, uint256 amount) private {
    require(account != address(0));
    _xTotalSupply += amount;
    _xbalances[account] += amount;

    xMagnifiedDividendCorrections[account] =
    xMagnifiedDividendCorrections[account] -
    int256(xMagnifiedDividendPerShare * amount);
  }
*/

/*
  function _xBurn(address account, uint256 amount) private {
    require(account != address(0));
    uint256 accountBalance = _xbalances[account];
    require(accountBalance >= amount, "XERC20: amt > balance");
    unchecked {
      _xbalances[account] = accountBalance - amount;
    }
    _xTotalSupply -= amount;

    xMagnifiedDividendCorrections[account] =
    xMagnifiedDividendCorrections[account] +
    int256(xMagnifiedDividendPerShare * amount);
  }
*/

  /* END XDPT */
  /* BEGIN XTRACKER */

  function xIsExcludedFromDividends(address account) public view returns (bool) {
    return xExcludedFromDividends[account];
  }
  function xExcludeFromDividends(address account) public onlyOwner {
    require(!xExcludedFromDividends[account]);
    xExcludedFromDividends[account] = true;
    _xSetBalance(account, 0);
    imap_remove(account);
  }

  function xUpdateGasForTransfer(uint256 newGasForTransfer) external onlyOwner {
    xGasForTransfer = newGasForTransfer;
  }
  function xUpdateClaimWait(uint256 newClaimWait) external onlyOwner {
    require(newClaimWait >= 180 && newClaimWait <= 86400,"1h-24h");
    xClaimWait = newClaimWait;
  }

//  function xGetLastProcessedIndex() external view returns (uint256) {
//    return xLastProcessedIndex;
//  }

/*
  function xGetNumberOfTokenHolders() external view returns (uint256) {
    return xTokenHoldersMap.keys.length;
  }

*/
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
      if (uint256(index) > xLastProcessedIndex) {
        iterationsUntilProcessed = index - int256(xLastProcessedIndex);
      } else {
        uint256 processesUntilEndOfArray = xTokenHoldersMap.keys.length >
        xLastProcessedIndex ? xTokenHoldersMap.keys.length - xLastProcessedIndex : 0;
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

/*
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
    if (_index >= xTokenHoldersMap.keys.length) {
      return (0x0000000000000000000000000000000000000000, -1, -1, 0, 0, 0, 0, 0);
    }
    address _account = imap_getKeyAtIndex(_index);
    return xGetAccount(_account);
  }
*/

/*
  function xCanAutoClaim(uint256 lastClaimTime) private view returns (bool) {
    if (lastClaimTime > block.timestamp) {
      return false;
    }
    return block.timestamp - lastClaimTime >= xClaimWait;
  }
*/

  function _xSetBalance(address account, uint256 newBalance) private {
    require(account != address(0));
    uint256 currentBalance = balanceOf(account);
    if (newBalance > currentBalance) {
      uint256 mintAmount = newBalance - currentBalance;
//      _xMint(account, mintAmount);
      _xTotalSupply += mintAmount;
      _xbalances[account] += mintAmount;
      xMagnifiedDividendCorrections[account] =
      xMagnifiedDividendCorrections[account] -
      int256(xMagnifiedDividendPerShare * mintAmount);

    } else if (newBalance < currentBalance) {
      uint256 burnAmount = currentBalance - newBalance;
//      _xBurn(account, burnAmount);
      require(account != address(0));
      uint256 accountBalance = _xbalances[account];
      require(accountBalance >= burnAmount);
      unchecked {
        _xbalances[account] = accountBalance - burnAmount;
      }
      _xTotalSupply -= burnAmount;

      xMagnifiedDividendCorrections[account] =
      xMagnifiedDividendCorrections[account] +
      int256(xMagnifiedDividendPerShare * burnAmount);

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
    xProcessAccount(account);
  }

  function xProcessAll(uint256 gas) public returns (uint256, uint256, uint256){
    uint256 numberOfTokenHolders = xTokenHoldersMap.keys.length;
    if (numberOfTokenHolders == 0) {
      return (0, 0, xLastProcessedIndex);
    }
    uint256 _xLastProcessedIndex = xLastProcessedIndex;
    uint256 gasUsed = 0;
    uint256 gasLeft = gasleft();
    uint256 iterations = 0;
    uint256 claims = 0;
    while (gasUsed < gas && iterations < numberOfTokenHolders) {
      _xLastProcessedIndex++;
      if (_xLastProcessedIndex >= xTokenHoldersMap.keys.length) {
        _xLastProcessedIndex = 0;
      }
      address account = xTokenHoldersMap.keys[_xLastProcessedIndex];

      if (xLastClaimTimes[account] < block.timestamp
      && block.timestamp - xLastClaimTimes[account] >= xClaimWait
      && xProcessAccount(payable(account))
      ) {
        claims++;
      }
/*
      if (xCanAutoClaim(xLastClaimTimes[account])) {
        if (xProcessAccount(payable(account), true)) {
          claims++;
        }
      }
*/
      iterations++;
      uint256 newGasLeft = gasleft();
      if (gasLeft > newGasLeft) {
        gasUsed = gasUsed + (gasLeft - newGasLeft);
      }
      gasLeft = newGasLeft;
    }
    xLastProcessedIndex = _xLastProcessedIndex;
    return (iterations, claims, xLastProcessedIndex);
  }

  function xProcessAccount(address payable account) public onlyOwner returns (bool successful){
    uint256 amount = 0;
    uint256 _withdrawableDividend = xWithdrawableDividendOf(account);
    if (_withdrawableDividend > 0) {
      xWithdrawnDividends[account] =
      xWithdrawnDividends[account] +
      _withdrawableDividend;
      emit XDividendWithdrawn(account, _withdrawableDividend);
      (bool success,) = account.call{value: _withdrawableDividend, gas: xGasForTransfer}("");
      if (success) {
        amount = _withdrawableDividend;
        xLastClaimTimes[account] = block.timestamp;
        emit XClaim(account, amount);
        return true;
      }else{
        xWithdrawnDividends[account] =
        xWithdrawnDividends[account] -
        _withdrawableDividend;
        return false;
      }
    }else{return false;}
  }
  function xClaim() external {
    xProcessAccount(payable(msg.sender));
  }
  function recoverEth() external onlyOwner {// DEV ONLY
    payable(_msgSender()).transfer(address(this).balance);
  }

}
