
async function main(setup) {
  if(!setup){setup = await require("./_setup")();}
  const {
    _addr, _g, _i, _deployNew,
  } = setup;

  const ETH_PRICE = 4630.00;
  const ETH_PER_1USD = (1 / ETH_PRICE).toFixed(7);
  const ETH_PER_1000USD = (1000 / ETH_PRICE).toFixed(7);

  const FROGE_SUPPLY = 500_000_000_000;
  const FROGE_IDEAL_VALUE_USD = 0.00000805;
  //find val where...  FROGE_SUPPLY * FROGE_PRICE


}

if(!require.main.filename.includes('sequence_')){
  main().then(() => process.exit(0)).catch(err => {
    console.error(err);process.exit(1);});
}else{module.exports = main}
