// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

//import "./IXERC20.sol";
//import "./IXERC20Metadata.sol";
import "./oz430/Context.sol";

contract XERC20 is Context {
    mapping(address => uint256) private _x_balances;
    mapping(address => mapping(address => uint256)) private _x_allowances;
    uint256 private _x_totalSupply;
    string private _x_name;
    string private _x_symbol;

    constructor(string memory name_, string memory symbol_) {
        _x_name = name_; _x_symbol = symbol_;
    }
    function x_name() public view virtual override returns (string memory) {return _x_name;}
    function x_symbol() public view virtual override returns (string memory) {return _x_symbol;}
    function x_decimals() public view virtual override returns (uint8) {return 18;}
    function x_totalSupply() public view virtual override returns (uint256) {return _x_totalSupply;}
    function x_balanceOf(address account) public view virtual override returns (uint256) {return _x_balances[account];}
    function x_transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _x_transfer(_msgSender(), recipient, amount); return true;
    }
    function x_allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _x_allowances[owner][spender];
    }
    function x_approve(address spender, uint256 amount) public virtual override returns (bool) {
        _x_approve(_msgSender(), spender, amount); return true;
    }
    function x_transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _x_transfer(sender, recipient, amount);
        uint256 currentAllowance = _x_allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "XERC20: x_transfer amount exceeds x_allowance");
        unchecked {_x_approve(sender, _msgSender(), currentAllowance - amount);}
        return true;
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
    function _x_transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "XERC20: x_transfer from the zero address");
        require(recipient != address(0), "XERC20: x_transfer to the zero address");
        uint256 senderBalance = _x_balances[sender];
        require(senderBalance >= amount, "XERC20: x_transfer amount exceeds balance");
        unchecked {
            _x_balances[sender] = senderBalance - amount;
        }
        _x_balances[recipient] += amount;
    }
    function _x_mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "XERC20: mint to the zero address");
        _x_totalSupply += amount;
        _x_balances[account] += amount;
    }
    function _x_burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "XERC20: burn from the zero address");
        uint256 accountBalance = _x_balances[account];
        require(accountBalance >= amount, "XERC20: burn amount exceeds balance");
        unchecked {
            _x_balances[account] = accountBalance - amount;
        }
        _x_totalSupply -= amount;
    }
    function _x_approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "XERC20: x_approve from the zero address");
        require(spender != address(0), "XERC20: x_approve to the zero address");
        _x_allowances[owner][spender] = amount;
    }
}
