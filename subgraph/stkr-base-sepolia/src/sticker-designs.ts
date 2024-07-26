import {
  AdminFeeRecipientChanged as AdminFeeRecipientChangedEvent,
  OwnershipTransferred as OwnershipTransferredEvent,
  PublisherReputationFeeChanged as PublisherReputationFeeChangedEvent,
  StickerCapped as StickerCappedEvent,
  StickerDesignPublished as StickerDesignPublishedEvent,
  StickerEndTimeChanged as StickerEndTimeChangedEvent,
  StickerPriceSet as StickerPriceSetEvent,
  StickerPublisherChanged as StickerPublisherChangedEvent,
  StickerRegistrationFeeChanged as StickerRegistrationFeeChangedEvent
} from "../generated/StickerDesigns/StickerDesigns"
import {
  AdminFeeRecipientChanged,
  OwnershipTransferred,
  PublisherReputationFeeChanged,
  StickerCapped,
  StickerDesignPublished,
  StickerEndTimeChanged,
  StickerPriceSet,
  StickerPublisherChanged,
  StickerRegistrationFeeChanged
} from "../generated/schema"

export function handleAdminFeeRecipientChanged(
  event: AdminFeeRecipientChangedEvent
): void {
  let entity = new AdminFeeRecipientChanged(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.newRecipient = event.params.newRecipient

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleOwnershipTransferred(
  event: OwnershipTransferredEvent
): void {
  let entity = new OwnershipTransferred(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.previousOwner = event.params.previousOwner
  entity.newOwner = event.params.newOwner

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handlePublisherReputationFeeChanged(
  event: PublisherReputationFeeChangedEvent
): void {
  let entity = new PublisherReputationFeeChanged(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.newFee = event.params.newFee

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleStickerCapped(event: StickerCappedEvent): void {
  let entity = new StickerCapped(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.stickerId = event.params.stickerId

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleStickerDesignPublished(
  event: StickerDesignPublishedEvent
): void {
  let entity = new StickerDesignPublished(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.stickerId = event.params.stickerId
  entity.publisher = event.params.publisher
  entity.payoutAddress = event.params.payoutAddress
  entity.metadataCID = event.params.metadataCID

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleStickerEndTimeChanged(
  event: StickerEndTimeChangedEvent
): void {
  let entity = new StickerEndTimeChanged(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.stickerId = event.params.stickerId
  entity.endTime = event.params.endTime

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleStickerPriceSet(event: StickerPriceSetEvent): void {
  let entity = new StickerPriceSet(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.stickerId = event.params.stickerId
  entity.paymentMethodId = event.params.paymentMethodId
  entity.price = event.params.price

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleStickerPublisherChanged(
  event: StickerPublisherChangedEvent
): void {
  let entity = new StickerPublisherChanged(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.stickerId = event.params.stickerId
  entity.from = event.params.from
  entity.to = event.params.to

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleStickerRegistrationFeeChanged(
  event: StickerRegistrationFeeChangedEvent
): void {
  let entity = new StickerRegistrationFeeChanged(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.newFee = event.params.newFee

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}
