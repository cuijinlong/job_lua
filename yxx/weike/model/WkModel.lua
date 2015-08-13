--[[
@Author cuijinlong
@date 2015-6-18
--]]
local _WK = {};
--[[
	局部函数:微课APP更新日志
	参数：
	subject_id：学科ID
]]
function _WK:app_update_record_add(table)
    local dbUtil = require "yxx.tool.DbUtil";
    local tableUtil = require "yxx.tool.TableUtil";
    local ssdb_db = dbUtil:getSSDb();
    local mysql_db = dbUtil:getMysqlDb();
    local apk_version_id = ssdb_db:incr("apk_version_pk");--生成主键ID
    table["id"]= tonumber(apk_version_id[1]);-- ID
    ssdb_db:multi_hset("apk_version_info_"..apk_version_id[1],table);--微课app（ssdb）
    local k_v_table = tableUtil:convert_sql(table);
    local rows = mysql_db:query("INSERT INTO t_wklm_app_version("..k_v_table["k_str"]..") value("..k_v_table["v_str"]..")");
    if not rows then
        ngx.print("{\"success\":\"false\",\"info\":\"添加失败。\"}");
        return;
    end
    ssdb_db:set_keepalive(0,v_pool_size);
    mysql_db:set_keepalive(0,v_pool_size);
end

--[[
	局部函数:微课APP更新日志列表
	参数：
	subject_id：学科ID
]]
function _WK:app_update_record_list(page_size,page_number)
    local dbUtil = require "yxx.tool.DbUtil";
    local ssdb_db = dbUtil:getSSDb();
    local mysql_db = dbUtil:getMysqlDb();
    local total_row	= 0;
    local total_page = 0;
    local total_rows_sql = "SELECT count(1) as TOTAL_ROW from t_wklm_app_version where 1=1;";
    local total_query = mysql_db:query(total_rows_sql);
    if not total_query then
        return {success=false, info="查询数据出错。"};
    end
    total_row = total_query[1]["TOTAL_ROW"];
    total_page = math.floor((total_row+page_size-1)/page_size);
    local offset = page_size*page_number-page_size;
    local limit  = page_size;
    local query_sql = "select id from t_wklm_app_version where 1=1 order by create_time desc limit " .. offset .. "," .. limit .. ";";
    local rows, err = mysql_db:query(query_sql);
    if not rows then
        return {success=false, info="查询数据出错。"};
    end
    local appArray = {};
    for i=1,#rows do
        local app_info = ssdb_db:multi_hget("apk_version_info_"..rows[i]["id"],"app_name","app_version","remark","apk_url","create_time")
        local ssdb_info = {};
        ssdb_info["id"]= rows[i]["id"];
        ssdb_info["app_name"]= app_info[2];
        ssdb_info["app_version"] = app_info[4];
        ssdb_info["remark"] = app_info[6];
        ssdb_info["apk_url"] = app_info[8];
        ssdb_info["create_time"] = app_info[10];
        table.insert(appArray, ssdb_info);
    end
    --------------------------------------------------------------------------------------------------------------------------------------------------------
    local appListJson = {};
    appListJson.success = true;
    appListJson.total_row   = total_row;
    appListJson.total_page  = total_page;
    appListJson.page_number = page_number;
    appListJson.page_size   = page_size;
    appListJson.list = appArray;
    ssdb_db:set_keepalive(0,v_pool_size);
    mysql_db:set_keepalive(0,v_pool_size);
    return appListJson;
end

--[[
	局部函数:获得最新微课APP路径
]]
function _WK:app_last_info()
    local dbUtil = require "yxx.tool.DbUtil";
    local ssdb_db = dbUtil:getSSDb();
    local mysql_db = dbUtil:getMysqlDb();
    local query_sql = "select id from t_wklm_app_version where 1=1 order by create_time desc limit 1;";
    local rows, err = mysql_db:query(query_sql);
    if not rows then
        return {success=false, info="查询数据出错。"};
    end
    local app_info = ssdb_db:multi_hget("apk_version_info_"..rows[1]["id"],"app_name","app_version","remark","apk_url","create_time")
    local ssdb_info = {};
    ssdb_info["id"]= rows[1]["id"];
    ssdb_info["app_name"]= app_info[2];
    ssdb_info["app_version"] = app_info[4];
    ssdb_info["remark"] = app_info[6];
    ssdb_info["apk_url"] = app_info[8];
    ssdb_info["create_time"] = app_info[10];
    ssdb_db:set_keepalive(0,v_pool_size);
    mysql_db:set_keepalive(0,v_pool_size);
    return ssdb_info;
end

--[[
	局部函数:微课APP更新日志
	参数：
	subject_id：学科ID
]]
function _WK:app_update_record_delete(id)
    local dbUtil = require "yxx.tool.DbUtil";
    local ssdb_db = dbUtil:getSSDb();
    local mysql_db = dbUtil:getMysqlDb();
    local query_sql = "delete from t_wklm_app_version where id="..id;
    local rows = mysql_db:query(query_sql);
    if not rows then
        return {success=false, info="删除失败。"};
    end
    ssdb_db:multi_hdel("apk_version_info_"..id,"id","app_name","app_version","remark","apk_url","create_time")
    ssdb_db:set_keepalive(0,v_pool_size);
    mysql_db:set_keepalive(0,v_pool_size);
end
return _WK
