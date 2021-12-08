// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
//import "./XERC20.sol";

contract XDPT {

    /* BEGIN XDPT */
    mapping(address => uint256) private _x_balances;
    mapping(address => mapping(address => uint256)) private _x_allowances;
    uint256 private _x_totalSupply;
    uint256 internal constant dpt_magnitude = 2**128;
    uint256 internal magnifiedDividendPerShare;
    mapping(address => int256) internal magnifiedDividendCorrections;
    mapping(address => uint256) internal withdrawnDividends;
    uint256 public gasForTransfer;
    uint256 public totalDividendsDistributed;
    constructor(string memory _name, string memory _symbol) {
        gasForTransfer = 3000;
    }
/* BEGIN XERC20 */

    function x_decimals() public view virtual override returns (uint8) {return 18;}
    function x_totalSupply() public view virtual override returns (uint256) {return _x_totalSupply;}
    function x_balanceOf(address account) public view virtual override returns (uint256) {
        return _x_balances[account];
    }
    function x_allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _x_allowances[owner][spender];
    }
    function x_approve(address spender, uint256 amount) public virtual override returns (bool) {
        _x_approve(_msgSender(), spender, amount); return true;
    }
    function x_increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _x_approve(_msgSender(), spender, _x_allowances[_msgSender()][spender] + addedValue); return true;
    }
    function x_decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _x_allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "XERC20: decreased x_allowance below zero");
        unchecked {_x_approve(_msgSender(), spender, currentAllowance - subtractedValue);}
        return true;
    }
    function _x_approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "XERC20: x_approve from the zero address");
        require(spender != address(0), "XERC20: x_approve to the zero address");
        _x_allowances[owner][spender] = amount;
    }

/* END XERC20 */
    receive() external payable {
        distributeDividends();
    }

    function distributeDividends() public payable {
        require(x_totalSupply() > 0);
        if (msg.value > 0) {
            magnifiedDividendPerShare =
            magnifiedDividendPerShare +
            (((msg.value) * (dpt_magnitude)) / x_totalSupply());
            emit DividendsDistributed(msg.sender, msg.value);
            totalDividendsDistributed = totalDividendsDistributed + msg.value;
        }
    }

    function distributeDividends(uint256 amount) public {
        require(x_totalSupply() > 0);
        if (amount > 0) {
            magnifiedDividendPerShare =
            magnifiedDividendPerShare +
            ((amount * dpt_magnitude) / x_totalSupply());
            emit DividendsDistributed(msg.sender, amount);
            totalDividendsDistributed = totalDividendsDistributed + amount;
        }
    }

    function withdrawDividend() public {
        _withdrawDividendOfUser(payable(msg.sender));
    }

    function _withdrawDividendOfUser(address payable user) internal returns (uint256){
        uint256 _withdrawableDividend = withdrawableDividendOf(user);
        if (_withdrawableDividend > 0) {
            withdrawnDividends[user] =
            withdrawnDividends[user] +
            _withdrawableDividend;
            emit DividendWithdrawn(user, _withdrawableDividend);
            (bool success,) = user.call{value: _withdrawableDividend, gas: gasForTransfer}("");
            if (!success) {
                withdrawnDividends[user] =
                withdrawnDividends[user] -
                _withdrawableDividend;
                return 0;
            }
            return _withdrawableDividend;
        }
        return 0;
    }

    function dividendOf(address _owner) public view override returns (uint256) {
        return withdrawableDividendOf(_owner);
    }

    function withdrawableDividendOf(address _owner) public view returns (uint256){
        return accumulativeDividendOf(_owner) - withdrawnDividends[_owner];
    }

    function withdrawnDividendOf(address _owner) public view returns (uint256){
        return withdrawnDividends[_owner];
    }

    function accumulativeDividendOf(address _owner) public view returns (uint256){
        return uint256(
            int256(magnifiedDividendPerShare * balanceOf(_owner)) +
            magnifiedDividendCorrections[_owner]
        ) / dpt_magnitude;
    }

    function _x_mint(address account, uint256 amount) internal {
        require(account != address(0), "XERC20: cannot mint to the zero address");
        _x_totalSupply += amount;
        _x_balances[account] += amount;

        magnifiedDividendCorrections[account] =
        magnifiedDividendCorrections[account] -
        int256(magnifiedDividendPerShare * amount);
    }

    function _x_burn(address account, uint256 amount) internal {
        require(account != address(0), "XERC20: burn from the zero address");
        uint256 accountBalance = _x_balances[account];
        require(accountBalance >= amount, "XERC20: burn amount exceeds balance");
        unchecked {
            _x_balances[account] = accountBalance - amount;
        }
        _x_totalSupply -= amount;

        magnifiedDividendCorrections[account] =
        magnifiedDividendCorrections[account] +
        int256(magnifiedDividendPerShare * amount);
    }

    function _setBalance(address account, uint256 newBalance) internal {
        uint256 currentBalance = balanceOf(account);

        if (newBalance > currentBalance) {
            uint256 mintAmount = newBalance - currentBalance;
            _x_mint(account, mintAmount);
        } else if (newBalance < currentBalance) {
            uint256 burnAmount = currentBalance - newBalance;
            _x_burn(account, burnAmount);
        }
    }
    /* END XDPT */

}
