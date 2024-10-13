module message_board_addr::SkillExchange {

    use aptos_framework::coin as Coin;
    use std::vector;
    use std::signer;

    // Struct to hold agreement details
    struct Agreement has store {
        learner: address,
        teacher: address,
        skill_amount: u64,
        learner_confirmed: bool,
        teacher_confirmed: bool,
    }

    // Define AgreementStore as a resource
    struct AgreementStore has key {
        agreements: vector<Agreement>,
    }

    // Initialize the AgreementStore for the first time
    public fun init_account(account: &signer) {
        move_to(account, AgreementStore { agreements: vector::empty<Agreement>() });
    }

    // Create a new skill exchange agreement
    public fun create_agreement(
        learner: &signer,
        teacher: address,
        skill_amount: u64
    ) {
        let agreement = Agreement {
            learner: signer::address_of(learner),
            teacher,
            skill_amount,
            learner_confirmed: false,
            teacher_confirmed: false,
        };
        let store = borrow_global_mut<AgreementStore>(signer::address_of(learner));
        vector::push_back(&mut store.agreements, agreement);
    }

    // Learner confirms skill received
    public fun confirm_learner(learner: &signer, agreement_id: u64) {
        let store = borrow_global_mut<AgreementStore>(signer::address_of(learner));
        let agreement = vector::borrow_mut(&mut store.agreements, agreement_id);
        assert!(agreement.learner == signer::address_of(learner), 100);
        agreement.learner_confirmed = true;
        Self::check_completion(agreement);
    }

    // Teacher confirms skill shared
    public fun confirm_teacher(teacher: &signer, learner_addr: address, agreement_id: u64) {
        let store = borrow_global_mut<AgreementStore>(learner_addr);
        let agreement = vector::borrow_mut(&mut store.agreements, agreement_id);
        assert!(agreement.teacher == signer::address_of(teacher), 101);
        agreement.teacher_confirmed = true;
        Self::check_completion(agreement);
    }

    // Internal function to check if both parties have confirmed the exchange
    fun check_completion(agreement: &mut Agreement) {
        if (agreement.learner_confirmed && agreement.teacher_confirmed) {
            Coin::transfer(
                &agreement.learner,
                &agreement.teacher,
                agreement.skill_amount
            );
        }
    }
}


