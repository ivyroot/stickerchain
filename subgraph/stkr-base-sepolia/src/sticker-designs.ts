import { json, Bytes, dataSource } from '@graphprotocol/graph-ts'
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
  StickerDesigns as StickerDesignsContract,
} from "../generated/StickerDesigns/StickerDesigns"
import {
  StickerDesign,
} from "../generated/schema"



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

  const contractInstance = StickerDesignsContract.bind(event.address)
  const stickerDesign = contractInstance.getStickerDesign(event.params.stickerId)
  entity.price = stickerDesign.price
  entity.endTime = stickerDesign.endTime
  entity.paymentMethodId = stickerDesign.paymentMethodId
  entity.publishedAt = stickerDesign.publishedAt
  entity.limit = stickerDesign.limit
  entity.limitToHolders = stickerDesign.limitToHolders

  if (event.params.metadataCID) {
    entity.metadataCID = event.params.metadataCID.toHexString()
  }

  entity.save()
}