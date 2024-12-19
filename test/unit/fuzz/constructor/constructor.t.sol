// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.25;

import { BaseTest } from "test/Base.t.sol";
import { LPOracle } from "src/LPOracle.sol";
import { Defaults } from "test/utils/Defaults.sol";

contract Constructor_Fuzz_Unit_Test is BaseTest {
    // Override and only deploy defaults contract
    function setUp() public override {
        defaults = new Defaults();
    }

    function testFuzz_ShouldRevert_Feed0DecimalsCallFails(address feed0) external {
        vm.expectRevert();
        new LPOracle(mocks.pool, address(helper), feed0, mocks.feed1);
    }

    function testFuzz_ShouldRevert_Feed1DecimalsCallFails(address feed1) external {
        vm.expectRevert();
        new LPOracle(mocks.pool, address(helper), mocks.feed0, feed1);
    }

    modifier whenFeedDecimalsCallSucceeds() {
        _;
    }

    function testFuzz_ShouldRevert_Feed0DecimalsGt18(
        address feed0,
        address feed1,
        uint8 decimal0,
        uint8 decimal1
    )
        external
        whenFeedDecimalsCallSucceeds
    {
        decimal0 = boundUint8(decimal0, 19, defaults.MAX_UINT8());
        decimal1 = boundUint8(decimal1, 0, 18);
        setFeedsAndDecimals(feed0, feed1, decimal0, decimal1);

        vm.expectRevert();
        new LPOracle(mocks.pool, address(helper), feed0, feed1);
    }

    function testFuzz_ShouldRevert_Feed1DecimalsGt18(
        address feed0,
        address feed1,
        uint8 decimal0,
        uint8 decimal1
    )
        external
        whenFeedDecimalsCallSucceeds
    {
        decimal0 = boundUint8(decimal0, 0, 18);
        decimal1 = boundUint8(decimal1, 19, defaults.MAX_UINT8());
        setFeedsAndDecimals(feed0, feed1, decimal0, decimal1);

        vm.expectRevert();
        new LPOracle(mocks.pool, address(helper), feed0, feed1);
    }

    modifier whenFeedDecimalsSupported() {
        _;
    }

    function testFuzz_ShouldRevert_Helper_TokensCallFails(
        address feed0,
        address feed1,
        uint8 decimal0,
        uint8 decimal1,
        address pool,
        address helper_
    )
        external
        whenFeedDecimalsCallSucceeds
        whenFeedDecimalsSupported
    {
        decimal0 = boundUint8(decimal0, 0, 18);
        decimal1 = boundUint8(decimal1, 0, 18);

        setFeedsAndDecimals(feed0, feed1, decimal0, decimal1);

        vm.expectRevert();
        new LPOracle(pool, helper_, feed0, feed1);
    }

    modifier givenWhenPoolHelperDeployedBySameFactory() {
        _;
    }

    modifier givenWhenPoolIsFinalized() {
        _;
    }

    modifier givenWhenTwoTokenPool() {
        _;
    }

    function testFuzz_Constructor(
        string memory feed0String,
        string memory feed1String,
        uint8 decimal0,
        uint8 decimal1,
        string memory poolString,
        string memory helperString,
        string memory token0String,
        string memory token1String
    )
        external
        whenFeedDecimalsCallSucceeds
        whenFeedDecimalsSupported
        givenWhenPoolHelperDeployedBySameFactory
        givenWhenPoolIsFinalized
        givenWhenTwoTokenPool
    {
        // Fuzz bounds
        decimal0 = boundUint8(decimal0, 0, 18);
        decimal1 = boundUint8(decimal1, 0, 18);

        // This method avoids address clashes
        address feed0 = makeAddr(string.concat("feed0", feed0String));
        address feed1 = makeAddr(string.concat("feed1", feed1String));
        address pool = makeAddr(string.concat("pool", poolString));
        address helper_ = makeAddr(string.concat("helper", helperString));
        address token0 = makeAddr(string.concat("token0", token0String));
        address token1 = makeAddr(string.concat("token1", token1String));

        // Mock calls required for success
        setFeedsAndDecimals(feed0, feed1, decimal0, decimal1);
        mock_helper_tokens(helper_, pool, token0, token1);
        mock_address_decimals(token0, 18);
        mock_address_decimals(token1, 18);

        // Deploy should succeed
        LPOracle oracle_ = new LPOracle(pool, helper_, feed0, feed1);

        // Assertions
        assertEq(oracle_.POOL(), pool, "POOL");
        assertEq(address(oracle_.HELPER()), helper_, "HELPER");
        assertEq(address(oracle_.TOKEN0()), token0, "TOKEN0");
        assertEq(address(oracle_.TOKEN1()), token1, "TOKEN1");
        assertEq(oracle_.TOKEN0_DECIMALS(), 18, "TOKEN0_DECIMALS");
        assertEq(oracle_.TOKEN1_DECIMALS(), 18, "TOKEN1_DECIMALS");
        assertEq(address(oracle_.FEED0()), feed0, "FEED0");
        assertEq(address(oracle_.FEED1()), feed1, "FEED1");
    }
}
