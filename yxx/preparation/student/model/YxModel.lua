--[[
@Author cuijinlong
@date 2015-5-22
--]]
local _YX = {};
--[[
	局部函数：学生列表
]]
function _YX:yx_list(person_id,identity_id,yx_name,structure_id,subject_id,sort_order,model_order)
    local MysqlUtil = require "yxx.tool.MysqlUtil";
    local SSDBUtil = require "yxx.tool.SSDBUtil";
    local db = MysqlUtil:getDb();
    local query_sql = "select yx_id from t_yx_person where person_id="..person_id.." and identity_id="..identity_id.." subject_id="..subject_id;
    local rows = MysqlUtil:query(query_sql);
    local return_table = {};
    for i=1,#rows do
        local yx_table = SSDBUtil:multi_hget_hash("yx_model_"..rows[i].yx_id,"yx_id","yx_name","create_time","person_id","identity_id","scheme_id","structure_id","subject_id");
        table.insert(return_table,yx_table);
    end
    MysqlUtil:close(db);
    return return_table;
end
--[[
	局部函数：提交预习
]]
function _YX:get_yx_detail(yx_id,person_id,identity_id)

end

--[[
	局部函数：提交预习
]]
function _YX:submit_yx(yx_id,person_id,identity_id)

end




return _YX;