import { json, Bytes, dataSource, BigInt, Address } from '@graphprotocol/graph-ts'
import {
  AdminFeeRecipientChanged as AdminFeeRecipientChangedEvent,
  OwnershipTransferred as OwnershipTransferredEvent,
  PublisherReputationFeeChanged as PublisherReputationFeeChangedEvent,
  StickerCapped as StickerCappedEvent,
  StickerDesignPublished as StickerDesignPublishedEvent,
  StickerEndTimeChanged as StickerEndTimeChangedEvent,
  StickerPriceSet as StickerPriceSetEvent,
  StickerPublisherChanged as StickerPublisherChangedEvent,
  StickerRegistrationFeeChanged as StickerRegistrationFeeChangedEvent,
  StickerPayoutAddressSet as StickerPayoutAddressSetEvent,
  StickerLimitToHoldersSet as StickerLimitToHoldersSetEvent,
  StickerDesigns as StickerDesignsContract,
} from "../generated/StickerDesigns/StickerDesigns"
import {
  StickerDesign,
} from "../generated/schema"

function updateStickerDesignState(entity: StickerDesign, contractAddress: Address, stickerId: BigInt): void {
  const contractInstance = StickerDesignsContract.bind(contractAddress)
  const stickerDesign = contractInstance.getStickerDesign(stickerId)

  entity.price = stickerDesign.price
  entity.endTime = stickerDesign.endTime
  entity.paymentMethodId = stickerDesign.paymentMethodId
  entity.publishedAt = stickerDesign.publishedAt
  entity.limit = stickerDesign.limit
  entity.limitToHolders = stickerDesign.limitToHolders
}

export function handleStickerDesignPublished(
  event: StickerDesignPublishedEvent
): void {
  let entity = new StickerDesign(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.stickerId = event.params.stickerId
  entity.originalPublisher = event.params.publisher
  entity.currentPublisher = event.params.publisher
  entity.payoutAddress = event.params.payoutAddress

  if (event.params.metadataCID) {
    entity.metadataCID = event.params.metadataCID.toHexString()
  }

  updateStickerDesignState(entity, event.address, event.params.stickerId)
  entity.save()
}

export function handleStickerPublisherChanged(
  event: StickerPublisherChangedEvent
): void {
  let entity = StickerDesign.load(event.transaction.hash.concatI32(event.logIndex.toI32()))
  if (!entity) {
    entity = new StickerDesign(event.transaction.hash.concatI32(event.logIndex.toI32()))
  }
  entity.stickerId = event.params.stickerId
  entity.currentPublisher = event.params.to

  updateStickerDesignState(entity, event.address, event.params.stickerId)
  entity.save()
}

export function handleStickerPayoutAddressSet(
  event: StickerPayoutAddressSetEvent
): void {
  let entity = StickerDesign.load(event.transaction.hash.concatI32(event.logIndex.toI32()))
  if (!entity) {
    entity = new StickerDesign(event.transaction.hash.concatI32(event.logIndex.toI32()))
  }
  entity.stickerId = event.params.stickerId
  entity.payoutAddress = event.params.payoutAddress

  updateStickerDesignState(entity, event.address, event.params.stickerId)
  entity.save()
}

export function handleStickerPriceSet(
  event: StickerPriceSetEvent
): void {
  let entity = StickerDesign.load(event.transaction.hash.concatI32(event.logIndex.toI32()))
  if (!entity) {
    entity = new StickerDesign(event.transaction.hash.concatI32(event.logIndex.toI32()))
  }
  entity.stickerId = event.params.stickerId
  entity.price = event.params.price
  entity.paymentMethodId = event.params.paymentMethodId

  updateStickerDesignState(entity, event.address, event.params.stickerId)
  entity.save()
}

export function handleStickerEndTimeChanged(
  event: StickerEndTimeChangedEvent
): void {
  let entity = StickerDesign.load(event.transaction.hash.concatI32(event.logIndex.toI32()))
  if (!entity) {
    entity = new StickerDesign(event.transaction.hash.concatI32(event.logIndex.toI32()))
  }
  entity.stickerId = event.params.stickerId
  entity.endTime = event.params.endTime

  updateStickerDesignState(entity, event.address, event.params.stickerId)
  entity.save()
}

export function handleStickerCapped(
  event: StickerCappedEvent
): void {
  let entity = StickerDesign.load(event.transaction.hash.concatI32(event.logIndex.toI32()))
  if (!entity) {
    entity = new StickerDesign(event.transaction.hash.concatI32(event.logIndex.toI32()))
  }
  entity.stickerId = event.params.stickerId

  updateStickerDesignState(entity, event.address, event.params.stickerId)
  entity.save()
}

export function handleStickerLimitToHoldersSet(
  event: StickerLimitToHoldersSetEvent
): void {
  let entity = StickerDesign.load(event.transaction.hash.concatI32(event.logIndex.toI32()))
  if (!entity) {
    entity = new StickerDesign(event.transaction.hash.concatI32(event.logIndex.toI32()))
  }
  entity.stickerId = event.params.stickerId
  entity.limitToHolders = event.params.limitToHolders

  updateStickerDesignState(entity, event.address, event.params.stickerId)
  entity.save()
}