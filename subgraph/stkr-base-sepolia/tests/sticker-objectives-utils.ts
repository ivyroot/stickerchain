import { newMockEvent } from "matchstick-as"
import { ethereum, Address, BigInt } from "@graphprotocol/graph-ts"
import {
  AdminTransferFailure,
  NewObjective,
  ObjectiveBanned,
  ObjectiveUnbanned,
  OwnershipTransferred
} from "../generated/StickerObjectives/StickerObjectives"

export function createAdminTransferFailureEvent(
  recipient: Address,
  amount: BigInt
): AdminTransferFailure {
  let adminTransferFailureEvent = changetype<AdminTransferFailure>(
    newMockEvent()
  )

  adminTransferFailureEvent.parameters = new Array()

  adminTransferFailureEvent.parameters.push(
    new ethereum.EventParam("recipient", ethereum.Value.fromAddress(recipient))
  )
  adminTransferFailureEvent.parameters.push(
    new ethereum.EventParam("amount", ethereum.Value.fromUnsignedBigInt(amount))
  )

  return adminTransferFailureEvent
}

export function createNewObjectiveEvent(
  objective: Address,
  objectiveId: BigInt,
  dev: Address
): NewObjective {
  let newObjectiveEvent = changetype<NewObjective>(newMockEvent())

  newObjectiveEvent.parameters = new Array()

  newObjectiveEvent.parameters.push(
    new ethereum.EventParam("objective", ethereum.Value.fromAddress(objective))
  )
  newObjectiveEvent.parameters.push(
    new ethereum.EventParam(
      "objectiveId",
      ethereum.Value.fromUnsignedBigInt(objectiveId)
    )
  )
  newObjectiveEvent.parameters.push(
    new ethereum.EventParam("dev", ethereum.Value.fromAddress(dev))
  )

  return newObjectiveEvent
}

export function createObjectiveBannedEvent(
  objective: Address,
  objectiveId: BigInt
): ObjectiveBanned {
  let objectiveBannedEvent = changetype<ObjectiveBanned>(newMockEvent())

  objectiveBannedEvent.parameters = new Array()

  objectiveBannedEvent.parameters.push(
    new ethereum.EventParam("objective", ethereum.Value.fromAddress(objective))
  )
  objectiveBannedEvent.parameters.push(
    new ethereum.EventParam(
      "objectiveId",
      ethereum.Value.fromUnsignedBigInt(objectiveId)
    )
  )

  return objectiveBannedEvent
}

export function createObjectiveUnbannedEvent(
  objective: Address,
  objectiveId: BigInt
): ObjectiveUnbanned {
  let objectiveUnbannedEvent = changetype<ObjectiveUnbanned>(newMockEvent())

  objectiveUnbannedEvent.parameters = new Array()

  objectiveUnbannedEvent.parameters.push(
    new ethereum.EventParam("objective", ethereum.Value.fromAddress(objective))
  )
  objectiveUnbannedEvent.parameters.push(
    new ethereum.EventParam(
      "objectiveId",
      ethereum.Value.fromUnsignedBigInt(objectiveId)
    )
  )

  return objectiveUnbannedEvent
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
