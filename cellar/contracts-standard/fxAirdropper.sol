// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

//import './oz430/IERC20.sol';
import './FlowX.sol';
//import './SafeMath.sol';
import './oz430/Ownable.sol';

/**
 * @title POLY token initial distribution
 *
 * @dev Distribute purchasers, airdrop, reserve, and founder tokens
 */
contract FxAirdrop is Ownable {
    FlowX public token;

    function doAirdrop1 (address[] calldata _recipients , uint256[] calldata _balances)  external onlyOwner{
        require(_recipients.length == _balances.length);
        for (uint i=0; i < _recipients.length; i++) {
            token.transfer(_recipients[i], _balances[i]);
        }
    }

/*
    uint256 public tokenAmountToAirdrop;
    function doAirdrop2(address[] _recipients, uint256[] _balances) public {
        require(msg.sender == owner);
        for (uint256 i=0; i < _recipients.length; i++) {
            require(tokenAmountToAirdrop >= _balances[i]);
            tokenAmountToAirdrop = tokenAmountToAirdrop - _balances[i];
            balances[_recipients[i]] = balances[_recipients[i]] + _balances[i];
            Transfer(0x0, _recipients[i], _balances[i]);
        }
    }
*/
}