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
}