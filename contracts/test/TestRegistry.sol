// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

// OpenZeppelin.
import '../openzeppelin-solidity/contracts/ERC20/SafeERC20.sol';

contract TestRegistry {
    using SafeERC20 for IERC20;

    address feeToken;
    uint256 fee;
    mapping (address => uint256) latestPrices;

    constructor(address _feeToken, uint256 _usageFee) {
        feeToken = _feeToken;
        fee = _usageFee;
    }

    function usageFeeToken(address) external view returns (address) {
        return feeToken;
    }

    function usageFee(address) external view returns (uint256) {
        return fee;
    }

    function getTokenPrice(address _asset) external returns (uint256) {
        IERC20(feeToken).safeTransferFrom(msg.sender, address(this), fee);

        return latestPrices[_asset];
    }

    function setLatestPrice(address _asset, uint256 _price) external {
        latestPrices[_asset] = _price;
    }
}