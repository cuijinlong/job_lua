--[[
@Author chuzheng
@date 2014-12-18
@测试数据
功能：创建预习
--]]
local say = ngx.say;
local cjson = require "cjson";
local cpModel = require "yxx.cp.model.CpModel"; --测评的表
local SSDBUtil = require "yxx.tool.SSDBUtil";
local yxModel = require "yxx.preparation.teacher.model.YxModel";
local trainModel = require "yxx.preparation.train.model.TrainModel";
local materialModel = require "yxx.preparation.material.model.MaterialModel";
local yxPersonModel = require "yxx.preparation.person.model.PersonModel"; --预习的人员表
local cpPersonModel = require "yxx.cp.person.model.PersonModel"; --测评的表
local studentModel = require "yxx.student.model.StudentModel";
local preparetionModel = require "yxx.preparation.model.Model";
local parameterUtil = require "yxx.tool.ParameterUtil";
local param_json = parameterUtil:getStrParam("param_json","");
if not param_json or string.len(param_json) == 0 then
    say("{\"success\":false,\"info\":\"参数错误！\"}");
    return
end
local param_table = cjson.decode(ngx.decode_base64(param_json));
if  not param_table.yx_name or string.len(param_table.yx_name) == 0 or
    not param_table.person_id or string.len(param_table.person_id) == 0 or
    not param_table.identity_id or string.len(param_table.identity_id) == 0 or
    ((not param_table.class_ids or string.len(param_table.class_ids) == 0) and (not param_table.group_ids or string.len(param_table.group_ids) == 0)) or
    not param_table.is_public or string.len(param_table.is_public) == 0 or
    not param_table.scheme_id or string.len(param_table.scheme_id) == 0 or
    not param_table.structure_id or string.len(param_table.structure_id) == 0 or
    not param_table.subject_id or string.len(param_table.subject_id) == 0 then
    say("{\"success\":false,\"info\":\"参数错误！yx_name，person_id，identity_id，class_ids和group_ids（不能都为空）,structure_id,subject_id,is_public,scheme_id,structure_id都不能为空\"}");
    return
end

--第一步：组装预习的vo start
if tostring(param_table.yx_id) == "nil" or
        not param_table.yx_id or
            string.len(param_table.yx_id) == 0 then
    param_table.yx_id = tonumber(SSDBUtil:incr("yx_moudel_pk"));
end
local yx_table        = yxModel:getYxTableArrs(param_table);
local yx_insert_sql   = yxModel:getYxInsertSql(yx_table); --组装预习表的sql插入脚本
--组装预习的vo end

--第二步：组装环节和素材-----------------------------------------------------------------------------------------------------------------------------------------------------------
local tain_insert_sql_table    = {}; --环节表的insert语句数组
local material_inser_sql_table = {}; --素材表的insert语句数组
local cp_table_arrs            = {}; --存储本次预习中测评的信息
local cp_sql_table             = {}; --素材中测评的insert语句数组
if param_table.train_list and #param_table.train_list > 0 then
    --环节表
    local train_table_arrs     = {}; --存储本次预习的所有经过字段处理的环节
    local material_table_arrs  = {}; --存储本次预习的所有环节下的素材资源
    for i = 1, #param_table.train_list do
        --组装预习中环节的Vo数组 start
        local train_vo = trainModel:getTrainVo(yx_table.yx_id,param_table.train_list[i]); --组装环节VO
        table.insert(train_table_arrs, train_vo);
        --组装预习中环节的Vo数组 end
        --组装环节中素材的Vo数组 start
        local material_table = {};
        if param_table.train_list[i].material_list then
            material_table   = param_table.train_list[i].material_list; --环节i中的预习素材
        end
        if material_table and #material_table > 0 then
            for j=1,#material_table do
                material_table[j].material_id = tonumber(SSDBUtil:incr("yx_moudel_material_pk"));--生成环节中素材的ID
                if material_table[j].resource_type and string.len(material_table[j].resource_type) > 0
                        and material_table[j].resource_id  and string.len(material_table[j].resource_id) > 0 then
                    --如果格式化试卷，要添加到测评表 start
                    if tonumber(material_table[j].resource_type) == 3 and material_table[j].paper_source
                            and tonumber(material_table[j].paper_source) == 1 then
                        local cp_table         = {};
                        cp_table.parent_id     = -1;
                        cp_table.cp_id         = tonumber(SSDBUtil:incr("ceping_moudel_pk"));
                        cp_table.cp_name       = yx_table.yx_name;                        --测评名称
                        cp_table.bus_id        = yx_table.yx_id;                          --业务ID
                        cp_table.create_time   = ngx.localtime();                         --创建时间
                        cp_table.paper_id      = tonumber(material_table[j].resource_id);--试卷ID
                        cp_table.paper_id_char = material_table[j].paper_id;
                        cp_table.cp_type_id    = 2;                                       --1:作业 2:测评
                        cp_table.person_id     = yx_table.person_id;                      --创建人ID
                        cp_table.identity_id   = yx_table.identity_id;                    --创建人身份
                        cp_table.scheme_id     = yx_table.scheme_id;                      --教材版本ID
                        cp_table.structure_id  = yx_table.structure_id;                   --版本章节目录
                        cp_table.subject_id    = yx_table.subject_id;                     --学科ID
                        table.insert(cp_table_arrs, cp_table);                            --测评VO数组
                        SSDBUtil:multi_hset("cp_moudel_info_"..cp_table.cp_id,cp_table);
                        material_table[j].cp_id= cp_table.cp_id;                          --为了预习浏览页面中点击格式化试卷可以定位到测评。
                    end
                    table.insert(material_table_arrs, materialModel:getMaterialVo(train_vo.train_id, material_table[j])); --素材数组
                    --如果格式化试卷，要添加到测评表 end
                else
                    say("{\"success\":false,\"info\":\"素材的分类不能为空！\"}");
                    return;
                end
            end
        end
        --组装环节中素材的Vo数组 end
    end
    if train_table_arrs and #train_table_arrs > 0 then
        tain_insert_sql_table = trainModel:getTrainInsertSqlArrstable(train_table_arrs);--表名：t_yx_train（预习环节）
    end
    if material_table_arrs and #material_table_arrs > 0 then
        material_inser_sql_table = materialModel:getMaterialInsertSqlArrstable(material_table_arrs);--表名：t_yx_material（预习素材）
    end
    if cp_table_arrs and #cp_table_arrs > 0 then
        for i=1,#cp_table_arrs do
            table.insert(cp_sql_table, cpModel:CpMoudelInsertSql(cp_table_arrs[i])); --表名：t_cp_info（测评主表）
        end
    end
end

local success = "";
if tonumber(param_table.is_public) == 0 then
    --第三步：保存到数据库（方式：1、发布；2、不发布）-----------------------------------------------------------------------------------------------------------------------------------------------------------
    success = preparetionModel:saveYxToMysqlForUnpublic(yx_insert_sql,            --表名：t_yx_info（预习主表）
                                                        tain_insert_sql_table,    --表名：t_yx_train（预习环节）
                                                        material_inser_sql_table, --表名：t_yx_material（预习素材）
                                                        cp_sql_table              --表名：t_cp_info（测评主表）
                                                        );
elseif tonumber(param_table.is_public) == 1 then
    --第三步：组装预习对象的Vo--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    local person_table_arrs = studentModel:getPersonTableArrs(param_table.class_ids, param_table.group_ids); --通过班级和组查询基础数据
    --表名：t_yx_person（预习参与人）
    local yx_person_insert_sql_table = yxPersonModel:getPersonInsertSqlTable(yx_table.yx_id, person_table_arrs); --组装预习参与人的insert语句
    local cp_person_insert_sql_table = {}; --组装预习中测评的参与人的insert语句
    for i = 1, #cp_table_arrs do
        --表名：t_cp_person（测评参与人）
        table.insert(cp_person_insert_sql_table, cpPersonModel:getPersonInsertSqlTable(cp_table_arrs[i].cp_id,yx_table.yx_id,2,person_table_arrs));--2：表示预习
    end
    --第四步：保存到数据库（方式：1、发布；2、不发布）-----------------------------------------------------------------------------------------------------------------------------------------------------------
    success = preparetionModel:saveYxToMysqlForPublic(yx_insert_sql,              --表名：t_yx_info（预习主表）
                                                      tain_insert_sql_table,      --表名：t_yx_train（预习环节）
                                                      material_inser_sql_table,   --表名：t_yx_material（预习素材）
                                                      cp_sql_table,               --表名：t_cp_info（测评主表）
                                                      cp_person_insert_sql_table, --表名：t_cp_person（测评参与人）
                                                      yx_person_insert_sql_table  --表名：t_yx_person（预习参与人）
                                                     );
end
if tostring(success) == "true" then
    SSDBUtil:hset("preparation_yx_info",yx_table.yx_id,cjson.encode(param_table));
    SSDBUtil:multi_hset("yx_moudel_info_"..yx_table.yx_id,yx_table);
    say("{\"yx_id\":"..yx_table.yx_id..",\"success\":".. tostring(success)..",\"info\":\"保存成功\"}");
else
    say("{\"success\":false,\"info\":\"保存失败\"}");
end

