// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./base/OrchestratedUpgradeable.sol";

/// @title Dividend-Paying Token Interface
/// @author Roger Wu (https://github.com/roger-wu)
/// @dev An interface for a dividend-paying token contract.
interface DividendPayingTokenInterface {
    function dividendOf(address _owner) external view returns(uint256);
    function distributeDividends(uint256 amount) external;
    function withdrawDividend(address account) external returns(uint256);
    event DividendsDistributed(
        address indexed from,
        uint256 weiAmount
    );
    event DividendWithdrawn(
        address indexed to,
        uint256 weiAmount
    );
}

/// @title Dividend-Paying Token Optional Interface
/// @author Roger Wu (https://github.com/roger-wu)
/// @dev OPTIONAL functions for a dividend-paying token contract.
interface DividendPayingTokenOptionalInterface {
    function withdrawableDividendOf(address _owner) external view returns(uint256);
    function withdrawnDividendOf(address _owner) external view returns(uint256);
    function accumulativeDividendOf(address _owner) external view returns(uint256);
}

contract DividendPaying is OrchestratedUpgradeable, DividendPayingTokenInterface, DividendPayingTokenOptionalInterface
{
    using SafeMath for uint256;
    using SafeMathUint for uint256;
    using SafeMathInt for int256;

    uint256 internal constant magnitude = 2**128;
    uint256 internal magnifiedDividendPerShare;
    mapping(address => int256) internal magnifiedDividendCorrections;

    mapping(address => uint256) internal withdrawnDividends;


    uint256 public totalDividendsDistributed;

    mapping(address => uint) public userBalances;
    uint public totalToken;

    function initialize() initializer public {
        __DividendPaying_init();
    }

    function __DividendPaying_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __Orchestrated_init_unchained();
        __DividendPaying_init_unchained();
    }

    function __DividendPaying_init_unchained() internal onlyInitializing {
        orchestration[owner()][0x3243c791] = true;
        orchestration[owner()][0x21e5383a] = true;
        orchestration[owner()][0xcf8eeb7e] = true;
        orchestration[owner()][0x9c53c0ca] = true;
    }

    function setAllAuth(address user, bool auth) public onlyOwner {
        orchestration[user][0x3243c791] = auth;
        orchestration[user][0x21e5383a] = auth;
        orchestration[user][0xcf8eeb7e] = auth;
        orchestration[user][0x9c53c0ca] = auth;
    }

    //0x3243c791
    function distributeDividends(uint256 amount) override external onlyOrchestrated("onlyOrchestrated: distributeDividends") {
        if (amount > 0 && totalToken > 0) {
            magnifiedDividendPerShare = magnifiedDividendPerShare.add(
                (amount).mul(magnitude) / (totalToken)
            );
            emit DividendsDistributed(msg.sender, amount);
            totalDividendsDistributed = totalDividendsDistributed.add(amount);
        }
    }

    //21e5383a
    function addBalance(address account, uint amount) external onlyOrchestrated("onlyOrchestrated: addBalance") {
        userBalances[account] = userBalances[account].add(amount);
        totalToken = totalToken.add(amount);
        magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account].sub((magnifiedDividendPerShare.mul(amount)).toInt256Safe());
    }

    //cf8eeb7e
    function subBalance(address account, uint amount) external onlyOrchestrated("onlyOrchestrated: subBalance") {
        userBalances[account] = userBalances[account].sub(amount);
        if(userBalances[account] >= amount) {
            userBalances[account] = userBalances[account].sub(amount);
        } else {
            userBalances[account] = 0;
        }
        totalToken = totalToken.sub(amount);
        magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account].add((magnifiedDividendPerShare.mul(amount)).toInt256Safe());
    }


    function withdrawDividend(address account) external virtual override onlyOrchestrated("onlyOrchestrated: withdrawDividend") returns (uint256) {
        return _withdrawDividendOfUser(account);
    }


    function accumulativeDividendOf(address _owner) public view override returns (uint256) {
        return magnifiedDividendPerShare
        .mul(userBalances[_owner])
        .toInt256Safe()
        .add(magnifiedDividendCorrections[_owner])
        .toUint256Safe() / magnitude;
    }


    function withdrawableDividendOf(address _owner) public view override returns (uint256) {
        return accumulativeDividendOf(_owner).sub(withdrawnDividends[_owner]);
    }

    function dividendOf(address _owner) public view override returns (uint256) {
        return withdrawableDividendOf(_owner);
    }

    function _withdrawDividendOfUser(address user) internal returns (uint256) {
        uint256 _withdrawableDividend = withdrawableDividendOf(user);
        if (_withdrawableDividend > 0) {
            withdrawnDividends[user] = withdrawnDividends[user].add(_withdrawableDividend);
            emit DividendWithdrawn(user, _withdrawableDividend);
            return _withdrawableDividend;
        }
        return 0;
    }


    function withdrawnDividendOf(address _owner) public view override returns (uint256) {
        return withdrawnDividends[_owner];
    }

}

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }
    }
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (b > a) return (false, 0);
        return (true, a - b);
    }
    }
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }
    }
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }
    }
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
    unchecked {
        require(b <= a, errorMessage);
        return a - b;
    }
    }
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
    unchecked {
        require(b > 0, errorMessage);
        return a / b;
    }
    }
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
    unchecked {
        require(b > 0, errorMessage);
        return a % b;
    }
    }
}

library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);
    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != -1 || a != MIN_INT256);
        return a / b;
    }
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }
    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }
    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
    }
}

library SafeMathUint {
    function toInt256Safe(uint256 a) internal pure returns (int256) {
        int256 b = int256(a);
        require(b >= 0);
        return b;
    }
}
