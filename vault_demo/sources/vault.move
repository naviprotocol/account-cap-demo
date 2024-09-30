module vault_demo::vault{

    use std::type_name::{Self, TypeName};

    use sui::coin::{Self, Coin, TreasuryCap};
    use sui::balance::{Self, Balance};
    use sui::clock::{Clock};
    use sui::table::{Self, Table};
    use sui::transfer::{Self};

    use lending_core::account::{AccountCap};
    use lending_core::lending;
    use lending_core::incentive::{Incentive as IncentiveV1};
    use lending_core::incentive_v2::{Self, Incentive};
    use lending_core::pool::{Pool};
    use lending_core::storage::{Storage};
    use lending_core::version;
    use lending_core::logic;

    use oracle::oracle::{PriceOracle};
    

    public struct Vault has key, store {
        id: UID,
        account_cap: AccountCap,
        sui_index: u8,
        usdc_index: u8
    }

    public fun get_version(): u64 {
        version::this_version()
    }

    fun init(
        ctx: &mut TxContext
    ) {
        let vault = Vault {
            id: object::new(ctx),
            account_cap: lending::create_account(ctx),
            sui_index: 0,
            usdc_index: 1
        };
        transfer::public_share_object(vault);

    }

    public fun deposit<A> (
        vault: &Vault,
        deposit_coin: Coin<A>,
        storage: &mut Storage,
        pool_a: &mut Pool<A>,
        inc_v1: &mut IncentiveV1,
        inc_v2: &mut Incentive,
        clock: &Clock
    ) {

        lending_core::incentive_v2::deposit_with_account_cap(clock, storage, pool_a, vault.sui_index, deposit_coin, inc_v1, inc_v2, &vault.account_cap)
    }

    public fun withdraw<A> (
        vault: &Vault,
        sui_withdraw_amount: u64,
        storage: &mut Storage,
        pool_a: &mut Pool<A>,
        inc_v1: &mut IncentiveV1,
        inc_v2: &mut Incentive,
        clock: &Clock,
        oracle: &PriceOracle,
        ctx: &mut TxContext
    ): Coin<A> {

        let withdrawn_balance = lending_core::incentive_v2::withdraw_with_account_cap(clock, oracle, storage, pool_a, vault.sui_index, sui_withdraw_amount, inc_v1, inc_v2, &vault.account_cap);
        coin::from_balance(withdrawn_balance, ctx)
    }

    public fun info<A>(vault: &Vault, pool_a: &Pool<A>, storage: &mut Storage): u64 {
        let deposited_balance = logic::user_collateral_balance(storage, vault.sui_index, vault.account_cap.account_owner());
    
        pool_a.unnormal_amount(deposited_balance as u64)
    }

}