const fs = require('fs-extra');
const path = require('path')
const {spawnSync} = require('child_process');


function flattenToFile(filename){
  const PROJECTROOT = __dirname.match('.*deployMate')[0];
  const readPath = path.resolve(PROJECTROOT, `./contracts/${filename}`);
  const writePath = path.resolve(PROJECTROOT, `./scripts/util/Flattened_${filename}`);
  const child = spawnSync(`npx.cmd`, [`hardhat`, `flatten`, readPath], { cwd:PROJECTROOT,encoding : 'utf8' });
  // console.log("stdout: ",child.stdout);
  fs.writeFileSync(writePath, new Buffer.from(child.stdout), { encoding : 'utf8' })
  console.log('...created flattened file');
  return writePath;
}

function rmCommentsFromFile(filepath){
  const PROJECTROOT = __dirname.match('.*deployMate')[0];
  const fileNameFromPath = filepath.match(/[\w-]+\..+/)[0];
  // const readPath = path.resolve(PROJECTROOT, `./contracts/${filename}`);
  const writePath = path.resolve(PROJECTROOT, `./scripts/util/Stripped_${fileNameFromPath}`);
  const content = fs.readFileSync(filepath)
  const rmComments = content.toString().replace(/\/\*[\s\S]*?\*\/|([^\\:]|^)\/\/.*$/gm, '$1');
  const rmNewlines = rmComments.replace(/^(\s*[\r\n]){2,}/gm, '\r\n')
  fs.writeFileSync(writePath, new Buffer.from(rmNewlines), { encoding : 'utf8' })
  console.log('...created a reduced file');
}

async function main(setup) {
  // if(!setup){setup = await require("./_setup")();}
  // const {} = setup;

  const flattenedFilePath = flattenToFile('FlowX.sol');
  rmCommentsFromFile(flattenedFilePath)
}

if(!require.main.filename.includes('sequence_')){
  main().then(() => process.exit(0)).catch(err => {
    console.error(err);process.exit(1);});
}else{module.exports = main}
