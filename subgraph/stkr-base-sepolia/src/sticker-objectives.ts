import {
  AdminTransferFailure as AdminTransferFailureEvent,
  NewObjective as NewObjectiveEvent,
  ObjectiveBanned as ObjectiveBannedEvent,
  ObjectiveUnbanned as ObjectiveUnbannedEvent,
  OwnershipTransferred as OwnershipTransferredEvent,
} from "../generated/StickerObjectives/StickerObjectives"
import {
  AdminTransferFailure,
  NewObjective,
  ObjectiveBanned,
  ObjectiveUnbanned,
  OwnershipTransferred,
} from "../generated/schema"

export function handleAdminTransferFailure(
  event: AdminTransferFailureEvent,
): void {
  let entity = new AdminTransferFailure(
    event.transaction.hash.concatI32(event.logIndex.toI32()),
  )
  entity.recipient = event.params.recipient
  entity.amount = event.params.amount

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleNewObjective(event: NewObjectiveEvent): void {
  let entity = new NewObjective(
    event.transaction.hash.concatI32(event.logIndex.toI32()),
  )
  entity.objective = event.params.objective
  entity.objectiveId = event.params.objectiveId
  entity.dev = event.params.dev

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleObjectiveBanned(event: ObjectiveBannedEvent): void {
  let entity = new ObjectiveBanned(
    event.transaction.hash.concatI32(event.logIndex.toI32()),
  )
  entity.objective = event.params.objective
  entity.objectiveId = event.params.objectiveId

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleObjectiveUnbanned(event: ObjectiveUnbannedEvent): void {
  let entity = new ObjectiveUnbanned(
    event.transaction.hash.concatI32(event.logIndex.toI32()),
  )
  entity.objective = event.params.objective
  entity.objectiveId = event.params.objectiveId

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleOwnershipTransferred(
  event: OwnershipTransferredEvent,
): void {
  let entity = new OwnershipTransferred(
    event.transaction.hash.concatI32(event.logIndex.toI32()),
  )
  entity.previousOwner = event.params.previousOwner
  entity.newOwner = event.params.newOwner

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}
