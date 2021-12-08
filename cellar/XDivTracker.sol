pragma solidity ^0.8.4;

import "./XDPT.sol";
import "./oz430/Ownable.sol";
import "./dpt/IterableMapping.sol";

contract FlowXDividendTracker is Ownable {
    mapping(address => uint256) private _xbalances;
    mapping(address => mapping(address => uint256)) private _xAllowances;
    uint256 private _xTotalSupply;
    uint256 internal constant xMagnitude = 2**128;
    uint256 internal xMagnifiedDividendPerShare;
    mapping(address => int256) internal xMagnifiedDividendCorrections;
    mapping(address => uint256) internal xWithdrawnDividends;
    uint256 public xGasForTransfer;
    uint256 public xTotalDividendsDistributed;
    using IterableMapping for IterableMapping.Map;
    IterableMapping.Map private xTokenHoldersMap;
    uint256 public lastProcessedIndex;
    mapping(address => bool) public xExcludedFromDividends;
    mapping(address => uint256) public xLastClaimTimes;
    uint256 public xClaimWait;
    uint256 public constant xMinTokenBalanceForDividends = 10000 * (10**18);
    event XExcludeFromDividends(address indexed account);
    event XGasForTransferUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event XClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event XClaim(address indexed account, uint256 amount, bool indexed automatic);

    constructor() {
        xClaimWait = 180;
        xGasForTransfer = 3000;
    }
    /* BEGIN XDPT */
/* BEGIN XERC20 */

    function xDecimals() public view virtual override returns (uint8) {return 18;}
    function xTotalSupply() public view virtual override returns (uint256) {return _xTotalSupply;}
    function xBalanceOf(address account) public view virtual override returns (uint256) {
        return _xbalances[account];
    }
    function xAllowance(address owner, address spender) public view virtual override returns (uint256) {
        return _xAllowances[owner][spender];
    }
    function _xApprove(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "XERC20: xApprove from the zero address");
        require(spender != address(0), "XERC20: xApprove to the zero address");
        _xAllowances[owner][spender] = amount;
    }
    function xApprove(address spender, uint256 amount) public virtual override returns (bool) {
        _xApprove(_msgSender(), spender, amount); return true;
    }
    function xIncreaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _xApprove(_msgSender(), spender, _xAllowances[_msgSender()][spender] + addedValue); return true;
    }
    function xDecreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _xAllowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "XERC20: decreased xAllowance below zero");
        unchecked {_xApprove(_msgSender(), spender, currentAllowance - subtractedValue);}
        return true;
    }

/* END XERC20 */
    receive() external payable {
        xDistributeDividends();
    }
    function xDistributeDividends() public payable {
        require(xTotalSupply() > 0);
        if (msg.value > 0) {
            xMagnifiedDividendPerShare =
            xMagnifiedDividendPerShare +
            ((msg.value * xMagnitude) / xTotalSupply());
            emit DividendsDistributed(msg.sender, msg.value);
            xTotalDividendsDistributed = xTotalDividendsDistributed + msg.value;
        }
    }

    function _xWithdrawDividendOfUser(address payable user) internal returns (uint256){
        uint256 _withdrawableDividend = xWithdrawableDividendOf(user);
        if (_withdrawableDividend > 0) {
            xWithdrawnDividends[user] =
            xWithdrawnDividends[user] +
            _withdrawableDividend;
            emit DividendWithdrawn(user, _withdrawableDividend);
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

    function xDividendOf(address _owner) public view override returns (uint256) {
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

    function _xMint(address account, uint256 amount) internal {
        require(account != address(0), "XERC20: cannot mint to the zero address");
        _xTotalSupply += amount;
        _xbalances[account] += amount;

        xMagnifiedDividendCorrections[account] =
        xMagnifiedDividendCorrections[account] -
        int256(xMagnifiedDividendPerShare * amount);
    }

    function _xBurn(address account, uint256 amount) internal {
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

    /* END XDPT */
    /* BEGIN XTRACKER */

    function xIsExcludedFromDividends(address account) public view returns (bool) {
        return xExcludedFromDividends[account];
    }
    function xExcludeFromDividends(address account) external onlyOwner {
        require(!xExcludedFromDividends[account], "FlowX_Dividend_Tracker: Account is already excluded from rewards");
        xExcludedFromDividends[account] = true;
        _xSetBalance(account, 0);
        xTokenHoldersMap.remove(account);
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
        index = xTokenHoldersMap.getIndexOfKey(account);
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
        if (_index >= xTokenHoldersMap.size()) {
            return (0x0000000000000000000000000000000000000000, -1, -1, 0, 0, 0, 0, 0);
        }
        address _account = xTokenHoldersMap.getKeyAtIndex(_index);
        return xGetAccount(_account);
    }

    function xCanAutoClaim(uint256 lastClaimTime) private view returns (bool) {
        if (lastClaimTime > block.timestamp) {
            return false;
        }
        return block.timestamp - lastClaimTime >= xClaimWait;
    }
    
    function _xSetBalance(address account, uint256 newBalance) internal {
        uint256 currentBalance = balanceOf(account);
        if (newBalance > currentBalance) {
            uint256 mintAmount = newBalance - currentBalance;
            _xMint(account, mintAmount);
        } else if (newBalance < currentBalance) {
            uint256 burnAmount = currentBalance - newBalance;
            _xBurn(account, burnAmount);
        }
    }
    function xSetBalance(address payable account, uint256 newBalance) external onlyOwner {
        if (xExcludedFromDividends[account]) {
            return;
        }
        if (newBalance >= xMinTokenBalanceForDividends) {
            _xSetBalance(account, newBalance);
            xTokenHoldersMap.set(account, newBalance);
        } else {
            _xSetBalance(account, 0);
            xTokenHoldersMap.remove(account);
        }
        xProcessAccount(account, true);
    }

    function xProcess(uint256 gas) public returns (uint256, uint256, uint256){
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

    function xRecoverEth() external onlyOwner {
        payable(_msgSender()).transfer(address(this).balance);
    }

}
