// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

interface ISyntheticAssetToken {
    /**
    * @notice Returns the maximum number of tokens that can be minted for this asset.
    */
    function getAvailableTokensToMint() external view returns (uint256);

    /**
    * @notice Returns the maximum number of tokens for this asset that can be in circulation.
    */
    function maxSupply() external view returns (uint256);

    /**
    * @notice Mints the given number of tokens for this asset.
    * @dev Transaction will revert if _numberOfTokens exceeds the available tokens to mint.
    * @dev Assumes that the user has already approved the asset's data feed's usage fee.
    * @dev Assumes that the user has approved (mintFee + (_numberOfTokens * oraclePrice)) worth of stablecoin.
    * @param _numberOfTokens Number of tokens to mint.
    */
    function mintTokens(uint256 _numberOfTokens) external;

    /**
    * @notice Increases the maximum supply of tokens for this asset.
    * @dev Only the SyntheticAssetRegistry contract can call this function.
    * @dev The new max supply must be higher than the current max supply.
    * @param _newMaxSupply The new maximum number of tokens that can exist for this asset.
    */
    function increaseMaxSupply(uint256 _newMaxSupply) external;

    /**
    * @notice Enables, or disables, the ability to mint new tokens.
    * @dev Only the SyntheticAssetRegistry contract can call this function.
    * @dev This function is meant to be used to protect the protocol from Black Swan events.
    * @param _enableMinting Whether to allow new tokens to be minted.
    */
    function toggleMintingStatus(bool _enableMinting) external;
}