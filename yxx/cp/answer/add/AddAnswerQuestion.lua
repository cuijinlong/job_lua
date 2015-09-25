--[[
@Author cuijinlong
@date 2015-8-14
--]]
local say = ngx.say
local answerModel = require "yxx.cp.answer.model.AnswerModel";
local parameterUtil = require "yxx.tool.ParameterUtil";
local SSDBUtil = require "yxx.tool.SSDBUtil";
local TS = require "resty.TS";
local cp_id = parameterUtil:getStrParam("cp_id", "");
local question_id = parameterUtil:getStrParam("question_id", "");
local identity_id = parameterUtil:getStrParam("identity_id", "");
local cp_type_id = parameterUtil:getStrParam("cp_type_id", "");
local person_id = parameterUtil:getStrParam("person_id", "");
local class_id = parameterUtil:getStrParam("class_id", "");
local bus_id = parameterUtil:getStrParam("bus_id", "");
local person_answer = parameterUtil:getStrParam("person_answer", "");
if string.len(cp_id) == 0 then
    say("{\"success\":false,\"info\":\"cp_id参数错误！\"}")
    return
end
if string.len(question_id) == 0 then
    say("{\"success\":false,\"info\":\"question_id参数错误！\"}")
    return
end
if string.len(identity_id) == 0 then
    say("{\"success\":false,\"info\":\"identity_id参数错误！\"}")
    return
end
if string.len(person_id) == 0 then
    say("{\"success\":false,\"info\":\"person_id参数错误！\"}")
    return
end
if string.len(cp_type_id) == 0 then
    say("{\"success\":false,\"info\":\"cp_type_id参数错误！\"}")
    return
end
if string.len(class_id) == 0 then
    say("{\"success\":false,\"info\":\"class_id参数错误！\"}")
    return
end
if string.len(bus_id) == 0 then
    say("{\"success\":false,\"info\":\"bus_id参数错误！\"}")
    return
end
local question_vo = SSDBUtil:multi_hget_hash("yxx_cp_question_info_"..cp_id.."_"..question_id,"answer","question_type_id","knowledge_point_codes","nd_id");
if string.len(person_answer) > 0 then
    --判断学生的作答是否正确
    local is_full_score = 0;
    if tostring(person_answer) == tostring(question_vo.answer) then
        is_full_score = 1;
    end
    local table ={};
    table.cp_id = cp_id;
    table.question_id = question_id;
    table.person_id = person_id;
    table.identity_id = identity_id;
    table.cp_type_id = cp_type_id;
    table.class_id = class_id;
    table.bus_id = bus_id;
    table.person_answer = person_answer;
    table.nd_id = question_vo.nd_id;
    table.question_type_id = question_vo.question_type_id;
    table.knowledge_point_codes = question_vo.knowledge_point_codes;
    table.score = 0;
    table.create_time = ngx.localtime();
    table.is_full_score = is_full_score;
    table.update_ts = TS.getTs();
    answerModel:SetAnswerQuestion(table);
else
    local table ={};
    table.cp_id = cp_id;
    table.question_id = question_id;
    table.person_id = person_id;
    table.identity_id = identity_id;
    table.cp_type_id = cp_type_id;
    answerModel:DelAnswerQuestion(table);
end
SSDBUtil:keepAlive();
-- todo 判断学生的作答是否正确 end
say("{\"success\": \"true\",\"info\":\"答案提交成功！\"}")

