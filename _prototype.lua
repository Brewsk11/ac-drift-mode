local Zone = class("Zone")
local Common = require("drift-mode.models.Common")


Zone.Model = class("Zone.Model")
Zone.Model.__model_path = "Elements.Zone:Model"

Zone.State = class("Zone.State")
Zone.Model.__model_path = "Elements.Zone:State"

Zone.Drawers = {}

Zone.Drawers.Base = class("Zone:Drawers:Base", Common.DrawerBase)
Zone.Drawers.Base.__model_path = "Elements.Zone:State"

Zone.Drawers.Run = class("Zone:Drawers:Run", Zone.Drawers.Base)
Zone.Drawers.Run.__model_path = "Elements.Zone:Drawers:Base"

Zone.Drawers.Setup = class("Zone:Drawers:Setup", Zone.Drawers.Base)
Zone.Drawers.Setup.__model_path = "Elements.Zone:Drawers:Setup"
