// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

interface IOracle {
    /**
    * @notice Returns the latest price of the given asset.
    * @dev Calls the current data source to get the price.
    * @param _asset Address of the asset.
    * @return uint256 Latest price of the asset.
    */
    function getLatestPrice(address _asset) external returns (uint256);

    /**
    * @notice Returns the address of the oracle contract's data source.
    */
    function dataSource() external view returns (address);

    /**
    * @notice Returns the info needed to pay the usage fee for the given asset.
    * @param _asset Address of the asset.
    * @return address, uint256 The address of the asset's usage fee token and the asset's usage fee.
    */
    function getUsageFeeInfo(address _asset) external view returns (address, uint256);
}