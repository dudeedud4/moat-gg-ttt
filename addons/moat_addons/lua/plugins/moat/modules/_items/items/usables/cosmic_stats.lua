ITEM.Name = "Cosmic Stat Mutator"
ITEM.ID = 4007
ITEM.Description = "Using this item allows you to re-roll the stats of any Cosmic item"
ITEM.Rarity = 7
ITEM.Collection = "Gamma Collection"
ITEM.Image = "https://moat.gg/assets/img/cosmic_stat64.png"
ITEM.ItemCheck = 6
ITEM.ItemUsed = function(pl, slot, item)
	m_ResetStats(pl, slot, item)
    m_SendInvItem(pl, slot)
end