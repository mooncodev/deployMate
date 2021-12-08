const fs=require('fs-extra');const path=require('path');const {spawnSync}=require('child_process');


const FILE_NAME = "FlowX.sol";
const SCRIPTS_SUBDIR = "FlowX";

function flattenToFile(filename){
  const PROJECTROOT = __dirname.match('.*deployMate')[0];
  const readPath = path.resolve(PROJECTROOT, `./contracts/${filename}`);
  const writePath = path.resolve(PROJECTROOT, `./scripts/${SCRIPTS_SUBDIR}/util/Flattened_${filename}`);
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
  const writePath = path.resolve(PROJECTROOT, `./scripts/${SCRIPTS_SUBDIR}/util/Stripped_${fileNameFromPath}`);
  const content = fs.readFileSync(filepath)
  const rmComments = content.toString().replace(/\/\*[\s\S]*?\*\/|([^\\:]|^)\/\/.*$/gm, '$1');
  const rmNewlines = rmComments.replace(/^(\s*[\r\n]){2,}/gm, '\r\n')
  fs.writeFileSync(writePath, new Buffer.from(rmNewlines), { encoding : 'utf8' })
  console.log('...created a stripped file');
}

const flattenedFilePath = flattenToFile(FILE_NAME);
rmCommentsFromFile(flattenedFilePath)

