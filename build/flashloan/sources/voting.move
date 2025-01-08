module flashloan::voting {
    //use sui::coin::{Self, Coin};
    //use sui::balance::{Self, Balance};
    //use sui::clock::{Self};
    use sui::table;

    //errors:
    const PROPOSAL_NOW_INVALID: u64 = 1;
    const PROPOSAL_EXISTING_IS_NOT_FINALISED: u64 = 2;
    const PROPOSAL_TIME_COMPLETE: u64 = 3;

    //constants
    const ONE_HOUR_EPOCH_VALUE: u64 = 3600000;

    //public struct Proposal_status 
    // should we do an account value to check and see if there is one token or two token to see
    // if something exists or not.????
    
    // proposal that is created for a voting system to begin.
    public struct Proposal_for_voting has key, store { 
        // should have a few fields for descriptions
        id: UID,
        amount: u64, 
        current_time: u64, 
        end_time: u64, 
        still_active : bool,
        votes_yes: u64,
        votes_no: u64
    }

    // a tracker that the proposal is then attached too, this will be its own object
    // that stores the current proposal voting system.
    public struct Proposal_tracker has key, store {
        id: UID,
        existing_proposal: bool,
        current_proposal: table::Table<u64, Proposal_for_voting>
    }

    //public struct Transaction_voted_fail has key { // not sure if we need to have a fail or pass struct.
    //    id: UID,
    //    vote_failed: bool,
    //    time: u64,
    //    votes_yes: u64,
    //    votes_no: u64
    //}

    // init function that will be executed upon publishing.
    // This function will create a tracker and will only be able to create one which will be publicly shared.
    fun init(ctx: &mut TxContext){
        let tracker = Proposal_tracker {
            id: object::new(ctx),
            existing_proposal: false,
            current_proposal: table::new(ctx)
        };
        transfer::public_share_object(tracker);
    }

    // this is to create a new voting proposal for token holders to then vote what to do.
    public fun start_new_vote(tracker: &mut Proposal_tracker, proposed_transfer_amount: u64, end_time_in_hours: u64, ctx: &mut TxContext) {
        let is_existing = tracker.existing_proposal;
        if(is_existing == true) {
            abort(PROPOSAL_EXISTING_IS_NOT_FINALISED)
        };
        let current_time = ctx.epoch_timestamp_ms();
        let new_epoch_value = end_time_in_hours * ONE_HOUR_EPOCH_VALUE;
        let end_time = current_time + new_epoch_value;
        let proposal = Proposal_for_voting {
            id: object::new(ctx),
            amount: proposed_transfer_amount,
            current_time, 
            end_time,  
            still_active : true,
            votes_yes: 0,
            votes_no: 0
        };
        table::add(&mut tracker.current_proposal, 1, proposal);
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
        // assert! that the sender has tokens in their account. 
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
            abort(PROPOSAL_TIME_COMPLETE)
        };
        // assert! that the sender has tokens in their account. 
        let original_amount = table.votes_no;
        table.votes_no = original_amount + amount_of_votes;
    }

                                                    /// Helpers:
    // check to see if proposal is still active
    public fun check_if_active(proposal: &Proposal_for_voting):bool {
        let is_active = proposal.still_active;
        return is_active
    }

    // update the proposal time and ensuring that voters cant vote even after the time.
    fun update_proposal_time(tracker: &mut Proposal_tracker, ctx: &TxContext) {
        let update_time = ctx.epoch_timestamp_ms();
        let table = table::borrow_mut(&mut tracker.current_proposal, 1);
        table.current_time = update_time;
    }

    /// testing functions: soul purpose is for testing these operation of the smart contract.
    /// changes the propsal to false in the still_active param.
    public fun change_proposal_to_false(proposal: &mut Proposal_for_voting, _ctx: &mut TxContext) {
        proposal.still_active = false;
    }


}