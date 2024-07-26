import { newMockEvent } from "matchstick-as"
import { ethereum, Address, BigInt, Bytes } from "@graphprotocol/graph-ts"
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
} from "../generated/StickerDesigns/StickerDesigns"

export function createAdminFeeRecipientChangedEvent(
  newRecipient: Address
): AdminFeeRecipientChanged {
  let adminFeeRecipientChangedEvent = changetype<AdminFeeRecipientChanged>(
    newMockEvent()
  )

  adminFeeRecipientChangedEvent.parameters = new Array()

  adminFeeRecipientChangedEvent.parameters.push(
    new ethereum.EventParam(
      "newRecipient",
      ethereum.Value.fromAddress(newRecipient)
    )
  )

  return adminFeeRecipientChangedEvent
}

export function createOwnershipTransferredEvent(
  previousOwner: Address,
  newOwner: Address
): OwnershipTransferred {
  let ownershipTransferredEvent = changetype<OwnershipTransferred>(
    newMockEvent()
  )

  ownershipTransferredEvent.parameters = new Array()

  ownershipTransferredEvent.parameters.push(
    new ethereum.EventParam(
      "previousOwner",
      ethereum.Value.fromAddress(previousOwner)
    )
  )
  ownershipTransferredEvent.parameters.push(
    new ethereum.EventParam("newOwner", ethereum.Value.fromAddress(newOwner))
  )

  return ownershipTransferredEvent
}

export function createPublisherReputationFeeChangedEvent(
  newFee: BigInt
): PublisherReputationFeeChanged {
  let publisherReputationFeeChangedEvent =
    changetype<PublisherReputationFeeChanged>(newMockEvent())

  publisherReputationFeeChangedEvent.parameters = new Array()

  publisherReputationFeeChangedEvent.parameters.push(
    new ethereum.EventParam("newFee", ethereum.Value.fromUnsignedBigInt(newFee))
  )

  return publisherReputationFeeChangedEvent
}

export function createStickerCappedEvent(stickerId: BigInt): StickerCapped {
  let stickerCappedEvent = changetype<StickerCapped>(newMockEvent())

  stickerCappedEvent.parameters = new Array()

  stickerCappedEvent.parameters.push(
    new ethereum.EventParam(
      "stickerId",
      ethereum.Value.fromUnsignedBigInt(stickerId)
    )
  )

  return stickerCappedEvent
}

export function createStickerDesignPublishedEvent(
  stickerId: BigInt,
  publisher: Address,
  payoutAddress: Address,
  metadataCID: Bytes
): StickerDesignPublished {
  let stickerDesignPublishedEvent = changetype<StickerDesignPublished>(
    newMockEvent()
  )

  stickerDesignPublishedEvent.parameters = new Array()

  stickerDesignPublishedEvent.parameters.push(
    new ethereum.EventParam(
      "stickerId",
      ethereum.Value.fromUnsignedBigInt(stickerId)
    )
  )
  stickerDesignPublishedEvent.parameters.push(
    new ethereum.EventParam("publisher", ethereum.Value.fromAddress(publisher))
  )
  stickerDesignPublishedEvent.parameters.push(
    new ethereum.EventParam(
      "payoutAddress",
      ethereum.Value.fromAddress(payoutAddress)
    )
  )
  stickerDesignPublishedEvent.parameters.push(
    new ethereum.EventParam(
      "metadataCID",
      ethereum.Value.fromBytes(metadataCID)
    )
  )

  return stickerDesignPublishedEvent
}

export function createStickerEndTimeChangedEvent(
  stickerId: BigInt,
  endTime: BigInt
): StickerEndTimeChanged {
  let stickerEndTimeChangedEvent = changetype<StickerEndTimeChanged>(
    newMockEvent()
  )

  stickerEndTimeChangedEvent.parameters = new Array()

  stickerEndTimeChangedEvent.parameters.push(
    new ethereum.EventParam(
      "stickerId",
      ethereum.Value.fromUnsignedBigInt(stickerId)
    )
  )
  stickerEndTimeChangedEvent.parameters.push(
    new ethereum.EventParam(
      "endTime",
      ethereum.Value.fromUnsignedBigInt(endTime)
    )
  )

  return stickerEndTimeChangedEvent
}

export function createStickerPriceSetEvent(
  stickerId: BigInt,
  paymentMethodId: BigInt,
  price: BigInt
): StickerPriceSet {
  let stickerPriceSetEvent = changetype<StickerPriceSet>(newMockEvent())

  stickerPriceSetEvent.parameters = new Array()

  stickerPriceSetEvent.parameters.push(
    new ethereum.EventParam(
      "stickerId",
      ethereum.Value.fromUnsignedBigInt(stickerId)
    )
  )
  stickerPriceSetEvent.parameters.push(
    new ethereum.EventParam(
      "paymentMethodId",
      ethereum.Value.fromUnsignedBigInt(paymentMethodId)
    )
  )
  stickerPriceSetEvent.parameters.push(
    new ethereum.EventParam("price", ethereum.Value.fromUnsignedBigInt(price))
  )

  return stickerPriceSetEvent
}

export function createStickerPublisherChangedEvent(
  stickerId: BigInt,
  from: Address,
  to: Address
): StickerPublisherChanged {
  let stickerPublisherChangedEvent = changetype<StickerPublisherChanged>(
    newMockEvent()
  )

  stickerPublisherChangedEvent.parameters = new Array()

  stickerPublisherChangedEvent.parameters.push(
    new ethereum.EventParam(
      "stickerId",
      ethereum.Value.fromUnsignedBigInt(stickerId)
    )
  )
  stickerPublisherChangedEvent.parameters.push(
    new ethereum.EventParam("from", ethereum.Value.fromAddress(from))
  )
  stickerPublisherChangedEvent.parameters.push(
    new ethereum.EventParam("to", ethereum.Value.fromAddress(to))
  )

  return stickerPublisherChangedEvent
}

export function createStickerRegistrationFeeChangedEvent(
  newFee: BigInt
): StickerRegistrationFeeChanged {
  let stickerRegistrationFeeChangedEvent =
    changetype<StickerRegistrationFeeChanged>(newMockEvent())

  stickerRegistrationFeeChangedEvent.parameters = new Array()

  stickerRegistrationFeeChangedEvent.parameters.push(
    new ethereum.EventParam("newFee", ethereum.Value.fromUnsignedBigInt(newFee))
  )

  return stickerRegistrationFeeChangedEvent
}
