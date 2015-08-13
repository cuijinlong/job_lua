--[[
@Author cuijinlong
@date 2015-7-23
--]]
local _Person = {};

--[[
	局部函数：通过基础数据的人员信息，组装测评表的参与人插入脚本
]]
function _Person:getPersonInsertSqlTable(yx_id,person_table)
    local tableUtil = require "yxx.tool.TableUtil";
    local person_sql_table = {};
    if person_table then
        for i=1,#person_table do
            local person_vo = {};
            person_vo.yx_id = yx_id;
            person_vo.person_id = tonumber(person_table[i].STUDENT_ID);
            person_vo.identity_id = 6;
            person_vo.bureau_id = tonumber(person_table[i].BUREAU_ID);
            person_vo.class_id = tonumber(person_table[i].CLASS_ID);
            if person_table.group_id and string.len(group_id)>0 then
                person_vo.group_id = person_table[i].group_id;
            end
            person_vo.submit_state = 0;
            local k_v_table = tableUtil:convert_sql(person_vo);
            person_sql_table[i] = "insert into t_yx_person("..k_v_table["k_str"]..") value("..k_v_table["v_str"]..");"
        end
    end
    return person_sql_table;
end

--[[
	局部函数：通过基础数据的人员信息，组装测评表的参与人插入脚本
]]
function _Person:delYxPerson(yx_id,cp_type_id)
    local sql = "START TRANSACTION;delete FROM t_yx_person where yx_id="..yx_id..
                ";delete from t_cp_person where bus_id="..yx_id.." and cp_type_id="..cp_type_id..
                ";COMMIT;";
    local DBUtil = require "common.DBUtil";
    DBUtil:querySingleSql(sql);
end
return _Person;