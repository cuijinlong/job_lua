--[[
@Author cuijinlong
@date 2015-9-16
--]]
local say = ngx.say
local statModel = require "yxx.cp.stat.model.StatModel";
local parameterUtil = require "yxx.tool.ParameterUtil";
local cjson = require "cjson";
--  获取request的参数
local cp_id = parameterUtil:getStrParam("cp_id", "");
local question_id = parameterUtil:getStrParam("question_id", "");
if string.len(cp_id) == 0 then
    say("{\"success\":false,\"info\":\"cp_id参数错误！\"}")
    return
end
if string.len(question_id) == 0 then
    say("{\"success\":false,\"info\":\"question_id参数错误！\"}")
    return
end
local return_table = {};
local person_table = statModel:getWrongStudentByQuestion(cp_id,question_id);
return_table.sucess = true;
return_table.person_table = person_table;
cjson.encode_empty_table_as_object(false);
local responseJson = cjson.encode(return_table);
say(responseJson);