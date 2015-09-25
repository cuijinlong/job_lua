--[[
@Author cuijinlong
@date 2015-8-14
--]]
local say = ngx.say
local cjson = require "cjson"
local QuestionModel = require "yxx.cp.question.model.QuestionModel";
local parameterUtil = require "yxx.tool.ParameterUtil";
--  获取request的参数
local cp_id = parameterUtil:getStrParam("cp_id","");
if string.len(cp_id)==0 then
    say("{\"success\":false,\"info\":\"cp_id参数错误！\"}")
    return
end
local question_list = QuestionModel:getQuestionListByCpId(cp_id);
cjson.encode_empty_table_as_object(false)
local json_data=cjson.encode(question_list)
say("{\"success\": \"true\",\"question_list\":"..json_data.."}")