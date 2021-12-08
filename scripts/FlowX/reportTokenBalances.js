const {
  log1, log2, log3, logE, ethScanURI, logTxError
} = require('./util/logUtils');

async function main(setup) {
  if(!setup){setup = await require("./_setup")();}
  const {
    __reportTokenBalances,
  } = setup;
  //await hre.run('compile');

  await __reportTokenBalances();

}

if(!require.main.filename.includes('sequence_')){
  main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    logTxError(error);
    process.exit(1);
  });
}else{
  module.exports = main
}
