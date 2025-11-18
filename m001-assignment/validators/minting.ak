use aiken/collection/list
use cardano/transaction.{Mint, Transaction}

// ============================================================================
// DATUM (shared with spending validator)
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
//
// Rules:
//   1. Only the merchant can mint loyalty tokens.
//   2. The minted amount must equal the datum.token_amount.
//   3. The positive direction of mint.value represents minting.
//
validator loyalty_mint {
  mint(
    redeemer: LoyaltyDatum,
    _mint: Mint,
    tx: Transaction,
  ) {
    let signatories = tx.extra_signatories

    // Rule 1: Merchant signature required
    trace("Checking merchant signature for minting...")
    expect True = list.has(signatories, redeemer.merchant)

    // Rule 2: Minted amount must match datum.token_amount
    let mint_value = _mint.value

    trace("Checking minted amount...")
    expect redeemer.token_amount == mint_value

    True
  }

  else(_) {
    trace("Minting validator failed")
    fail
  }
}
