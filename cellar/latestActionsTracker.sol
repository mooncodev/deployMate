pragma solidity ^0.4.0;

contract latestActionsTracker {
  struct LastAction {
    uint8 xtype;
    uint256 epoch;
  }
  //1 or 2 prepended to timestamp, 1=buy, 2=sell
  mapping (address => LastAction) private _latestActions;



  function latestActionsTracker(){
    /*  📈24hr lock in: If someone buys FrogeX and then sells within 24hrs, they incur an additional 25% tax
     which goes directly into Liquidity. This also applies to sells, so if you paperhand sell out of FrogeX
     and want to buy in within 24hrs because the pump kept going then you’ll also pay an additional 25% tax.
     (You can buy more if you bought, or sell more if you sold at no extra tax) 🤖 This kills the bots 🤖 */

      if(_latestAction[msg.sender] && _latestAction[msg.sender].epoch+86400 > block.timestamp){
          if(_latestAction[msg.sender].xtype != numBuyOrSell){

          }
      }
      if(numBuyOrSell){
          _latestAction[msg.sender].xtype = numBuyOrSell;
          _latestAction[msg.sender].epoch = block.timestamp;
      }

  }
}
