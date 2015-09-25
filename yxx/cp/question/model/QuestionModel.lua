--[[
@Author cuijinlong
@date 2015-7-11
--]]
local _Question = {};

--[[
	局部函数：组装测评模块试题的vo
]]
function _Question:getQuestionVo(cp_table,question_id)
    local questionBase = require "question.model.QuestionBase";
    local stringUtil = require "yxx.wrong_question_book.util.stringUtil";
    local question_info = questionBase:getQuesDetailByIdChar(question_id);
    local knowledge_point_codes = stringUtil:kwonledge_point_code_convert(question_info.knowledge_point_codes);
    local question_vo = {};
    question_vo.cp_id = cp_table.cp_id;
    question_vo.question_id = question_id;
    question_vo.bus_id = cp_table.bus_id;
    question_vo.cp_type_id = cp_table.cp_type_id;
    question_vo.subject_id = cp_table.subject_id;
    question_vo.scheme_id = cp_table.scheme_id;
    question_vo.structure_id = cp_table.structure_id;
    question_vo.knowledge_point_codes = knowledge_point_codes;
    question_vo.question_type_id = question_info.question_type_id;
    question_vo.nd_id = question_info.nd_id;
    question_vo.right_count = 0;
    question_vo.wrong_count = 0;
    question_vo.sequence_number = 0;
    question_vo.score = 0;
    return question_vo;
end

--[[
	局部函数：组装测评模块试题的insert语句
]]
function _Question:getQuestionInsertSqlTable(cp_question_table_arrs)
    local tableUtil = require "yxx.tool.TableUtil";
    local question_insert_sql_arrs = {};
    for i=1,#cp_question_table_arrs do
        local k_v_table = tableUtil:convert_sql(cp_question_table_arrs[i]);
        question_insert_sql_arrs[i] = "insert into t_cp_question("..k_v_table["k_str"]..") value("..k_v_table["v_str"]..");"
    end
    return question_insert_sql_arrs;
end
--[[
	局部函数：通过测评ID获得测评中试题的信息
]]
function _Question:getQuestionListByCpId(cp_id)
    local SSDBUtil = require "yxx.tool.SSDBUtil";
    local question_ids = SSDBUtil:hscan("yxx_cp_question_ids_"..cp_id,300);--等价于 select question_id from t_cp_question where cp_id = 204
    if not question_ids then
        ngx.say("{\"success\":false,\"info\":\"查询测评中的试题失败！\"}")
        return
    end
    local question_list = {};
    local kg_question_list = {};
    local zg_question_list = {};
    if question_ids[1]~="ok" then
        for i=1,#question_ids,2 do
            local  question_vo = SSDBUtil:multi_hget_hash("yxx_cp_question_info_"..cp_id.."_"..question_ids[i],
                --"cp_id","bus_id","cp_type_id","subject_id","scheme_id","score","wrong_count",
                --"structure_id","knowledge_point_codes","difficult_star","right_count","wrong_count",
                "question_id","answer","question_type_id",
                "nd_id","kg_zg","option_count",
                "file_id");--等价于 select * from t_cp_question where question_id=40770
            if question_vo ~= 'ok' and question_vo.kg_zg and tonumber(question_vo.kg_zg) == 1 then
                table.insert(kg_question_list,question_vo);
            else
                table.insert(zg_question_list,question_vo);
            end
        end
    end
    question_list.kg_question_list = kg_question_list;
    question_list.zg_question_list = zg_question_list;
    SSDBUtil:keepAlive();
    return question_list;
end
--[[
	局部函数：组装测评中试题集合的对象。
]]
function _Question:getQuestionVoList(cp_table,question_list)
    local SSDBUtil = require "yxx.tool.SSDBUtil";
    local cjson = require "cjson";
    local cp_question_table_arrs = {};
    for i=1,#question_list do
        --组装试卷中试题的Vo数组 start
        local question_vo = {};
        question_vo.cp_id = cp_table.cp_id;
        question_vo.question_id = question_list[i].info_id;
        question_vo.bus_id = cp_table.bus_id;
        question_vo.cp_type_id = cp_table.cp_type_id;
        question_vo.subject_id = cp_table.subject_id;
        question_vo.scheme_id = question_list[i].scheme_id;
        question_vo.structure_id = question_list[i].structure_id;
        question_vo.knowledge_point_codes = self:convertZsds(question_list[i].zsd_array);
        question_vo.answer = question_list[i].answer;
        question_vo.question_type_id = question_list[i].question_type_id;
        question_vo.nd_id = question_list[i].difficult_id;
        question_vo.kg_zg = question_list[i].kg_zg;
        question_vo.option_count = question_list[i].option_count;
        question_vo.file_id = question_list[i].file_id;
        question_vo.difficult_star = question_list[i].difficult_star;
        question_vo.score = 0;
        table.insert(cp_question_table_arrs, question_vo);
        if tonumber(question_vo.kg_zg) == 1 then
            self:cpHasKnowledgePoints(cp_table.cp_id,question_vo.knowledge_point_codes); --系统自动分析客观题，保持本次测评客观题涉及的知识点。
        end
        SSDBUtil:multi_hset("yxx_cp_question_info_"..cp_table.cp_id.."_"..question_list[i].info_id,question_vo);--等价于 select * from t_cp_question where question_id = 427705
        SSDBUtil:hset("yxx_cp_question_ids_"..cp_table.cp_id,question_list[i].info_id,question_list[i].kg_zg);--等价于 select question_id from t_cp_question where cp_id = 204
        --组装试卷中试题的Vo数组 end
    end
    SSDBUtil:keepAlive();
    return cp_question_table_arrs;
end
--[[
	局部函数：知识点的下划线处理    _23444_58733_78473_17729_  转换 ,23444,58733,78473_17729,
]]
local function convertZsds(self,zsd_array)
    local stringUtil = require "yxx.wrong_question_book.util.stringUtil";
    local knowledge_point_codes = "";
    if zsd_array and #zsd_array > 0 then
        local structure_code_temp  = "_";
        for j=1,#zsd_array do
            structure_code_temp = structure_code_temp..zsd_array[j].structure_code.."_"
        end
        if structure_code_temp ~= "_" then
            knowledge_point_codes = stringUtil:kwonledge_point_code_convert(structure_code_temp);
        end
    end
    return knowledge_point_codes;
end
_Question.convertZsds = convertZsds;

--[[
	局部函数：保持本次测评所包含的说有知识点。
]]
local function cpHasKnowledgePoints(self,cp_id,knowledge_point_codes)
    local SSDBUtil = require "yxx.tool.SSDBUtil";
    local cacheUtil = require "common.CacheUtil";
    local cjson = require "cjson";
    if knowledge_point_codes and knowledge_point_codes ~= "" then
        local structure_code_arrs = Split(knowledge_point_codes,",");
        for i=1,#structure_code_arrs do
            local structure_code = structure_code_arrs[i];
            if tostring(structure_code) ~= "" then
                local knowledge_points_vo = {};
                local structure_name = cacheUtil:hget("t_resource_structure_"..structure_code,"structure_name");
                knowledge_points_vo.structure_code = structure_code;
                knowledge_points_vo.structure_name =structure_name;
                knowledge_points_vo.right_count = 0;
                knowledge_points_vo.wrong_count = 0;
                --等价于select kownledge_point_codes from t_cp_answer where cp_id=32332
                SSDBUtil:hset("yxx_cp_has_knowledge_points_"..cp_id,structure_code,structure_name); --记录本次测评的所有涉及的知识点
                --等价于select * from t_cp_answer where cp_id=236 and structure_code=51523
                SSDBUtil:multi_hset("yxx_cp_has_knowledge_point_info_"..cp_id.."_"..structure_code,knowledge_points_vo);
            end
        end
    end
    SSDBUtil:keepAlive();
end
_Question.cpHasKnowledgePoints = cpHasKnowledgePoints;
return _Question;