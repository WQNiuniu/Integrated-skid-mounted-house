(defun c:dclloader ()
  ;; （测试用）选择并加载 DCL 文件，预览指定对话框
  (setq dlg_file (getfiled "选择要预览的对话框所在文件" "E:\\code\\Projects\\Integrated-skid-mounted-house\\demo.dcl" "DCL" 2))
  (if (= dlg_file nil) (exit))
  (setq dlg_name (getstring "\n对话框名称:"))
  (if (= dlg_name "") (exit))
  (setq dlg_id (load_dialog dlg_file))
  (if (< dlg_id 0) (exit))
  (setq std 0)
  (if (not (new_dialog dlg_name dlg_id)) (exit))
  (action_tile "accept" "(done_dialog 1)")
  (action_tile "cancel" "(done_dialog 0)")
  (setq std (start_dialog))
  (unload_dialog dlg_id)
  (cond ((= std 1) (princ "确定"))
	((= std 0) (princ "取消"))
	)
  (princ)
)

(defun c:blueprint ()
  ;; 加载包含对话框定义的 DCL 文件（当前 repo 中的 demo.dcl）
  (setq dlg_file "E:\\code\\Projects\\Integrated-skid-mounted-house\\demo.dcl")
  (setq dlg_id (load_dialog dlg_file))
  (if (< dlg_id 0)
    (progn (princ "\n无法加载对话文件: ") (princ dlg_file) (princ) (exit))
  )

  ;; 打开 blueprint_type 对话框
  (setq selected_type "architectural")  ;; 默认选择建筑图纸
  (if (not (new_dialog "blueprint_type" dlg_id))
    (progn (unload_dialog dlg_id) (princ "\n无法创建对话: blueprint_type") (exit))
  )
  ;; 设置单选按钮动作
  (action_tile "architectural" "(setq selected_type \"architectural\")")
  (action_tile "structural" "(setq selected_type \"structural\")")
  (action_tile "electrical" "(setq selected_type \"electrical\")")
  (action_tile "plumbing" "(setq selected_type \"plumbing\")")
  (action_tile "accept" "(done_dialog 1)")
  (action_tile "cancel" "(done_dialog 0)")

  (setq dlg_ret (start_dialog))

  ;; 如果用户按下确定，检查是否选择了建筑图纸
  (if (= dlg_ret 1)
    (progn
      (if (equal selected_type "architectural")
        (princ "\n已选择建筑图纸类型。")
        (princ (strcat "\n已选择图纸类型: " selected_type))
      )
      ;; 如果选择了建筑图纸，显示标题栏信息输入对话框
      (if (equal selected_type "architectural")
        (progn
          ;; 显示 title_table 对话框以输入标题栏信息
          (if (not (new_dialog "title_table" dlg_id))
            (princ "\n无法创建对话: title_table")
            (progn
              ;; 初始化默认值
              (init-title-dialog)
              
              ;; 设置控件动作
              (action_tile "today" 
                "(set_tile \"date\" (menucmd \"M=$(edtime,$(getvar,date),YYYY.MO.DD)\"))"
              )
              (action_tile "accept" 
                (strcat "(progn "
                       "(setq *title-info* (collect-title-info)) "
                       "(done_dialog 1)"
                       ")")
              )
              (action_tile "cancel" "(done_dialog 0)")
              
              ;; 启动对话框
              (setq title_ret (start_dialog))
              
              ;; 处理对话框返回结果
              (if (= title_ret 1)
                (progn
                  (princ "\n标题栏信息收集完成！")
                  (princ "\n正在生成表格...")
                  (generate-title-table)
                )
                (princ "\n用户取消了标题栏输入")
              )
            )
          )
        )
      )
    )
  )

  (unload_dialog dlg_id)
  (princ)
)

;; 初始化标题栏对话框默认值
(defun init-title-dialog ()
  (set_tile "scale" "1:100")
  (set_tile "version" "0")
  (set_tile "date" (menucmd "M=$(edtime,$(getvar,date),YYYY.MO.DD)"))
)

;; 收集标题栏信息
(defun collect-title-info ()
  (list
    (cons "一级项目标题" (get_tile "title1"))
    (cons "二级项目标题" (get_tile "title2"))
    (cons "设计阶段"     (get_tile "phase"))
    (cons "比例"         (get_tile "scale"))
    (cons "日期"         (get_tile "date"))
    (cons "CADD号"       (get_tile "cadd"))
    (cons "文件号"       (get_tile "fileno"))
    (cons "项目号"       (get_tile "projectno"))
    (cons "版本号"       (get_version_text))
  )
)

;; 获取版本号文本（根据数值转换为对应文本）
(defun get_version_text ()
  (cond
    ((= (get_tile "version") "0") "A版")
    ((= (get_tile "version") "1") "B版")
    ((= (get_tile "version") "2") "0版")
    (t "A版")
  )
)

;; 生成标题栏表格
(defun generate-title-table (/ select-pt insert-pt total-width total-height row-height
                               col-widths row-heights text-pt text-height
                               current-pt line-start line-end old-cmdecho
                               old-osmode old-textstyle)
  (princ "\n请选择表格右下角点: ")
  (setq select-pt (getpoint))
  
  ;; 保存当前系统变量
  (setq old-cmdecho (getvar "CMDECHO"))
  (setq old-osmode (getvar "OSMODE"))
  (setq old-textstyle (getvar "TEXTSTYLE"))
  
  ;; 设置系统变量
  (setvar "CMDECHO" 0)
  (setvar "OSMODE" 0)
  
  ;; 表格参数
  (setq total-width (+ 1500 2000 1500 2200 1800 3500 1500))  ; 总宽度：1500+2000+1500+2200+1800+3500+1500
  (setq total-height (+ 2000 (* 600 9)))                    ; 总高度：2000+600*9
  (setq row-height 600)                            ; 行高
  (setq col-widths '(1500 2000 1500 2200 1800 3500 1500))    ; 列宽（新增左侧两列）
  
  ;; 计算表格左下角点（选择点向左上方偏移）
  (setq insert-pt (list
    (- (car select-pt) total-width)
    (cadr select-pt)
    (caddr select-pt)
  ))
  
  ;; 调用绘制表格函数
  (draw-table insert-pt total-width total-height row-height col-widths)
  
  ;; 调用填充文字函数
  (fill-text insert-pt total-width total-height row-height col-widths)
)

;; 绘制表格函数
(defun draw-table (insert-pt total-width total-height row-height col-widths / p1 p2 p3 p4 current-pt col-total-widths)
  ;; 绘制表格外框
  (setq p1 insert-pt)
  (setq p2 (polar p1 0 total-width))
  (setq p3 (polar p2 (/ pi 2) total-height))
  (setq p4 (polar p3 pi total-width))
  (command "._pline" p1 p2 p3 p4 "_close")
  
  ;; 绘制内部横线
  (setq current-pt insert-pt)
  (repeat 3
    (setq current-pt (polar current-pt (/ pi 2) row-height))
    (command "._line" current-pt (polar current-pt 0 total-width) "")
  )
  (repeat 3
    (setq current-pt (polar current-pt (/ pi 2) row-height))
    (command "._line" current-pt (polar current-pt 0 3500) "")
  )
  (setq current-pt (polar current-pt (/ pi 2) row-height))
  (command "._line" current-pt (polar current-pt 0 total-width) "")
  (setq current-pt (polar current-pt (/ pi 2) row-height))
  (command "._line" current-pt (polar current-pt 0 1500) "")
  (setq current-pt (polar current-pt (/ pi 2) row-height))
  (command "._line" current-pt (polar current-pt 0 total-width) "")
  
  ;; 绘制内部竖线
  (setq current-pt insert-pt)
  (setq col-heights (list (* row-height 9) (* row-height 9) (* row-height 3) (* row-height 3) (* row-height 3) row-height))
  (foreach col (mapcar 'list col-widths col-heights)
    (setq current-pt (polar current-pt 0 (car col)))
    (command "._line" current-pt (polar current-pt (/ pi 2) (cadr col)) "")
  )
)

;; 填充文字函数
(defun fill-text (insert-pt total-width total-height row-height col-widths / text-pt text-height offset-left)
  ;; 左侧新增两列的总宽度偏移
  (setq offset-left (+ 1500 2000))

  ;; 表头
  (setq text-height 600)
  (setq text-pt (list 
    (+ (car insert-pt) 8400)
    (+ (cadr insert-pt) (+ (* row-height 9) 1300))
    0.0
  ))
  (command "._text" "_justify" "MC" "_non" text-pt text-height 0 "四川科宏石油天然气工程有限公司")

  (setq text-height 260)
  (setq text-pt (list 
    (+ (car insert-pt) 5000)
    (+ (cadr insert-pt) (* row-height 9.5))
    0.0
  ))
  (command "._text" "_justify" "MC" "_non" text-pt text-height 0 "设计证书编号：A151008377  甲级")

  (setq text-pt (list 
    (+ (car insert-pt) 11000)
    (+ (cadr insert-pt) (* row-height 9.5))
    0.0
  ))
  (command "._text" "_justify" "MC" "_non" text-pt text-height 0 "勘察证书编号：B151008377  甲级")

  ;; 分工表
  (setq text-height 300)
  (setq text-pt (list 
    (+ (car insert-pt)  (/ 1500 2))
    (+ (cadr insert-pt) (* row-height 8.5))
    0.0
  ))
  (command "._text" "_justify" "MC" "_non" text-pt text-height 0 "制图")

  (setq text-pt (list 
    (+ (car insert-pt)  (/ 1500 2))
    (+ (cadr insert-pt) (* row-height 7.5))
    0.0
  ))
  (command "._text" "_justify" "MC" "_non" text-pt text-height 0 "设计")

  (setq text-pt (list 
    (+ (car insert-pt)  (/ 1500 2))
    (+ (cadr insert-pt) (* row-height 6.5))
    0.0
  ))
  (command "._text" "_justify" "MC" "_non" text-pt text-height 0 "校对")

  (setq text-pt (list 
    (+ (car insert-pt)  (/ 1500 2))
    (+ (cadr insert-pt) (* row-height 5.5))
    0.0
  ))
  (command "._text" "_justify" "MC" "_non" text-pt text-height 0 "审核")

  (setq text-pt (list 
    (+ (car insert-pt)  (/ 1500 2))
    (+ (cadr insert-pt) (* row-height 4.5))
    0.0
  ))
  (command "._text" "_justify" "MC" "_non" text-pt text-height 0 "审定")

  ;; 一级项目标题
  (setq text-height 400)
  (setq text-pt (list 
    (+ (car insert-pt) (/ total-width 2))
    (+ (cadr insert-pt) (* row-height 8))  ; 第一行和第二行中间
    0.0
  ))

  (if (> (strlen (cdr (assoc "一级项目标题" *title-info*))) 0)
    (progn
      (command "._text" "_justify" "MC" "_non" text-pt text-height 0 
               (cdr (assoc "一级项目标题" *title-info*)))
    )
  )

  ;; 二级项目标题
  (setq text-height 400)
  (setq text-pt (list 
    (+ (car insert-pt) (/ total-width 2))
    (+ (cadr insert-pt) (* row-height 5))  ; 第3-5行的中间
    0.0
  ))

  (if (> (strlen (cdr (assoc "二级项目标题" *title-info*))) 0)
    (progn
      (command "._text" "_justify" "MC" "_non" text-pt text-height 0 
               (cdr (assoc "二级项目标题" *title-info*)))
    )
  )

  ;; 设计阶段
  (setq text-height 300)
  (setq text-pt (list 
    (+ (car insert-pt) offset-left (/ (nth 2 col-widths) 2))
    (+ (cadr insert-pt) (* row-height 2.5))
    0.0
  ))
  (command "._text" "_justify" "MC" "_non" text-pt text-height 0 "阶段")

  (setq text-pt (list 
    (+ (car insert-pt) offset-left 1500 (/ 2200 2))
    (+ (cadr insert-pt) (* row-height 2.5))
    0.0
  ))
  (if (> (strlen (cdr (assoc "设计阶段" *title-info*))) 0)
    (progn
      (command "._text" "_justify" "MC" "_non" text-pt text-height 0 
               (cdr (assoc "设计阶段" *title-info*)))
    )
  )

  ;; CADD号
  (setq text-height 300)
  (setq text-pt (list 
    (+ (car insert-pt) offset-left (+ 1500 2200) (/ 1800 2))
    (+ (cadr insert-pt) (* row-height 2.5))
    0.0
  ))
  (command "._text" "_justify" "MC" "_non" text-pt text-height 0 "CADD号")

  (setq text-pt (list 
    (+ (car insert-pt) offset-left (+ 1500 2200 1800) (/ 5000 2))
    (+ (cadr insert-pt) (* row-height 2.5))
    0.0
  ))
  (if (> (strlen (cdr (assoc "CADD号" *title-info*))) 0)
    (progn
      (command "._text" "_justify" "MC" "_non" text-pt text-height 0 
               (cdr (assoc "CADD号" *title-info*)))
    )
  )

  ;; 比例
  (setq text-height 300)
  (setq text-pt (list 
    (+ (car insert-pt) offset-left (/ (nth 2 col-widths) 2))
    (+ (cadr insert-pt) (* row-height 1.5))
    0.0
  ))
  (command "._text" "_justify" "MC" "_non" text-pt text-height 0 "比例")

  (setq text-pt (list 
    (+ (car insert-pt) offset-left 1500 (/ 2200 2))
    (+ (cadr insert-pt) (* row-height 1.5))
    0.0
  ))
  (if (> (strlen (cdr (assoc "比例" *title-info*))) 0)
    (progn
      (command "._text" "_justify" "MC" "_non" text-pt text-height 0 
               (cdr (assoc "比例" *title-info*)))
    )
  )

  ;; 文件号
  (setq text-height 300)
  (setq text-pt (list 
    (+ (car insert-pt) offset-left (+ 1500 2200) (/ 1800 2))
    (+ (cadr insert-pt) (* row-height 1.5))
    0.0
  ))
  (command "._text" "_justify" "MC" "_non" text-pt text-height 0 "文件号")

  (setq text-pt (list 
    (+ (car insert-pt) offset-left (+ 1500 2200 1800) (/ 5000 2))
    (+ (cadr insert-pt) (* row-height 1.5))
    0.0
  ))
  (if (> (strlen (cdr (assoc "文件号" *title-info*))) 0)
    (progn
      (command "._text" "_justify" "MC" "_non" text-pt text-height 0 
               (cdr (assoc "文件号" *title-info*)))
    )
  )

  ;; 日期
  (setq text-height 300)
  (setq text-pt (list 
    (+ (car insert-pt) offset-left (/ (nth 2 col-widths) 2))
    (+ (cadr insert-pt) (* row-height 0.5))
    0.0
  ))
  (command "._text" "_justify" "MC" "_non" text-pt text-height 0 "日期")

  (setq text-pt (list 
    (+ (car insert-pt) offset-left 1500 (/ 2200 2))
    (+ (cadr insert-pt) (* row-height 0.5))
    0.0
  ))
  (if (> (strlen (cdr (assoc "日期" *title-info*))) 0)
    (progn
      (command "._text" "_justify" "MC" "_non" text-pt text-height 0 
               (cdr (assoc "日期" *title-info*)))
    )
  )

  ;; 项目号
  (setq text-height 300)
  (setq text-pt (list 
    (+ (car insert-pt) offset-left (+ 1500 2200) (/ 1800 2))
    (+ (cadr insert-pt) (* row-height 0.5))
    0.0
  ))
  (command "._text" "_justify" "MC" "_non" text-pt text-height 0 "项目号")

  (setq text-pt (list 
    (+ (car insert-pt) offset-left (+ 1500 2200 1800) (/ 3500 2))
    (+ (cadr insert-pt) (* row-height 0.5))
    0.0
  ))
  (if (> (strlen (cdr (assoc "项目号" *title-info*))) 0)
    (progn
      
      (command "._text" "_justify" "MC" "_non" text-pt text-height 0 
               (cdr (assoc "项目号" *title-info*)))
    )
  )

  ;; 版本号
  (setq text-height 300)
  (setq text-pt (list 
    (+ (car insert-pt) offset-left (+ 1500 2200 1800 3500) (/ 1500 2))
    (+ (cadr insert-pt) (* row-height 0.5))
    0.0
  ))
  (if (> (strlen (cdr (assoc "版本号" *title-info*))) 0)
    (progn
      (command "._text" "_justify" "MC" "_non" text-pt text-height 0 
               (cdr (assoc "版本号" *title-info*)))
    )
  )

  ;; 恢复系统变量
  (setvar "CMDECHO" old-cmdecho)
  (setvar "OSMODE" old-osmode)
  (setvar "TEXTSTYLE" old-textstyle)

  (princ "\n标题栏表格生成完成！")
  t
)
