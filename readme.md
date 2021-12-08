## deployMate Repo

This project is currently setup to run exclusively on ropsten

It could be switched to another testnet or mainnet fairly easily, but I suspect switching it to local dev might require a bit more work(?)

`./contracts/` folder will include all the contracts to compile and establish artifacts for

`./scripts/` folder has the action suite being built

`./scripts/compile.js` file executes hre.compile.all()

`./scripts/master.js` file is intended as having the ability to run multiple scripts in succession

`./scripts/DeployNewToken.js` file contains block examples of contract deployment actions that can be commented/cloned

`./scripts/MyAwesomeAction.js` files contain more or less 1 specific action each- please clone the entire file to make more actions

`./scripts/util/setup.js` file prepares and exports all the inputs any action file could need to perform

`./scripts/util/logUtils.js` file contains some bulky error handling (for better console output) and chalk-npm stuff

everything in `./deploy` and `./test` are leftovers from the forked repo (MateCore)

.gitignore contents:
```
build
abi
artifacts
cache
node_modules
hardhat.secrets.js
```
Please create your own hardhat.secrets.js and provide your own accounts and API keys

This project leans (exclusively, for now) on the use of the cli command pattern:

`npx hardhat run scripts/file.js --network ropsten`

In webstorm we're able to right click files and tabs to "run" and "debug" files.

That is why I am not maintaining action entries in the package.json/scripts:{} block