const hre = require("hardhat");
const chalk = require('chalk');
const fs = require('fs-extra')
const clra = chalk.blueBright;
const clrb = chalk.greenBright.bgGray;
const clrc = chalk.bold.red;
const clrd = chalk.bgYellow;
const errorStyle = chalk.bold.red;
const successStyle = chalk.bold.green;
const vaporStyle = chalk.bgMagenta.bold.cyan;
const boldUnderline = chalk.bold.underline.green;
const ethScanURI = {
  tx: `https://${hre.network.name==='mainnet'?'':hre.network.name+'.'}etherscan.io/tx/`,
  addr: `https://${hre.network.name==='mainnet'?'':hre.network.name+'.'}etherscan.io/address/`,
};
function appendToLog(newobj){
  const log = fs.readJsonSync('./_LOG.json');
  log.push({_time: new Date().toLocaleString(), ...newobj});
  fs.writeJsonSync('./_LOG.json', log, {spaces:2});
  console.log('...appended to _LOG.json')
}


const __ = logFactory(chalk.bold.blueBright, chalk.bold.cyan.bgBlackBright)
const log = logFactory(chalk.blue, chalk.green)
const log1 = logFactory(chalk.blue, chalk.green)
const log2 = logFactory(chalk.black.bgYellow, chalk.yellow)
const log3 = logFactory(chalk.bgCyan.bold.magenta, chalk.bgMagenta.bold.cyan)
const logE = logFactory(chalk.red, chalk.bold.red)

function logFactory(color1, color2){
  return function (a1, a2=null){
    try{
      if(a2==null){
        console.log(color1(a1));
      }else if(typeof(a2)==='object'){
        console.log(color1(a1), a2);
      }else{
        console.log(color1(a1) + color2(a2));
      }
    }catch(e){console.log('couldn\'t log: ', a1);}
  }
}

function logTxError(error){
  logE('error.reason/code: ' + error.reason + ` ` + error.code);
  if(error.transaction){
    try{logE('error.transactionHash: ' + error.transactionHash);}catch(e){}
    try{logE('error.transaction: ' + JSON.stringify(error.transaction));}catch(e){}
    try{logE('tx.gasPrice: ' + error.transaction.gasPrice.toString());}catch(e){}
    try{logE('tx.gasLimit: ' + error.transaction.gasLimit.toString());}catch(e){}
    try{logE('tx.value: ' + error.transaction.value.toString());}catch(e){}
    try{logE('tx.effectiveGasPrice: ' + error.transaction.effectiveGasPrice.toString());}catch(e){}
    try{logE('tx.cumulativeGasUsed: ' + error.transaction.cumulativeGasUsed.toString());}catch(e){}
    try{logE('tx.gasUsed: ' + error.transaction.gasUsed.toString());}catch(e){}
    try{logE('tx.nonce: ' + error.transaction.nonce.toString());}catch(e){}
    try{logE(ethScanURI.tx + error.transactionHash);}catch(e){}

  }
}
function ___pause___(){return new Promise(r=>setTimeout(r,1000))}//await ___pause___();
const ___pressanykey___ = async () => {
  console.log('press any key to continue...')
  process.stdin.setRawMode(true)
  return new Promise(resolve => process.stdin.once('data', () => {
    process.stdin.setRawMode(false)
    resolve()
  }))
}
function num(string){return parseInt(string);}
function expand(amt, decimal){return amt*(10**decimal)}

module.exports = {
  __, log, log2, log3, logE, ethScanURI, logTxError,
  appendToLog, ___pressanykey___, ___pause___,num,expand

}
