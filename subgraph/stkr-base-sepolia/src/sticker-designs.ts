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
  StickerRegistrationFeeChanged as StickerRegistrationFeeChangedEvent
} from "../generated/StickerDesigns/StickerDesigns"
import {
  StickerDesign,
  StickerDesignMetadata
} from "../generated/schema"
import { StickerDesignMetadata as StickerDesignMetadataTemplate } from "../generated/templates"



export function handleStickerDesignPublished(
  event: StickerDesignPublishedEvent
): void {
  let entity = new StickerDesign(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.stickerId = event.params.stickerId
  entity.publisher = event.params.publisher
  entity.payoutAddress = event.params.payoutAddress

  if (event.params.metadataCID) {
    entity.metadataCID = event.params.metadataCID.toHexString()
    StickerDesignMetadataTemplate.create(entity.metadataCID)
  }

  entity.save()
}



export function handleStickerDesignMetadata(content: Bytes): void {
  let stickerMeta = new StickerDesignMetadata(dataSource.stringParam())
  const value = json.fromBytes(content).toObject()
  if (value) {
    const imageCID = value.get('imageCID')
    const filename = value.get('filename')
    const contentType = value.get('contentType')
    const aspectRatio = value.get('aspectRatio')
    const size = value.get('size')

    if (imageCID == null || filename == null || contentType == null || aspectRatio == null || size == null) {
      return
    }

    stickerMeta.imageCID = imageCID.toString()
    stickerMeta.filename = filename.toString()
    stickerMeta.contentType = contentType.toString()
    stickerMeta.aspectRatio = aspectRatio.toBigInt()
    stickerMeta.size = size.toBigInt()
    stickerMeta.save()
  }
}