// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

interface IOrderbookFactory {
    /**
    * @notice Deploys an Orderbook contract and returns the contract's address.
    * @dev This function can only be called by the Router contract.
    * @param _syntheticAsset Address of the synthetic asset.
    * @param _representsBuyOrders Whether this is the 'buy' version of the orderbook.
    * @return address Address of the deployed Orderbook contract.
    */
    function createOrderbook(address _syntheticAsset, bool _representsBuyOrders) external returns (address);
}