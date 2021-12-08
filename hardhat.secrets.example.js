
// Go to https://www.alchemyapi.io, sign up, create
// a new App in its dashboard, and replace "KEY" with its key
const INFURA_API_KEY = "0ha___________________________6p81";
const INFURA_API_URL = `https://ropsten.infura.io/v3/${INFURA_API_KEY}`;
const ALCHEMY_API_KEY = "cW___________________________B5a";
const ALCHEMY_API_URL = `https://eth-ropsten.alchemyapi.io/v2/${ALCHEMY_API_KEY}`;

// Replace this private key with your Ropsten account private key
// To export your private key from Metamask, open Metamask and
// go to Account Details > Export Private Key
// Be aware of NEVER putting real Ether into testing accounts
// dev wallet: 0xAd09040Ad09CFEb3aa45243FEb37147C8fbdEb37
const PERSONAL_PRIVATE_KEY_1 = "042212_______________________________________________ae1fd8da70e";
// dev wallet: 0x4Fcc34E4FccB2d1EbB0B2d1e475ae4f57d411aEb
const PERSONAL_PRIVATE_KEY_2 = "b054_____________________________________________________edb63e7";
// dev wallet: 0x347EDd1e3347c8448a3BfB347951370f1F2547c8
const PERSONAL_PRIVATE_KEY_3 = "36f994bd_____________________________________________620d23f1661";

const accounts = [
  // first in array treated as primary signer, or "deployer" across script suite
  // other accounts are available and can be used via:
  // instance.connect(MySecondaryAccount).methodName()
  `0x${PERSONAL_PRIVATE_KEY_2}`,
  `0x${PERSONAL_PRIVATE_KEY_3}`
];

const bal = "100000000000000000000000000000000";
const accountsHH = [
    // for use with HH env where a balance can be specified
    // Addresses:
    // 0xb4f9748ff97453661f974c99c8f97455e30bf974
    // 0x368756ed875658ee9875626b008756ed81028756
    // 0x6ce9d2c8e9d22016ae9d22457ae9d23b899de9d2
    // 0x5ec38274c382335a7c382e6b31c3822b6750c382
    // 0x886446df6446eb5956446f2a186446a073e76446
    // 0xc06b3a016b3a478256b3a8ff1a6b3ac723656b3a
    // 0x753e40e43e407f76e3e401080c3e40f637193e40
    // 0xed60da7560dacfc8460da14af660dad0072c60da
    // 0x3f801be5801b16f2f801b0c54c801b3f252d801b
    // 0x5a01f49501f43b23001f44481001f451e5c101f4
  { privateKey: "c85e________c85e________c85e_______c85e__________c85e______c85e", balance: bal },
  { privateKey: "0eba________0eba________0eba_______0eba__________0eba______0eba", balance: bal },
  { privateKey: "5678________5678________5678_______5678__________5678______5678", balance: bal },
  { privateKey: "47d2________47d2________47d2_______47d2__________47d2______47d2", balance: bal },
  { privateKey: "a32c________a32c________a32c_______a32c__________a32c______a32c", balance: bal },
  { privateKey: "5e54________5e54________5e54_______5e54__________5e54______5e54", balance: bal },
  { privateKey: "e8a1________e8a1________e8a1_______e8a1__________e8a1______e8a1", balance: bal },
  { privateKey: "b7d2________b7d2________b7d2_______b7d2__________b7d2______b7d2", balance: bal },
  { privateKey: "db4f________db4f________db4f_______db4f__________db4f______db4f", balance: bal },
  { privateKey: "b9b4________b9b4________b9b4_______b9b4__________b9b4______b9b4", balance: bal },
];

module.exports = {
  accounts,
  INFURA_API_URL,
  ALCHEMY_API_URL,
  accountsHH,
};