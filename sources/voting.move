module flashloan::voting {
    use sui::coin::{Self, Coin};
    use sui::balance::{Self, Balance};
    use sui::sui::{SUI};
    use sui::table;

    //errors:
    const PROPOSAL_NOW_INVALID: u64 = 1;
    const PROPOSAL_EXISTING_IS_NOT_FINALISED: u64 = 2;
    const PROPOSAL_EXISTING_IS_NOT_FINALISED_NEED_TO_FINALISE_FIRST: u64 = 3;
    const PROPOSAL_TIME_COMPLETE: u64 = 4;

    //constants
    const ADDRESS_ZERO: address = @0x00;
    const ONE_HOUR_EPOCH_VALUE: u64 = 3600000;
    
    // proposal that is created for a voting system to begin.
    public struct Proposal_for_voting has key, store { 
        // should have a few fields for descriptions??
        id: UID, // we keep the key for transparency // maybe not
        amount: Balance<SUI>, // amount requesting to take out. maybe this should be balance or coin instead of amount showing that the true value is being controlled by smart contract.
        destination: address, // address that the money is going to be transferred too.
        current_time: u64, // this is to keep track of the time and how much longer till end time.
        end_time: u64,  // past this time, no one can vote and the proposal will be closed.
        still_active : bool, // checking to see if this proposal is active still.
        votes_yes: u64, // the amount yes votes token holders have voted yes for.
        votes_no: u64 // the opposite but no votes.
    }

    // a tracker that the proposal is then attached too, this will be its own object
    // that stores the current proposal voting system.
    public struct Proposal_tracker has key, store {
        id: UID,
        existing_proposal: bool,
        current_proposal: table::Table<u64, Proposal_for_voting>,
        last_proposal_decision: bool
    }

    // init function that will be executed upon publishing.
    // This function will create a tracker and will only be able to create one which will be publicly shared.
    fun init(ctx: &mut TxContext){
        let mut tracker = Proposal_tracker {
            id: object::new(ctx),
            existing_proposal: false,
            current_proposal: table::new(ctx),
            last_proposal_decision: false
        };
        let proposal = Proposal_for_voting {
            id: object::new(ctx),
            amount: balance::zero(),
            destination: ADDRESS_ZERO,
            current_time: 0, 
            end_time: 0,  
            still_active : false,
            votes_yes: 0,
            votes_no: 0
        };
        table::add(&mut tracker.current_proposal, 1, proposal);
        transfer::public_share_object(tracker);
    }

    // this is to create a new voting proposal for token holders to then vote what to do.
    public fun start_new_vote(tracker: &mut Proposal_tracker, coin: &mut Coin<SUI>, proposed_transfer_amount: u64, sending_too: address, end_time_in_hours: u64, ctx: &mut TxContext) {
        if(tracker.existing_proposal == true) {
            abort(PROPOSAL_EXISTING_IS_NOT_FINALISED)
        };
        let table = table::borrow(&tracker.current_proposal, 1);
        if(table.current_time != 0) {
            abort(PROPOSAL_EXISTING_IS_NOT_FINALISED_NEED_TO_FINALISE_FIRST)
        };
        let current_time = ctx.epoch_timestamp_ms();
        let new_epoch_value = end_time_in_hours * ONE_HOUR_EPOCH_VALUE;
        let end_time = current_time + new_epoch_value;
        let coin_to_balance = coin::split(coin, proposed_transfer_amount, ctx);
        let balance = coin::into_balance(coin_to_balance);
        // change the voting struct not create a new one.
        let table = table::borrow_mut(&mut tracker.current_proposal, 1);
        table.current_time = current_time;
        table.end_time = end_time;
        table.still_active = true;
        table.destination = sending_too;
        balance::join(&mut table.amount, balance);
        tracker.existing_proposal = true;
    }

    // vote yes function with Params:
    /// amount_of_votes: the amount of votes you want to use for this call.
    /// proposal: the proposal that you are voting for, will only be one available to vote for at a time.
    public fun vote_yes(amount_of_votes: u64, tracker: &mut Proposal_tracker, ctx: &mut TxContext) { //may need coins in param.
        let checker = table::borrow(&tracker.current_proposal, 1);
        if(checker.still_active == false) {
            abort(PROPOSAL_NOW_INVALID)
        };
        update_proposal_time(tracker, ctx);
        let table = table::borrow_mut(&mut tracker.current_proposal, 1);
        if(table.current_time >= table.end_time) {
            abort(PROPOSAL_TIME_COMPLETE)
        };
        let original_amount = table.votes_yes;
        table.votes_yes = original_amount + amount_of_votes;
    }

    public fun vote_no(amount_of_votes: u64, tracker: &mut Proposal_tracker, ctx: &mut TxContext) { //may need coins in param.
        let checker = table::borrow(&tracker.current_proposal, 1);
        if(checker.still_active == false) {
            abort(PROPOSAL_NOW_INVALID)
        };
        update_proposal_time(tracker, ctx);
        let table = table::borrow_mut(&mut tracker.current_proposal, 1);
        if(table.current_time >= table.end_time) {

            let no_votes = table.votes_no;
            let yes_votes = table.votes_yes;
            let final_decision = calculate_final_decision(yes_votes, no_votes, ctx);
            complete_proposal(final_decision, tracker, ctx);
            return
        };
        let original_amount = table.votes_no;
        table.votes_no = original_amount + amount_of_votes;
    }

                                                    /// Helpers:
    // check to see if proposal is still active
    public fun check_if_active(tracker: &Proposal_tracker):bool {
        let table = table::borrow(&tracker.current_proposal, 1);
        let is_active = table.still_active;
        return is_active
    }
    public fun check_last_proposal_decision(tracker: &Proposal_tracker):bool {
        let last_decision = tracker.last_proposal_decision;
        return last_decision
    }
                                                    ///Updaters:
    // update the proposal time and ensuring that voters cant vote even after the time.
    fun update_proposal_time(tracker: &mut Proposal_tracker, ctx: &TxContext) {
        let update_time = ctx.epoch_timestamp_ms();
        let table = table::borrow_mut(&mut tracker.current_proposal, 1);
        table.current_time = update_time;
    }
    fun complete_proposal(final_decision: bool, tracker: &mut Proposal_tracker, ctx: &mut TxContext) {
        tracker.last_proposal_decision = final_decision;
        tracker.existing_proposal = false;
        if(final_decision == false) {
            // should return the funds to the original sender? which could be a treasury or something else and then re-do the proposal?
            reset_proposal(tracker);
            return // returns without drawing or transferring the Coins
        };
        withdraw_funds(tracker, ctx);
        reset_proposal(tracker);
    }
    fun withdraw_funds(tracker: &mut Proposal_tracker, ctx: &mut TxContext) {
        let table = table::borrow_mut(&mut tracker.current_proposal, 1);
        let proposed_amount = balance::withdraw_all(&mut table.amount); 
        let coin_amount = proposed_amount.into_coin(ctx);
        // complete the transfer
        let destination = table.destination; 
        transfer::public_transfer(coin_amount, destination);
    }
    fun reset_proposal(tracker: &mut Proposal_tracker) {
        let table = table::borrow_mut(&mut tracker.current_proposal, 1);
        table.current_time = 0;
        table.end_time = 0;
        table.destination = ADDRESS_ZERO;
        table.still_active = false;
        table.votes_no = 0;
        table.votes_yes = 0;
    }

    fun calculate_final_decision(yes_votes: u64, no_votes: u64, _ctx: &mut TxContext):bool {
        let mut final_decision= true;
        if(yes_votes < no_votes) {
            final_decision = false
        };
        return final_decision
    }

    /// testing functions: soul purpose is for testing these operation of the smart contract.
    /// changes the propsal to false in the still_active param.
    public fun change_proposal_to_false(proposal: &mut Proposal_for_voting, _ctx: &mut TxContext) {
        proposal.still_active = false;
    }

    public fun test_update_proposal_time(tracker: &mut Proposal_tracker, ctx: &TxContext) {
        let update_time = ctx.epoch_timestamp_ms();
        let table = table::borrow_mut(&mut tracker.current_proposal, 1);
        table.current_time = update_time;
    }
    public fun test_complete_proposal(final_decision: bool, tracker: &mut Proposal_tracker, _ctx: &mut TxContext) {
        // check the time and ensuring its over,
        tracker.last_proposal_decision = final_decision;
        tracker.existing_proposal = false;
    }

    public fun test_calculate_final_decision(yes_votes: u64, no_votes: u64, _ctx: &mut TxContext):bool {
        let mut final_decision= true;
        if(yes_votes < no_votes) {
            final_decision = false
        };
        return final_decision
    }
    

}