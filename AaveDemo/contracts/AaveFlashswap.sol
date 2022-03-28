// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;


// AAVE
import {FlashLoanReceiverBase} from './aave-v3-core/contracts/flashloan/base/FlashLoanReceiverBase.sol';
import {IPoolAddressesProvider} from './aave-v3-core/contracts/interfaces/IPoolAddressesProvider.sol';
import {IPool} from './aave-v3-core/contracts/interfaces/IPool.sol';
// Others
import {IERC20} from './aave-v3-core/contracts/dependencies/openzeppelin/contracts/IERC20.sol';
import {GPv2SafeERC20} from './aave-v3-core/contracts/dependencies/gnosis/contracts/GPv2SafeERC20.sol';

contract AaveFlashswap is FlashLoanReceiverBase {
    using GPv2SafeERC20 for IERC20;

    event SuccessEvent(string indexed message);
    event CatchStringError(string indexed message);
    event CatchDataError(bytes indexed data);

    constructor(IPoolAddressesProvider _provider) FlashLoanReceiverBase(_provider) public {}

    // 调用swap执行闪电贷
    function flashSwapCall(address _asset, uint _amount) public {
        
        // POOL 来自FlashLoanReceiverBase.
        try IPool(POOL).flashLoanSimple({
            receiverAddress: address(this),
            asset: _asset,
            amount: _amount,
            params: 0,
            referralCode: 0
        }) {
            emit SuccessEvent("FlashSwap Success!");
        } catch Error(string memory reason) {
            emit CatchStringError(reason);
        } catch (bytes memory data) {
            emit CatchDataError(data);
        }
    }

    // todo:闪电贷回调函数
    function executeOperation(
        address _asset,
        uint256 _amount,
        uint256 _fees,
        address _sender,
        bytes memory _params
    ) public override returns(bool){
        // 额度检查
        require(_amount <= IERC20(_asset).balanceOf(address(this)), 'Invalid balance for the contract');
        IERC20(_asset).approve(address(POOL), _amount + _fee);

        // todo: logic goes here.

        uint totalDebt = _amount + _fee;
        IERC20(_asset).transfer(_asset, totalDebt);

        return true;
    }

}