async function main(setup) {
  if(!setup){setup = await require("./_setup")();}
  const {_deployNew} = setup;

  const inst = _deployNew({
    artifact: "IterableMapping"
  });

  return inst.address;
}

if(!require.main.filename.includes('sequence_')){
  main().then(() => process.exit(0)).catch(err => {
    console.error(err);process.exit(1);});
}else{module.exports = main}
