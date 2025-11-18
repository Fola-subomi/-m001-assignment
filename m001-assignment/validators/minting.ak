// ============================================================================
// STANDALONE LOYALTY MINTING POLICY
// ============================================================================
// This policy controls the issuance (minting) and destruction (burning)
// of custom loyalty tokens. It requires a specific beneficiary's signature
// for any operation.
//
// Filename Suggestion: loyalty_minting.ak
// ============================================================================

use aiken/collection/list
use cardano/script_context.{ScriptContext, Transaction, extra_signatories, currency_symbol}
use mocktail.{mock_utxo_ref}

// ----------------------------------------------------------------------------
// REDEEMER - Action that can be taken
// ----------------------------------------------------------------------------
// Minting redeemers usually act as a simple trigger.
pub type MintingRedeemer {
  Mint
}

// ----------------------------------------------------------------------------
// POLICY PARAMETERS - The required signature (The Beneficiary Key)
// ----------------------------------------------------------------------------
// This public key is fixed when the policy is deployed/built.
pub type PolicyParams {
  beneficiary: ByteArray,
}

// ----------------------------------------------------------------------------
// VALIDATOR - The Security Logic
// ----------------------------------------------------------------------------
validator loyalty_minting(params: PolicyParams)
  // Required clause for all Minting Scripts in modern Aiken
  using currency_symbol 
{
  mint(_redeemer: MintingRedeemer, context: ScriptContext) {
    let tx: Transaction = context.transaction
    let beneficiary_key: ByteArray = params.beneficiary
    let signatories: List<ByteArray> = extra_signatories(tx)

    // Security check: The transaction must be signed by the beneficiary.
    list.has(signatories, beneficiary_key)
  }
}

// ============================================================================
// TEST SUITE
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

// The parameters are the required signature key
fn sample_policy_params() -> PolicyParams {
  PolicyParams { beneficiary: sample_beneficiary() }
}

// Create a mock context with specified signatories
fn sample_context(signatories: List<ByteArray>) -> ScriptContext {
  let tx = Transaction {
    ..cardano/transaction.placeholder,
    extra_signatories: signatories,
  }
  ScriptContext {
    transaction: tx,
    purpose: cardano/script_context.Minting(currency_symbol(#"ab")),
  }
}

// ----------------------------------------------------------------------------
// TEST 1: Happy Path - Beneficiary can mint
// ----------------------------------------------------------------------------
test mint_beneficiary_can_mint() {
  // SETUP
  let params = sample_policy_params()
  let redeemer = Mint
  let context = sample_context([sample_beneficiary()])

  // ACTION & ASSERT
  loyalty_minting.mint(params, redeemer, context)
}

// ----------------------------------------------------------------------------
// TEST 2: Intruder cannot mint
// ----------------------------------------------------------------------------
test mint_intruder_cannot_mint() {
  // SETUP
  let params = sample_policy_params()
  let redeemer = Mint
  let context = sample_context([sample_intruder()])

  // ACTION & ASSERT
  !loyalty_minting.mint(params, redeemer, context)
}

// ----------------------------------------------------------------------------
// TEST 3: No signature fails
// ----------------------------------------------------------------------------
test mint_no_signature_fails() {
  // SETUP
  let params = sample_policy_params()
  let redeemer = Mint
  let context = sample_context([])

  // ACTION & ASSERT
  !loyalty_minting.mint(params, redeemer, context)
}

// ----------------------------------------------------------------------------
// TEST 4: Extra signatures are okay
// ----------------------------------------------------------------------------
test mint_extra_signatures_are_okay() {
  // SETUP
  let params = sample_policy_params()
  let redeemer = Mint
  let context = sample_context([sample_beneficiary(), sample_intruder()])

  // ACTION & ASSERT
  loyalty_minting.mint(params, redeemer, context)
}