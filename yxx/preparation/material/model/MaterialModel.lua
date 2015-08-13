--[[
@Author cuijinlong
@date 2015-7-23
--]]
local _Material = {};

--[[
	局部函数：组装环节中素材Vo数组
]]
function _Material:getMaterialVo(train_id,material_table)
    local SSDBUtil = require "yxx.tool.SSDBUtil";
    local material_vo = {}
    material_vo.material_id = tonumber(SSDBUtil:incr("yx_moudel_material_pk"));
    material_vo.train_id = train_id;
    material_vo.resource_type = tonumber(material_table.resource_type);
    material_vo.resource_id = tostring(material_table.resource_id);
    material_vo.view_count = 0;
    material_vo.discuss_count = 0;
    material_vo.is_download = 0;
    return material_vo;
end


--[[
	局部函数：组装insert sql语句
]]
function _Material:getMaterialInsertSqlArrstable(material_table_arrs)
    local tableUtil = require "yxx.tool.TableUtil";
    local sql_table = {};
    for i=1,#material_table_arrs do
        local k_v_table = tableUtil:convert_sql(material_table_arrs[i]);
        sql_table[i] = "insert into t_yx_material("..k_v_table["k_str"]..") value("..k_v_table["v_str"]..");"
    end
    return sql_table;
end

return _Material;