import {
  Approval as ApprovalEvent,
  ApprovalForAll as ApprovalForAllEvent,
  ConsecutiveTransfer as ConsecutiveTransferEvent,
  OwnershipTransferred as OwnershipTransferredEvent,
  StickerSlapped as StickerSlappedEvent,
  Transfer as TransferEvent,
} from "../generated/StickerChain/StickerChain"
import {
  Slap,
} from "../generated/schema"


export function handleStickerSlapped(event: StickerSlappedEvent): void {
  let entity = new Slap(
    event.transaction.hash.concatI32(event.logIndex.toI32()),
  )
  entity.slapId = event.params.slapId
  entity.placeId = event.params.placeId
  entity.stickerId = event.params.stickerId
  entity.player = event.params.player
  entity.owner = entity.player
  entity.size = event.params.size

  entity.save()
}
