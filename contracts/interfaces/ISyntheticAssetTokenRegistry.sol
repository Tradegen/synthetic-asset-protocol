// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

interface ISyntheticAssetTokenRegistry {
    /**
    * @notice Returns the address of the synthetic asset's underlying data feed.
    * @dev Returns address(0) if the synthetic asset is not found.
    * @dev Either [_index] or [_syntheticAsset] is used for getting the data.
    * @dev If [_index] is 0, then [_syntheticAsset] is used.
    * @dev If [_syntheticAsset] is address(0), then [_syntheticAsset] is used.
    * @dev If [_index] and [_syntheticAsset] are both valid values, then [_index] is used.
    * @param _index Index of the synthetic asset.
    * @param _syntheticAsset Address of the synthetic asset.
    * @return address Address of the synthetic asset's underlying data feed.
    */
    function getDataFeed(uint256 _index, address _syntheticAsset) external view returns (address);

    /**
    * @notice Returns the synthetic asset's maximum supply of tokens.
    * @dev Returns 0 if the synthetic asset is not found.
    * @dev Either [_index] or [_syntheticAsset] is used for getting the data.
    * @dev If [_index] is 0, then [_syntheticAsset] is used.
    * @dev If [_syntheticAsset] is address(0), then [_syntheticAsset] is used.
    * @dev If [_index] and [_syntheticAsset] are both valid values, then [_index] is used.
    * @param _index Index of the synthetic asset.
    * @param _syntheticAsset Address of the synthetic asset.
    * @return uint256 The synthetic asset's maximum supply of tokens.
    */
    function getMaxSupply(uint256 _index, address _syntheticAsset) external view returns (uint256);

    /**
    * @notice Returns true if the minting is enabled for the given synthetic asset.
    * @dev Returns false if the synthetic asset is not found.
    * @dev Either [_index] or [_syntheticAsset] is used for getting the data.
    * @dev If [_index] is 0, then [_syntheticAsset] is used.
    * @dev If [_syntheticAsset] is address(0), then [_syntheticAsset] is used.
    * @dev If [_index] and [_syntheticAsset] are both valid values, then [_index] is used.
    * @param _index Index of the synthetic asset.
    * @param _syntheticAsset Address of the synthetic asset.
    * @return bool The synthetic asset's minting status.
    */
    function getMintingStatus(uint256 _index, address _syntheticAsset) external view returns (bool);

    /**
    * @notice Returns the synthetic asset's circulating supply of tokens.
    * @dev Returns 0 if the synthetic asset is not found.
    * @dev Either [_index] or [_syntheticAsset] is used for getting the data.
    * @dev If [_index] is 0, then [_syntheticAsset] is used.
    * @dev If [_syntheticAsset] is address(0), then [_syntheticAsset] is used.
    * @dev If [_index] and [_syntheticAsset] are both valid values, then [_index] is used.
    * @param _index Index of the synthetic asset.
    * @param _syntheticAsset Address of the synthetic asset.
    * @return uint256 The synthetic asset's circulating supply of tokens.
    */
    function getTotalSupply(uint256 _index, address _syntheticAsset) external view returns (uint256);

    /**
    * @notice Returns the user's balance of tokens for the given synthetic asset.
    * @dev Returns 0 if the synthetic asset is not found.
    * @dev Either [_index] or [_syntheticAsset] is used for getting the data.
    * @dev If [_index] is 0, then [_syntheticAsset] is used.
    * @dev If [_syntheticAsset] is address(0), then [_syntheticAsset] is used.
    * @dev If [_index] and [_syntheticAsset] are both valid values, then [_index] is used.
    * @param _user Address of the user.
    * @param _index Index of the synthetic asset.
    * @param _syntheticAsset Address of the synthetic asset.
    * @return uint256 The user's balance of tokens for the asset.
    */
    function getBalance(address _user, uint256 _index, address _syntheticAsset) external view returns (uint256);

    /**
    * @notice Creates a new synthetic asset token and registers it in the system.
    * @dev This function can only be called by the registrar of the SyntheticAssetTokenRegistry contract.
    * @param _asset Address of the synthetic asset's data feed.
    * @param _maxSupply The maximum number of tokens that can be minted.
    * @param _name A custom name for this asset.
    * @param _symbol A custom symbol for this asset.
    */
    function createSyntheticAssetToken(address _asset, uint256 _maxSupply, string memory _name, string memory _symbol) external;

    /**
    * @notice Increases the maximum supply of tokens for this asset.
    * @dev Only the operator of the SyntheticAssetTokenRegistry contract can call this function.
    * @dev The new max supply must be higher than the current max supply.
    * @param _syntheticAsset Address of the synthetic asset.
    * @param _newMaxSupply The new maximum number of tokens that can exist for this asset.
    */
    function increaseMaxSupply(address _syntheticAsset, uint256 _newMaxSupply) external;

    /**
    * @notice Enables, or disables, the ability to mint new tokens.
    * @dev Only the operator of the SyntheticAssetTokenRegistry contract can call this function.
    * @dev This function is meant to be used to protect the protocol from Black Swan events.
    * @param _syntheticAsset Address of the synthetic asset.
    * @param _enableMinting Whether to allow new tokens to be minted.
    */
    function toggleMintingStatus(address _syntheticAsset, bool _enableMinting) external;
}