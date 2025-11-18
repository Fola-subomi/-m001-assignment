use aiken/collection/list
use cardano/transaction.{OutputReference, Transaction}

// ============================================================================
// DATUM
// ============================================================================
pub type LoyaltyDatum {
  customer: ByteArray,
  merchant: ByteArray,
  token_amount: Int,
  redeemed: Bool,
}

// ============================================================================
// REDEEMER
// ============================================================================
pub type LoyaltyRedeemer {
  Redeem
  Revoke
}

// ============================================================================
// VALIDATOR
// ============================================================================
validator loyalty {
  spend(
    datum_opt: Option<LoyaltyDatum>,
    redeemer: LoyaltyRedeemer,
    _input: OutputReference,
    tx: Transaction,
  ) {
    expect Some(datum) = datum_opt

    let signatories = tx.extra_signatories

    when redeemer is {
      Redeem ->
        trace("Attempting Redeem...")
        trace("Checking customer signature...")
        list.has(signatories, datum.customer)

      Revoke ->
        trace("Attempting Revoke...")
        trace("Checking merchant signature...")
        list.has(signatories, datum.merchant)
    }
  }

  else(failed) {
    trace("Validator failed")
    fail
  }
}

// ============================================================================
// TEST SUITE
// ============================================================================

// ----------------------------------------------------------------------------
// HELPER FUNCTIONS FOR TESTS
// ----------------------------------------------------------------------------

// Sample keys
fn sample_customer() -> ByteArray {
  #"aa"
}

fn sample_merchant() -> ByteArray {
  #"bb"
}

fn sample_intruder() -> ByteArray {
  #"cc"
}

// Datum constructor
fn sample_datum() -> LoyaltyDatum {
  LoyaltyDatum {
    customer: sample_customer(),
    merchant: sample_merchant(),
    token_amount: 500,
    redeemed: False,
  }
}

// Transaction helper
fn sample_transaction(signatories: List<ByteArray>) -> Transaction {
  Transaction {
    ..placeholder,
    extra_signatories: signatories
  }
}

// Mock UTXO reference
fn mock_utxo_ref(tx_id: Int, index: Int) -> OutputReference {
  OutputReference {
    transaction_id: #[tx_id],
    output_index: index,
  }
}

// ============================================================================
// MINIMAL TEST SUITE (3 TESTS TOTAL)
// ============================================================================

// ----------------------------------------------------------------------------
// REDEEM SUCCESS (Customer)
// ----------------------------------------------------------------------------
test redeem_success_customer() {
  let datum = Some(sample_datum())
  let redeemer = Redeem
  let tx = sample_transaction([sample_customer()])
  let input = mock_utxo_ref(0, 0)

  // Should pass: customer signs Redeem
  loyalty.spend(datum, redeemer, input, tx)
}

// ----------------------------------------------------------------------------
// REVOKE SUCCESS (Merchant)
// ----------------------------------------------------------------------------
test revoke_success_merchant() {
  let datum = Some(sample_datum())
  let redeemer = Revoke
  let tx = sample_transaction([sample_merchant()])
  let input = mock_utxo_ref(0, 0)

  // Should pass: merchant signs Revoke
  loyalty.spend(datum, redeemer, input, tx)
}

// ----------------------------------------------------------------------------
// FAILURE TEST (Intruder attempts Redeem)
// ----------------------------------------------------------------------------
test failure_intruder_redeem() {
  let datum = Some(sample_datum())
  let redeemer = Redeem
  let tx = sample_transaction([sample_intruder()])
  let input = mock_utxo_ref(0, 0)

  // Should fail: intruder is not authorized
  !loyalty.spend(datum, redeemer, input, tx)
}
