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
function _YX:yxList(person_id,person_identity,subject_id,structure_id,sort_type,sort_mode,page_size,page_number)
    local MysqlUtil = require "yxx.tool.MysqlUtil";
    local SSDBUtil = require "yxx.tool.SSDBUtil";
    local offset = page_size*page_number-page_size;
    local limit = page_size;
    local str_maxmatches = page_number*100;
    --升序还是降序
    local asc_desc = "";
    if sort_mode == "1" then
        asc_desc = "asc";
    else
        asc_desc = "desc";
    end
    --排序
    local sort_filed="";
    if sort_type=="1" then
        sort_filed = "sort=attr_"..asc_desc..":update_ts;";
    end

    local query_condition = "";
    if person_id ~= "" then
        query_condition = query_condition.."filter=create_person_id,"..person_id..";";--预习创建人ID
    end
    if person_identity ~= "" then
        query_condition = query_condition.."filter=create_identity_id,"..person_identity..";";--预习创建人身份
    end
    if subject_id ~= "" then
        query_condition = query_condition.."filter=subject_id,"..subject_id..";";
    end
    if structure_id ~= "" then
        query_condition = query_condition.."filter=structure_id,"..structure_id..";";
    end
    local db = MysqlUtil:getDb();
    local query_sql = "SELECT SQL_NO_CACHE id FROM t_yx_person_sphinxse where QUERY=\'"..query_condition..sort_filed.."filter=is_delete,0;filter=class_id,0;filter=group_id,0;maxmatches="..str_maxmatches..";offset="..offset..";limit="..limit.."\';SHOW ENGINE SPHINX  STATUS;";
    local rows = MysqlUtil:query(query_sql);
    local read_result = db:read_result();
    local _,s_str = string.find(read_result[1]["Status"],"found: ");
    local e_str = string.find(read_result[1]["Status"],", time:");
    local total_row = string.sub(read_result[1]["Status"],s_str+1,e_str-1);
    local total_page = math.floor((total_row+page_size-1)/page_size);
    local return_table = {};
    for i=1,#rows do
        local yx_id= SSDBUtil:multi_hget("yxtoperson_"..rows[i].id,"yx_id");--rows[i].id：预习人员表的ID
        local yx_table = SSDBUtil:multi_hget_hash("yx_model_"..yx_id,"yx_id","yx_name","create_time","person_id","identity_id","scheme_id","structure_id","subject_id","is_public","class_ids","group_ids");
        table.insert(return_table,yx_table);
    end

    local result={};
    result["success"]="true";
    result["total_row"]=total_row;
    result["total_page"]=total_page;
    result["page_number"]=page_number
    result["page_size"]=page_size;
    result["list"]=return_table;
    MysqlUtil:close(db);
    return result;
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
    local SSDBUtil = require "yxx.tool.SSDBUtil";
    local ssdb = SSDBUtil.getDb();
    local TS = require "resty.TS";
    local yxtoperson_id = SSDBUtil:incr("t_yx_yxtoperson_pk");
    ssdb:multi_hset("yxtoperson_"..yxtoperson_id, "yx_id", yx_table.yx_id);
    local k_v_table = tableUtil:convert_sql(yx_table);
    local insert_sql = "START TRANSACTION;"..
                       "delete from t_cp_info where cp_type_id=2 and bus_id="..yx_table.yx_id..";"..
                       "delete from t_yx_info where yx_id="..yx_table.yx_id..";"..
                       "insert into t_yx_info("..k_v_table["k_str"]..") value("..k_v_table["v_str"]..");"..
                       "insert into t_yx_person(id,yx_id,person_id,identity_id,bureau_id,class_id,group_id,update_ts) value("..
                                                yxtoperson_id..","..yx_table.yx_id..",0,0,0,0,0,"..TS.getTs()..");"..
                       "COMMIT;"
    SSDBUtil:keepAlive();
    return insert_sql;
end
return _YX;