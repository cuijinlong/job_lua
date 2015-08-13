--[[
@Author cuijinlong
@date 2015-5-22
--]]
local _StatModel = {};
--[[
	局部函数：系统包含的所有作业、专题、微课 游戏总数
]]
function _StatModel:game_topic_count()
    --初始化变量
    local dbUtil = require "yxx.tool.DbUtil";
    local mysql_db = dbUtil:getMysqlDb();
    local query_sql = " SELECT IFNULL(COUNT(*),0) as count from t_yxx_game "..
                      " UNION "..
                      " SELECT IFNULL(COUNT(*),0) as count from t_yxx_topic;";
    local rows = mysql_db:query(query_sql);
    mysql_db:set_keepalive(0,v_pool_size);
    return rows;
end

--[[
	局部函数：系统包含的所有作业总数
]]
function _StatModel:zy_count()
    --初始化变量
    local dbUtil = require "yxx.tool.DbUtil";
    local mysql_db = dbUtil:getMysqlDb();
    local json = {};
    local all_sql = "SELECT IFNULL(COUNT(*),0) as count FROM t_zy_info";
    local xx_sql = "SELECT IFNULL(COUNT(*),0) as count FROM t_zy_info where SUBJECT_ID in(2,3,4,14,26,37,38,39,42,45,46,127)";
    local cz_sql = "SELECT IFNULL(COUNT(*),0) as count FROM t_zy_info where SUBJECT_ID in(5,6,7,8,9,11,12,13,15,32,36,43,47,48,49)";
    local gz_sql = "SELECT IFNULL(COUNT(*),0) as count FROM t_zy_info where SUBJECT_ID in(16,17,18,19,20,21,22,23,33,34,35,40,41,44,50)";
    local all_count = mysql_db:query(all_sql);
    local xx_count = mysql_db:query(xx_sql);
    local cz_count = mysql_db:query(cz_sql);
    local gz_count = mysql_db:query(gz_sql);
    json.all_count = all_count[1].count;
    json.xx_count = xx_count[1].count;
    json.cz_count = cz_count[1].count;
    json.gz_count = gz_count[1].count;
    mysql_db:set_keepalive(0,v_pool_size);
    return json;
end
--[[
	局部函数：系统包含的所有微课总数
]]
function _StatModel:wk_count()
    --初始化变量
    local dbUtil = require "yxx.tool.DbUtil";
    local cjson = require "cjson";
    local mysql_db = dbUtil:getMysqlDb();
    local json = {};
    local all_sql = "SELECT SQL_NO_CACHE COUNT(*) as count FROM t_wkds_info_sphinxse WHERE QUERY='filter=type,2;filter=type_id,6;filter=stage_id,4,5,6;filter=b_delete,0;limit=10000000'";
    local xx_sql = "SELECT SQL_NO_CACHE COUNT(*) as count FROM t_wkds_info_sphinxse WHERE QUERY='filter=type,2;filter=type_id,6;filter=stage_id,4;filter=b_delete,0;limit=10000000'";
    local cz_sql = "SELECT SQL_NO_CACHE COUNT(*) as count FROM t_wkds_info_sphinxse WHERE QUERY='filter=type,2;filter=type_id,6;filter=stage_id,5;filter=b_delete,0;limit=10000000'";
    local gz_sql = "SELECT SQL_NO_CACHE COUNT(*) as count FROM t_wkds_info_sphinxse WHERE QUERY='filter=type,2;filter=type_id,6;filter=stage_id,6;filter=b_delete,0;limit=10000000'";
    local all_count = mysql_db:query(all_sql);
    local xx_count = mysql_db:query(xx_sql);
    local cz_count = mysql_db:query(cz_sql);
    local gz_count = mysql_db:query(gz_sql);
    json.all_count = all_count[1].count;
    json.xx_count = xx_count[1].count;
    json.cz_count = cz_count[1].count;
    json.gz_count = gz_count[1].count;
    mysql_db:set_keepalive(0,v_pool_size);
    return json;
end

function _StatModel:get_moudel_subject(student_id)
    --初始化变量
    local dbUtil = require "yxx.tool.DbUtil";
    local cjson = require "cjson";
    local mysql_db = dbUtil:getMysqlDb();
    local json = {};
    --local zy_sql = "SELECT t2.SUBJECT_ID as zy_subject from t_zy_zytostudent t1 INNER JOIN t_zy_info t2 on t1.ZY_ID = t2.ID where t1.STUDENT_ID="..student_id.." and t2.STRUCTURE_ID="..structure_id.." GROUP BY zy_subject;";
    --local wk_sql = "SELECT t2.SUBJECT_ID as wk_subject from t_wkds_wktostudent t1 INNER JOIN t_wkds_info t2 on t1.wk_id = t2.id where t1.STUDENT_ID="..student_id.."t2.STRUCTURE_ID="..structure_id.." GROUP BY wk_subject";
    local zy_sql = "SELECT t2.SUBJECT_ID as zy_subject from t_zy_zytostudent t1 INNER JOIN t_zy_info t2 on t1.ZY_ID = t2.ID where t1.STUDENT_ID="..student_id.." GROUP BY zy_subject;";
    local wk_sql = "SELECT t2.SUBJECT_ID as wk_subject from t_wkds_wktostudent t1 INNER JOIN t_wkds_info t2 on t1.wk_id = t2.id where t1.STUDENT_ID="..student_id.." GROUP BY wk_subject";
    local zt_sql = "SELECT SUBJECT_ID AS topic_subject FROM t_yxx_topic GROUP BY SUBJECT_ID";
    local yx_sql = "SELECT SUBJECT_ID as game_subject FROM t_yxx_game GROUP BY SUBJECT_ID";
    local ct_sql = "SELECT SUBJECT_ID AS wq_subject from t_wrong_question_book where STUDENT_ID="..student_id.." GROUP BY wq_subject";
    local zy_rows = mysql_db:query(zy_sql);
    local wk_rows = mysql_db:query(wk_sql);
    local zt_rows = mysql_db:query(zt_sql);
    local yx_rows = mysql_db:query(yx_sql);
    local ct_rows = mysql_db:query(ct_sql);
    json.zy_subject_ids = zy_rows;
    json.wk_subject_ids = wk_rows;
    json.zt_subject_ids = zt_rows;
    json.yx_subject_ids = yx_rows;
    json.ct_subject_ids = ct_rows;
    mysql_db:set_keepalive(0,v_pool_size);
    return json;
end

-- 返回_StatModel对象
return _StatModel;
