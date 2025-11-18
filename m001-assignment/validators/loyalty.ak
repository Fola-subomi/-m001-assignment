// ============================================================================
// SIGNATURE-ONLY VAULT VALIDATOR WITH TESTS - Simple Signature Contract
// ============================================================================
// This validator locks funds and allows a specific beneficiary to claim them
// immediately, provided they sign the transaction. The time-lock feature
// has been removed to resolve the dependency error.
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

// The 'unlock_time' is removed since the time dependency is gone.

// ----------------------------------------------------------------------------
// REDEEMER - Action that can be taken
// ----------------------------------------------------------------------------
pub type VestingRedeemer {
  Unlock
}

// ----------------------------------------------------------------------------
// VALIDATOR - The security logic (Simplified)
// ----------------------------------------------------------------------------
validator vesting {
  spend(
    datum_opt: Option<VestingDatum>,
    redeemer: VestingRedeemer,
    _input: OutputReference,
    tx: Transaction,
  ) {
    expect Some(datum) = datum_opt

    when redeemer is {
      Unlock -> {
        let beneficiary_signed =
          list.has(tx.extra_signatories, datum.beneficiary)

        // The only condition is that the transaction must be signed by the beneficiary.
        beneficiary_signed
      }
    }
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

// The 'unlock_time' field is removed from the datum.
fn sample_datum() -> VestingDatum {
  VestingDatum { beneficiary: sample_beneficiary() }
}

// The 'from_time' argument is removed from the transaction helper.
fn sample_transaction(signatories: List<ByteArray>) -> Transaction {
  Transaction { ..placeholder, extra_signatories: signatories }
}

// ----------------------------------------------------------------------------
// TEST 1: Happy Path - Beneficiary can unlock (Time is no longer a factor)
// ----------------------------------------------------------------------------
test beneficiary_can_unlock_with_signature() {
  // SETUP
  let datum = Some(sample_datum())
  let redeemer = Unlock
  // Only the beneficiary signs
  let tx = sample_transaction([sample_beneficiary()])
  let input = mock_utxo_ref(0, 0)

  // ACTION & ASSERT
  // Should succeed because the beneficiary signed.
  vesting.spend(datum, redeemer, input, tx)
}

// ----------------------------------------------------------------------------
// TEST 2: Intruder cannot unlock
// ----------------------------------------------------------------------------
test intruder_cannot_unlock() {
  // SETUP
  let datum = Some(sample_datum())
  let redeemer = Unlock
  // Intruder signs instead of the beneficiary
  let tx = sample_transaction([sample_intruder()])
  let input = mock_utxo_ref(0, 0)

  // ACTION & ASSERT
  // Should fail because the beneficiary did not sign.
  !vesting.spend(datum, redeemer, input, tx)
}

// ----------------------------------------------------------------------------
// TEST 3: No signature fails
// ----------------------------------------------------------------------------
test no_signature_fails() {
  // SETUP
  let datum = Some(sample_datum())
  let redeemer = Unlock
  // No one signs
  let tx = sample_transaction([])
  let input = mock_utxo_ref(0, 0)

  // ACTION & ASSERT
  // Should fail because a signature is required.
  !vesting.spend(datum, redeemer, input, tx)
}

// ----------------------------------------------------------------------------
// TEST 4: Extra signatures are okay
// ----------------------------------------------------------------------------
test extra_signatures_are_okay() {
  // SETUP
  let datum = Some(sample_datum())
  let redeemer = Unlock
  // Beneficiary AND an intruder sign
  let tx = sample_transaction([sample_beneficiary(), sample_intruder()])
  let input = mock_utxo_ref(0, 0)

  // ACTION & ASSERT
  // Should succeed because the required signature (beneficiary) is present.
  vesting.spend(datum, redeemer, input, tx)
}
