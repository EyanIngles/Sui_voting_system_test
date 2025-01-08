module flashloan::test {
    // this is use to test small quick ideas.

    public struct Test_ctx_epoch_time has key, store{
        id: UID,
        epoch_value: u64
    }
    #[allow(lint(self_transfer))]
    public fun test(ctx: &mut TxContext) {
        let recipient = tx_context::sender(ctx);
        let epoch_value = ctx.epoch_timestamp_ms();
        let start_test = Test_ctx_epoch_time {
            id: object::new(ctx),
            epoch_value 
        };
        transfer::public_transfer(start_test, recipient);
    }
}