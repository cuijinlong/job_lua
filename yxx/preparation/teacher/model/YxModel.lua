--[[
@Author cuijinlong
@date 2015-5-22
--]]
local _YX = {};
--[[
	局部函数：创建预习
]]
function _YX:create_yx(table)
    local MysqlUtil = require "yxx.tool.MysqlUtil";
    local tableUtil = require "yxx.tool.TableUtil";
    local SSDBUtil = require "yxx.tool.SSDBUtil";
    local db = MysqlUtil:getDb();
    local yx_id = SSDBUtil:incr("yx_model_pk");
    table["yx_id"] = yx_id;
    SSDBUtil:multi_hset("yx_model_"..yx_id,table);
    local k_v_table = tableUtil:convert_sql(table);
    MysqlUtil:query("insert into t_cp_group("..k_v_table["k_str"]..") value("..k_v_table["v_str"]..")");
    MysqlUtil:close(db);
end

--[[
	局部函数：教师列表
]]
function _YX:teacher_yx_list(person_id,identity_id,yx_name,structure_id,subject_id,sort_order,model_order)
    local MysqlUtil = require "yxx.tool.MysqlUtil";
    local SSDBUtil = require "yxx.tool.SSDBUtil";
    local db = MysqlUtil:getDb();
    local query_sql = "select yx_id from t_yx_info where person_id="..person_id.." and identity_id="..identity_id.." and subject_id="..subject_id.." and is_delete=0";
    local rows = MysqlUtil:query(query_sql);
    local return_table = {};
    for i=1,#rows do
        local yx_table = SSDBUtil:multi_hget_hash("yx_model_"..rows[i].yx_id,"yx_id","yx_name","create_time","person_id","identity_id","scheme_id","structure_id","subject_id");
        table.insert(return_table,yx_table);
    end
    MysqlUtil:close(db);
    return return_table;
end

function _YX:getYxTableArrs(param_table)
    local yx_table = {};
    yx_table.yx_id = param_table.yx_id;
    yx_table.yx_name = param_table.yx_name;--预习名称
    yx_table.create_time = ngx.localtime();--创建时间
    yx_table.class_ids = param_table.class_ids;--预习对象(按班级留预习)
    yx_table.group_ids = param_table.group_ids;--预习对象(按组留预习)
    yx_table.person_id = tonumber(param_table.person_id);--创建人
    yx_table.identity_id = tonumber(param_table.identity_id);--创建人身份
    yx_table.scheme_id = tonumber(param_table.scheme_id);--教材版本ID
    yx_table.structure_id = tonumber(param_table.structure_id);--教材章节目录
    yx_table.subject_id = tonumber(param_table.subject_id);--学科ID
    yx_table.yx_conent = param_table.yx_conent;--预习说明
    yx_table.is_delete = 0;--是否删除 0：未删除 1:删除
    yx_table.is_public = tonumber(param_table.is_public);--是否发布 1：发布 0表示未发布
    return yx_table;
end
--[[
	局部函数：组装预习表的insert语句
]]
function _YX:getYxInsertSql(yx_table)
    local tableUtil = require "yxx.tool.TableUtil";
    local k_v_table = tableUtil:convert_sql(yx_table);
    local insert_sql = "delete from t_cp_info where cp_type_id=2 and bus_id="..yx_table.yx_id..";delete from t_yx_info where yx_id="..yx_table.yx_id..";insert into t_yx_info("..k_v_table["k_str"]..") value("..k_v_table["v_str"]..");"
    return insert_sql;
end
return _YX;