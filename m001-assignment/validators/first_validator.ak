use aiken/collection/list
use cardano/transaction.{OutputReference, Transaction}

// NOTE: Using `list.has` for signature check

// Datum
pub type LoyaltyDatum {
  customer: ByteArray,
  merchant: ByteArray,
  token_amount: Int,
  redeemed: Bool,
}

// Redeemer
pub type LoyaltyRedeemer {
  Redeem
  Revoke
}

// Validator
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
      Redeem -> list.has(signatories, datum.customer)

      Revoke -> list.has(signatories, datum.merchant)
    }
  }

  else(_) {
    fail
  }
}
