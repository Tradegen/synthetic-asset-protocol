// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

// OpenZeppelin.
import "./openzeppelin-solidity/contracts/ERC20/ERC20.sol";
import "./openzeppelin-solidity/contracts/ReentrancyGuard.sol";
import './openzeppelin-solidity/contracts/ERC20/SafeERC20.sol';
import "./openzeppelin-solidity/contracts/SafeMath.sol";

// Interfaces.
import './interfaces/IOracle.sol';
import './interfaces/IProtocolSettings.sol';
import './interfaces/ITreasury.sol';

// Inheritance.
import './interfaces/ISyntheticAssetToken.sol';

contract SyntheticAssetToken is ISyntheticAssetToken, ERC20, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address public registry;
    IOracle public oracle;
    IProtocolSettings public protocolSettings;
    ITreasury public treasury;
    IERC20 public stablecoin;
    address public override asset;
    uint256 public override maxSupply;
    bool public override mintingIsEnabled;

    constructor(address _registry,
                address _oracle,
                address _protocolSettings,
                address _treasury,
                address _stablecoin,
                address _asset,
                uint256 _maxSupply,
                string memory _name,
                string memory _symbol)
                ERC20(_name, _symbol) 
    {
        registry = _registry;
        oracle = IOracle(_oracle);
        protocolSettings = IProtocolSettings(_protocolSettings);
        treasury = ITreasury(_treasury);
        stablecoin = IERC20(_stablecoin);
        asset = _asset;
        maxSupply = _maxSupply;
        mintingIsEnabled = true;
    }

    /* ========== VIEWS ========== */

    /**
    * @notice Returns the maximum number of tokens that can be minted for this asset.
    */
    function getAvailableTokensToMint() public view returns (uint256) {
        return maxSupply - totalSupply();
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
    * @notice Mints the given number of tokens for this asset.
    * @dev Transaction will revert if _numberOfTokens exceeds the available tokens to mint.
    * @dev Assumes that the user has already approved the asset's data feed's usage fee.
    * @dev Assumes that the user has approved (mintFee + (_numberOfTokens * oraclePrice)) worth of stablecoin.
    * @param _numberOfTokens Number of tokens to mint.
    */
    function mintTokens(uint256 _numberOfTokens) external {
        require(_numberOfTokens <= getAvailableTokensToMint(), "SyntheticAssetToken: Number of tokens is too high.");

        address feeToken;
        uint256 usageFee;
        (feeToken, usageFee) = oracle.getUsageFeeInfo(asset);

        IERC20(feeToken).safeTransferFrom(msg.sender, address(this), usageFee);
        IERC20(feeToken).approve(address(oracle), usageFee);
        uint256 oraclePrice = oracle.getLatestPrice(asset);

        uint256 dollarValue = oraclePrice.mul(_numberOfTokens).div(10 ** 18);
        uint256 mintFeeValue = dollarValue.mul(protocolSettings.mintFee().add(10000)).div(10000);
        stablecoin.safeTransferFrom(msg.sender, address(this), dollarValue.add(mintFeeValue));
        treasury.recordMintedTokens(asset, dollarValue, mintFeeValue);

        _mint(msg.sender, _numberOfTokens);

        emit MintedTokens(msg.sender, _numberOfTokens, oraclePrice, usageFee, mintFeeValue);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
    * @notice Increases the maximum supply of tokens for this asset.
    * @dev Only the SyntheticAssetTokenRegistry contract can call this function.
    * @dev The new max supply must be higher than the current max supply.
    * @param _newMaxSupply The new maximum number of tokens that can exist for this asset.
    */
    function increaseMaxSupply(uint256 _newMaxSupply) external onlyRegistry {
        // Gas savings.
        uint256 oldMaxSupply = maxSupply;

        require(_newMaxSupply > oldMaxSupply, "SyntheticAssetToken: The new max supply must be higher than the current max supply.");

        maxSupply = _newMaxSupply;

        emit IncreasedMaxSupply(oldMaxSupply, _newMaxSupply);
    }

    /**
    * @notice Enables, or disables, the ability to mint new tokens.
    * @dev Only the SyntheticAssetTokenRegistry contract can call this function.
    * @dev This function is meant to be used to protect the protocol from Black Swan events.
    * @param _enableMinting Whether to allow new tokens to be minted.
    */
    function toggleMintingStatus(bool _enableMinting) external onlyRegistry {
        mintingIsEnabled = _enableMinting;

        emit ToggledMintingStatus(_enableMinting);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyRegistry() {
        require(msg.sender == registry, "SyntheticAssetToken: Only the SyntheticAssetTokenRegistry contract can call this function.");
        _;
    }

    /* ========== EVENTS ========== */

    event MintedTokens(address user, uint256 numberOfTokens, uint256 oraclePrice, uint256 usageFeePaid, uint256 mintFeePaid);
    event IncreasedMaxSupply(uint256 oldMaxSupply, uint256 newMaxSupply);
    event ToggledMintingStatus(bool mintingStatus);
}