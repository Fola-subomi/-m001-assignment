use aiken/collection/list
use cardano/transaction.{Mint, Transaction}

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
// MINTING VALIDATOR
// ============================================================================
validator loyalty_mint {
  mint(redeemer: LoyaltyDatum, mint_val: Mint, tx: Transaction) {
    let signatories = tx.extra_signatories

    trace @"Mint path"

    // Rule 1: Merchant signature required
    expect list.has(signatories, redeemer.merchant)

    // Rule 2: Minted amount must match datum.token_amount
    let value = mint_val.value
    expect redeemer.token_amount == value

    True
  }

  else(_) {
    trace @"Minting validator failed"
    fail
  }
}

// ============================================================================
// HELPERS
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

fn sample_mint(amount: Int) -> Mint {
  Mint { value: amount }
}
