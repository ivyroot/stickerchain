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

const STICKER_DESIGN_TYPE_ID = BigInt.fromI32(0)

function updateStickerDesignState(entity: StickerDesign, contractAddress: Address): void {
  const contractInstance = StickerDesignsContract.bind(contractAddress)
  const stickerDesign = contractInstance.getStickerDesign(entity.stickerId)

  entity.originalPublisher = stickerDesign.originalPublisher
  entity.currentPublisher = stickerDesign.currentPublisher
  entity.payoutAddress = stickerDesign.payoutAddress
  entity.price = stickerDesign.price
  entity.endTime = stickerDesign.endTime
  entity.paymentMethodId = stickerDesign.paymentMethodId
  entity.publishedAt = stickerDesign.publishedAt
  entity.limit = stickerDesign.limit
  entity.limitToHolders = stickerDesign.limitToHolders
  entity.metadataCID = stickerDesign.metadataCID.toHexString()
  entity.typeId = STICKER_DESIGN_TYPE_ID
}

export function handleStickerDesignPublished(
  event: StickerDesignPublishedEvent
): void {
  let entity = new StickerDesign(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.stickerId = event.params.stickerId
  updateStickerDesignState(entity, event.address)
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
  updateStickerDesignState(entity, event.address)
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
  updateStickerDesignState(entity, event.address)
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
  updateStickerDesignState(entity, event.address)
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
  updateStickerDesignState(entity, event.address)
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
  updateStickerDesignState(entity, event.address)
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
  updateStickerDesignState(entity, event.address)
  entity.save()
}