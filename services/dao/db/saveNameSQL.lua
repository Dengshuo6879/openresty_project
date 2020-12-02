local sqls  = {
    SAVE = 
    [[INSERT INTO dsop_user(dsNameUUID, dsName) 
      VALUES("@dsNameUUID", "@dsName")
      ON DUPLICATE KEY UPDATE dsName="@dsName";]],
}

return sqls