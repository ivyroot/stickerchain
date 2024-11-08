import { CoinAdded as CoinAddedEvent } from "../generated/PaymentMethod/PaymentMethod"
import { ERC20 } from "../generated/PaymentMethod/ERC20"
import { Coin } from "../generated/schema"

export function handleCoinAdded(event: CoinAddedEvent): void {
  let entity = new Coin(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )

  // Get the ERC20 contract instance
  const tokenContract = ERC20.bind(event.params.coin)

  // Set basic properties
  entity.address = event.params.coin
  entity.paymentMethodId = event.params.coinId

  // Call ERC20 methods to get token details
  entity.name = tokenContract.name()
  entity.symbol = tokenContract.symbol()
  entity.decimals = tokenContract.decimals()

  entity.save()
}
