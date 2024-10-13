module message_board_addr::SkillExchange {

    use aptos_framework::aptos_account;
    use std::vector;
    use std::signer;

    struct Agreement has store {
        learner: address,
        teacher: address,
        skill_amount: u64,
        learner_confirmed: bool,
        teacher_confirmed: bool,
    }

    struct AgreementStore has key {
        agreements: vector<Agreement>,
    }

    public fun init_account(account: &signer) {
        move_to(account, AgreementStore { agreements: vector::empty<Agreement>() });
    }

    public fun create_agreement(
        learner: &signer,
        teacher: address,
        skill_amount: u64
    ) acquires AgreementStore {
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

    public fun confirm_learner(learner: &signer, agreement_id: u64) acquires AgreementStore {
        let store = borrow_global_mut<AgreementStore>(signer::address_of(learner));
        let agreement = vector::borrow_mut(&mut store.agreements, agreement_id);

        assert!(agreement.learner == signer::address_of(learner), 100);
        agreement.learner_confirmed = true;

        let learner_confirmed = agreement.learner_confirmed;
        let teacher_confirmed = agreement.teacher_confirmed;
        let skill_amount = agreement.skill_amount;
        let teacher = agreement.teacher;

        // Drop the mutable borrow before proceeding with resource operations
        if (learner_confirmed && teacher_confirmed) {
            Self::check_completion(learner, teacher, skill_amount);
        }
    }

    public fun confirm_teacher(teacher: &signer, learner_addr: address, agreement_id: u64) acquires AgreementStore {
        let store = borrow_global_mut<AgreementStore>(learner_addr);
        let agreement = vector::borrow_mut(&mut store.agreements, agreement_id);

        assert!(agreement.teacher == signer::address_of(teacher), 101);
        agreement.teacher_confirmed = true;

        let learner_confirmed = agreement.learner_confirmed;
        let teacher_confirmed = agreement.teacher_confirmed;
        let skill_amount = agreement.skill_amount;

        // Drop the mutable borrow before proceeding with resource operations
        if (learner_confirmed && teacher_confirmed) {
            Self::check_completion(teacher, agreement.learner, skill_amount);
        }
    }

    fun check_completion(signer_ref: &signer, recipient: address, amount: u64) {
        aptos_account::transfer(signer_ref, recipient, amount);
    }
}
