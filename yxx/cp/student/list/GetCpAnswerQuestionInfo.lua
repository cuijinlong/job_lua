--[[
@Author cuijinlong
@date 2015-8-14
--]]
local say = ngx.say;
local cjson = require "cjson";
local QuestionModel = require "yxx.cp.question.model.QuestionModel";
local parameterUtil = require "yxx.tool.ParameterUtil";
local SSDBUtil = require "yxx.tool.SSDBUtil";
--  获取request的参数
local cp_id = parameterUtil:getStrParam("cp_id","");
local identity_id = parameterUtil:getStrParam("identity_id", "");
local person_id = parameterUtil:getStrParam("person_id", "");
if string.len(cp_id)==0 then
    say("{\"success\":false,\"info\":\"cp_id参数错误！\"}")
    return
end
if string.len(identity_id)==0 then
    say("{\"success\":false,\"info\":\"identity_id参数错误！\"}")
    return
end
if string.len(person_id)==0 then
    say("{\"success\":false,\"info\":\"person_id参数错误！\"}")
    return
end

local question_list = QuestionModel:getQuestionListByCpId(cp_id);
-- todo 将之前作答过得试题的作答结果返回
if question_list.kg_question_list then
    local kg_question_list = question_list.kg_question_list
    for i=1,#kg_question_list do
        local answer_question_tab = SSDBUtil:multi_hget_hash("yxx_cp_answer_question_"..cp_id.."_"..kg_question_list[i].question_id.."_"..identity_id.."_"..person_id,"question_id","person_answer","is_full_score");
        if answer_question_tab[1] ~= "ok" then
            if answer_question_tab.person_answer  and string.len(answer_question_tab.person_answer)>0 then
                kg_question_list[i].person_answer = answer_question_tab.person_answer;
                kg_question_list[i].is_full_score = answer_question_tab.is_full_score;

            else
                kg_question_list[i].person_answer = "";
                kg_question_list[i].is_full_score = 0;
            end
        end
    end
end
SSDBUtil:keepAlive()
cjson.encode_empty_table_as_object(false)

local json_data=cjson.encode(question_list)
say("{\"success\": \"true\",\"question_list\":"..json_data.."}")