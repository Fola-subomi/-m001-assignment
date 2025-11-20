// ============================================================================
// SIGNATURE-ONLY VAULT VALIDATOR WITH TESTS - Simple Signature Contract
// ============================================================================
// FIX APPLIED: Addressed Aiken warnings by simplifying 'when' and using '_' prefix.
// !!! CONTAINS AN INTENTIONAL SECURITY BUG !!!
// This causes TEST 2 to fail.
// ============================================================================

use aiken/collection/list
use cardano/transaction.{OutputReference, Transaction, placeholder}
use mocktail.{mock_utxo_ref}

// ----------------------------------------------------------------------------
// DATUM - Data stored with locked funds
// ----------------------------------------------------------------------------
pub type VestingDatum {
  beneficiary: ByteArray,
}

// ----------------------------------------------------------------------------
// REDEEMER - Action that can be taken
// ----------------------------------------------------------------------------
pub type VestingRedeemer {
  Unlock
}

// ----------------------------------------------------------------------------
// VALIDATOR - The security logic (Simplified with intentional bug)
// ----------------------------------------------------------------------------
validator vesting {
  spend(
    datum_opt: Option<VestingDatum>,
    redeemer: VestingRedeemer,
    _input: OutputReference,
    tx: Transaction,
  ) {
    // FIX: Using '_datum' to suppress the unused variable warning.
    expect Some(_datum) = datum_opt

    // FIX: Replacing 'when redeemer is { Unlock -> ... }' with direct 'let Unlock = redeemer'
    let Unlock = redeemer

    // The logic below still contains the bug that allows ANY signature
    // by only checking if the signature list is not empty.
    let any_signed = !list.is_empty(tx.extra_signatories)

    any_signed
  }

  else(_) {
    fail
  }
}

// ============================================================================
// TEST SUITE (Updated for Signature-Only Logic)
// ============================================================================

// ----------------------------------------------------------------------------
// HELPER FUNCTIONS FOR TESTS
// ----------------------------------------------------------------------------

fn sample_beneficiary() -> ByteArray {
  #"aa"
}

fn sample_intruder() -> ByteArray {
  #"cc"
}

fn sample_datum() -> VestingDatum {
  VestingDatum { beneficiary: sample_beneficiary() }
}

fn sample_transaction(signatories: List<ByteArray>) -> Transaction {
  Transaction { ..placeholder, extra_signatories: signatories }
}

// ----------------------------------------------------------------------------
// TEST 1: Happy Path - Beneficiary can unlock (PASSES)
// ----------------------------------------------------------------------------
test beneficiary_can_unlock_with_signature() {
  // SETUP
  let datum = Some(sample_datum())
  let redeemer = Unlock
  let tx = sample_transaction([sample_beneficiary()])
  let input = mock_utxo_ref(0, 0)

  // ACTION & ASSERT
  vesting.spend(datum, redeemer, input, tx)
}

// ----------------------------------------------------------------------------
// TEST 2: Intruder cannot unlock (!!! THIS TEST FAILS !!!)
// ----------------------------------------------------------------------------
test intruder_cannot_unlock() {
  // SETUP
  let datum = Some(sample_datum())
  let redeemer = Unlock
  // Intruder signs instead of the beneficiary
  let tx = sample_transaction([sample_intruder()])
  let input = mock_utxo_ref(0, 0)

  // ACTION & ASSERT
  // This assertion fails because the buggy validator returns TRUE for the intruder's signature.
  !vesting.spend(datum, redeemer, input, tx)
}

// ----------------------------------------------------------------------------
// TEST 3: No signature fails (PASSES)
// ----------------------------------------------------------------------------
test no_signature_fails() {
  // SETUP
  let datum = Some(sample_datum())
  let redeemer = Unlock
  let tx = sample_transaction([])
  let input = mock_utxo_ref(0, 0)

  // ACTION & ASSERT
  !vesting.spend(datum, redeemer, input, tx)
}

// ----------------------------------------------------------------------------
// TEST 4: Extra signatures are okay (PASSES)
// ----------------------------------------------------------------------------
test extra_signatures_are_okay() {
  // SETUP
  let datum = Some(sample_datum())
  let redeemer = Unlock
  let tx = sample_transaction([sample_beneficiary(), sample_intruder()])
  let input = mock_utxo_ref(0, 0)

  // ACTION & ASSERT
  vesting.spend(datum, redeemer, input, tx)
}
