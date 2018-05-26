hook.Add("InventoryPrepare", function()
    MOAT_INV.SQL:Query [[
        CREATE TABLE IF NOT EXISTS mg_slots (
            c int not null,
            locked boolean not null default 0,
            slotid int unsigned not null,
            steamid bigint unsigned not null,
            primary key(steamid, slotid)
        );
    ]]
end)