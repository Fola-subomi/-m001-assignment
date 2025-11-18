use aiken/collection/list
use cardano/transaction.{Mint, OutputReference, Transaction}

// ============================================================================
// SHARED DATUM
// ============================================================================
pub type LoyaltyDatum {
  customer: ByteArray,
  merchant: ByteArray,
  token_amount: Int,
  redeemed: Bool,
}

// ============================================================================
// SPENDING REDEEMER
// ============================================================================
pub type LoyaltyRedeemer {
  Redeem
  Revoke
}

// ============================================================================
// SPENDING VALIDATOR
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
      Redeem -> {
        trace @"Redeem path"
        expect list.has(signatories, datum.customer)
        True
      }

      Revoke -> {
        trace @"Revoke path"
        expect list.has(signatories, datum.merchant)
        True
      }
    }
  }

  else(_) {
    trace @"Loyalty spending validation failed"
    fail
  }
}

// ============================================================================
// MINTING VALIDATOR
// ============================================================================
validator loyalty_mint {
  mint(redeemer: LoyaltyDatum, mint_val: Mint, tx: Transaction) {
    let signatories = tx.extra_signatories

    trace @"Mint path"
    expect list.has(signatories, redeemer.merchant)

    let minted_amount = mint_val.value
    expect minted_amount == redeemer.token_amount

    True
  }

  else(_) {
    trace @"Loyalty minting validation failed"
    fail
  }
}

// ============================================================================
// TEST HELPERS
// ============================================================================
fn sample_customer() -> ByteArray {
  #"aa"
}

fn sample_merchant() -> ByteArray {
  #"bb"
}

fn sample_intruder() -> ByteArray {
  #"cc"
}

fn sample_datum() -> LoyaltyDatum {
  LoyaltyDatum {
    customer: sample_customer(),
    merchant: sample_merchant(),
    token_amount: 500,
    redeemed: False,
  }
}

fn sample_transaction(signatories: List<ByteArray>) -> Transaction {
  Transaction { ..placeholder, extra_signatories: signatories }
}

fn mock_utxo_ref(tx_id: Int, index: Int) -> OutputReference {
  OutputReference { transaction_id: tx_id, output_index: index }
}

fn sample_mint(amount: Int) -> Mint {
  Mint { value: amount }
}

// ============================================================================
// SPENDING TESTS
// ============================================================================
test redeem_success() {
  trace @"TEST: redeem_success starting"
  let datum = Some(sample_datum())
  let tx = sample_transaction([sample_customer()])
  let input = mock_utxo_ref(0, 0)

  loyalty.spend(datum, Redeem, input, tx)
}

test revoke_success() {
  trace @"TEST: revoke_success starting"
  let datum = Some(sample_datum())
  let tx = sample_transaction([sample_merchant()])
  let input = mock_utxo_ref(0, 0)

  loyalty.spend(datum, Revoke, input, tx)
}

test redeem_failure_intruder() {
  trace @"TEST: redeem_failure_intruder starting"
  let datum = Some(sample_datum())
  let tx = sample_transaction([sample_intruder()])
  let input = mock_utxo_ref(0, 0)

  !loyalty.spend(datum, Redeem, input, tx)
}

// ============================================================================
// MINTING TESTS
// ============================================================================
test mint_success_correct_amount() {
  trace @"TEST: mint_success_correct_amount starting"
  let datum = sample_datum()
  let tx = sample_transaction([sample_merchant()])
  let mint_val = sample_mint(datum.token_amount)

  loyalty_mint.mint(datum, mint_val, tx)
}

test mint_success_second_time() {
  trace @"TEST: mint_success_second_time starting"
  let datum = sample_datum()
  let tx = sample_transaction([sample_merchant()])
  let mint_val = sample_mint(datum.token_amount)

  loyalty_mint.mint(datum, mint_val, tx)
}

test mint_failure_wrong_amount() {
  trace @"TEST: mint_failure_wrong_amount starting"
  let datum = sample_datum()
  let tx = sample_transaction([sample_merchant()])
  let mint_val = sample_mint(123)

  // Wrong amount
  !loyalty_mint.mint(datum, mint_val, tx)
}

test mint_failure_intruder() {
  trace @"TEST: mint_failure_intruder starting"
  let datum = sample_datum()
  let tx = sample_transaction([sample_intruder()])
  let mint_val = sample_mint(datum.token_amount)

  !loyalty_mint.mint(datum, mint_val, tx)
}
