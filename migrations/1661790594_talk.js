const talk = artifacts.require("talk")
const ChainChat = artifacts.require("ChainChat")
// const ChainChatProxy = artifacts.require("ChainChatProxy")

module.exports = function(_deployer, network, accounts) {
  // Use deployer to state migration tasks.
  var map = {};
  const fs = require("fs");
  const fse = require('fs-extra');
  const truffle_config = require("../truffle-config.js")
  const srcDir = `./build`;
  const destDir = `./cn_front_end/src/chain-info`;

  _deployer.deploy(ChainChat, {from:accounts[0]})
  .then(() => {
    // return _deployer.deploy(ChainChatProxy, ChainChat.address, {from: accounts[0]})
    //        .then(async () =>  {
    //             var ChainChatInstance = await ChainChat.deployed()
    //             await ChainChatInstance.setBurnRole(ChainChatProxy.address)
                return _deployer.deploy(talk, ChainChat.address, {from:accounts[0]})
                        .then(async () => {
                          var ChainChatInstance = await ChainChat.deployed()
                          await ChainChatInstance.setBurnRole(talk.address)
                        })
                        .then(() => {
                          map.ChainChat = ChainChat.address;
                          // map.ChainChatProxy = ChainChatProxy.address;
                          map.talk = talk.address;
                          fs.writeFileSync('./build/contracts/map.json',JSON.stringify(map), 'utf-8');
                          console.log("1: map address saved!");
                        })
                        .then(() => {
                          fs.writeFileSync("./cn_front_end/src/truffle-config.json", JSON.stringify(truffle_config), 'utf-8'); 
                          console.log("2: truffle config saved to front end!");
                        })
                        .then(() => {
                          // To copy a folder or file, select overwrite accordingly
                          try {
                            fse.copySync(srcDir, destDir, { overwrite: true })
                            console.log('3: copy chain-info success!')
                          } catch (err) {
                            console.error(err)
                          }
                          console.log("front end updated!")
                        })             
            //  })
  })

  // .then(() => {
  //   return _deployer.deploy(talk, ChainChat.address, {from:accounts[0]})
  //           .then(() => {
  //             map.ChainChat = ChainChat.address;
  //             map.talk = talk.address;
  //             fs.writeFileSync('./build/contracts/map.json',JSON.stringify(map), 'utf-8');
  //             console.log("1: map address saved!");
  //           })
  //           .then(() => {
  //             fs.writeFileSync("./front_end/src/truffle-config.json", JSON.stringify(truffle_config), 'utf-8'); 
  //             console.log("2: truffle config saved to front end!");
  //           })
  //           .then(() => {
  //             // To copy a folder or file, select overwrite accordingly
  //             try {
  //               fse.copySync(srcDir, destDir, { overwrite: true })
  //               console.log('3: copy chain-info success!')
  //             } catch (err) {
  //               console.error(err)
  //             }
  //             console.log("front end updated!")
  //           })
  
  // })


};