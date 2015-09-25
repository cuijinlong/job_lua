--[[
@Author cuijinlong
@date 2015-7-11
--]]
local _Cp = {};
--[[
@Author cuijinlong
@date 2015-7-23
--]]
--[[
    获得测评主表的mysql插入脚本
    cp_id:测评ID
    cp_name:测评名称
    bus_id：业务ID（作业/预习/复习）
    parent_id：父亲ID 默认值-1
    paper_id：试卷ID
    person_id：人员ID
    identity_id：身份ID
    scheme_id：版本ID
    structure_id：目录结构ID
    subject_id：学科ID
    cp_type_id：测评类型（1：作业 2：测评）
--]]
function _Cp:CpMoudelInsertSql(cp_table)
    local questionModel = require "yxx.cp.question.model.QuestionModel";
    local paperService = require "paper.service.PaperService"; --试卷库接口，负责人:申健
    local cp_question_insert_sql_table = {}; --测评中的试题的insert语句数组
    local cp_insert_sql = self:getCpInsertSql(cp_table);  --组装测评信息的信息
    -- 通过paper_id_char 获得试卷中试题的详情
    local cp_question_table = paperService:getPaperDetailByIdChar(cp_table.paper_id_char);
    --将试卷中的试题组装成测评模块预习的VO对象。
    local cp_question_table_arrs = questionModel:getQuestionVoList(cp_table,cp_question_table.question_list);--装着本次测评的所有试题信息
    if cp_question_table_arrs and #cp_question_table_arrs>0 then
        cp_question_insert_sql_table = questionModel:getQuestionInsertSqlTable(cp_question_table_arrs);
    end
    local cp_model_insert_sql_table = self:getCpAndQuestionSql(cp_insert_sql,cp_question_insert_sql_table);
    return  cp_model_insert_sql_table
end
--[[
	局部函数：组装测评模块测评主表的insert语句
]]
local function getCpInsertSql(self,cp_table)
    local tableUtil = require "yxx.tool.TableUtil";
    local SSDBUtil = require "yxx.tool.SSDBUtil";
    local TS = require "resty.TS";
    local cptoperson_id = tonumber(SSDBUtil:incr("t_cp_cptoperson_pk"));
    local k_v_table = tableUtil:convert_sql(cp_table);
    local insert_sql = "insert into t_cp_info("..k_v_table["k_str"]..") value("..k_v_table["v_str"]..");"..
                       "insert into t_cp_person(id,cp_id,bus_id,cp_type_id,person_id,identity_id,bureau_id,class_id,group_id,update_ts) value("..
                                                tonumber(cptoperson_id)..","..cp_table.cp_id..","..cp_table.bus_id..","..cp_table.cp_type_id..","..
                                                "0,0,0,0,0,"..TS.getTs()..");";

    local ssdb = SSDBUtil:getDb();
    ssdb:multi_hset("cptoperson_"..cptoperson_id,"cp_id",cp_table.cp_id);--rows[i].id：测评人员表的ID
    SSDBUtil:keepAlive();
    return insert_sql;
end
_Cp.getCpInsertSql = getCpInsertSql;
--[[
	局部函数：获得测评模块的insert语句（不发布发布）
]]
local function getCpAndQuestionSql(self,cp_insert_sql,cp_question_insert_sql_table)
    local cpSqlTable = {};
    cpSqlTable[1] = cp_insert_sql;
    if cp_question_insert_sql_table then
        for i=1,#cp_question_insert_sql_table do
            cpSqlTable[1+i] = cp_question_insert_sql_table[i];
        end
    end
    return cpSqlTable;
end
_Cp.getCpAndQuestionSql = getCpAndQuestionSql;
--[[
	局部函数：通过业务ID和业务类型获得测评ID
	bus_id：业务ID  作业：zy_id  预习:yx_id
	cp_type_id: 作业：1   预习：2
]]
function _Cp:getCpIdByBusIdAndCpTypeId(bus_id,cp_type_id)
    local MysqlUtil = require "yxx.tool.MysqlUtil";
    local SSDBUtil = require "yxx.tool.SSDBUtil";
    local db = MysqlUtil:getDb();
    local ssdb = SSDBUtil:getDb();
    local query_sql = "SELECT SQL_NO_CACHE id FROM t_cp_person_sphinxse where QUERY=\'filter=bus_id,"..bus_id..";filter=cp_type_id,"..cp_type_id..";filter=class_id,0;filter=group_id,0;\';SHOW ENGINE SPHINX  STATUS;";
    local rows = db:query(query_sql);
    db:read_result()
    local return_table = {};
    for i=1,#rows do
        local cp_id = ssdb:multi_hget("cptoperson_"..rows[i].id,"cp_id");--rows[i].id：测评人员表的ID
        return_table[i]= tonumber(cp_id[2]);
    end
    MysqlUtil:close(db);
    SSDBUtil:keepAlive();
    return return_table;
end
--[[
	局部函数：判断测评的客观题是否回答结束
	cp_ids：测评ids  2425,2426,2427
]]
function _Cp:isKgQuestionAnswerFinished(bus_id,cp_type_id,person_id,identity_id)
    local SSDBUtil = require "yxx.tool.SSDBUtil";
    local DBUtil = require "common.DBUtil";
    local db = DBUtil:getDb();
    local return_table = {};
    return_table.success = true;
    local cp_rows = db:query("SELECT SQL_NO_CACHE id FROM t_cp_person_sphinxse WHERE query=\'filter=bus_id,"..bus_id..";filter=cp_type_id,"..cp_type_id..";filter=participantor_id,"..person_id..";filter=participantor_identity,"..identity_id..";\';SHOW ENGINE SPHINX  STATUS;");
    if cp_rows and cp_rows[1].id and string.len(cp_rows[1].id)>0 then
        for i=1,#cp_rows do
            local person_vo = SSDBUtil:multi_hget_hash("yxx_cptoperson_"..cp_rows[i].id,"cp_id");
            --等价于 select * from t_cp_question where cp_id=652
            local question_ids = SSDBUtil:hscan("yxx_cp_question_ids_"..person_vo.cp_id,200);
            if question_ids[1]~="ok" then
                for j=1,#question_ids,2 do
                    --只判断测评中的客观题是否打完，主观题不判断
                    if string.len(question_ids[j+1])>0 and tonumber(question_ids[j+1]) == 1 then
                        --判断本次测评每道题学生是否都已经作答，如果完成作答：true，否则：false;
                        local is_answer = SSDBUtil:hsize("yxx_cp_answer_question_"..person_vo.cp_id.."_"..question_ids[j].."_"..identity_id.."_"..person_id);
                        if tonumber(is_answer) == 0 then
                            local cp_vo = SSDBUtil:multi_hget_hash("cp_moudel_info_"..person_vo.cp_id,"paper_id");--select * from t_cp_info where cp_id=126
                            return_table.success = false;
                            return_table.cp_id = person_vo.cp_id;
                            return_table.resource_id = cp_vo.paper_id;
                            return return_table;
                        end
                    end
                end
            end
        end
    end
    DBUtil:keepDbAlive(db);
    SSDBUtil:keepAlive();
    return return_table;
end
--[[
	局部函数：测评的提交
	cp_ids：bus_id 业务ID  cp_type_id 业务类型   person_id 参与人  identity_id 身份
]]
function _Cp:cpSubmit(bus_id,cp_type_id,person_id,identity_id)
    local SSDBUtil = require "yxx.tool.SSDBUtil";
    local TS = require "resty.TS";
    local DBUtil = require "common.DBUtil";
    local db = DBUtil:getDb();
    local cp_rows = db:query("SELECT SQL_NO_CACHE id FROM t_cp_person_sphinxse WHERE query=\'filter=bus_id,"..bus_id..";filter=cp_type_id,"..cp_type_id..";filter=participantor_id,"..person_id..";filter=participantor_identity,"..identity_id..";\';SHOW ENGINE SPHINX  STATUS;");
    if cp_rows and cp_rows[1].id and string.len(cp_rows[1].id)>0 then
        for i=1,#cp_rows do
            local person_vo = SSDBUtil:multi_hget_hash("yxx_cptoperson_"..cp_rows[i].id,"bureau_id","bus_id","class_id","cp_id","cp_type_id","id","identity_id","person_id","submit_state","sum_score","update_ts");
            if person_vo and person_vo[1] ~= "ok" then
                local localtime = ngx.localtime();
                local update_ts = TS.getTs();
                person_vo.update_ts = update_ts;
                person_vo.submit_time = localtime;
                person_vo.submit_state = 1;
                --等价于  select * from t_cp_person where bus_id=122 and cp_type_id=2 and id=33651
                SSDBUtil:multi_hset("yxx_cptoperson_"..cp_rows[i].id,person_vo);
                local sql_update = "update t_cp_person set submit_state=1,submit_time='"..localtime.."',update_ts="..update_ts.." where id="..cp_rows[i].id..";";
                DBUtil:querySingleSql(sql_update);
                SSDBUtil:hset("cp_student_submit_"..person_vo.bus_id.."_"..person_vo.cp_type_id,cp_rows[i].id,tostring(localtime));--等价于  select count(*) from t_cp_person where bus_id=122 and cp_type_id=2 and submit_state=1
            end
        end
    end
    DBUtil:keepDbAlive(db);
    SSDBUtil:keepAlive();
    return true;
end
return _Cp;