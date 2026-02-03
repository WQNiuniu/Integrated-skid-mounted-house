init_view : dialog {
    key = "title";
    initial_focus = "listbox";
    : list_box {
        tabs = "33";
        width = 40;
        key = "listbox";
        allow_accept = true;
    }
    ok_cancel_err;
}

// ============================================
// AutoCAD标题栏信息输入对话框
// 文件名: titleinfo.dcl
// ============================================

titleinfo : dialog {
    label = "标题栏信息输入";
    
    // 主布局 - 垂直排列
    : column {
        fixed_width = true;
        alignment = "left";
        
        // 项目信息组
        : boxed_column {
            label = "项目信息";
            
            : row {
                : text {
                    label = "一级项目标题:";
                    width = 15;
                    fixed_width = true;
                }
                : edit_box {
                    key = "title1";
                    width = 40;
                    fixed_width = true;
                    allow_accept = true;
                }
            }
            
            : row {
                : text {
                    label = "二级项目标题:";
                    width = 15;
                    fixed_width = true;
                }
                : edit_box {
                    key = "title2";
                    width = 40;
                    fixed_width = true;
                }
            }
            
            : row {
                : text {
                    label = "设计阶段:";
                    width = 15;
                    fixed_width = true;
                }
                : edit_box {
                    key = "phase";
                    width = 40;
                    fixed_width = true;
                }
            }
        }
        
        spacer_1;
        
        // 图纸信息组
        : boxed_column {
            label = "图纸信息";
            
            : row {
                : text {
                    label = "比例:";
                    width = 15;
                    fixed_width = true;
                }
                : edit_box {
                    key = "scale";
                    width = 15;
                    fixed_width = true;
                }
                
                : text {
                    label = "日期:";
                    width = 8;
                    fixed_width = true;
                }
                : edit_box {
                    key = "date";
                    width = 15;
                    fixed_width = true;
                }
                : button {
                    label = "今天";
                    key = "today";
                    width = 8;
                    fixed_width = true;
                }
            }
        }
        
        spacer_1;
        
        // 编号信息组
        : boxed_column {
            label = "编号信息";
            
            : row {
                : text {
                    label = "CADD号:";
                    width = 15;
                    fixed_width = true;
                }
                : edit_box {
                    key = "cadd";
                    width = 15;
                    fixed_width = true;
                }
                
                : text {
                    label = "文件号:";
                    width = 8;
                    fixed_width = true;
                }
                : edit_box {
                    key = "fileno";
                    width = 15;
                    fixed_width = true;
                }
            }
            
            : row {
                : text {
                    label = "项目号:";
                    width = 15;
                    fixed_width = true;
                }
                : edit_box {
                    key = "projectno";
                    width = 15;
                    fixed_width = true;
                }
                
                : text {
                    label = "版本号:";
                    width = 8;
                    fixed_width = true;
                }
                : edit_box {
                    key = "version";
                    width = 15;
                    fixed_width = true;
                }
            }
        }
    }
    ok_cancel_err;
}