--[[
@Author cuijinlong
@date 2015-7-28
--]]
local _Answer = {};

--[[
	局部函数：通过业务ID和业务类型获得测评ID
	bus_id：业务ID  作业：zy_id  预习:yx_id
	cp_type_id: 作业：1   预习：2
]]
function _Answer:isExistAnswerQuestion(bus_id,cp_type_id)
    local sql = "SELECT count(*) as TOTAL_ROW FROM t_cp_answer where bus_id="..bus_id.." and cp_type_id="..cp_type_id;
    local DBUtil = require "common.DBUtil";
    local queryResult = DBUtil:querySingleSql(sql);
    return tonumber(queryResult[1]["TOTAL_ROW"]);
end

return _Answer;