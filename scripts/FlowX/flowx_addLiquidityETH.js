const hre = require("hardhat");
const { ethers } = hre;
const { BigNumber, provider } = ethers;
const { MaxUint256 } = ethers.constants;
const { parseEther, parseUnits, formatUnits, defaultAbiCoder,hexValue  } = ethers.utils;
const axios = require('axios');
const oovAddrs = require("./util/oovAddresses");
const {__, logE, ethScanURI,   appendToLog,
  ___pressanykey___, ___pause___, num, expand
} = require('./util/logUtils');

const inTenMinutes = (Math.floor(Date.now() / 1000) + 60 * 10).toString();
const gLimitRopsten = "4512788";

let tx, cstx, i={},estGas,getGasPrice,gVals,
tokensToPool,ethToPool,deployerTokenBal,routerAllowance,
  tokensToGiveDeployer=0,amtToApprove=0;
let addr = {
  flowx: "0x18f8120a46768B800E3B35C59C9F620202C3e7F9",
  flowxPair: "0x3F923303135D2d3290CE5B3981B0da2152872fae",
  router: "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D",
  factory: "0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f",
  deployer: "0xda46eee9b7E7f5d40d599c778a5E607F7e8242BD",
  chtywallet: "0xb849fBBfB25b679ADdFAD5Ebe94132c9ec7803aa",
  mktgwallet: "0xF2d5C58cB49148D7cFC00E833328f15D92e95fdC",
  ...oovAddrs,
};

async function main() {
  const [deployer, chtywallet, mktgwallet, aaaa, bbbb, cccc, dddd]
    = await ethers.getSigners();

  getGasPrice = formatUnits(await provider.getGasPrice(), "wei");
  gVals = {gasLimit: gLimitRopsten, gasPrice: getGasPrice};

// ...often this gas price is easier to understand or
// display to the user in gwei


  i.router = await ethers.getContractAt('IUniswapV2Router02', addr.router);
  i.factory = await ethers.getContractAt('IUniswapV2Factory', addr.factory);
  i.weth = await ethers.getContractAt('IWETH', addr.weth);
  i.flowx = await ethers.getContractAt("FlowX", addr.flowx);

  addr.flowxPair =  await i.factory.getPair(addr.flowx, addr.weth, gVals);



  tokensToPool = expand(12850487932, 9).toString();
  ethToPool = parseUnits("2.231", "ether").toString();
  __(`tokensToPool `, tokensToPool);
  __(`ethToPool `, ethToPool);


  deployerTokenBal = await i.flowx.callStatic.balanceOf(addr.deployer);
  deployerTokenBal = deployerTokenBal.toString();
  __(`deployerTokenBal: `, deployerTokenBal);
  //allowance(address owner_, address spender) => uint256
  routerAllowance = await i.flowx.callStatic.allowance(addr.deployer, addr.router);
  routerAllowance = routerAllowance.toString();
  __(`routerAllowance: `, routerAllowance);

  if(num(deployerTokenBal) < num(tokensToPool)){
    tokensToGiveDeployer = (num(tokensToPool) - num(deployerTokenBal)).toString();
  }
  if(num(routerAllowance) < num(tokensToPool)){
    amtToApprove = (num(tokensToPool) - num(routerAllowance)).toString();
  }
  // await pressanykey();
  // amtToApprove = MaxUint256;
  if(tokensToGiveDeployer>0){
    __(`-------------transfer()-------------`);
    tx = await i.flowx.transfer(addr.deployer, tokensToGiveDeployer, gVals)
    await wait(tx.hash, `transfer`);
    await ___pause___();
    deployerTokenBal = await i.flowx.callStatic.balanceOf(addr.deployer);
    deployerTokenBal = deployerTokenBal.toString();
    __(`new deployerTokenBal: `, deployerTokenBal)
  }

  if(amtToApprove>0){
    __(`-------------approve()-------------`);
    tx = await i.flowx.approve(addr.router, amtToApprove, gVals)
    await wait(tx.hash, `approve`);
    await ___pause___();
    //allowance(address owner_, address spender) => uint256
    routerAllowance = await i.flowx.callStatic.allowance(addr.deployer, addr.router);
    routerAllowance = routerAllowance.toString();
    __(`new routerAllowance: `, routerAllowance)
  }


  if(num(deployerTokenBal) < num(tokensToPool)){__('not enough deployerTokenBal');return;}
  if(num(routerAllowance) < num(tokensToPool)){__('not enough routerAllowance');return;}

  __(`-------------addLiquidityETH()-------------`);
  const args_addLiquidityETH = [
    addr.flowx, tokensToPool, 1, 1,
    addr.deployer, inTenMinutes,
    {from: addr.deployer, value: ethToPool, ...gVals}
  ]

  __(`---Infura API eth_estimateGas---`);
  await infuraEstimateGas(args_addLiquidityETH);

  await ___pressanykey___();

  __(`---Contract.estimateGas---`);
  gVals.gasPrice = formatUnits(await provider.getGasPrice(), "wei");
  estGas = await i.router.estimateGas.addLiquidityETH(...args_addLiquidityETH)
  .then((res)=>{__(`estimateGas res: `, res);})
  .catch((err)=>{__(`estimateGas err: `, err);});
  args_addLiquidityETH.at(-1).gasPrice = getGasPrice + estGas;

  __(`---callStatic---`);
  cstx = await i.router.callStatic
  .addLiquidityETH(...args_addLiquidityETH)
  await wait(cstx.hash, `callStatic.addLiquidity`);

  await ___pause___();

  await ___pressanykey___();

  __(`---transaction---`);
  tx = await i.router
  .addLiquidityETH(...args_addLiquidityETH);
  await wait(tx.hash, `addLiquidityETH`);


}

async function wait(txhash, label, confirmation=1) {
  return new Promise((resolve,reject)=> {
    if (label) {console.log(`> Awaiting "${label}"\n tx: ${txhash}`);
    } else {console.log(`> Awaiting tx: ${txhash}`);}
    ethers.provider.waitForTransaction(txhash, confirmation)
    .then((rcpt)=>{__(`receipt: `, rcpt);resolve(rcpt);})
    .catch((err)=>{__(`tx err: `, err);reject(err)});
  })
}
async function infuraEstimateGas(args) {
  const opts = args.pop();
  const newargs = [
    args[0],
    ethers.BigNumber.from(args[1]),
    ethers.BigNumber.from(args[2]),
    ethers.BigNumber.from(args[3]),
    args[4],
    ethers.BigNumber.from(args[5])
  ];

  const bn_oneEth = ethers.BigNumber.from(parseEther("1.0"));
  const hex_oneEth = hexValue(parseEther("1.0"));
  const bn_gasPrice = ethers.BigNumber.from(opts.gasPrice);
  const hex_gasPrice = hexValue(parseInt(opts.gasPrice));
  const router01 = hre.artifacts.readArtifactSync("IUniswapV2Router01");
  const abiFrag = router01.abi.filter(f=>f.name==="addLiquidityETH");

  // let contract = new ethers.Contract(testContractAddress, abi, customHttpProvider);
  // let contractWithSigner = contract.connect(wallet);

  // let iface = new ethers.utils.Interface(abiFrag_addLiquidityETH)
  let iface = new ethers.utils.Interface(router01.abi)
  // let calldata = defaultAbiCoder.encode(args);
  // let calldata = iface.fragments[0].encode(args);
  let calldata = iface.encodeFunctionData("addLiquidityETH", newargs)
  // let signPromise = await wallet.sign(transaction);

  const url = `https://ropsten.infura.io/v3/0eaa508254d64389be2f25787cc66181`;
  const payload = {
    jsonrpc: '2.0',
    method: 'eth_estimateGas',
    params: [
      {
        from: addr.deployer,
        to: addr.router,
        // gas: '0x76c0',
        gasPrice: hex_gasPrice,
        value: hex_oneEth,
        data: calldata
      }
    ],
    id: 'est_addLiqETH'
  };
  await axios.post(url, payload)
  .then(function (res) {
    __(`eth_estimateGas res: `, res);
  })
  .catch(function (err) {
    __(`eth_estimateGas err: `, err);
  });

}


main().then()
