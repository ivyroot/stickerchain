import {
  Approval as ApprovalEvent,
  ApprovalForAll as ApprovalForAllEvent,
  ConsecutiveTransfer as ConsecutiveTransferEvent,
  OwnershipTransferred as OwnershipTransferredEvent,
  StickerSlapped as StickerSlappedEvent,
  StickerChain as StickerChainContract,
  Transfer as TransferEvent,
} from "../generated/StickerChain/StickerChain"
import {
  Slap,
} from "../generated/schema"
import { BigInt } from "@graphprotocol/graph-ts"

const SLAP_TYPE_ID = BigInt.fromI32(1)

export function handleStickerSlapped(event: StickerSlappedEvent): void {

  let entity = new Slap(
    event.transaction.hash.concatI32(event.logIndex.toI32()),
  )
  const contractInstance = StickerChainContract.bind(event.address)
  const slap = contractInstance.getSlap(event.params.slapId)
  entity.slapId = event.params.slapId
  entity.placeId = event.params.placeId
  entity.height = slap.height
  entity.stickerId = event.params.stickerId
  entity.player = event.params.player
  entity.owner = entity.player
  entity.size = event.params.size
  entity.slappedAt = event.block.timestamp
  entity.blockNumber = event.block.number
  entity.objectiveIds = slap.objectiveIds
  entity.typeId = SLAP_TYPE_ID

  entity.save()
}
