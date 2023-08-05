// SPDX-License-Identifier: NOne
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./utils/ChainLinkPriceConsumers.sol";
import "./interfaces/IMembershipCollection.sol";
import "./interfaces/IWETH.sol";

contract RecurringPayments is
  Ownable,
  ReentrancyGuard,
  ChainLinkPriceConsumers
{
  using SafeERC20 for IERC20;
  address public immutable WMATIC;

  uint public subscriptionCounter = 0;

  uint public platformFee;
  address public feeReceiverAddress;

  //Structure for subscription

  struct Subscription {
    address creator;
    address merchant;
    IMembershipCollection collection;
    MembershipTier[] listOfTiers;
  }
  struct MembershipTier {
    uint period;
    uint amountInDollars;
    string tokenURI;
  }

  struct Sponsor {
    uint nextTier;
    TokenInfo token;
  }

  mapping(uint => mapping(uint => Sponsor)) public sponsors;

  mapping(uint => Subscription) public subscriptions;

  mapping(address => uint) public collectionsubscription;

  TokenInfo[] public tokens;

  // Events
  event RegisterBrandsubscription(
    uint subscriptionId,
    address merchant,
    address collection,
    uint totoalTier
  );
  event ChangeMerchantAddress(
    uint subscriptionId,
    address caller,
    address newMerchant
  );
  event AddNewTiers(
    uint subscriptionId,
    uint tierId,
    uint period,
    uint amountInDollars,
    string tokenURI
  );

  /**
   * @dev Constructor function for the RecurringPayments contract.
   * @param _wmatic The address of the WETH token contract.
   * @param _tokens An array of TokenInfo structs representing the different tokens used in the contract.
   */
  constructor(address _wmatic, TokenInfo[] memory _tokens) {
    WMATIC = _wmatic;

    for (uint i = 0; i < _tokens.length; i++) {
      require(
        _tokens[i].aggregator != address(0),
        "invalid zero aggregator address"
      );
      tokens.push(_tokens[i]);
    }
  }

  modifier isValidsubscription(uint subscriptionId) {
    require(validsubscription(subscriptionId), "invalid subscription Id");
    _;
  }

  modifier isValidCreator(uint subscriptionId) {
    require(
      _subscriptionCreator(subscriptionId) == msg.sender,
      "only creator can call"
    );
    _;
  }

  // This is matic receive function
  receive() external payable {
    emit MaticReceive(_msgSender(), msg.value);
  }

  /**
   * @dev Creates a new subscription for the user calling the function.
   * @param _subscriptionId The ID of the subscription to create.
   * @param _tierId The ID of the subscription tier to use.
   * @param _tokenAddressID The ID of the token to use for payment.
   */
  function createNewSubscription(
    uint _subscriptionId,
    uint _tierId,
    uint _tokenAddressID
  ) external payable isValidsubscription(_subscriptionId) nonReentrant {
    MembershipTier memory _tier = _getTier(_subscriptionId, _tierId);
    TokenInfo memory token = _getToken(_tokenAddressID);
    uint amountToPay = getAmountToPay(token, _tier.amountInDollars);
    _handleIncomingToken(_msgSender(), amountToPay, token.tokenAddress);
    uint tokenId = subscriptions[_subscriptionId].collection.mint(
      _msgSender(),
      _tierId
    );
    Sponsor memory _sponsor = Sponsor({ nextTier: 10000, token: token });
    sponsors[_subscriptionId][tokenId] = _sponsor;
    uint feeAmount = 0;
    if (platformFee != 0 && feeReceiverAddress != address(0)) {
      feeAmount = (platformFee * amountToPay) / 10000;
      _handleOutgoingToken(feeReceiverAddress, feeAmount, token.tokenAddress);
    }
    _handleOutgoingToken(
      subscriptions[_subscriptionId].merchant,
      amountToPay - feeAmount,
      token.tokenAddress
    );
    emit CreateNewSubscription(
      _msgSender(),
      _subscriptionId,
      _tierId,
      _tokenAddressID,
      amountToPay
    );
  }

  /**
   * @dev Cancels a user's subscription with the given ID.
   * @param _subscriptionId The ID of the subscription to cancel.
   * @param _tokenId The ID of the user's token representing the subscription.
   */
  function cancelSubscription(
    uint _subscriptionId,
    uint _tokenId
  ) external isValidsubscription(_subscriptionId) nonReentrant {
    Subscription memory _subscription = subscriptions[_subscriptionId];
    address tokenOwner = _subscription.collection.ownerOf(_tokenId);
    require(tokenOwner == _msgSender(), "only token owner can call");
    subscriptions[_subscriptionId].collection.deactivatePlan(_tokenId);
    sponsors[_subscriptionId][_tokenId].nextTier = 10000;
    emit CancelSubscription(_msgSender(), _tokenId, _subscriptionId);
  }

  /**
   * @dev Upgrades a user's subscription plan to the given tier and activates it.
   * @param _subscriptionId The ID of the subscription to modify.
   * @param _tokenId The ID of the user's token representing the subscription.
   * @param _tierId The ID of the subscription tier to upgrade to.
   * @param _tokenAddressID The ID of the token to use for payment.
   */
  function upgradeAndActivatesubscriptionPlan(
    uint _subscriptionId,
    uint _tokenId,
    uint _tierId,
    uint _tokenAddressID
  ) external payable isValidsubscription(_subscriptionId) nonReentrant {
    Subscription memory _subscription = subscriptions[_subscriptionId];
    address tokenOwner = _subscription.collection.ownerOf(_tokenId);
    require(tokenOwner == _msgSender(), "only token owner can call");
    MembershipTier memory _tier = _getTier(_subscriptionId, _tierId);
    TokenInfo memory token = _getToken(_tokenAddressID);
    if (_subscription.collection.isSubscriptionPeriodOver(_tokenId)) {
      uint amountToPay = getAmountToPay(token, _tier.amountInDollars);
      _handleIncomingToken(_msgSender(), amountToPay, token.tokenAddress);
      subscriptions[_subscriptionId].collection.upgradeToken(_tokenId, _tierId);
      sponsors[_subscriptionId][_tokenId].nextTier = 10000;
      sponsors[_subscriptionId][_tokenId].token = token;
      uint feeAmount = 0;
      if (platformFee != 0 && feeReceiverAddress != address(0)) {
        feeAmount = (platformFee * amountToPay) / 10000;
        _handleOutgoingToken(feeReceiverAddress, feeAmount, token.tokenAddress);
      }
      _handleOutgoingToken(
        subscriptions[_subscriptionId].merchant,
        amountToPay - feeAmount,
        token.tokenAddress
      );
      emit UpgradeAndActivatesubscriptionPlan(
        _msgSender(),
        _subscriptionId,
        _tokenId,
        _tierId,
        _tokenAddressID,
        amountToPay
      );
    } else {
      Sponsor memory _sponsor = Sponsor({ nextTier: _tierId, token: token });
      sponsors[_subscriptionId][_tokenId] = _sponsor;
      _subscription.collection.activatePlan(_tokenId);
      emit UpgradeAndActivatesubscriptionPlan(
        _msgSender(),
        _subscriptionId,
        _tokenId,
        _tierId,
        _tokenAddressID,
        0
      );
    }
  }

  /**
   * @dev Executes recurring payments for a given subscription and set of tokens.
   * @param _subscriptionId The ID of the subscription to execute payments for.
   * @param _tokenIds An array of token IDs to execute payments for.
   */
  function executeRecurringPayment(
    uint _subscriptionId,
    uint[] memory _tokenIds
  ) external isValidCreator(_subscriptionId) nonReentrant {
    address _merchant = subscriptions[_subscriptionId].merchant;
    for (uint i = 0; i < _tokenIds.length; i++) {
      Sponsor storage _sponsor = sponsors[_subscriptionId][_tokenIds[i]];
      IMembershipCollection.TokenInfo memory tokenInfo = subscriptions[
        _subscriptionId
      ].collection.getTokenInfo(_tokenIds[i]);
      address tokenOwner = subscriptions[_subscriptionId].collection.ownerOf(
        _tokenIds[i]
      );
      require(tokenOwner != address(0), "invalid token owner");
      require(tokenInfo.isActive, "token must be active");
      require(
        tokenInfo.expireTime < block.timestamp,
        "token period is not over"
      );
      uint _tierId = tokenInfo.tierId;
      if (_sponsor.nextTier != 10000) {
        _tierId = _sponsor.nextTier;
        _sponsor.nextTier = 10000;
      }
      MembershipTier memory _tier = _getTier(_subscriptionId, _tierId);
      uint amountToPay = getAmountToPay(_sponsor.token, _tier.amountInDollars);
      _handleIncomingToken(
        tokenOwner,
        amountToPay,
        _sponsor.token.tokenAddress
      );
      subscriptions[_subscriptionId].collection.upgradeToken(
        _tokenIds[i],
        _tierId
      );
      uint feeAmount = 0;
      if (platformFee != 0 && feeReceiverAddress != address(0)) {
        feeAmount = (platformFee * amountToPay) / 10000;
        _handleOutgoingToken(
          feeReceiverAddress,
          feeAmount,
          _sponsor.token.tokenAddress
        );
      }
      _handleOutgoingToken(
        _merchant,
        amountToPay - feeAmount,
        _sponsor.token.tokenAddress
      );
      emit ExecuteRecurringPayment(
        tokenOwner,
        _subscriptionId,
        _tokenIds[i],
        _tierId,
        _sponsor.token.tokenAddress,
        amountToPay
      );
    }
  }

  /**
   * @dev Given an amount and a currency, transfers the currency to this contract.
   * If the currency is ETH (0x0), attempts to wrap the amount as WETH.
   * @param from The address to transfer the currency from.
   * @param amount The amount of the currency to transfer.
   * @param currency The address of the currency to transfer.
   */
  function _handleIncomingToken(
    address from,
    uint256 amount,
    address currency
  ) internal {
    // If this is an ETH , ensure they sent enough and convert it to WETH under the hood
    if (currency == address(0)) {
      if (msg.value == 0) {
        bool success = IWETH(WMATIC).transferFrom(from, address(this), amount);
        require(success, "Wmatic failed to transfer");
      } else {
        require(
          msg.value >= amount,
          "Sent ETH Value does not match specified  amount"
        );
        uint remainingAmount = msg.value - amount;
        if (remainingAmount > 0) {
          _safeTransferETH(payable(from), remainingAmount);
        }
        IWETH(WMATIC).deposit{ value: (amount) }();
      }
    } else {
      // We must check the balance that was actually transferred to the auction,
      // as some tokens impose a transfer fee and would not actually transfer the
      // full amount to the market, resulting in potentally locked funds
      IERC20 token = IERC20(currency);
      uint256 beforeBalance = token.balanceOf(address(this));
      token.safeTransferFrom(from, address(this), amount);
      uint256 afterBalance = token.balanceOf(address(this));
      require(
        beforeBalance + (amount) == afterBalance,
        "Token transfer call did not transfer expected amount"
      );
    }
  }

  /**
   * @dev Handles the transfer of outgoing tokens from the contract.
   * @param to The address of the recipient.
   * @param amount The amount of tokens to transfer.
   * @param currency The address of the token contract, or zero address for ETH.
   * @notice This function is internal and should only be called by other functions in the contract.
   */
  function _handleOutgoingToken(
    address to,
    uint256 amount,
    address currency
  ) internal {
    // If the auction is in ETH, unwrap it from its underlying WETH and try to send it to the recipient.
    if (currency == address(0)) {
      IWETH(WMATIC).withdraw(amount);

      // If the ETH transfer fails (sigh), rewrap the ETH and try send it as WETH.
      if (!_safeTransferETH(payable(to), amount)) {
        IWETH(WMATIC).deposit{ value: amount }();
        IERC20(WMATIC).safeTransfer(to, amount);
      }
    } else {
      IERC20(currency).safeTransfer(to, amount);
    }
  }

  /**
   * @dev Safely transfers ETH from the contract to the specified recipient.
   * @param to The address of the recipient.
   * @param value The amount of ETH to transfer.
   * @return A boolean indicating whether the transfer was successful.
   * @notice This function is internal and should only be called by other functions in the contract.
   */
  function _safeTransferETH(address to, uint256 value) internal returns (bool) {
    (bool success, ) = to.call{ value: value }(new bytes(0));
    return success;
  }

  /**
   * @dev Returns the total number of tiers for a given subscription ID.
   * @param _subscriptionId The ID of the subscription to return the number of tiers for.
   * @return The total number of tiers for the given subscription ID.
   */
  function totalTiers(uint _subscriptionId) public view returns (uint) {
    return subscriptions[_subscriptionId].listOfTiers.length;
  }

  /**
   * @dev Returns the total number of tokens registered in the system.
   * @return The total number of tokens.
   */
  function totalTokens() public view returns (uint) {
    return tokens.length;
  }

  /**
   * @dev Returns information for a given token ID.
   * @param _tokenAddressId The ID of the token to return information for.
   * @return Information for the given token ID.
   */
  function _getToken(
    uint _tokenAddressId
  ) internal view returns (TokenInfo memory) {
    require(_tokenAddressId < totalTokens(), "invalid token address id");
    return tokens[_tokenAddressId];
  }

  /**
   * @dev Returns a given tier for a given subscription ID.
   * @param _subscriptionId The ID of the subscription to return the tier for.
   * @param _tierId The ID of the tier to return.
   * @return The specified tier for the given subscription ID.
   */
  function _getTier(
    uint _subscriptionId,
    uint _tierId
  ) internal view returns (MembershipTier memory) {
    require(_tierId < totalTiers(_subscriptionId), "invalid tiers id");

    return subscriptions[_subscriptionId].listOfTiers[_tierId];
  }

  /**
   * @dev Returns true if a subscription with the given ID is valid (i.e. has a creator address).
   * @param _subscriptionId The ID of the subscription to check.
   * @return True if the subscription is valid, false otherwise.
   */
  function validsubscription(
    uint _subscriptionId
  ) internal view returns (bool) {
    if (_subscriptionCreator(_subscriptionId) == address(0)) {
      return false;
    }
    return true;
  }

  /**
   * @dev Returns the address of the creator of a subscription with the given ID.
   * @param _subscriptionId The ID of the subscription to query.
   * @return The address of the subscription's creator.
   */
  function _subscriptionCreator(
    uint _subscriptionId
  ) internal view returns (address) {
    return subscriptions[_subscriptionId].creator;
  }
}
