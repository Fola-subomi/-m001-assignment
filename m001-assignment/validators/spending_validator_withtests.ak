// ============================================================================
// COMBINED LOYALTY CONTRACT: SPENDING VALIDATOR & MINTING POLICY
// ============================================================================
// FIX APPLIED: Changed 'policy' keyword to 'validator ... using currency_symbol'
// for the minting script to comply with modern Aiken versions.
// ============================================================================

use aiken/collection/list
use cardano/script_context.{ScriptContext, Transaction, extra_signatories, currency_symbol}
use cardano/transaction.{OutputReference, placeholder}
use mocktail.{mock_utxo_ref}

// ----------------------------------------------------------------------------
// DATUM - Data for the Spending Validator (Vesting)
// ----------------------------------------------------------------------------
pub type VestingDatum {
  beneficiary: ByteArray,
}

// ----------------------------------------------------------------------------
// SPENDING REDEEMER - Action for the Spending Validator
// ----------------------------------------------------------------------------
pub type VestingRedeemer {
  Unlock
}

// ----------------------------------------------------------------------------
// 1. SPENDING VALIDATOR (The Vault)
// ----------------------------------------------------------------------------
validator vesting {
  spend(
    datum_opt: Option<VestingDatum>,
    _redeemer: VestingRedeemer,
    _input: OutputReference,
    tx: Transaction,
  ) {
    expect Some(datum) = datum_opt
    let beneficiary_signed = list.has(tx.extra_signatories, datum.beneficiary)
    
    // Only requirement: beneficiary must sign
    beneficiary_signed
  }

  else(_) {
    fail
  }
}

// ----------------------------------------------------------------------------
// MINTING REDEEMER - Action for the Minting Policy
// ----------------------------------------------------------------------------
pub type MintingRedeemer {
  Mint
}

// ----------------------------------------------------------------------------
// POLICY PARAMETERS - Parameter for the Minting Policy
// ----------------------------------------------------------------------------
pub type PolicyParams {
  beneficiary: ByteArray,
}

// ----------------------------------------------------------------------------
// 2. MINTING POLICY (The Token Controller) - CORRECTED SYNTAX
// ----------------------------------------------------------------------------
validator loyalty_minting(params: PolicyParams)
  using currency_symbol // This specifies the validator is a Minting Policy
{
  mint(_redeemer: MintingRedeemer, context: ScriptContext) {
    let tx: Transaction = context.transaction
    let beneficiary_key: ByteArray = params.beneficiary
    let signatories: List<ByteArray> = extra_signatories(tx)

    // Only requirement: beneficiary must sign
    list.has(signatories, beneficiary_key)
  }
}

// ============================================================================
// TEST SUITE - Helper Functions
// ============================================================================

fn sample_beneficiary() -> ByteArray {
  #"aa"
}

fn sample_intruder() -> ByteArray {
  #"cc"
}

// SPENDING VALIDATOR TEST HELPERS
fn sample_vesting_datum() -> VestingDatum {
  VestingDatum { beneficiary: sample_beneficiary() }
}

fn sample_spend_tx(signatories: List<ByteArray>) -> Transaction {
  Transaction { ..placeholder, extra_signatories: signatories }
}

// MINTING POLICY TEST HELPERS
fn sample_policy_params() -> PolicyParams {
  PolicyParams { beneficiary: sample_beneficiary() }
}

fn sample_context(signatories: List<ByteArray>) -> ScriptContext {
  let tx = Transaction {
    ..placeholder,
    extra_signatories: signatories,
  }
  ScriptContext {
    transaction: tx,
    purpose: cardano/script_context.Minting(currency_symbol(#"ab")),
  }
}

// ============================================================================
// TEST SUITE - SPENDING VALIDATOR TESTS
// ============================================================================

test spend_beneficiary_can_unlock() {
  let datum = Some(sample_vesting_datum())
  let redeemer = Unlock
  let tx = sample_spend_tx([sample_beneficiary()])
  let input = mock_utxo_ref(0, 0)
  vesting.spend(datum, redeemer, input, tx)
}

test spend_intruder_cannot_unlock() {
  let datum = Some(sample_vesting_datum())
  let redeemer = Unlock
  let tx = sample_spend_tx([sample_intruder()])
  let input = mock_utxo_ref(0, 0)
  !vesting.spend(datum, redeemer, input, tx)
}

// ============================================================================
// TEST SUITE - MINTING POLICY TESTS
// ============================================================================

test mint_beneficiary_can_mint() {
  let params = sample_policy_params()
  let redeemer = Mint
  let context = sample_context([sample_beneficiary()])
  loyalty_minting.mint(params, redeemer, context)
}

test mint_intruder_cannot_mint() {
  let params = sample_policy_params()
  let redeemer = Mint
  let context = sample_context([sample_intruder()])
  !loyalty_minting.mint(params, redeemer, context)
}