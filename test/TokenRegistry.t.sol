// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "src/TokenRegistry.sol";

contract TokenRegistryTest is Test {
    TokenRegistry tokenRegistry;
    address council = address(1);
    address nonCouncil = address(2);
    address tokentroller = address(5);
    address tokenAddress = address(3);
    uint256 autoApprovalTime = 1 weeks;

    function setUp() public {
        tokenRegistry = new TokenRegistry(council, autoApprovalTime);
        tokenRegistry.updateTokentroller(tokentroller);
    }

    function testAddToken() public {
        vm.prank(tokentroller);
        tokenRegistry.addToken("Test Token", "A sample token", "https://example.com/logo.png", "TTK", tokenAddress, 18);

        (
            string memory name,
            string memory description,
            string memory tokenLogoURL,
            string memory symbol,
            uint8 decimals,
            bool isPending
        ) = tokenRegistry.getToken(tokenAddress);

        assertEq(name, "Test Token");
        assertEq(description, "A sample token");
        assertEq(tokenLogoURL, "https://example.com/logo.png");
        assertEq(symbol, "TTK");
        assertEq(decimals, 18);
        assertEq(isPending, true);
    }

    function testApproveToken() public {
        vm.prank(tokentroller);
        tokenRegistry.addToken("Test Token", "A sample token", "https://example.com/logo.png", "TTK", tokenAddress, 18);

        vm.prank(council);
        tokenRegistry.approveToken(tokenAddress);

        (, , , , , bool isPending) = tokenRegistry.getToken(tokenAddress);
        assertEq(isPending, false);
    }

    function testRejectToken() public {
        vm.prank(tokentroller);
        tokenRegistry.addToken("Test Token", "A sample token", "https://example.com/logo.png", "TTK", tokenAddress, 18);

        vm.prank(council);
        tokenRegistry.rejectToken(tokenAddress);

        // Expect revert because token does not exist after rejection
        vm.expectRevert("Token does not exist");
        tokenRegistry.getToken(tokenAddress);
    }

    function testUpdateCouncil() public {
        address newCouncil = address(4);
        vm.prank(council);
        tokenRegistry.updateCouncil(newCouncil);
        assertEq(tokenRegistry.council(), newCouncil);
    }

    function testAutoApproveToken() public {
        vm.prank(tokentroller);
        tokenRegistry.addToken("Test Token", "A sample token", "https://example.com/logo.png", "TTK", tokenAddress, 18);

        // Fast-forward time beyond auto-approval time
        vm.warp(block.timestamp + autoApprovalTime + 1);

        vm.prank(tokentroller);
        tokenRegistry.autoApproveTokens();

        (, , , , , bool isPending) = tokenRegistry.getToken(tokenAddress);
        assertEq(isPending, false);
    }

    function testListTokensPagination() public {
        // Add multiple tokens
        for (uint256 i = 0; i < 5; i++) {
            vm.prank(tokentroller);
            tokenRegistry.addToken(
                string(abi.encodePacked("Token ", uintToStr(i))),
                "A sample token",
                "https://example.com/logo.png",
                string(abi.encodePacked("TK", uintToStr(i))),
                address(uint160(i + 10)),
                18
            );
        }

        vm.prank(tokentroller);
        TokenRegistry.Token[] memory page1 = tokenRegistry.listTokens(0, 2);
        assertEq(page1.length, 2);
        assertEq(page1[0].name, "Token 0");
        assertEq(page1[1].name, "Token 1");

        vm.prank(tokentroller);
        TokenRegistry.Token[] memory page2 = tokenRegistry.listTokens(1, 2);
        assertEq(page2.length, 2);
        assertEq(page2[0].name, "Token 2");
        assertEq(page2[1].name, "Token 3");
    }

    function testGetLatestIndex() public {
        // Add multiple tokens
        for (uint256 i = 0; i < 3; i++) {
            vm.prank(tokentroller);
            tokenRegistry.addToken(
                string(abi.encodePacked("Token ", uintToStr(i))),
                "A sample token",
                "https://example.com/logo.png",
                string(abi.encodePacked("TK", uintToStr(i))),
                address(uint160(i + 10)),
                18
            );
        }

        vm.prank(tokentroller);
        uint256 latestIndex = tokenRegistry.getLatestIndex();
        assertEq(latestIndex, 3);
    }

    function uintToStr(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bstr[k] = bytes1(temp);
            _i /= 10;
        }
        return string(bstr);
    }
}
