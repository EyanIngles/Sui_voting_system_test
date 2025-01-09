module flashloan::test {
    // this is use to test small quick ideas.
    use sui::table;
    use sui::sui::{SUI};
    use sui::coin::{Coin, Self};
    use sui::balance::{Balance, Self};



    public struct Test_share has key, store{
        id: UID,
        coin: table::Table<u64, Coin_storage>
    }
    public struct Coin_storage has store {
        balance: Balance<SUI>
    }

    fun init(ctx: &mut TxContext) {
        let test_shared_object = Test_share {
            id: object::new(ctx),
            coin: table::new(ctx)
        };
        transfer::public_share_object(test_shared_object);
    }

    public fun create_balance(storage: &mut Test_share, coin: &mut Coin<SUI>, amount: u64, ctx: &mut TxContext){
        let coin_amount = coin::split(coin, amount, ctx);
        let balance_amount = coin::into_balance(coin_amount);
        let mut coin_storage = Coin_storage {
            balance: balance::zero()
        };
        balance::join(&mut coin_storage.balance, balance_amount);
        table::add(&mut storage.coin, 1, coin_storage);
    }

    public fun pull_balance_out(storage: &mut Test_share, coin: &mut Coin<SUI>, ctx: &mut TxContext) {
        let table = table::borrow_mut(&mut storage.coin, 1);
        let balance = balance::withdraw_all(&mut table.balance);
        let coin_balance = balance.into_coin(ctx);
        coin::join(coin, coin_balance);
    }

}