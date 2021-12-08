module.exports = {
  networks: {
    development: {
      host: "localhost",
      port: 7545,
      network_id: "5777"
    },
    test: {
      host: "localhost",
      port: 7545,
      network_id: "*"
    }
    // > truffle migrate --network development  //use truffle with ganache interface
    // live: { ... }
  },
  plugins: ["truffle-contract-size"],
  compilers: {
    solc: {
      version: "^0.8.4", // A version or constraint - Ex. "^0.5.0"
      // Can also be set to "native" to use a native solc
      //docker: false, // Use a version obtained through docker
      parser: "solcjs",  // Leverages solc-js purely for speedy parsing
      settings: {
/*
        optimizer: {
          enabled: false,
          runs: 1   // Optimize for how many times you intend to run the code
        },
*/
        evmVersion: "istanbul" // Default: "istanbul"
      }
    }
  }

  // Uncommenting the defaults below 
  // provides for an easier quick-start with Ganache.
  // You can also follow this format for other networks;
  // see <http://truffleframework.com/docs/advanced/configuration>
  // for more details on how to specify configuration options!
  //
  //networks: {
  //  development: {
  //    host: "127.0.0.1",
  //    port: 7545,
  //    network_id: "*"
  //  },
  //  test: {
  //    host: "127.0.0.1",
  //    port: 7545,
  //    network_id: "*"
  //  }
  //}
  //

};
