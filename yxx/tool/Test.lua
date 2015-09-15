--local zyModel = require "yxx.zuoye.model.ZyModel";
--local wkModel = require "yxx.weike.model.WkModel";
--local cjson = require "cjson";
--local result = wkModel:getClassWkds(45,2000,1)
--cjson.encode_empty_table_as_object(false)
--local resultjson=cjson.encode(result)
--ngx.say(resultjson)
local cjson = require "cjson"
local zyModel = require "zy.model.zyModel"
local student_table = zyModel:getStudentByZyId(1076);
local result={}
result["success"]="true"
result["list"]=student_table
cjson.encode_empty_table_as_object(false)
local resultjson=cjson.encode(result)
ngx.say(resultjson)