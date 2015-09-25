--[[
@Author cuijinlong
@date 2015-7-11
--]]
local _Cp = {};
--[[
	局部函数：获得测评模块的insert语句（不发布发布）
]]
function _Cp:getCpInsertSqlForUpPublic(cp_insert_sql,cp_question_insert_sql_table)
    local MysqlUtil = require "yxx.tool.MysqlUtil";
    local cpSqlTable = {};
    cpSqlTable[1] = cp_insert_sql;
    if cp_question_insert_sql_table then
        for i=1,#cp_question_insert_sql_table do
            cpSqlTable[1+i] = cp_question_insert_sql_table[i];
        end
    end
end
--[[
	局部函数：带事务的保持测评信息（发布）
]]
function _Cp:getCpInsertSqlForPublic(cp_insert_sql,cp_question_insert_sql_table,cp_person_insert_table)
    local MysqlUtil = require "yxx.tool.MysqlUtil";
    local cpSqlTable = {};
    cpSqlTable[1] = cp_insert_sql;
    if cp_question_insert_sql_table then
        for i=1,#cp_question_insert_sql_table do
            cpSqlTable[1+i] = cp_question_insert_sql_table[i];
        end
    end
    if cp_person_insert_table then
        for i=1,#cp_person_insert_table do
            cpSqlTable[1+#cp_question_insert_sql_table+i] = cp_person_insert_table[i];
        end
    end
    return cpSqlTable;
end

--[[
	局部函数：带事务的保持测评信息（发布）
]]
function _Cp:PublicCp(cp_person_insert_table)
    local MysqlUtil = require "yxx.tool.MysqlUtil";
    local sqlTable = {};
    if cp_person_insert_table then
        for i=1,#cp_person_insert_table do
            sqlTable[i] = cp_person_insert_table[i];
        end
    end
    local db = MysqlUtil:getDb();
    local success = MysqlUtil:batch(sqlTable,#sqlTable);
    MysqlUtil:close(db);
    return success;
end

--[[
	局部函数：组装测评模块测评主表的insert语句
]]
local function getCpInsertSqlTable(cp_table)
    local tableUtil = require "yxx.tool.TableUtil";
    local k_v_table = tableUtil:convert_sql(cp_table);
    local insert_sql = "insert into t_cp_info("..k_v_table["k_str"]..") value("..k_v_table["v_str"]..");"
    return insert_sql;
end
_Cp.getCpInsertSqlTable = getCpInsertSqlTable;

return _Cp;