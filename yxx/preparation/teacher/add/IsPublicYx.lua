--[[
@Author chuzheng
@date 2014-12-18
@测试数据
功能：创建预习
--]]
local say = ngx.say;
local cjson = require "cjson";
local yxPersonModel = require "yxx.preparation.person.model.PersonModel"; --预习的人员表
local cpPersonModel = require "yxx.cp.person.model.PersonModel"; --测评的表
local cpModel = require "yxx.cp.model.CpModel"; --测评的表
local studentModel = require "yxx.student.model.StudentModel";
local preparetionModel = require "yxx.preparation.model.Model";
local parameterUtil = require "yxx.tool.ParameterUtil";
local answerUtil = require "yxx.cp.answer.AnswerModel"
local SSDBUtil = require "yxx.tool.SSDBUtil"
local ssdb = SSDBUtil:getDb();
local is_public = parameterUtil:getNumParam("is_public",0);--0：取消发布  1：发布
local class_ids = parameterUtil:getStrParam("class_ids",'');--发布的班级
local group_ids = parameterUtil:getStrParam("group_ids",'');--按组发布
local yx_id = parameterUtil:getStrParam("yx_id",'');--预习ID

if tonumber(is_public) == 0 then
    local isCanCancel = answerUtil:isExistAnswerQuestion(yx_id,2);
    if tonumber(isCanCancel) == 0 then
        yxPersonModel:delYxPerson(yx_id,2);--todo删除 cp_person yx_person
    else
        say("{\"success\":false,\"info\":\"已经有学生作答不能取消发布.\"}");
        return;
    end
    local yx_update_table = {};
    yx_update_table.is_public = 0;
    preparetionModel:updateYx(yx_id,yx_update_table);
    ssdb:multi_hset("yx_moudel_info_"..yx_id,"is_public",0);
    say("{\"success\":true,\"info\":\"预习取消发布成功！\"}");
elseif tonumber(is_public) == 1 then
    --第三步：组装预习对象的Vo-----------------------------------------------------------------------------------------------------------------------------------------------------------
    local person_table_arrs = studentModel:getPersonTableArrs(class_ids,group_ids); --通过班级和组查询基础数据
    --表名：t_yx_person（预习参与人）
    local yx_person_insert_sql_table = yxPersonModel:getPersonInsertSqlTable(yx_id, person_table_arrs); --组装预习参与人的insert语句
    local cp_person_insert_sql_table = {}; --组装预习中测评的参与人的insert语句
    local cp_id_arrs = cpModel:getCpIdByBusIdAndCpTypeId(yx_id,2);--通过bus_id，cp_type_id获得cp_id数组
    for i = 1,#cp_id_arrs do
        --表名：t_cp_person（测评参与人）
        table.insert(cp_person_insert_sql_table, cpPersonModel:getPersonInsertSqlTable(cp_id_arrs[i].cp_id,yx_id,2, person_table_arrs));
    end
    local success = "";
    --第四步：保存到数据库（方式：1、发布；2、不发布）-----------------------------------------------------------------------------------------------------------------------------------------------------------
    success = preparetionModel:YxPublic(
        cp_person_insert_sql_table, --组装预习中测评的参与人的insert语句
        yx_person_insert_sql_table --表名：t_yx_person（预习参与人）
    );
    if tostring(success) == "true" then
        local yx_update_table = {};
        yx_update_table.is_public = 1;
        preparetionModel:updateYx(yx_id,yx_update_table);
        ssdb:multi_hset("yx_moudel_info_"..yx_id,"is_public",1);
        say("{\"success\":" .. tostring(success) .. ",\"info\":\"预习发布成功！\"}");
    else
        say("{\"success\":false,\"info\":\"预习保存失败！\"}");
    end
end

SSDBUtil:_keepAlive();
