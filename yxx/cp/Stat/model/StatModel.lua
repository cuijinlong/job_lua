local _Stat = {};
--[[
	局部函数：按知识点统计本次测评的错误率
	参数： cp_id 测评ID
]]
function _Stat:getKnowledgePointRate(cp_id)
    local SSDBUtil = require "yxx.tool.SSDBUtil";
    local DBUtil = require "common.DBUtil";
    local db = DBUtil:getDb();
    local return_table = {};
    local kownledge_points = SSDBUtil:hscan("yxx_cp_has_knowledge_points_"..cp_id,500);
    local rows = db:query("SELECT is_full_score,knowledge_point_codes from t_cp_answer where cp_id="..cp_id.." and update_ts<(select max(update_ts) from t_cp_person where cp_id="..cp_id.." and submit_state=1)");
    if kownledge_points[1]~="ok" then
        for i=1,#kownledge_points,2 do
            local kownledge_point_vo = {};
            local right_count = 0;
            local wrong_count = 0;
            kownledge_point_vo.kownledge_point_code = kownledge_points[i];
            kownledge_point_vo.kownledge_point_name = kownledge_points[i+1];
            local kownledge_point_code = ","..kownledge_points[i]..",";
            for j=1,#rows do
                local kownledge_point_codes = rows[j].knowledge_point_codes;
                if kownledge_point_codes and string.len(kownledge_point_codes)>0 then
                    local is_full_score = rows[j].is_full_score;
                    local is_find = string.find(kownledge_point_codes, kownledge_point_code);
                    if is_find and tonumber(is_find) > 0 then
                         if tonumber(is_full_score) == 1 then
                             right_count = right_count + 1;
                         else
                             wrong_count = wrong_count + 1;
                         end
                    end
                end
            end
            kownledge_point_vo.right_count = right_count;
            kownledge_point_vo.wrong_count = wrong_count;
            table.insert(return_table,kownledge_point_vo);
        end
    end
    DBUtil:keepDbAlive(db);
    SSDBUtil:keepAlive();
    return return_table;
end

--[[
	局部函数：按试题统计本次测评的错误率
	参数： cp_id 测评ID
]]
function _Stat:getQuestionRate(cp_id)
    local SSDBUtil = require "yxx.tool.SSDBUtil";
    local DBUtil = require "common.DBUtil";
    local db = DBUtil:getDb();
    local return_table = {};
    local question_ids = SSDBUtil:hscan("yxx_cp_question_ids_"..cp_id,500);--等价于 select question_id from t_cp_question where cp_id = 204
    local rows = db:query("SELECT is_full_score,question_id from t_cp_answer where cp_id="..cp_id.." and update_ts<(select max(update_ts) from t_cp_person where cp_id="..cp_id.." and submit_state=1)");
    --local rows = db:query("SELECT is_full_score,question_id from t_cp_answer where cp_id="..cp_id);
    if question_ids[1]~="ok" then
        for i=1,#question_ids,2 do
            local right_count = 0;
            local wrong_count = 0;
            local  question_vo = SSDBUtil:multi_hget_hash("yxx_cp_question_info_"..cp_id.."_"..question_ids[i],
                                "question_id","answer","question_type_id", "nd_id","kg_zg","option_count", "file_id");
            for j=1,#rows do
                local question_id = rows[j].question_id;
                local is_full_score = rows[j].is_full_score;
                if tonumber(question_id) == tonumber(question_ids[i]) then
                    if tonumber(is_full_score) == 1 then
                        right_count = right_count + 1;
                    else
                        wrong_count = wrong_count + 1;
                    end
                end
            end
            question_vo.right_count = right_count;
            question_vo.wrong_count = wrong_count;
            table.insert(return_table,question_vo);
        end
    end
    DBUtil:keepDbAlive(db);
    SSDBUtil:keepAlive();
    return return_table;
end

--[[
	局部函数：按知识点统计本次测评有哪些"学生"错题了
	参数： cp_id 测评ID  knowledge_point_code:知识点code
]]
function _Stat:getWrongStudentByKnowledgePointCode(cp_id,knowledge_point_code)
    local SSDBUtil = require "yxx.tool.SSDBUtil";
    local DBUtil = require "common.DBUtil";
    local PersonInfoModel = require "base.person.model.PersonInfoModel";
    local db = DBUtil:getDb();
    local return_table = {};
    local rows = db:query("SELECT person_id from t_cp_answer where cp_id="..cp_id.." and knowledge_point_codes like '%,"..knowledge_point_code..",%' and update_ts<(select max(update_ts) from t_cp_person where cp_id="..cp_id.." and submit_state=1) group by person_id");
    --local rows = db:query("SELECT person_id from t_cp_answer where cp_id="..cp_id.." and knowledge_point_codes like '%,"..knowledge_point_code..",%' group by person_id");
    for j=1,#rows do
       local person_vo = PersonInfoModel:getPersonDetail(rows[j].person_id,6);
        table.insert(return_table,person_vo);
    end
    DBUtil:keepDbAlive(db);
    SSDBUtil:keepAlive();
    return return_table;
end

--[[
	局部函数：：按知识点统计本次测评有哪些"学生"错题了
	参数： cp_id 测评ID
]]
function _Stat:getWrongStudentByQuestion(cp_id,question_id)
    local SSDBUtil = require "yxx.tool.SSDBUtil";
    local DBUtil = require "common.DBUtil";
    local PersonInfoModel = require "base.person.model.PersonInfoModel";
    local db = DBUtil:getDb();
    local return_table = {};
    local rows = db:query("SELECT person_id from t_cp_answer where cp_id="..cp_id.." and question_id="..question_id.." and update_ts<(select max(update_ts) from t_cp_person where cp_id="..cp_id.." and submit_state=1) group by person_id");
    --local rows = db:query("SELECT person_id from t_cp_answer where cp_id="..cp_id.." and question_id="..question_id.." group by person_id");
    for j=1,#rows do
        local person_vo = PersonInfoModel:getPersonDetail(rows[j].person_id,6);
        table.insert(return_table,person_vo);
    end
    DBUtil:keepDbAlive(db);
    SSDBUtil:keepAlive();
    return return_table;
end
return _Stat;