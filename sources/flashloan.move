/// Module: flashloan

module flashloan::flashloan_token_swap{
    use sui::sui::SUI;
    use sui::coin::{Self, Coin};
    use sui::balance::{Self, Balance};

    //errors
    const ELoanAmountExceedPool: u64 = 0;
    const ERepayAmountInvalid: u64 = 1;

    // struct for loanPool
    public struct LoanPool has key {
        id: UID,
        amount: Balance<SUI>,
    }
    // struct for loan (the hot potato)
    public struct Loan {
        amount: u64,
    }

    // borrow flashloan
    public fun borrow(pool: &mut LoanPool, amount: u64, ctx: &mut TxContext): (Coin<SUI>, Loan) {
        assert!(amount <= balance::value(&pool.amount), ELoanAmountExceedPool);

        (   
            coin::from_balance(balance::split(&mut pool.amount, amount), ctx),
            Loan {
               amount
            }
        )
    }

    //repaying the loan function.
    public fun repay(pool: &mut LoanPool, loan: Loan, payment: Coin<SUI>) {
        let Loan { amount } = loan;
        assert!(coin::value(&payment) == amount, ERepayAmountInvalid);

        balance::join(&mut pool.amount, coin::into_balance(payment));
    }

    public fun borrow_and_repay_loan(pool: &mut LoanPool, amount_to_borrow: u64, ctx: &mut TxContext) {
        // call borrow
        let (coin, loan) = borrow(pool, amount_to_borrow, ctx);
        repay(pool, loan, coin);
        //call repay loan.
    }

}
