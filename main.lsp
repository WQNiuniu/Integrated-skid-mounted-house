;; ============================================
;; 五视图模板调用主脚本 (smart-template.lsp)
;; 支持多种模板类型：动态块、属性块、外部参照
;; ============================================

;; 全局配置
(defun load-config ()
  (setq *template-path* "C:/CAD_五视图生成器/模板文件/")
  (setq *standard-layers* '(("轮廓线" . 7) ("中心线" . 1) ("标注" . 2)))
  (setq *view-spacing* 50)  ;; 视图间距
  (setq *scale-factor* 1.0) ;; 缩放因子
)

;; 1. 模板检测函数
(defun detect-template-type (template-name)
  ;; 检测模板类型
  (cond
    ((findfile (strcat *template-path* template-name ".dwg"))
      (progn
        (setq blkdef (tblsearch "BLOCK" template-name))
        (cond
          ((and blkdef (assoc 280 blkdef)) 'dynamic-block)  ;; 动态块
          ((tblsearch "ATTDEF" "LENGTH") 'attribute-block)   ;; 属性块
          (t 'regular-block)                                 ;; 普通块
        )
      )
    )
    (t nil)
  )
)

;; 2. 动态块处理函数
(defun insert-dynamic-block (block-name ins-pt length width / blkref)
  ;; 插入并设置动态块参数
  (command "._-insert" block-name ins-pt 1 1 0)
  (setq blkref (entlast))
  
  ;; 获取动态块参数
  (if (vlax-property-available-p (vlax-ename->vla-object blkref) 'GetDynamicBlockProperties)
    (progn
      (setq dynprops (vlax-invoke (vlax-ename->vla-object blkref) 'GetDynamicBlockProperties))
      
      ;; 设置长度参数
      (foreach prop dynprops
        (if (wcmatch (strcase (vla-get-propertyname prop)) "*LENGTH*")
          (vla-put-value prop length)
        )
        (if (wcmatch (strcase (vla-get-propertyname prop)) "*WIDTH*")
          (vla-put-value prop width)
        )
      )
    )
  )
  blkref
)

;; 3. 属性块处理函数
(defun insert-attribute-block (block-name ins-pt length width)
  ;; 插入属性块并设置属性值
  (command "._insert" block-name ins-pt 1 1 0)
  
  ;; 设置属性值
  (setq blkref (entlast))
  (if (= (cdr (assoc 0 (entget blkref))) "INSERT")
    (progn
      (setq attdefs (entnext blkref))
      (while (and attdefs (= (cdr (assoc 0 (entget attdefs))) "ATTRIB"))
        (cond
          ((wcmatch (strcase (cdr (assoc 2 (entget attdefs)))) "*LENGTH*")
            (entmod (subst (cons 1 (rtos length 2 2)) 
                          (assoc 1 (entget attdefs)) 
                          (entget attdefs)))
          )
          ((wcmatch (strcase (cdr (assoc 2 (entget attdefs)))) "*WIDTH*")
            (entmod (subst (cons 1 (rtos width 2 2)) 
                          (assoc 1 (entget attdefs)) 
                          (entget attdefs)))
          )
        )
        (setq attdefs (entnext attdefs))
      )
    )
  )
  blkref
)

;; 4. 外部参照模板函数
(defun xref-template (template-file ins-pt length width scale / xref-name)
  ;; 以外部参照方式插入模板
  (setq xref-name (vl-filename-base template-file))
  
  ;; 插入外部参照
  (command "._-xref" "attach" template-file ins-pt scale scale 0)
  
  ;; 如果模板是参数化设计，通过数据提取调整
  (if (findfile (strcat *template-path* "参数表.csv"))
    (update-xref-parameters xref-name length width)
  )
  
  (entlast)
)

;; 5. 模板参数更新函数
(defun update-template-parameters (template-type entity length width)
  ;; 根据模板类型更新参数
  (cond
    ((= template-type 'dynamic-block)
      (update-dynamic-block entity length width)
    )
    ((= template-type 'attribute-block)
      (update-attribute-block entity length width)
    )
    ((= template-type 'xref)
      (update-xref-parameters entity length width)
    )
  )
)

;; 6. 五视图布局函数
(defun arrange-five-views (base-pt length width)
  ;; 计算五个视图的位置
  (setq spacing (* *view-spacing* *scale-factor*))
  
  (list
    ;; 主视图位置
    (list "主视图" base-pt 0)
    ;; 俯视图位置（上方）
    (list "俯视图" (polar base-pt (/ pi 2) (+ width spacing)) 0)
    ;; 左视图位置（左侧）
    (list "左视图" (polar base-pt pi (+ length spacing)) 0)
    ;; 右视图位置（右侧）
    (list "右视图" (polar base-pt 0 (+ length spacing)) 0)
    ;; 后视图位置（下方）
    (list "后视图" (polar base-pt (/ pi -2) (+ width spacing)) 0)
  )
)

;; 7. 主调用函数
(defun c:GENVIEWS (/ length width base-pt template-type views view-list)
  (load-config)
  
  ;; 用户输入
  (setq length (getreal "\n请输入图形长度: "))
  (setq width (getreal "\n请输入图形宽度: "))
  (setq base-pt (getpoint "\n选择插入基点: "))
  
  ;; 选择模板
  (initget "1 2 3")
  (setq template-choice 
    (getkword "\n选择模板类型 [1-动态块/2-属性块/3-外部参照]: "))
  
  ;; 根据选择设置模板类型和文件
  (cond
    ((= template-choice "1")
      (setq template-type 'dynamic-block)
      (setq template-file "五视图模板")
    )
    ((= template-choice "2")
      (setq template-type 'attribute-block)
      (setq template-file "五视图模板_属性")
    )
    ((= template-choice "3")
      (setq template-type 'xref)
      (setq template-file (strcat *template-path* "五视图模板.dwg"))
    )
  )
  
  ;; 检测模板是否存在
  (if (not (detect-template-type template-file))
    (progn
      (alert "未找到模板文件！请检查路径。")
      (exit)
    )
  )
  
  ;; 生成视图布局
  (setq view-list (arrange-five-views base-pt length width))
  
  ;; 插入并配置五个视图
  (foreach view-info view-list
    (setq view-name (nth 0 view-info))
    (setq view-pt (nth 1 view-info))
    (setq view-rot (nth 2 view-info))
    
    (princ (strcat "\n生成" view-name "..."))
    
    ;; 根据模板类型插入
    (cond
      ((= template-type 'dynamic-block)
        (insert-dynamic-block template-file view-pt length width)
      )
      ((= template-type 'attribute-block)
        (insert-attribute-block template-file view-pt length width)
      )
      ((= template-type 'xref)
        (xref-template template-file view-pt length width *scale-factor*)
      )
    )
    
    ;; 添加视图标签
    (add-view-label view-name view-pt)
  )
  
  ;; 生成中心线和标注
  (add-centerlines base-pt length width)
  (add-dimensions base-pt length width)
  
  (princ "\n✅ 五视图生成完成！")
  (princ)
)

;; 8. 视图标签函数
(defun add-view-label (view-name position / label-pt)
  (setq label-pt (polar position (* pi -0.5) 20))
  (command "._text" "j" "mc" label-pt 5 0 view-name)
)

;; 9. 批量处理函数（扩展功能）
(defun c:BATCHGEN (/ data-file count)
  ;; 从CSV文件批量生成
  (setq data-file (getfiled "选择参数文件" "" "csv" 0))
  (if data-file
    (progn
      (setq count 0)
      (setq data (read-csv data-file))  ;; 需要CSV读取函数
      (foreach row data
        (setq length (atof (nth 0 row)))
        (setq width (atof (nth 1 row)))
        (setq base-pt (list (atof (nth 2 row)) (atof (nth 3 row))))
        
        (c:GENVIEWS-helper length width base-pt)
        (setq count (1+ count))
      )
      (princ (strcat "\n批量生成完成，共生成 " (itoa count) " 组视图。"))
    )
  )
  (princ)
)

;; 10. 辅助函数
(defun c:GENVIEWS-helper (length width base-pt)
  ;; 供批量调用的辅助函数
  (c:GENVIEWS)
)

;; 11. 模板库管理函数
(defun c:MANAGETEMPLATES ()
  ;; 模板库管理界面
  (princ "\n=== 模板管理器 ===")
  (princ "\n1. 列出可用模板")
  (princ "\n2. 设置默认模板")
  (princ "\n3. 导入新模板")
  (princ "\n4. 编辑模板参数")
  
  (initget "1 2 3 4")
  (setq choice (getkword "\n选择操作 [1/2/3/4]: "))
  
  (cond
    ((= choice "1") (list-templates))
    ((= choice "2") (set-default-template))
    ((= choice "3") (import-template))
    ((= choice "4") (edit-template-params))
  )
)

;; 12. 错误处理函数
(defun *error* (msg)
  ;; 错误处理
  (if (not (wcmatch (strcase msg) "*BREAK,*CANCEL*,*EXIT*"))
    (princ (strcat "\n错误: " msg))
  )
  (setvar "CMDECHO" 1)
  (princ)
)

;; ============================================
;; 初始化加载
;; ============================================

(load-config)

(princ "\n✅ 五视图模板系统已加载")
(princ "\n可用命令:")
(princ "\n  GENVIEWS   - 生成五视图")
(princ "\n  BATCHGEN   - 批量生成")
(princ "\n  MANAGETEMPLATES - 管理模板库")
(princ)