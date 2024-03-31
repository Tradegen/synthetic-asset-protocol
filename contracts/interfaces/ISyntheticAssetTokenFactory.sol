// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

interface ISyntheticAssetTokenFactory {
    /**
    * @notice Deploys a SyntheticAssetToken contract and returns the contract's address.
    * @dev This function can only be called by the SyntheticAssetTokenRegistry contract.
    * @param _asset Address of the synthetic asset's data feed.
    * @param _maxSupply The maximum number of tokens that can be minted.
    * @param _name A custom name for this asset.
    * @param _symbol A custom symbol for this asset.
    * @return address Address of the deployed SyntheticAssetToken contract.
    */
    function createSyntheticAssetToken(address _asset, uint256 _maxSupply, string memory _name, string memory _symbol) external returns (address);
}