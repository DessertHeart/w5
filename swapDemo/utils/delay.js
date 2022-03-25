/// RPC方法：手动加快区块时间
/// provider: network

// 时间加速：Time
async function advanceTime(provider, time) {
  await provider.send('evm_increaseTime',[time]);
}

// 挖矿模式
async function advanceBlock(provider) {
  await provider.send('evm_mine');
}

// 时间加速：1Day
async function delay1Day(provider) {
  let day = 86400;
  await advanceTime(provider, day);
  await advanceBlock(provider);
}

module.exports = {
  advanceTime,
  advanceBlock,
  delay1Day
}

