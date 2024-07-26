// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {SantasList} from "../../src/SantasList.sol";
import {SantaToken} from "../../src/SantaToken.sol";
import {Test, console2} from "forge-std/Test.sol";
import {_CheatCodes} from "../mocks/CheatCodes.t.sol";

contract SantasListTest is Test {
    SantasList santasList;
    SantaToken santaToken;

    address user = makeAddr("user");
    address santa = makeAddr("santa");
    _CheatCodes cheatCodes = _CheatCodes(VM_ADDRESS);

    function setUp() public {
        vm.startPrank(santa);
        santasList = new SantasList();
        santaToken = SantaToken(santasList.getSantaToken());
        vm.stopPrank();
    }

    function testCheckList() public {
        vm.prank(santa);
        santasList.checkList(user, SantasList.Status.NICE);
        assertEq(uint256(santasList.getNaughtyOrNiceOnce(user)), uint256(SantasList.Status.NICE));
    }

    function testCheckListTwice() public {
        vm.startPrank(santa);
        santasList.checkList(user, SantasList.Status.NICE);
        santasList.checkTwice(user, SantasList.Status.NICE);
        vm.stopPrank();

        assertEq(uint256(santasList.getNaughtyOrNiceOnce(user)), uint256(SantasList.Status.NICE));
        assertEq(uint256(santasList.getNaughtyOrNiceTwice(user)), uint256(SantasList.Status.NICE));
    }

    function testCantCheckListTwiceWithDifferentThanOnce() public {
        vm.startPrank(santa);
        santasList.checkList(user, SantasList.Status.NICE);
        vm.expectRevert();
        santasList.checkTwice(user, SantasList.Status.NAUGHTY);
        vm.stopPrank();
    }

    function testCantCollectPresentBeforeChristmas() public {
        vm.expectRevert(SantasList.SantasList__NotChristmasYet.selector);
        santasList.collectPresent();
    }

    function testCantCollectPresentIfAlreadyCollected() public {
        vm.startPrank(santa);
        santasList.checkList(user, SantasList.Status.NICE);
        santasList.checkTwice(user, SantasList.Status.NICE);
        vm.stopPrank();

        vm.warp(santasList.CHRISTMAS_2023_BLOCK_TIME() + 1);

        vm.startPrank(user);
        santasList.collectPresent();
        vm.expectRevert(SantasList.SantasList__AlreadyCollected.selector);
        santasList.collectPresent();
    }

    function testCollectPresentNice() public {
        vm.startPrank(santa);
        santasList.checkList(user, SantasList.Status.NICE);
        santasList.checkTwice(user, SantasList.Status.NICE);
        vm.stopPrank();

        vm.warp(santasList.CHRISTMAS_2023_BLOCK_TIME() + 1);

        vm.startPrank(user);
        santasList.collectPresent();
        assertEq(santasList.balanceOf(user), 1);
        vm.stopPrank();
    }

    function testCollectPresentExtraNice() public {
        vm.startPrank(santa);
        santasList.checkList(user, SantasList.Status.EXTRA_NICE);
        santasList.checkTwice(user, SantasList.Status.EXTRA_NICE);
        vm.stopPrank();

        vm.warp(santasList.CHRISTMAS_2023_BLOCK_TIME() + 1);

        vm.startPrank(user);
        santasList.collectPresent();
        assertEq(santasList.balanceOf(user), 1);
        assertEq(santaToken.balanceOf(user), 1e18);
        vm.stopPrank();
    }

    function testCantCollectPresentUnlessAtLeastNice() public {
        vm.startPrank(santa);
        santasList.checkList(user, SantasList.Status.NAUGHTY);
        santasList.checkTwice(user, SantasList.Status.NAUGHTY);
        vm.stopPrank();

        vm.warp(santasList.CHRISTMAS_2023_BLOCK_TIME() + 1);

        vm.startPrank(user);
        vm.expectRevert();
        santasList.collectPresent();
    }

    function testBuyPresent() public {
        vm.startPrank(santa);
        santasList.checkList(user, SantasList.Status.EXTRA_NICE);
        santasList.checkTwice(user, SantasList.Status.EXTRA_NICE);
        vm.stopPrank();

        vm.warp(santasList.CHRISTMAS_2023_BLOCK_TIME() + 1);

        vm.startPrank(user);
        santaToken.approve(address(santasList), 1e18);
        santasList.collectPresent();
        santasList.buyPresent(user);
        assertEq(santasList.balanceOf(user), 2);
        assertEq(santaToken.balanceOf(user), 0);
        vm.stopPrank();
    }

    function testOnlyListCanMintTokens() public {
        vm.expectRevert();
        santaToken.mint(user);
    }

    function testOnlyListCanBurnTokens() public {
        vm.expectRevert();
        santaToken.burn(user);
    }

    function testTokenURI() public view {
        string memory tokenURI = santasList.tokenURI(0);
        assertEq(tokenURI, santasList.TOKEN_URI());
    }

    function testGetSantaToken() public view {
        assertEq(santasList.getSantaToken(), address(santaToken));
    }

    function testGetSanta() public view {
        assertEq(santasList.getSanta(), santa);
    }


    // malicious `transferFrom()` function

    function testMaliciousTransferFrom() external {
        vm.startPrank(santa);
        santasList.checkList(user, SantasList.Status.EXTRA_NICE);
        santasList.checkTwice(user, SantasList.Status.EXTRA_NICE);
        vm.stopPrank();

        vm.startPrank(user);
        vm.warp(1_703_500_000);
        santasList.collectPresent();
        vm.stopPrank();

        console2.log("Current SantaToken `user` Balance After Collecting Present: ", santaToken.balanceOf(user));
        assertEq(santaToken.balanceOf(user), 1e18);

        address maliciousActor = 0x815F577F1c1bcE213c012f166744937C889DAF17;
        vm.startPrank(maliciousActor);
        console2.log("MaliciousActor Comes in Tries to Call transferFrom() to Steal `user` balance.");
        santaToken.transferFrom(user, maliciousActor, 1e18);
        vm.stopPrank();

        console2.log("Current SantaToken `user` Balance After MaliciousActor Stole his/her Tokens: ", santaToken.balanceOf(user));
        console2.log("Current SantaToken `maliciousActor` Balance After Stealing it From `user` with transferFrom() function: ", santaToken.balanceOf(maliciousActor));
        assertEq(santaToken.balanceOf(user), 0);
        assertEq(santaToken.balanceOf(maliciousActor), 1e18);
    }

    // every Address is `NICE` by default.

    function testEveryAddressIsNiceByDefault() external {
        vm.prank(user);
        SantasList.Status checkOnceStatus = santasList.getNaughtyOrNiceOnce(user);
        SantasList.Status checkTwiceStatus = santasList.getNaughtyOrNiceTwice(user);

        console2.log("Check Once Status: ", uint256(checkOnceStatus));
        console2.log("Check Twice Status: ", uint256(checkTwiceStatus));
        assert(uint256(checkOnceStatus) == uint256(checkTwiceStatus));
    }

    // Anyone can call `checkList()` function to Set a Status for himself or Set Status For Others.

    function testAnyoneCanSetStatusForHimselfOrOthers() external {
        address user2 = makeAddr("user2");

        vm.prank(user);
        santasList.checkList(user, SantasList.Status.EXTRA_NICE);
        santasList.checkList(user2, SantasList.Status.NAUGHTY);

        SantasList.Status statusOfuser = santasList.getNaughtyOrNiceOnce(user);
        SantasList.Status statusOfuser2 = santasList.getNaughtyOrNiceOnce(user2);

        assert(uint256(statusOfuser) == 1);
        assert(uint256(statusOfuser2) == 2);
    }

    // `NICE` and `EXTRA_NICE` people can get infinite amount of NFT And SantaTokens.

    function testUserMintsHimselfUnlimitedAmountNFTandSantaTokens() external {
        address user2 = makeAddr("user2");

        vm.startPrank(santa);
        santasList.checkList(user, SantasList.Status.EXTRA_NICE);
        santasList.checkTwice(user, SantasList.Status.EXTRA_NICE);
        vm.stopPrank();

        vm.startPrank(user);
        vm.warp(1_703_500_000);

        for (uint i = 0; i < 4; i++) {
            santasList.collectPresent();
            santasList.safeTransferFrom(user, user2, i);
        }

        vm.stopPrank();

        assertEq(santasList.balanceOf(user2), 4);
        assertEq(santaToken.balanceOf(user), 4e18);
    }

    // if We Pass Someone Address that holds atleast 1e18 SantaToken's to `buyPresent()` function, it will burn the Given Address Tokens And msg.sender Gonna Receive the NFT.

    function testMaliciousActorBurnsSomeoneElseTokensToReceiveNFT() external {
        address maliciousActor = makeAddr("maliciousActor");

        vm.startPrank(santa);
        santasList.checkList(user, SantasList.Status.EXTRA_NICE);
        santasList.checkTwice(user, SantasList.Status.EXTRA_NICE);
        vm.stopPrank();

        vm.startPrank(user);
        vm.warp(1_703_500_000);
        santasList.collectPresent();
        vm.stopPrank();

        vm.startPrank(maliciousActor);
        santasList.buyPresent(user);
        vm.stopPrank();

        assertEq(santasList.balanceOf(maliciousActor), 1);
        assertEq(santaToken.balanceOf(user), 0);
    }

    // `NICE` and `EXTRA_NICE` can buy present with 1e18 SantaTokens.

    function testBuyPresentWith1e18() external {
        vm.startPrank(santa);
        santasList.checkList(user, SantasList.Status.EXTRA_NICE);
        santasList.checkTwice(user, SantasList.Status.EXTRA_NICE);
        vm.stopPrank();

        vm.startPrank(user);
        vm.warp(1_703_500_000);

        santasList.collectPresent();

        assertEq(santaToken.balanceOf(user), 1e18);
        console2.log("Current User Balance After Collecting Present: ", santaToken.balanceOf(user));

        santasList.buyPresent(user);

        console2.log("Current User Balance After Buying the Present: ", santaToken.balanceOf(user));
        assertEq(santaToken.balanceOf(user), 0);

        vm.stopPrank();
    }

    


    // function testPwned() public {
    //     string[] memory cmds = new string[](2);
    //     cmds[0] = "touch";
    //     cmds[1] = string.concat("youve-been-pwned");
    //     cheatCodes.ffi(cmds);
    // }
}
